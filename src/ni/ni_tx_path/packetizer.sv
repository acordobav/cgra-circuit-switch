`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Packetizer (Parallel-to-Flit Formatter)
//
// - Captures a parallel input word from PE when in_load is asserted.
// - Packs the captured word into NUM_FLITS flits of FLIT_WIDTH bits.
// - Exposes the packed flits in parallel on out_packet.
// - Clears and reloads packet storage only on in_load.
//
// Notes:
// - NUM_FLITS is derived from IN_WIDTH and FLIT_WIDTH using ceiling division.
// - If IN_WIDTH is not an exact multiple of FLIT_WIDTH, upper unused bits are
//   zero-padded.
// -----------------------------------------------------------------------------

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

  // Output side (to router)
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

