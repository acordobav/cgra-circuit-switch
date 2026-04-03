`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// NI RX Path (Network Interface Reception Path)
//
// - Receives flits serially on input valid/ready handshake.
// - Stores one complete packet in internal registers.
// - Presents stored packet in parallel on out_packet when complete.
// - Holds out_valid/data stable until PE acknowledges with out_ready.
//
// Notes:
// - Packet boundary is indicated by in_last.
// - If packet exceeds MAX_FLITS before in_last is seen, the current packet is
//   dropped safely (drop mode) until in_last arrives, preventing overflow and
//   preserving packet alignment for subsequent packets.
// -----------------------------------------------------------------------------
module ni_rx_path #(
	parameter int FLIT_WIDTH = 32,
	parameter int MAX_FLITS  = 8
)(
	input  logic clk,
	input  logic rst_n,

	// Input side (from router)
	input  logic                  in_valid,
	output logic                  in_ready,
	input  logic [FLIT_WIDTH-1:0] in_data,
	input  logic                  in_last,

	// Output side (to PE)
	output logic                                 out_valid,
	input  logic                                 out_ready,
	output logic [MAX_FLITS-1:0][FLIT_WIDTH-1:0] out_packet
);

localparam int COUNT_W = (MAX_FLITS > 1) ? $clog2(MAX_FLITS + 1) : 1;

// Datapath storage
logic [MAX_FLITS-1:0][FLIT_WIDTH-1:0] buffer_q;

// Number of currently assembled flits for the in-progress packet
logic [COUNT_W-1:0] flit_count_q;

// Control state
logic packet_ready_q;  // 1 when a complete packet is waiting for PE
logic drop_mode_q;     // 1 when discarding an oversized packet until in_last

logic in_fire;
logic out_fire;
logic buffer_full;

assign in_fire    = in_valid && in_ready;
assign out_fire   = out_valid && out_ready;
assign buffer_full = (flit_count_q == MAX_FLITS[COUNT_W-1:0]);

// -----------------------------------------------------------------------------
// Handshake/control (combinational)
//
// in_ready deasserts when:
// - A complete packet is waiting to be consumed by PE, or
// - The assembling buffer is full.
//
// Exception: in drop_mode, keep ready asserted to drain/discard incoming flits
// until in_last, so the interface can recover from oversized packets.
// -----------------------------------------------------------------------------
always_comb begin
	if (drop_mode_q) begin
		in_ready = 1'b1;
	end else begin
		in_ready = (!packet_ready_q) && (!buffer_full);
	end
end

assign out_valid  = packet_ready_q;
assign out_packet = buffer_q;

// -----------------------------------------------------------------------------
// Sequential logic
// -----------------------------------------------------------------------------
always_ff @(posedge clk) begin
	if (!rst_n) begin
		buffer_q      <= '0;
		flit_count_q  <= '0;
		packet_ready_q <= 1'b0;
		drop_mode_q   <= 1'b0;
	end else begin
		// Consume currently buffered packet when PE is ready
		if (out_fire) begin
			packet_ready_q <= 1'b0;
			flit_count_q   <= '0;
		end

		// Accept/discard one flit per cycle based on state
		if (in_fire) begin
			if (drop_mode_q) begin
				// Discard flits until end-of-packet marker
				if (in_last) begin
					drop_mode_q <= 1'b0;
				end
			end else if (!packet_ready_q) begin
				// Normal packet assembly
				buffer_q[flit_count_q] <= in_data;

				if (in_last) begin
					// Packet complete: expose in parallel and wait for out_ready
					flit_count_q   <= flit_count_q + 1'b1;
					packet_ready_q <= 1'b1;
				end else if (flit_count_q == (MAX_FLITS-1)) begin
					// Oversized packet (late in_last): enter drop mode safely
					flit_count_q <= '0;
					drop_mode_q  <= 1'b1;
				end else begin
					flit_count_q <= flit_count_q + 1'b1;
				end
			end
		end
	end
end

endmodule

