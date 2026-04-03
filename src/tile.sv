`timescale 1ns / 1ps

import cgra_config_pkg::*;

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2026 08:10:45 AM
// Design Name: 
// Module Name: tile
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


module tile #(
    parameter int DATA_W_P  = DATA_W,
    parameter int N_PORTS_P = N_PORTS,
    parameter int SEL_W_P   = SEL_W
)(
    input  logic clk,
    input  logic rst,

    // Entradas desde vecinos
    input  logic [DATA_W_P-1:0] in_north,
    input  logic [DATA_W_P-1:0] in_south,
    input  logic [DATA_W_P-1:0] in_east,
    input  logic [DATA_W_P-1:0] in_west,

    // Configuracion
    input  logic                 pe_op_cfg,
    input  logic                 inj_en_cfg,
    input  logic [DATA_W_P-1:0]  inj_data_cfg,
    input  logic [SEL_W_P-1:0]   sel_cfg [N_PORTS_P],

    // Salidas hacia vecinos
    output logic [DATA_W_P-1:0] out_north,
    output logic [DATA_W_P-1:0] out_south,
    output logic [DATA_W_P-1:0] out_east,
    output logic [DATA_W_P-1:0] out_west,

    // Debug pe out y pe in
    output logic [DATA_W_P-1:0] pe_out_obs,
    output logic [DATA_W_P-1:0] pe_in_obs
);

logic [DATA_W_P-1:0] pe_in;
logic [DATA_W_P-1:0] pe_out;

logic [DATA_W_P-1:0] sw_in  [N_PORTS_P];
logic [DATA_W_P-1:0] sw_out [N_PORTS_P];

// -------------------------
// Entradas al crossbar
// -------------------------

always_comb begin
    sw_in[LOCAL] = pe_out;
    sw_in[NORTH] = in_north;
    sw_in[SOUTH] = in_south;
    sw_in[EAST]  = in_east;
    sw_in[WEST]  = in_west;
end

// -------------------------
// Crossbar
// -------------------------
crossbar #(
    .N_INPUTS  (N_PORTS_P),
    .N_OUTPUTS (N_PORTS_P),
    .DATA_W    (DATA_W_P),
    .SEL_W     (SEL_W_P)
) u_crossbar (
    .in_data  (sw_in),
    .sel      (sel_cfg),
    .out_data (sw_out)
);

// -------------------------
// PE
// -------------------------
assign pe_in = (inj_en_cfg) ? inj_data_cfg : sw_out[LOCAL];

pe #(
    .DATA_W(DATA_W_P)
)u_pe (
    .clk     (clk),
    .rst     (rst),
    .data_in (pe_in),
    .op      (pe_op_cfg),
    .data_out(pe_out)
);

// -------------------------
// Salida a vecinos
// -------------------------
assign out_north  = sw_out[NORTH];
assign out_south  = sw_out[SOUTH];
assign out_east   = sw_out[EAST];
assign out_west   = sw_out[WEST];

// -------------------------
// Observación
// -------------------------
assign pe_in_obs = pe_in;
assign pe_out_obs = pe_out;

endmodule