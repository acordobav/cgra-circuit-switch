`timescale 1ns / 1ps

import cgra_config_pkg::*;

module mesh_bridge #(
    parameter int ROWS  = ROWS,
    parameter int COLS  = COLS,
    parameter int DATAW = DATA_W,
    parameter int NPORT = N_PORTS,
    parameter int SELW  = SEL_W
)(
    input  logic clk,
    input  logic rst,

    // -----------------------------
    // Flat interface (desde wrapper)
    // -----------------------------
    input  logic [ROWS*COLS-1:0] pe_op_flat,
    input  logic [ROWS*COLS-1:0] inj_en_flat,
    
    input  logic [ROWS*COLS*DATAW-1:0] inj_data_flat,
    
    input  logic [ROWS*COLS*NPORT*SELW-1:0] sel_flat,
    
    output logic [ROWS*COLS*DATAW-1:0] pe_out_flat

);

logic                pe_op_cfg   [ROWS][COLS];
logic                inj_en_cfg  [ROWS][COLS];
logic [DATAW-1:0]    inj_data_cfg[ROWS][COLS];
logic [SELW-1:0]     sel_cfg     [ROWS][COLS][NPORT];

logic [DATAW-1:0] pe_out_obs [ROWS][COLS];
logic [DATAW-1:0] pe_in_obs  [ROWS][COLS];

logic [DATAW-1:0] sw_out_obs [ROWS][COLS][NPORT];
logic [DATAW-1:0] sw_in_obs  [ROWS][COLS][NPORT];

genvar r,c,p;

generate
for (r=0; r<ROWS; r++) begin
    for (c=0; c<COLS; c++) begin

        assign pe_op_cfg[r][c]  = pe_op_flat[r*COLS + c];
        assign inj_en_cfg[r][c] = inj_en_flat[r*COLS + c];

        assign inj_data_cfg[r][c] =
            inj_data_flat[(r*COLS+c)*DATAW +: DATAW];

        for (p=0; p<NPORT; p++) begin
            assign sel_cfg[r][c][p] =
                sel_flat[((r*COLS*NPORT)+(c*NPORT)+p)*SELW +: SELW];
        end

    end
end
endgenerate


mesh_top #(
    .ROWS_P(ROWS),
    .COLS_P(COLS),
    .DATA_W_P(DATAW),
    .N_PORTS_P(NPORT),
    .SEL_W_P(SELW)
) mesh_inst (

    .clk(clk),
    .rst(rst),

    .pe_op_cfg(pe_op_cfg),
    .inj_en_cfg(inj_en_cfg),
    .inj_data_cfg(inj_data_cfg),
    .sel_cfg(sel_cfg),

    .pe_out_obs(pe_out_obs),
    .pe_in_obs(pe_in_obs),

    .sw_out_obs(sw_out_obs),
    .sw_in_obs(sw_in_obs)
);


generate
for (r=0; r<ROWS; r++) begin
    for (c=0; c<COLS; c++) begin

        assign pe_out_flat[(r*COLS+c)*DATAW +: DATAW] =
               pe_out_obs[r][c];

    end
end
endgenerate

endmodule
