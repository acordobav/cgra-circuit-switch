`timescale 1ns / 1ps

module pe #(
    parameter int DATA_W = 32
)(
    input  logic clk,
    input  logic rst,

    input  logic [DATA_W-1:0] data_in,
    input  logic op,

    output logic [DATA_W-1:0] data_out
);

always_ff @(posedge clk) begin
    if (rst) begin
        data_out <= '0;
    end else begin
        case (op)
            1'b0: data_out <= data_in;      // passthrough
            1'b1: data_out <= ~data_in;     // NOT
            default: data_out <= data_in;
        endcase
    end
end

endmodule