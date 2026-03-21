`timescale 1ns / 1ps

// ============================================================
// Testbench: CGRA 2x2 Mesh (Static Circuit-Switched Routing)
//
// This testbench validates a fixed routing path:
// PE0 -> SW0 -> SW1 -> SW3 -> PE3
//
// Communication pattern: ONE-TO-ONE (Unicast)
// ============================================================

module tb_cgra_2x2;

parameter int DATA_W = 32;

// ===============================
// DIRECCIONES
// ===============================
localparam int LOCAL = 0;
localparam int NORTH = 1;
localparam int EAST  = 2;
localparam int WEST  = 3;

// ===============================
// Señales
// ===============================
logic clk, rst;

logic [DATA_W-1:0] pe_in [3:0];
logic [DATA_W-1:0] pe_out[3:0];
logic pe_op[3:0];

// Switches
logic [3:0][3:0][DATA_W-1:0] sw_in;
logic [3:0][3:0][DATA_W-1:0] sw_out;
logic [3:0][3:0][1:0] sel;

// ===============================
// PEs
// ===============================
genvar i;
generate
    for (i = 0; i < 4; i++) begin : PES
        pe dut_pe (
            .clk(clk),
            .rst(rst),
            .data_in(pe_in[i]),
            .op(pe_op[i]),
            .data_out(pe_out[i])
        );
    end
endgenerate

// ===============================
// Crossbars (Switches)
// ===============================
generate
    for (i = 0; i < 4; i++) begin : SWITCHES
        crossbar #(
            .N_INPUTS(4),
            .N_OUTPUTS(4),
            .DATA_W(DATA_W)
        ) dut_sw (
            .in_data(sw_in[i]),
            .sel(sel[i]),
            .out_data(sw_out[i])
        );
    end
endgenerate

// ===============================
// MESH 2x2 (RUTA FIJA)
// ===============================

// SW0
always_comb begin
    sw_in[0][LOCAL] = pe_out[0];
    sw_in[0][NORTH] = 0;
    sw_in[0][EAST]  = 0;
    sw_in[0][WEST]  = 0;
end

// SW1
always_comb begin
    sw_in[1][LOCAL] = pe_out[1];
    sw_in[1][NORTH] = 0;
    sw_in[1][EAST]  = 0;
    sw_in[1][WEST]  = sw_out[0][EAST]; // SW0 -> SW1
end

// SW2 (reservado)
always_comb begin
    sw_in[2][LOCAL] = pe_out[2];
    sw_in[2][NORTH] = 0;
    sw_in[2][EAST]  = 0;
    sw_in[2][WEST]  = 0;
end

// SW3
always_comb begin
    sw_in[3][LOCAL] = pe_out[3];
    sw_in[3][NORTH] = sw_out[1][EAST]; // SW1 -> SW3
    sw_in[3][EAST]  = 0;
    sw_in[3][WEST]  = 0;
end

// ===============================
// Salidas hacia PEs
// ===============================
always_comb begin
    pe_in[0] = sw_out[0][LOCAL];
    pe_in[1] = sw_out[1][LOCAL];
    pe_in[2] = sw_out[2][LOCAL];
    pe_in[3] = sw_out[3][LOCAL];
end

// ===============================
// CLOCK
// ===============================
always #5 clk = ~clk;

// ===============================
// CONFIGURACIÓN
// ===============================
task config_1_to_1();
    sel = '{default:0};

    sel[0][EAST]  = LOCAL; // SW0
    sel[1][EAST]  = WEST;  // SW1
    sel[3][LOCAL] = NORTH; // SW3
endtask

// ===============================
// DEBUG
// ===============================
always @(posedge clk) begin
    $display("T=%0t | SW0(E)=%h | SW1(E)=%h | SW3(L)=%h | PE3=%h",
        $time,
        sw_out[0][EAST],
        sw_out[1][EAST],
        sw_out[3][LOCAL],
        pe_out[3]
    );
end

// ===============================
// TEST
// ===============================
initial begin
    clk = 0;
    rst = 1;

    // init
    for (int i = 0; i < 4; i++) begin
        pe_op[i] = 0;
        pe_in[i] = 0;
    end

    #10;
    rst = 0;

    // =====================================
    // TEST: ONE-TO-ONE
    // =====================================
    $display("\n[TEST] PE0 -> PE3 (Unicast)");

    config_1_to_1();

    pe_in[0] = 32'hDEADBEEF;

    repeat(6) @(posedge clk);

    if (pe_out[3] !== 32'hDEADBEEF)
        $error("FAIL: routing incorrecto");
    else
        $display("PASS: routing correcto");

    $display("\nSimulation completed");
    $finish;
end

endmodule