#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>

#define MAP_SIZE 4096

#define ROWS 3
#define COLS 3
#define TILES 9

#define N_PORTS 5
#define SEL_W 3

#define LOCAL 0
#define NORTH 1
#define SOUTH 2
#define EAST 3
#define WEST 4
#define NONE 5

/* GPIO bases */

#define GPIO0_BASE  0xA0000000
#define GPIO1_BASE  0xA0010000
#define GPIO2_BASE  0xA0020000
#define GPIO3_BASE  0xA0030000
#define GPIO4_BASE  0xA0040000
#define GPIO5_BASE  0xA0050000

#define GPIO6_BASE  0xA0060000
#define GPIO7_BASE  0xA0070000
#define GPIO8_BASE  0xA0080000

#define GPIO9_BASE  0xA0090000
#define GPIO10_BASE 0xA00A0000
#define GPIO11_BASE 0xA00B0000
#define GPIO12_BASE 0xA00C0000
#define GPIO13_BASE 0xA00D0000


volatile uint32_t* map_gpio(int fd, off_t base_addr)
{
    return (volatile uint32_t*) mmap(
        NULL,
        MAP_SIZE,
        PROT_READ | PROT_WRITE,
        MAP_SHARED,
        fd,
        base_addr
    );
}

void write_channel(volatile uint32_t *base, int channel, uint32_t value)
{
    base[channel*2] = value;
}

uint32_t read_channel(volatile uint32_t *base, int channel)
{
    return base[channel*2];
}


/* ============================= */
/* Variables de configuración    */
/* ============================= */

uint32_t pe_op_gpio = 0;
uint32_t inj_en_gpio = 0;

uint32_t inj_data_flat[9];
uint32_t sel_flat[5];

uint8_t sel_cfg[ROWS][COLS][N_PORTS];


/* ============================= */
/* GPIO pointers                 */
/* ============================= */

volatile uint32_t *g0,*g1,*g2,*g3,*g4,*g5;
volatile uint32_t *g6,*g7,*g8;
volatile uint32_t *g9,*g10,*g11,*g12,*g13;


/* ============================= */
/* Escritura a GPIO              */
/* ============================= */

void write_pe_op()
{
    write_channel(g0,0,pe_op_gpio);
}

void write_inj_en()
{
    write_channel(g0,1,inj_en_gpio);
}

void write_inj_data()
{
    write_channel(g1,0,inj_data_flat[0]);
    write_channel(g1,1,inj_data_flat[1]);

    write_channel(g2,0,inj_data_flat[2]);
    write_channel(g2,1,inj_data_flat[3]);

    write_channel(g3,0,inj_data_flat[4]);
    write_channel(g3,1,inj_data_flat[5]);

    write_channel(g4,0,inj_data_flat[6]);
    write_channel(g4,1,inj_data_flat[7]);

    write_channel(g5,0,inj_data_flat[8]);
}

void write_sel()
{
    write_channel(g6,0,sel_flat[0]);
    write_channel(g6,1,sel_flat[1]);

    write_channel(g7,0,sel_flat[2]);
    write_channel(g7,1,sel_flat[3]);

    write_channel(g8,0,sel_flat[4]);
}


/* ============================= */
/* Limpieza                      */
/* ============================= */

void clear_route()
{
    for(int r=0;r<ROWS;r++)
        for(int c=0;c<COLS;c++)
            for(int p=0;p<N_PORTS;p++)
                sel_cfg[r][c][p] = NONE;
}

void clear_injection()
{
    memset(inj_data_flat,0,sizeof(inj_data_flat));
    inj_en_gpio = 0;
}

void clear_all()
{
    clear_route();
    clear_injection();

    memset(sel_flat,0,sizeof(sel_flat));
}


/* ============================= */
/* Convertir sel_cfg → sel_flat  */
/* ============================= */

