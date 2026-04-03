`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// NI TX Path (Network Interface Transmission Path)
//
// - Captures PE input through packetizer when in_load is asserted.
// - Stores packet data as an array of NUM_FLITS flits.
// - Starts transmission when start_tx is asserted.
// - Sends one flit per cycle on out_packet while tx_valid is high.
// - Pulses tx_done for one cycle after the last flit is transmitted.
//
// Notes:
// - in_load resets the TX state and reloads packet contents.
// - Transmission is sequential from flit index 0 to NUM_FLITS-1.
// - out_packet is driven to zero when no transmission is active.
// -----------------------------------------------------------------------------

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
  output logic [FLIT_WIDTH-1:0] out_packet,
  output logic tx_valid,
  output logic tx_done
);

  localparam int COUNT_W = (NUM_FLITS > 1) ? $clog2(NUM_FLITS) : 1;

  logic [COUNT_W-1:0] flit_count_q;
  logic [NUM_FLITS-1:0][FLIT_WIDTH-1:0] packet_flits;
  logic tx_active_q;
  logic tx_done_q;

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

  // Start transmission on start_tx, advance one flit per cycle, pulse done on last flit
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      flit_count_q <= '0;
      tx_active_q  <= 1'b0;
      tx_done_q    <= 1'b0;
    end else if (in_load) begin
      flit_count_q <= '0;
      tx_active_q  <= 1'b0;
      tx_done_q    <= 1'b0;
    end else begin
      tx_done_q <= 1'b0;

      if (tx_active_q) begin
        if (flit_count_q < NUM_FLITS-1) begin
          flit_count_q <= flit_count_q + 1'b1;
        end else begin
          flit_count_q <= '0;
          tx_active_q  <= 1'b0;
          tx_done_q    <= 1'b1;
        end
      end else if (start_tx) begin
        tx_active_q <= 1'b1;
      end
    end
  end

  assign tx_valid = tx_active_q;
  assign tx_done  = tx_done_q;

  // Drive selected flit only while transmission is active
  always_comb begin
    if (tx_active_q && (flit_count_q < NUM_FLITS)) begin
      out_packet = packet_flits[flit_count_q];
    end else begin
      out_packet = '0;
    end
  end

endmodule