`timescale 1ns / 1ps
import cgra_config_pkg::*; 

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2026 08:35:16 AM
// Design Name: 
// Module Name: tb_cgra_mesh
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_cgra_mesh;

// ===============================
// Señales principales
// ===============================
logic clk, rst;

// Sel signal
logic                inj_en_cfg   [ROWS][COLS];
logic [DATA_W-1:0]   inj_data_cfg [ROWS][COLS];
logic [SEL_W-1:0]    sel_cfg      [ROWS][COLS][N_PORTS];

//Interfaz de los PEs
logic                pe_op_cfg    [ROWS][COLS];
logic [DATA_W-1:0]   pe_out_obs   [ROWS][COLS];
logic [DATA_W-1:0]   pe_in_obs    [ROWS][COLS];

mesh_top uut (
    .clk         (clk),
    .rst         (rst),
    .pe_op_cfg   (pe_op_cfg),
    .inj_en_cfg  (inj_en_cfg),
    .inj_data_cfg(inj_data_cfg),
    .sel_cfg     (sel_cfg),
    .pe_out_obs  (pe_out_obs),
    .pe_in_obs   (pe_in_obs)
);

// ===============================
// CLOCK
// ===============================
always #5 clk = ~clk;  

// ===============================
// DEBUG
// ===============================
always @(posedge clk) begin
    // Si hay actividad en algun PE muestra el Flow
    if (|pe_in_obs[0][0] || |pe_in_obs[0][1] ||
        |pe_in_obs[1][0] || |pe_in_obs[1][1]) begin
        $display("T=%0t FLOW:", $time);
        print_pe_outputs();
    end
end

// ===============================
// Configuraciones de ruteo 
// ===============================
task automatic clear_all();
    // limpia toda la configuracion de la malla
    for (int i = 0; i < ROWS; i++) begin
        for (int j = 0; j < COLS; j++) begin
            pe_op_cfg[i][j]    = 0;
            inj_en_cfg[i][j]   = 0;
            inj_data_cfg[i][j] = 0;
            for (int p = 0; p < N_PORTS; p++)
                sel_cfg[i][j][p] = NONE;
        end
    end
endtask

task automatic print_pe_outputs();
    // Dump del estado actual de todos los PEs
    $display("---- PE OUTPUTS ----");
    for (int i = 0; i < ROWS; i++) begin
        for (int j = 0; j < COLS; j++) begin
            $display("PE[%0d][%0d] in=%h out=%h",
                i, j, pe_in_obs[i][j], pe_out_obs[i][j]);
        end
    end
    $display("--------------------");
endtask

// ===============================
// ROUTING
// ===============================
// ruta Manhattan
task automatic route_one_to_one(
    input int src_r, input int src_c,
    input int dst_r, input int dst_c
);
    int cr, cc, inc_port;

    clear_all();

    cr = src_r;
    cc = src_c;
    inc_port = LOCAL;

    // Camino Horizontal (EAST/WEST)
    while (cc < dst_c) begin
        sel_cfg[cr][cc][EAST] = inc_port;
        cc++; 
        inc_port = WEST;
    end
    while (cc > dst_c) begin
        sel_cfg[cr][cc][WEST] = inc_port;
        cc--; inc_port = EAST;
    end

    // Camino Vertical (NORTH/SOUTH)
    while (cr < dst_r) begin
        sel_cfg[cr][cc][SOUTH] = inc_port;
        cr++; inc_port = NORTH;
    end
    while (cr > dst_r) begin
        sel_cfg[cr][cc][NORTH] = inc_port;
        cr--; inc_port = SOUTH;
    end
    // Destino final
    sel_cfg[cr][cc][LOCAL] = inc_port; 
endtask

 // Ruta manual pasando por un PE intermedio
task automatic route_via_pes(
    input int src_r, input int src_c,
    input int mid_r, input int mid_c,
    input int dst_r, input int dst_c
);
    clear_all();

    // src -> mid
    sel_cfg[src_r][src_c][EAST] = LOCAL;

    // paso por PE intermedio
    sel_cfg[mid_r][mid_c][LOCAL] = WEST;
    sel_cfg[mid_r][mid_c][SOUTH] = LOCAL;

    // mid -> dst
    sel_cfg[dst_r][dst_c][LOCAL] = NORTH;
endtask

// ===============================
// SETUPS
// ===============================
task automatic setup_route_00_to_11();
    // Ruta fija (0,0) -> (1,1) pasando por (0,1)
    route_via_pes(0,0,0,1,1,1);
    inj_en_cfg[0][0] = 1;
endtask

// Broadcast simple a vecinos (derecha y abajo)
task automatic setup_broadcast_00_basic();
    clear_all();

    // distribuye hacia derecha y abajo
    sel_cfg[0][0][EAST]  = LOCAL;
    sel_cfg[0][0][SOUTH] = LOCAL;
    
    // Configuración de recepción
    sel_cfg[0][1][LOCAL] = WEST;
    sel_cfg[1][0][LOCAL] = NORTH;

    inj_en_cfg[0][0] = 1;
endtask

// ===============================
// WAIT HELPERS (para comparar el dato final)
// ===============================
task automatic wait_for_value_at(
    input int r, input int c,
    input logic [31:0] expected
);
    // Espera bloqueante hasta observar valor esperado
    wait (pe_out_obs[r][c] == expected); 
endtask

task automatic wait_for_two(
    input int r1, input int c1,
    input int r2, input int c2,
    input logic [31:0] expected
);
     // Sincroniza dos nodos
    wait (
        pe_out_obs[r1][c1] == expected &&
        pe_out_obs[r2][c2] == expected
    );
endtask

task automatic wait_for_all(
    input int r1, input int c1,
    input int r2, input int c2,
    input int r3, input int c3,
    input logic [31:0] expected
);
    // Sincroniza tres nodos
    wait (
        pe_out_obs[r1][c1] == expected &&
        pe_out_obs[r2][c2] == expected &&
        pe_out_obs[r3][c3] == expected
    );
endtask

// Envía dos paquetes consecutivos (pipeline)
task automatic send_two_packets(
    input logic [31:0] d1,
    input logic [31:0] d2,
    output logic [31:0] expected
);
    inj_data_cfg[0][0] = d1;
    repeat(2) @(posedge clk); // separación temporal

    inj_data_cfg[0][0] = d2;
    expected = d2; // último dato esperado en destino

    @(posedge clk);
    inj_en_cfg[0][0] = 0; // detener inyeccion
endtask

// ===============================
// TESTS
// ===============================
initial begin
    logic [31:0] expected;

    clk = 0;
    rst = 1;
    clear_all();

    repeat(2) @(posedge clk);
    rst = 0;

    // =====================================================
    $display("\n[TEST 1] ONE-TO-ONE");
    setup_route_00_to_11();

    inj_data_cfg[0][0] = 32'hDEADBEEF;
    wait_for_value_at(1,1, 32'hDEADBEEF);

    print_pe_outputs();
    $display("PASS TEST 1");

    // =====================================================
    $display("\n[TEST 2] NOT en el camino");

    route_via_pes(0,0,0,1,1,1);

    inj_en_cfg[0][0] = 1;
    inj_data_cfg[0][0] = 32'h0000FFFF;

    pe_op_cfg[0][1] = 1; // activar operacion en PE intermedio

    expected = ~32'h0000FFFF;

    wait_for_value_at(1,1, expected);

    print_pe_outputs();
    $display("PASS TEST 2 - Resultado %h", expected);

    // =====================================================
    $display("\n[TEST 3] BROADCAST");

    setup_broadcast_00_basic();

    inj_data_cfg[0][0] = 32'hCAFEBABE;
    repeat(3) @(posedge clk);

    inj_data_cfg[0][0] = 32'h12345678;

    wait_for_two(0,1, 1,0, 32'h12345678);

    print_pe_outputs();
    $display("PASS TEST 3");

    // =====================================================
    $display("\n[TEST 4] PIPELINE");

    setup_route_00_to_11();

    send_two_packets(32'hAAAA5555, 32'h1234ABCD, expected);
    wait_for_value_at(1,1, expected);

    print_pe_outputs();
    $display("PASS TEST 4");

    // =====================================================
    $display("\n[TEST 5] FULL BROADCAST");

    setup_broadcast_00_basic();

    // Extiende broadcast a todo el mesh
    sel_cfg[0][1][SOUTH] = WEST;
    sel_cfg[1][0][EAST]  = NORTH;
    sel_cfg[1][1][LOCAL] = WEST;

    inj_data_cfg[0][0] = 32'hFACE1234;

    wait_for_all(0,1, 1,0, 1,1, 32'hFACE1234);

    print_pe_outputs();
    $display("PASS TEST 5");

    // =====================================================
    $display("\nSimulation completed");
    $finish;
end

endmodule