void pack_sel()
{
    memset(sel_flat,0,sizeof(sel_flat));

    int index=0;

    for(int r=0;r<ROWS;r++)
    {
        for(int c=0;c<COLS;c++)
        {
            for(int p=0;p<N_PORTS;p++)
            {
                uint32_t val = sel_cfg[r][c][p];

                int bitpos = index * SEL_W;
                int word = bitpos / 32;
                int shift = bitpos % 32;

                sel_flat[word] |= (val << shift);

                index++;
            }
        }
    }
}


/* ============================= */
/* Routing Manhattan             */
/* ============================= */

void route_one_to_one(int src_r,int src_c,int dst_r,int dst_c)
{
    int cr = src_r;
    int cc = src_c;
    int inc_port = LOCAL;

    clear_route();

    while(cc < dst_c)
    {
        sel_cfg[cr][cc][EAST] = inc_port;
        cc++;
        inc_port = WEST;
    }

    while(cc > dst_c)
    {
        sel_cfg[cr][cc][WEST] = inc_port;
        cc--;
        inc_port = EAST;
    }

    while(cr < dst_r)
    {
        sel_cfg[cr][cc][SOUTH] = inc_port;
        cr++;
        inc_port = NORTH;
    }

    while(cr > dst_r)
    {
        sel_cfg[cr][cc][NORTH] = inc_port;
        cr--;
        inc_port = SOUTH;
    }

    sel_cfg[cr][cc][LOCAL] = inc_port;
}


/* ============================= */
/* Setup test                    */
/* ============================= */

void setup_one_to_one(int sr,int sc,int dr,int dc)
{
    clear_all();

    route_one_to_one(sr,sc,dr,dc);

    pack_sel();

    inj_en_gpio |= (1 << (sr*COLS + sc));
}


/* ============================= */
/* Leer outputs                  */
/* ============================= */

void print_pe_outputs()
{
    uint32_t out[9];

    out[0] = read_channel(g9,0);
    out[1] = read_channel(g9,1);

    out[2] = read_channel(g10,0);
    out[3] = read_channel(g10,1);

    out[4] = read_channel(g11,0);
    out[5] = read_channel(g11,1);

    out[6] = read_channel(g12,0);
    out[7] = read_channel(g12,1);

    out[8] = read_channel(g13,0);

    printf("\nPE outputs\n");

    for(int r=0;r<ROWS;r++)
        for(int c=0;c<COLS;c++)
            printf("PE[%d][%d] = %08X\n",r,c,out[r*COLS+c]);
}


/* ============================= */
/* MAIN                          */
/* ============================= */

int main()
{
    int fd = open("/dev/mem", O_RDWR | O_SYNC);

    g0  = map_gpio(fd,GPIO0_BASE);
    g1  = map_gpio(fd,GPIO1_BASE);
    g2  = map_gpio(fd,GPIO2_BASE);
    g3  = map_gpio(fd,GPIO3_BASE);
    g4  = map_gpio(fd,GPIO4_BASE);
    g5  = map_gpio(fd,GPIO5_BASE);

    g6  = map_gpio(fd,GPIO6_BASE);
    g7  = map_gpio(fd,GPIO7_BASE);
    g8  = map_gpio(fd,GPIO8_BASE);

    g9  = map_gpio(fd,GPIO9_BASE);
    g10 = map_gpio(fd,GPIO10_BASE);
    g11 = map_gpio(fd,GPIO11_BASE);
    g12 = map_gpio(fd,GPIO12_BASE);
    g13 = map_gpio(fd,GPIO13_BASE);


    printf("\nTEST 1 ONE TO ONE\n");

    setup_one_to_one(0,0,1,1);

    inj_data_flat[0] = 0xDEADBEEF;

    printf("SEL0 = %08X\n", sel_flat[0]);
    printf("SEL1 = %08X\n", sel_flat[1]);
    printf("SEL2 = %08X\n", sel_flat[2]);
    printf("SEL3 = %08X\n", sel_flat[3]);
    printf("SEL4 = %08X\n", sel_flat[4]);


    write_pe_op();
    write_sel();
    write_inj_data();
    write_inj_en();

    sleep(1);

    print_pe_outputs();

    while(1)
    {
        sleep(1);
        print_pe_outputs();
    }

}