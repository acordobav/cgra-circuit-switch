`timescale 1ns / 1ps

module packetizer #(
  parameter int IN_WIDTH   = 64,
  parameter int FLIT_WIDTH = 32,
  parameter int NUM_FLITS  = (IN_WIDTH + FLIT_WIDTH - 1) / FLIT_WIDTH
)(
  input  logic clk,
  input  logic rst_n,
  input  logic in_load,

  // Input side (from PE)
  input  logic [IN_WIDTH-1:0] in_data,

  // Output side (to router/FIFO)
  output logic [NUM_FLITS-1:0][FLIT_WIDTH-1:0] out_packet
);

  logic [NUM_FLITS*FLIT_WIDTH-1:0] packet_flat;

  // Capture packet data only when requested by in_load.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      packet_flat <= '0;
    end else if (in_load) begin
      packet_flat <= '0;
      packet_flat[IN_WIDTH-1:0] <= in_data;
    end
  end

  assign out_packet = packet_flat;

endmodule

