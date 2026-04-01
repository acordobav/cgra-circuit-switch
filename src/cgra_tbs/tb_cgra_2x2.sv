`timescale 1ns / 1ps

module tb_cgra_2x2;

parameter int DATA_W = 32;

// ===============================
// Direcciones de puertos del switch
// ===============================
localparam int LOCAL = 0;
localparam int NORTH = 1;
localparam int EAST  = 2;
localparam int WEST  = 3;

// ===============================
// Señales principales
// ===============================
logic clk, rst;
//Interfaz de los PEs
logic [DATA_W-1:0] pe_in [3:0];
logic [DATA_W-1:0] pe_drive [3:0]; //inyecta datos en el TB
logic [DATA_W-1:0] pe_out[3:0];
logic pe_op[3:0];

// Interconexion de switches
logic [3:0][3:0][DATA_W-1:0] sw_in;
logic [3:0][3:0][DATA_W-1:0] sw_out;
logic [3:0][3:0][1:0] sel;  // seleccion de salida

// ===============================
// Instancia de PEs
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
// Instancia de Crossbars (switches)
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
// Topologia MESH 2x2 fija
// ===============================

// SW0 (arriba-izq)
always_comb begin
    sw_in[0][LOCAL] = pe_out[0];
    sw_in[0][NORTH] = 0;
    sw_in[0][EAST]  = sw_out[1][WEST]; // SW1 conex horizontal
    sw_in[0][WEST]  = 0;
end

// SW1 (arriba-derecha)
always_comb begin
    sw_in[1][LOCAL] = pe_drive[1];
    sw_in[1][NORTH] = 0;
    sw_in[1][EAST]  = 0;
    sw_in[1][WEST]  = sw_out[0][EAST]; // SW0
end

// SW2 (PE2)
always_comb begin
    sw_in[2][LOCAL] = pe_drive[2];
    sw_in[2][NORTH] = sw_out[0][EAST]; // baja desde SW0 (vertical)
    sw_in[2][EAST]  = sw_out[3][WEST]; // SW3
    sw_in[2][WEST]  = 0;
end

// SW3 (PE3)
always_comb begin
    sw_in[3][LOCAL] = pe_out[3];
    sw_in[3][NORTH] = sw_out[1][EAST]; // SW1
    sw_in[3][EAST]  = 0;
    sw_in[3][WEST]  = sw_out[2][EAST]; // SW2
end

// ===============================
// Entrada a PEs  (PE0 se maneja directo)
// ===============================
always_comb begin
    pe_in[0] = pe_drive[0];  //fuente principal
    pe_in[1] = sw_out[1][LOCAL];  //desde switch
    pe_in[2] = sw_out[2][LOCAL];
    pe_in[3] = sw_out[3][LOCAL];
end

// ===============================
// CLOCK
// ===============================
always #5 clk = ~clk;

// ===============================
// Configuraciones de ruteo 
// ===============================

// PE0 a PE3
task config_0_to_3();
    sel = '{default:0};

    sel[0][EAST]  = LOCAL;
    sel[1][EAST]  = WEST;
    sel[3][LOCAL] = NORTH;
endtask

// PE1 a PE3
task config_1_to_3();
    sel = '{default:0};

    sel[1][EAST]  = LOCAL;
    sel[3][LOCAL] = NORTH;
endtask

// PE2 a PE3 
task config_2_to_3();
    sel = '{default:0};

    sel[2][EAST]  = LOCAL; // PE2 a SW3
    sel[3][LOCAL] = WEST;  // SW3 recibe de SW2
endtask

// =====================================
// ONE-TO-MANY: PE0 a: PE1, PE2, PE3
// =====================================
task config_0_to_all();
    sel = '{default:0};

    // Se duplica salida de SW0 
    sel[0][EAST]  = LOCAL; // hacia  SW1
    sel[0][NORTH] = LOCAL; // hacia SW2

    // SW1: envia a PE1
    sel[1][LOCAL] = WEST;  

    // SW2:
    sel[2][LOCAL] = NORTH; // hacia PE2
    sel[2][EAST]  = NORTH; // hacia SW3

    // SW3: envia a PE3
    sel[3][LOCAL] = WEST;
endtask

// ===============================
// DEBUG para el flujo en runtime 
// ===============================
always @(posedge clk) begin
    $display("T=%0t | SW0(L)=%h SW0(E)=%h | SW1(W)=%h SW1(E)=%h | SW2(L)=%h SW2(E)=%h | SW3(W)=%h SW3(L)=%h | PE3=%h",
        $time,
        sw_out[0][LOCAL], sw_out[0][EAST],
        sw_out[1][WEST],  sw_out[1][EAST],
        sw_out[2][LOCAL], sw_out[2][EAST],
        sw_out[3][WEST],  sw_out[3][LOCAL],
        pe_out[3]
    );
end
// ===============================
// Secuencia de pruebas 
// ===============================
initial begin
    clk = 0;
    rst = 1;
    // initial general 
    for (int i = 0; i < 4; i++) begin
        pe_op[i] = 0;
        pe_drive[i] = 0;
    end

    #10;
    rst = 0;


    // TEST 1: ONE-TO-ONE (PE0 a PE3)

    $display("\n[TEST 1] ONE-TO-ONE: PE0 -> PE3");

    config_0_to_3();

    pe_drive[0] = 32'hDEADBEEF;

    repeat(6) @(posedge clk);

    if (pe_out[3] !== 32'hDEADBEEF)
        $error("FAIL: PE0 -> PE3");
    else
        $display("PASS: PE0 -> PE3");


    // TEST 2: SEGUNDO DATO (MISMA RUTA PE0 a PE3)

    $display("\n[TEST 2] Segundo dato (ONE TO ONE)");

    pe_drive[0] = 32'hCAFE0011;

    repeat(6) @(posedge clk);

    if (pe_out[3] !== 32'hCAFE0011)
        $error("FAIL: segundo dato incorrecto");
    else
        $display("PASS: segundo dato correcto");

    pe_drive[0] = 0;

    // ===============================================================================================
    // MANY TO ONE  -SECUENCIAL-
    // ===============================================================================================

    // TEST 3: PE0 a PE3

    $display("\n[TEST] PE0 -> PE3");

    config_0_to_3();
    pe_drive[0] = 32'hAAAA;

    repeat(6) @(posedge clk);

    $display("PE3 = %h", pe_out[3]);

    pe_drive[0] = 0;


    // TEST 4: PE1 a PE3

    $display("\n[TEST] PE1 -> PE3");

    config_1_to_3();
    pe_drive[1] = 32'hBBBB;

    repeat(6) @(posedge clk);

    $display("PE3 = %h", pe_out[3]);

    pe_drive[1] = 0;


    // TEST 5: PE2 a PE3 
 
    $display("\n[TEST] PE2 -> PE3");

    config_2_to_3();
    pe_drive[2] = 32'hCCCC;

    repeat(6) @(posedge clk);

    $display("PE3 = %h", pe_out[3]);

    pe_drive[2] = 0;
    
    // ===============================================================================================
    // ONE TO MANY -PE0 a TODOS-
    // ===============================================================================================
    
    
    // =====================================
    // TEST 6: ONE-TO-MANY (broadcast desde PE0)
    // =====================================
    $display("\n[TEST 6] ONE-TO-MANY: PE0 -> PE1, PE2, PE3");
    
    config_0_to_all();
    
    pe_drive[0] = 32'hFACE1234;
    
    repeat(6) @(posedge clk);
    
    // Validacion
    $display("PE1 = %h", pe_out[1]);
    $display("PE2 = %h", pe_out[2]);
    $display("PE3 = %h", pe_out[3]);
    
    if (pe_out[1] !== 32'hFACE1234 ||
        pe_out[2] !== 32'hFACE1234 ||
        pe_out[3] !== 32'hFACE1234)
        $error("FAIL: ONE-TO-MANY incorrecto");
    else
        $display("PASS: ONE-TO-MANY correcto");
    
    pe_drive[0] = 0;


    $display("\nSimulation completed");
    $finish;
end

endmodule