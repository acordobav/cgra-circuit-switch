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

localparam int MAX_WAIT_CYCLES = 20;

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

`include "tb_includes/tb_tasks_clear.svh"
`include "tb_includes/tb_tasks_debug.svh"
`include "tb_includes/tb_tasks_routing.svh"
`include "tb_includes/tb_tasks_setups.svh"
`include "tb_includes/tb_tasks_waits.svh"
`include "tb_includes/tb_tasks_pipeline.svh"


// ===============================
// TESTS
// ===============================
initial begin
    logic [DATA_W-1:0] expected;

    clk = 0;
    rst = 1;
    debug_enable = 0;
    start_clean_test();

    // =====================================================
    $display("\n--------------------------------------");
    $display("\n[[RUN ] TEST  1 - ONE-TO-ONE long path");
    $display("\n--------------------------------------");
    start_clean_test();
    
    setup_one_to_one(0, 0, ROWS-1, COLS-1);

    inj_data_cfg[0][0] = 32'hDEADBEEF;
    wait_for_value_at(ROWS-1, COLS-1, 32'hDEADBEEF);

    print_pe_outputs();
    $display("[PASS] TEST 1");

    if (ROWS >= 2 && COLS >= 2) begin
    
        // =====================================================
        $display("\n--------------------------------------");
        $display("\n[RUN ] TEST 2 - NOT en el camino");
        $display("\n--------------------------------------");
        start_clean_test();
    
        route_via_single_mid_2x2(0,0,0,1,1,1);
    
        inj_en_cfg[0][0] = 1;
        inj_data_cfg[0][0] = 32'h0000FFFF;
    
        pe_op_cfg[0][1] = 1; // activar operacion en PE intermedio
    
        expected = ~32'h0000FFFF;
    
        wait_for_value_at(1,1, expected);
    
        print_pe_outputs();
        $display("[PASS] TEST 2 - Resultado %h", expected);
    
        // =====================================================
        $display("\n--------------------------------------");
        $display("\n[RUN ] TEST 3 - BROADCAST");
        $display("\n--------------------------------------");
        start_clean_test();
    
        setup_broadcast_00_basic_2x2();
    
        inj_data_cfg[0][0] = 32'hCAFEBABE;
        repeat(3) @(posedge clk);
    
        inj_data_cfg[0][0] = 32'h12345678;
    
        wait_for_two(0,1, 1,0, 32'h12345678);
    
        print_pe_outputs();
        $display("[PASS] TEST 3");
        
        // =====================================================
        $display("\n--------------------------------------");
        $display("\n[RUN ] TEST 4 - FULL BROADCAST");
        $display("\n--------------------------------------");
        start_clean_test();
    
        setup_broadcast_00_basic_2x2();
    
        // Extiende broadcast a todo el mesh
        sel_cfg[0][1][SOUTH] = WEST;
        sel_cfg[1][0][EAST]  = NORTH;
        sel_cfg[1][1][LOCAL] = WEST;
    
        inj_data_cfg[0][0] = 32'hFACE1234;
    
        wait_for_all(0,1, 1,0, 1,1, 32'hFACE1234);
    
        print_pe_outputs();
        $display("[PASS] TEST 4");
    
    end

    // =====================================================
    $display("\n--------------------------------------");
    $display("\n[RUN ] TEST 5 - PIPELINE long path");
    $display("\n--------------------------------------");
    start_clean_test();

    setup_one_to_one(0, 0, ROWS-1, COLS-1);

    send_two_packets(0, 0, 32'hAAAA5555, 32'h1234ABCD, 2, expected);
    wait_for_value_at(ROWS-1, COLS-1, expected);

    print_pe_outputs();
    $display("[PASS] TEST 5");
    
    if (ROWS >= 3 || COLS >= 3) begin
        $display("\n--------------------------------------");
        $display("\n[RUN ] TEST 6 - VIA MID generic");
        $display("\n--------------------------------------");
        start_clean_test();
    
        setup_long_via_mid();
    
        // activa operacion en midpoint elegido automaticamente
        if (COLS >= 3)
            pe_op_cfg[0][COLS/2] = 1'b1;
        else
            pe_op_cfg[ROWS/2][0] = 1'b1;
    
        inj_data_cfg[0][0] = 32'h00FF00FF;
        expected = ~32'h00FF00FF;
    
        wait_for_last_node(expected);
    
        print_pe_outputs();
        $display("[PASS] TEST 6");
    end
    
    $display("\n--------------------------------------");
    $display("\n[RUN ] TEST 7 - FULL BROADCAST generic");
    $display("\n--------------------------------------");
    start_clean_test();
    
    setup_full_broadcast_from_00();
    
    inj_data_cfg[0][0] = 32'h55AA33CC;
    
    wait_for_mesh_except_source(0, 0, 32'h55AA33CC);
    
    print_pe_outputs();
    $display("[PASS] TEST 7"); 

    // =====================================================
    $display("\nSimulation completed");
    $finish;
end

endmodule