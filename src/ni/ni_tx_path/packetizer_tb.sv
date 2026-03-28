`timescale 1ns / 1ps

module packetizer_tb;
  localparam int IN_WIDTH   = 40;
  localparam int FLIT_WIDTH = 16;
  localparam int NUM_FLITS  = (IN_WIDTH + FLIT_WIDTH - 1) / FLIT_WIDTH;

  logic clk;
  logic rst_n;
  logic in_load;
  logic [IN_WIDTH-1:0] in_data;
  logic [NUM_FLITS-1:0][FLIT_WIDTH-1:0] out_packet;

  logic [NUM_FLITS*FLIT_WIDTH-1:0] expected_flat;

  packetizer #(
    .IN_WIDTH(IN_WIDTH),
    .FLIT_WIDTH(FLIT_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_load(in_load),
    .in_data(in_data),
    .out_packet(out_packet)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task automatic check_output(input string step_name);
    begin
      if (out_packet !== expected_flat) begin
        $error("[%s] Expected 0x%0h, got 0x%0h", step_name, expected_flat, out_packet);
      end
    end
  endtask

  initial begin
    // Default stimulus
    rst_n   = 1'b0;
    in_load = 1'b0;
    in_data = '0;

    // During reset, output must be zero.
    repeat (2) @(posedge clk);
    expected_flat = '0;
    check_output("reset_clears_output");

    // Release reset and capture first payload.
    rst_n = 1'b1;
    @(negedge clk);
    in_data = 40'h12_3456_789a;
    in_load = 1'b1;
    @(posedge clk);
    #1;
    expected_flat = '0;
    expected_flat[IN_WIDTH-1:0] = 40'h12_3456_789a;
    check_output("capture_on_in_load");

    // Change input without load: output must hold previous value.
    @(negedge clk);
    in_data = 40'h0f_fedc_ba98;
    in_load = 1'b0;
    @(posedge clk);
    #1;
    check_output("hold_when_in_load_low");

    // Load new payload and verify update.
    @(negedge clk);
    in_data = 40'h0a_bcde_f123;
    in_load = 1'b1;
    @(posedge clk);
    #1;
    expected_flat = '0;
    expected_flat[IN_WIDTH-1:0] = 40'h0a_bcde_f123;
    check_output("second_capture");

    // Explicitly verify zero-padding in upper unused bits.
    if (out_packet[NUM_FLITS*FLIT_WIDTH-1:IN_WIDTH] !== '0) begin
      $error("[zero_padding] Upper bits are not zero: 0x%0h", out_packet[NUM_FLITS*FLIT_WIDTH-1:IN_WIDTH]);
    end

    $display("packetizer_tb PASSED");
    $finish;
  end

endmodule
