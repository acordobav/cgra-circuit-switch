`timescale 1ns / 1ps

module ni_tx_path_tb;
  localparam int IN_WIDTH   = 40;
  localparam int FLIT_WIDTH = 16;
  localparam int NUM_FLITS  = (IN_WIDTH + FLIT_WIDTH - 1) / FLIT_WIDTH;

  logic clk;
  logic rst_n;
  logic in_load;
  logic start_tx;
  logic [IN_WIDTH-1:0] in_data;
  logic [FLIT_WIDTH-1:0] out_packet;
  logic tx_valid;
  logic tx_done;

  ni_tx_path #(
    .IN_WIDTH(IN_WIDTH),
    .FLIT_WIDTH(FLIT_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_load(in_load),
    .start_tx(start_tx),
    .in_data(in_data),
    .out_packet(out_packet),
    .tx_valid(tx_valid),
    .tx_done(tx_done)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task automatic check_state(
    input string name,
    input logic [FLIT_WIDTH-1:0] exp_out,
    input logic exp_valid,
    input logic exp_done
  );
    begin
      if (out_packet !== exp_out || tx_valid !== exp_valid || tx_done !== exp_done) begin
        $error("[%s] exp out=0x%0h valid=%0b done=%0b | got out=0x%0h valid=%0b done=%0b",
               name, exp_out, exp_valid, exp_done, out_packet, tx_valid, tx_done);
      end
    end
  endtask

  task automatic pulse_start_tx;
    begin
      @(negedge clk);
      start_tx = 1'b1;
      @(posedge clk);
      #1;
      start_tx = 1'b0;
    end
  endtask

  initial begin
    logic [IN_WIDTH-1:0] payload;

    rst_n     = 1'b0;
    in_load   = 1'b0;
    start_tx  = 1'b0;
    in_data   = '0;
    payload   = 40'h12_3456_789a;

    // Reset phase.
    repeat (2) @(posedge clk);
    #1;
    check_state("reset", 16'h0000, 1'b0, 1'b0);

    // Load payload into packetizer.
    @(negedge clk);
    rst_n   = 1'b1;
    in_data = payload;
    in_load = 1'b1;
    @(posedge clk);
    #1;
    in_load = 1'b0;
    check_state("after_load_idle", 16'h0000, 1'b0, 1'b0);

    // Start TX and verify flit stream order.
    pulse_start_tx();
    check_state("flit0", payload[15:0], 1'b1, 1'b0);

    @(posedge clk);
    #1;
    check_state("flit1", payload[31:16], 1'b1, 1'b0);

    @(posedge clk);
    #1;
    check_state("flit2_padded", {8'h00, payload[39:32]}, 1'b1, 1'b0);

    // One cycle after last flit: transmission ends and done pulses.
    @(posedge clk);
    #1;
    check_state("done_pulse", 16'h0000, 1'b0, 1'b1);

    // done should clear on next cycle.
    @(posedge clk);
    #1;
    check_state("post_done_idle", 16'h0000, 1'b0, 1'b0);

    // Start again without reloading: should replay same packet from flit0.
    pulse_start_tx();
    check_state("restart_flit0", payload[15:0], 1'b1, 1'b0);

    $display("ni_tx_path_tb PASSED");
    $finish;
  end

endmodule
