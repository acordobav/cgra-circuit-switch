`timescale 1ns / 1ps

module crossbar #(
    parameter int N_INPUTS  = 5,
    parameter int N_OUTPUTS = 5,
    parameter int DATA_W    = 32,
    parameter int SEL_W     = $clog2(N_INPUTS + 1)
)(
    input  logic [DATA_W-1:0]  in_data  [N_INPUTS],
    input  logic [SEL_W-1:0]   sel      [N_OUTPUTS],
    output logic [DATA_W-1:0]  out_data [N_OUTPUTS]
);
    
always_comb begin
    for (int i = 0; i < N_OUTPUTS; i++) begin : OUT_MUX
        if (sel[i] < N_INPUTS)
            out_data[i] = in_data[sel[i]];
        else
            out_data[i] = '0;
    end
end

endmodule