`timescale 1ns / 1ps

module tb_pe;

parameter int DATA_W = 32;

logic clk;
logic rst;

logic [DATA_W-1:0] data_in;
logic op;
logic [DATA_W-1:0] data_out;

pe #(.DATA_W(DATA_W)) dut (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .op(op),
    .data_out(data_out)
);

// clock
always #5 clk = ~clk;

// check task
int error_count = 0;
task check(input [DATA_W-1:0] expected);
    if (data_out !== expected) begin
        $error("Mismatch: got=%h expected=%h", data_out, expected);
        error_count++;
    end
endtask

initial begin
    clk = 0;
    rst = 1;
    data_in = 0;
    op = 0;

    #10;
    rst = 0;

    // Test 1: passthrough
    $display("\n Test 1: passthrough");
    data_in = 32'hAAAA5555;
    op = 1'b0;
    #10;
    @(posedge clk); 
    check(data_in);
    
    
    // Test 2: NOT
    #20;
    $display("\n Test 2: NOT");
    data_in = 32'h0F0F0F0F;
    op = 1'b1;
    #10;
    @(posedge clk); 
    check(~data_in);

    // check erros
    if (error_count == 0) begin
        $display("\n All tests completed successfully \n");
    end else begin
        $display("\n Tests finished with %0d errors \n", error_count);
    end
    $finish;
end

endmodule