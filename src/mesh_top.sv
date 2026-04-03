`timescale 1ns / 1ps

import cgra_config_pkg::*;

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2026 08:10:50 AM
// Design Name: 
// Module Name: mesh_top
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

module mesh_top #(
    parameter int ROWS_P   = ROWS,
    parameter int COLS_P   = COLS,
    parameter int DATA_W_P = DATA_W,
    parameter int N_PORTS_P = N_PORTS,
    parameter int SEL_W_P   = SEL_W
)(
    input logic clk,
    input logic rst,

    // Configuración por tile
    input logic                pe_op_cfg    [ROWS_P][COLS_P],
    input logic                inj_en_cfg   [ROWS_P][COLS_P],
    input logic [DATA_W_P-1:0] inj_data_cfg [ROWS_P][COLS_P],
    input logic [SEL_W_P-1:0]  sel_cfg      [ROWS_P][COLS_P][N_PORTS_P],

    // Observación
    output logic [DATA_W_P-1:0] pe_out_obs [ROWS_P][COLS_P],
    output logic [DATA_W_P-1:0] pe_in_obs  [ROWS_P][COLS_P]
);

    // Conexiones entre tiles
    logic [DATA_W_P-1:0] n_to_s [ROWS_P+1][COLS_P];
    logic [DATA_W_P-1:0] s_to_n [ROWS_P+1][COLS_P];
    logic [DATA_W_P-1:0] w_to_e [ROWS_P][COLS_P+1];
    logic [DATA_W_P-1:0] e_to_w [ROWS_P][COLS_P+1];

    genvar r, c;
    generate
        for (r = 0; r < ROWS_P; r++) begin : GEN_ROWS
            for (c = 0; c < COLS_P; c++) begin : GEN_COLS
            
                // -------------------------
                // Tile
                // -------------------------
                tile #(
                    .DATA_W_P (DATA_W_P),
                    .N_PORTS_P(N_PORTS_P),
                    .SEL_W_P  (SEL_W_P)
                ) u_tile (
                    .clk         (clk),
                    .rst         (rst),

                    .in_north    (n_to_s[r][c]),
                    .in_south    (s_to_n[r+1][c]),
                    .in_east     (e_to_w[r][c+1]),
                    .in_west     (w_to_e[r][c]),
                    
                    .out_north   (s_to_n[r][c]), 
                    .out_south   (n_to_s[r+1][c]),
                    .out_west    (e_to_w[r][c]),
                    .out_east    (w_to_e[r][c+1]),

                    .pe_op_cfg   (pe_op_cfg[r][c]),
                    .inj_en_cfg  (inj_en_cfg[r][c]),
                    .inj_data_cfg(inj_data_cfg[r][c]),
                    .sel_cfg     (sel_cfg[r][c]),

                    .pe_out_obs  (pe_out_obs[r][c]),
                    .pe_in_obs   (pe_in_obs[r][c])
                );
            end
        end
        
        for (c = 0; c < COLS_P; c++) begin
            assign n_to_s[0][c]      = '0; // Borde superior
            assign s_to_n[ROWS_P][c] = '0; // Borde inferior
        end
        for (r = 0; r < ROWS_P; r++) begin
            assign w_to_e[r][0]      = '0; // Borde izquierdo
            assign e_to_w[r][COLS_P] = '0; // Borde derecho
        end
        
    endgenerate

endmodule