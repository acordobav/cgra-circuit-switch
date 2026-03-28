`timescale 1ns / 1ps

module ni_tx_path #(
  parameter int IN_WIDTH   = 64,
  parameter int FLIT_WIDTH = 32,
  parameter int NUM_FLITS  = (IN_WIDTH + FLIT_WIDTH - 1) / FLIT_WIDTH
)(
  input  logic clk,
  input  logic rst_n,
  input  logic in_load,
  input  logic start_tx,

  // Input side (from PE)
  input  logic [IN_WIDTH-1:0] in_data,

  // Output side (to router/FIFO)
  output logic [FLIT_WIDTH-1:0] out_packet
);

  localparam int COUNT_W = (NUM_FLITS > 1) ? $clog2(NUM_FLITS) : 1;

  logic [COUNT_W-1:0] flit_count_q;
  logic [NUM_FLITS-1:0][FLIT_WIDTH-1:0] packet_flits;

  packetizer #(
    .IN_WIDTH(IN_WIDTH),
    .FLIT_WIDTH(FLIT_WIDTH)
  ) packetizer_0 (
    .clk(clk),
    .rst_n(rst_n),
    .in_load(in_load),
    .in_data(in_data),
    .out_packet(packet_flits)
  );

  // Capture/reset the flit index and advance on transmit requests.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      flit_count_q <= '0;
    end else if (in_load) begin
      flit_count_q <= '0;
    end else if (start_tx && (flit_count_q < NUM_FLITS-1)) begin
      flit_count_q <= flit_count_q + 1'b1;
    end
  end

  // Select current flit; guard against invalid indexes.
  always_comb begin
    if (flit_count_q < NUM_FLITS) begin
      out_packet = packet_flits[flit_count_q];
    end else begin
      out_packet = '0;
    end
  end

endmodule