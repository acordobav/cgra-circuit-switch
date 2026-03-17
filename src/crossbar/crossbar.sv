`timescale 1ns / 1ps

module crossbar #(
    parameter int N_INPUTS  = 4,
    parameter int N_OUTPUTS = 4,
    parameter int DATA_W    = 32
)(
    input  logic [N_INPUTS-1:0][DATA_W-1:0]  in_data,
    input  logic [N_OUTPUTS-1:0][$clog2(N_INPUTS)-1:0] sel,
    output logic [N_OUTPUTS-1:0][DATA_W-1:0] out_data
);

genvar i;

generate
    for (i = 0; i < N_OUTPUTS; i++) begin : OUT_MUX
        always_comb begin
            out_data[i] = in_data[sel[i]];
        end
    end
endgenerate

endmodule
