`timescale 1ns / 1ps


module mesh_Wrapper #(
    parameter ROWS    = 3,
    parameter COLS    = 3,
    parameter DATA_W  = 32,

    // Mesh
    parameter N_PORTS = 5,
    parameter SEL_W   = $clog2(N_PORTS + 1)

)(

    input clk,
    input rst,

    input  [ROWS*COLS-1:0] pe_op_gpio,
    input  [ROWS*COLS-1:0] inj_en_gpio,

    input  [ROWS*COLS*DATA_W-1:0] inj_data_flat,
    input  [ROWS*COLS*N_PORTS*SEL_W-1:0] sel_flat_gpio,

    output [ROWS*COLS*DATA_W-1:0] pe_out_flat
);

wire rst_int;
assign rst_int = ~rst;

mesh_bridge bridge_i(
    .clk(clk),
    .rst(rst_int),

    .pe_op_flat(pe_op_gpio),
    .inj_en_flat(inj_en_gpio),
    .inj_data_flat(inj_data_flat),
    .sel_flat(sel_flat_gpio),

    .pe_out_flat(pe_out_flat)
);


endmodule