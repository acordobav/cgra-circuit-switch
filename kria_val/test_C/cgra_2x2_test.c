#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>

#define MAP_SIZE 4096

#define ROWS 2
#define COLS 2
#define TILES 4

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

uint32_t inj_data_flat[4];
uint32_t sel_flat[2];

uint8_t sel_cfg[ROWS][COLS][N_PORTS];

/* ============================= */
/* GPIO pointers                 */
/* ============================= */

volatile uint32_t *g0,*g1,*g2,*g3,*g4,*g5;

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
}

void write_sel()
{
    write_channel(g3,0,sel_flat[0]);
    write_channel(g3,1,sel_flat[1]);
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
    uint32_t out[4];

    out[0] = read_channel(g4,0);
    out[1] = read_channel(g4,1);

    out[2] = read_channel(g5,0);
    out[3] = read_channel(g5,1);

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

    g0 = map_gpio(fd,GPIO0_BASE);
    g1 = map_gpio(fd,GPIO1_BASE);
    g2 = map_gpio(fd,GPIO2_BASE);
    g3 = map_gpio(fd,GPIO3_BASE);
    g4 = map_gpio(fd,GPIO4_BASE);
    g5 = map_gpio(fd,GPIO5_BASE);

    printf("\nTEST 2x2 ONE TO ONE\n");

    setup_one_to_one(0,0,1,1);

    printf("SEL0 = %08X\n", sel_flat[0]);
    printf("SEL1 = %08X\n", sel_flat[1]);

    inj_data_flat[0] = 0xDEADBEEF;

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