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

// Clock y Reset
logic clk, rst;

// Sel signal
logic                inj_en_cfg   [ROWS][COLS];
logic [DATA_W-1:0]   inj_data_cfg [ROWS][COLS];
logic [SEL_W-1:0]    sel_cfg      [ROWS][COLS][N_PORTS];

//Interfaz de los PEs
logic                pe_op_cfg    [ROWS][COLS];
logic [DATA_W-1:0]   pe_out_obs [ROWS][COLS];
logic [DATA_W-1:0]   pe_in_obs  [ROWS][COLS];

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
// Configuraciones de ruteo 
// ===============================

task automatic clear_all();
    for (int i = 0; i < ROWS; i++) begin
        for (int j = 0; j < COLS; j++) begin
            pe_op_cfg[i][j]    = 1'b0;
            inj_en_cfg[i][j]   = 1'b0;
            inj_data_cfg[i][j] = '0;
            
            for (int p = 0; p < N_PORTS; p++) begin
                sel_cfg[i][j][p] = NONE;
            end
        end
    end
endtask

// Ruteo Manhattan
task automatic route_one_to_one(
    input int src_r, input int src_c,
    input int dst_r, input int dst_c
);
    int cr, cc;
    int inc_port;

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
        cc--;
        inc_port = EAST;
    end

    // Camino Vertical (NORTH/SOUTH)
    while (cr < dst_r) begin
        sel_cfg[cr][cc][SOUTH] = inc_port;
        cr++;
        inc_port = NORTH;
    end
    while (cr > dst_r) begin
        sel_cfg[cr][cc][NORTH] = inc_port;
        cr--;
        inc_port = SOUTH;
    end

    // Destino final
    sel_cfg[cr][cc][LOCAL] = inc_port;
endtask

task automatic print_pe_outputs();
    $display("---- PE OUTPUTS ----");
    for (int i = 0; i < ROWS; i++) begin
        for (int j = 0; j < COLS; j++) begin
            $display("PE[%0d][%0d] in=%h out=%h",
                i, j, pe_in_obs[i][j], pe_out_obs[i][j]);
        end
    end
    $display("--------------------");
endtask

initial begin
    clk = 0;
    rst = 1;

    clear_all();

    repeat(2) @(posedge clk);
    rst = 0;
    
    $display("\n[TEST 1] ONE-TO-ONE: PE(0,0) -> PE(1,1)");
    route_one_to_one(0, 0, 1, 1);

    inj_en_cfg[0][0]   = 1'b1;
    inj_data_cfg[0][0] = 32'hDEADBEEF;

    repeat(3) @(posedge clk);
    print_pe_outputs();

    if (pe_out_obs[1][1] !== 32'hDEADBEEF)
        $error("FAIL: ruta (0,0)->(1,1)");
    else
        $display("PASS: ruta (0,0)->(1,1)");

    clear_all();

    $display("\n[TEST 2] NOT en destino");

    route_one_to_one(0, 0, 1, 1);

    inj_en_cfg[0][0]   = 1'b1;
    inj_data_cfg[0][0] = 32'h0000FFFF;
    pe_op_cfg[1][1]    = 1'b1;

    repeat(3) @(posedge clk);
    print_pe_outputs();

    if (pe_out_obs[1][1] !== ~32'h0000FFFF)
        $error("FAIL: NOT en destino");
    else
        $display("PASS: NOT en destino");

    $display("\nSimulation completed");
    $finish;
end

endmodule