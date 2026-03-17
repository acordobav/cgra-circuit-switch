`timescale 1ns / 1ps

module tb_crossbar;

parameter int N_INPUTS  = 4;
parameter int N_OUTPUTS = 4;
parameter int DATA_W    = 32;

logic [N_INPUTS-1:0][DATA_W-1:0]  in_data;
logic [N_OUTPUTS-1:0][$clog2(N_INPUTS)-1:0] sel;
logic [N_OUTPUTS-1:0][DATA_W-1:0] out_data;

crossbar #(
    .N_INPUTS(N_INPUTS),
    .N_OUTPUTS(N_OUTPUTS),
    .DATA_W(DATA_W)
) dut (
    .in_data(in_data),
    .sel(sel),
    .out_data(out_data)
);

task check_outputs;
    for (int i = 0; i < N_OUTPUTS; i++) begin
        if (out_data[i] !== in_data[sel[i]]) begin
            $error("Mismatch: out_data[%0d]=%h expected=%h",
                    i, out_data[i], in_data[sel[i]]);
        end
    end
endtask


initial begin

    $display("Starting crossbar testbench");

    // Initialize inputs with identifiable values
    for (int i = 0; i < N_INPUTS; i++) begin
        in_data[i] = 32'h1000 + i;
    end

    // ------------------------------------------------
    // Test 1: direct mapping
    // ------------------------------------------------
    $display("Test 1: direct mapping");

    for (int i = 0; i < N_OUTPUTS; i++) begin
        sel[i] = i % N_INPUTS;
    end

    #1;
    check_outputs();


    // ------------------------------------------------
    // Test 2: reverse mapping
    // ------------------------------------------------
    $display("Test 2: reverse mapping");

    for (int i = 0; i < N_OUTPUTS; i++) begin
        sel[i] = N_INPUTS - 1 - i;
    end

    #1;
    check_outputs();


    // ------------------------------------------------
    // Test 3: all outputs select same input
    // ------------------------------------------------
    $display("Test 3: broadcast input 2");

    for (int i = 0; i < N_OUTPUTS; i++) begin
        sel[i] = 2;
    end

    #1;
    check_outputs();


    // ------------------------------------------------
    // Test 4: random tests
    // ------------------------------------------------
    $display("Test 4: random selections");

    for (int test = 0; test < 20; test++) begin

        // randomize inputs
        for (int i = 0; i < N_INPUTS; i++) begin
            in_data[i] = $urandom;
        end

        // randomize selections
        for (int i = 0; i < N_OUTPUTS; i++) begin
            sel[i] = $urandom_range(0, N_INPUTS-1);
        end

        #1;
        check_outputs();

    end

    $display("All tests completed");
    $finish;

end

endmodule
