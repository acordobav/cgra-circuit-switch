// Envía dos paquetes consecutivos (pipeline)
task automatic send_two_packets(
    input int src_r, input int src_c,
    input logic [DATA_W-1:0] d1,
    input logic [DATA_W-1:0] d2,
    input int gap_cycles,
    output logic [DATA_W-1:0] expected
);
    inj_en_cfg[src_r][src_c]   = 1'b1;
    inj_data_cfg[src_r][src_c] = d1;

    repeat(gap_cycles) @(posedge clk);

    inj_data_cfg[src_r][src_c] = d2;
    expected = d2;

    @(posedge clk);
    inj_en_cfg[src_r][src_c]   = 1'b0;
    inj_data_cfg[src_r][src_c] = '0;
endtask
