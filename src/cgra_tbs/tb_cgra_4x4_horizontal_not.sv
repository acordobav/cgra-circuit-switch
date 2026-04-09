`timescale 1ns / 1ps

import cgra_config_pkg::*;

module tb_cgra_4x4_horizontal_not;

localparam int DATA_W_P  = 8;
localparam int ROWS_P    = 4;
localparam int COLS_P    = 4;
localparam int N_PORTS_P = 5;
localparam int SEL_W_P   = $clog2(N_PORTS_P + 1);

localparam int MAX_WAIT_CYCLES = 20;

logic clk;
logic rst;

logic                pe_op_cfg    [ROWS_P][COLS_P];
logic                inj_en_cfg   [ROWS_P][COLS_P];
logic [DATA_W_P-1:0] inj_data_cfg [ROWS_P][COLS_P];
logic [SEL_W_P-1:0]  sel_cfg      [ROWS_P][COLS_P][N_PORTS_P];

logic [DATA_W_P-1:0] pe_out_obs [ROWS_P][COLS_P];
logic [DATA_W_P-1:0] pe_in_obs  [ROWS_P][COLS_P];
logic [DATA_W_P-1:0] sw_out_obs [ROWS_P][COLS_P][N_PORTS_P];
logic [DATA_W_P-1:0] sw_in_obs  [ROWS_P][COLS_P][N_PORTS_P];

mesh_top #(
	.ROWS_P   (ROWS_P),
	.COLS_P   (COLS_P),
	.DATA_W_P (DATA_W_P),
	.N_PORTS_P(N_PORTS_P),
	.SEL_W_P  (SEL_W_P)
) uut (
	.clk         (clk),
	.rst         (rst),
	.pe_op_cfg   (pe_op_cfg),
	.inj_en_cfg  (inj_en_cfg),
	.inj_data_cfg(inj_data_cfg),
	.sel_cfg     (sel_cfg),
	.pe_out_obs  (pe_out_obs),
	.pe_in_obs   (pe_in_obs),
	.sw_out_obs  (sw_out_obs),
	.sw_in_obs   (sw_in_obs)
);

always #5 clk = ~clk;

task automatic clear_all();
	for (int r = 0; r < ROWS_P; r++) begin
		for (int c = 0; c < COLS_P; c++) begin
			pe_op_cfg[r][c]    = 1'b0; // 0x0 passthrough
			inj_en_cfg[r][c]   = 1'b0;
			inj_data_cfg[r][c] = '0;
			for (int p = 0; p < N_PORTS_P; p++) begin
				sel_cfg[r][c][p] = NONE;
			end
		end
	end
endtask

task automatic reset_dut();
	rst = 1'b1;
	clear_all();
	repeat (2) @(posedge clk);
	rst = 1'b0;
	@(posedge clk);
endtask

task automatic configure_row_left_to_right(input int row_idx);
	if (row_idx < 0 || row_idx >= ROWS_P) begin
		$fatal(1, "[FAIL] Invalid row index %0d", row_idx);
	end

	// (row,0) -> (row,1) -> (row,2 PE/NOT) -> (row,3)
	sel_cfg[row_idx][0][EAST] = LOCAL;
	sel_cfg[row_idx][1][EAST] = WEST;
	sel_cfg[row_idx][2][LOCAL] = WEST;
	sel_cfg[row_idx][2][EAST]  = LOCAL;
	sel_cfg[row_idx][3][LOCAL] = WEST;

	// Force NOT operation at (row,2)
	pe_op_cfg[row_idx][2] = 1'b1;
endtask

task automatic configure_all_rows_left_to_right();
	for (int r = 0; r < ROWS_P; r++) begin
		configure_row_left_to_right(r);
	end
endtask

task automatic wait_for_value_at(
	input int r,
	input int c,
	input logic [DATA_W_P-1:0] expected
);
	int cycles;

	cycles = 0;
	while ((pe_out_obs[r][c] !== expected) && (cycles < MAX_WAIT_CYCLES)) begin
		@(posedge clk);
		cycles++;
	end

	if (pe_out_obs[r][c] !== expected) begin
		$fatal(1,
			"[FAIL] Timeout row=%0d col=%0d expected=%h observed=%h",
			r, c, expected, pe_out_obs[r][c]
		);
	end
endtask

initial begin
	logic [DATA_W_P-1:0] payload [ROWS_P];
	logic [DATA_W_P-1:0] expected [ROWS_P];

	clk = 1'b0;
	rst = 1'b0;

	reset_dut();
	clear_all();

	// Configure all requested routes concurrently.
	configure_all_rows_left_to_right();

	// Inject one random byte at each route source concurrently.
	for (int r = 0; r < ROWS_P; r++) begin
		payload[r] = $urandom_range(8'h00, 8'hFF);
		expected[r] = ~payload[r];
		inj_en_cfg[r][0]   = 1'b1;
		inj_data_cfg[r][0] = payload[r];
	end

	@(posedge clk);

	for (int r = 0; r < ROWS_P; r++) begin
		inj_en_cfg[r][0]   = 1'b0;
		inj_data_cfg[r][0] = '0;
	end

	for (int r = 0; r < ROWS_P; r++) begin
		wait_for_value_at(r, COLS_P-1, expected[r]);
		$display("[PASS] Row %0d: in=%h expected_not=%h observed=%h",
				 r, payload[r], expected[r], pe_out_obs[r][COLS_P-1]);
	end

	$display("[DONE] All 4 routes used PE at (X,2) with NOT and passed.");
	$finish;
end



endmodule