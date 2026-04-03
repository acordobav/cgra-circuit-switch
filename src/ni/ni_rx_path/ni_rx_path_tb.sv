`timescale 1ns / 1ps

module ni_rx_path_tb;

parameter int FLIT_WIDTH = 32;
parameter int MAX_FLITS  = 8;

logic clk;
logic rst_n;

logic                  in_valid;
logic                  in_ready;
logic [FLIT_WIDTH-1:0] in_data;
logic                  in_last;

logic                                 out_valid;
logic                                 out_ready;
logic [MAX_FLITS-1:0][FLIT_WIDTH-1:0] out_packet;

int error_count;

ni_rx_path #(
	.FLIT_WIDTH(FLIT_WIDTH),
	.MAX_FLITS (MAX_FLITS)
) dut (
	.clk       (clk),
	.rst_n     (rst_n),
	.in_valid  (in_valid),
	.in_ready  (in_ready),
	.in_data   (in_data),
	.in_last   (in_last),
	.out_valid (out_valid),
	.out_ready (out_ready),
	.out_packet(out_packet)
);

// -----------------------------------------------------------------------------
// Clock generation
// -----------------------------------------------------------------------------
always #5 clk = ~clk;

// -----------------------------------------------------------------------------
// Utility tasks
// -----------------------------------------------------------------------------
task automatic fail(input string msg);
	begin
		$error("%s", msg);
		error_count++;
	end
endtask

task automatic check_packet(
	input int unsigned n_flits,
	input logic [MAX_FLITS-1:0][FLIT_WIDTH-1:0] exp_packet,
	input string tag
);
	begin
		for (int i = 0; i < n_flits; i++) begin
			if (out_packet[i] !== exp_packet[i]) begin
				fail($sformatf("%s: flit[%0d] mismatch. got=%h exp=%h",
				               tag, i, out_packet[i], exp_packet[i]));
			end
		end
	end
endtask

task automatic wait_out_valid(input int unsigned timeout_cycles, input string tag);
	int unsigned cyc;
	begin
		cyc = 0;
		while ((out_valid !== 1'b1) && (cyc < timeout_cycles)) begin
			@(posedge clk);
			cyc++;
		end
		if (out_valid !== 1'b1) begin
			fail($sformatf("%s: timeout waiting for out_valid", tag));
		end
	end
endtask

task automatic send_packet(
	input int unsigned n_flits,
	input logic [MAX_FLITS-1:0][FLIT_WIDTH-1:0] packet,
	input string tag
);
	begin
		if (n_flits == 0) begin
			fail($sformatf("%s: n_flits must be > 0", tag));
			return;
		end

		in_valid <= 1'b1;
		for (int unsigned i = 0; i < n_flits; i++) begin
			in_data <= packet[i];
			in_last <= (i == (n_flits - 1));

			// Hold current flit stable until accepted
			do begin
				@(posedge clk);
			end while (in_ready !== 1'b1);
		end

		in_valid <= 1'b0;
		in_last  <= 1'b0;
		in_data  <= '0;
	end
endtask

// -----------------------------------------------------------------------------
// Test sequence
// -----------------------------------------------------------------------------
initial begin
	logic [MAX_FLITS-1:0][FLIT_WIDTH-1:0] pkt_a;
	logic [MAX_FLITS-1:0][FLIT_WIDTH-1:0] pkt_b;
	logic [MAX_FLITS-1:0][FLIT_WIDTH-1:0] pkt_c;
	logic [MAX_FLITS+1:0][FLIT_WIDTH-1:0] pkt_ovf;

	clk        = 1'b0;
	rst_n      = 1'b0;
	in_valid   = 1'b0;
	in_data    = '0;
	in_last    = 1'b0;
	out_ready  = 1'b0;
	error_count = 0;

	for (int i = 0; i < MAX_FLITS; i++) begin
		pkt_a[i] = '0;
		pkt_b[i] = '0;
		pkt_c[i] = '0;
	end
	for (int i = 0; i < (MAX_FLITS + 2); i++) begin
		pkt_ovf[i] = '0;
	end

	// Packet contents
	pkt_a[0] = 32'hA0A0_0001;
	pkt_a[1] = 32'hA0A0_0002;

	pkt_b[0] = 32'hB0B0_0001;
	pkt_b[1] = 32'hB0B0_0002;
	pkt_b[2] = 32'hB0B0_0003;

	pkt_c[0] = 32'hC0C0_0001;
	pkt_c[1] = 32'hC0C0_0002;
	pkt_c[2] = 32'hC0C0_0003;
	pkt_c[3] = 32'hC0C0_0004;

	for (int i = 0; i < (MAX_FLITS + 2); i++) begin
		pkt_ovf[i] = 32'hD0D0_0000 + i;
	end

	// Reset
	repeat (3) @(posedge clk);
	rst_n <= 1'b1;
	@(posedge clk);

	// -------------------------------------------------------------------------
	// Test 1: Back-to-back packets (one packet consumed, next packet follows)
	// -------------------------------------------------------------------------
	$display("[TB] Test 1: Back-to-back packets");
	out_ready <= 1'b1;

	send_packet(2, pkt_a, "T1_pkt_a_send");
	wait_out_valid(20, "T1_pkt_a_wait_valid");
	check_packet(2, pkt_a, "T1_pkt_a_check");
	@(posedge clk); // allow consume handshake

	send_packet(3, pkt_b, "T1_pkt_b_send");
	wait_out_valid(20, "T1_pkt_b_wait_valid");
	check_packet(3, pkt_b, "T1_pkt_b_check");
	@(posedge clk); // allow consume handshake

	// -------------------------------------------------------------------------
	// Test 2: PE stall (out_ready=0), ensure out data stable and input stalls
	// -------------------------------------------------------------------------
	$display("[TB] Test 2: PE stall");
	out_ready <= 1'b0;

	send_packet(3, pkt_b, "T2_pkt_send");
	wait_out_valid(20, "T2_wait_valid");
	check_packet(3, pkt_b, "T2_check_before_stall");

	// While stalled, in_ready must be low and packet must remain stable
	repeat (4) begin
		@(posedge clk);
		if (in_ready !== 1'b0) begin
			fail("T2: in_ready should be low while packet is waiting for PE");
		end
		check_packet(3, pkt_b, "T2_check_during_stall");
	end

	// Release stall and ensure packet is consumed
	out_ready <= 1'b1;
	@(posedge clk);
	@(posedge clk);
	if (out_valid !== 1'b0) begin
		fail("T2: out_valid should deassert after PE consumes packet");
	end

	// -------------------------------------------------------------------------
	// Test 3: Overflow/drop handling and recovery
	// - Send oversized packet (> MAX_FLITS) with late in_last
	// - Expect no out_valid for dropped packet
	// - Then send a valid packet and verify recovery
	// -------------------------------------------------------------------------
	$display("[TB] Test 3: Overflow/drop and recovery");
	out_ready <= 1'b1;

	// Build and send oversized packet with in_last on flit MAX_FLITS+1
	in_valid <= 1'b1;
	for (int unsigned i = 0; i < (MAX_FLITS + 2); i++) begin
		in_data <= pkt_ovf[i];
		in_last <= (i == (MAX_FLITS + 1));
		do begin
			@(posedge clk);
		end while (in_ready !== 1'b1);
	end
	in_valid <= 1'b0;
	in_last  <= 1'b0;
	in_data  <= '0;

	// Allow a few cycles; dropped packet must not produce out_valid
	repeat (4) @(posedge clk);
	if (out_valid !== 1'b0) begin
		fail("T3: oversized packet should be dropped (out_valid must stay low)");
	end

	// Recovery: next valid packet must pass correctly
	send_packet(4, pkt_c, "T3_recovery_send");
	wait_out_valid(20, "T3_recovery_wait_valid");
	check_packet(4, pkt_c, "T3_recovery_check");
	@(posedge clk); // allow consume handshake

	// -------------------------------------------------------------------------
	// Final report
	// -------------------------------------------------------------------------
	if (error_count == 0) begin
		$display("[TB] PASS: packet_buffer tests completed successfully");
	end else begin
		$display("[TB] FAIL: packet_buffer tests finished with %0d errors", error_count);
	end

	$finish;
end

endmodule
