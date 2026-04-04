// ===============================
// CLEARs
// ===============================
task automatic clear_route();
    for (int i = 0; i < ROWS; i++) begin
        for (int j = 0; j < COLS; j++) begin
            for (int p = 0; p < N_PORTS; p++) begin
                sel_cfg[i][j][p] = NONE;
            end
        end
    end
endtask

task automatic clear_stimulus();
    for (int i = 0; i < ROWS; i++) begin
        for (int j = 0; j < COLS; j++) begin
            pe_op_cfg[i][j]    = 1'b0;
            inj_en_cfg[i][j]   = 1'b0;
            inj_data_cfg[i][j] = '0;
        end
    end
endtask

task automatic clear_all();
    clear_route();
    clear_stimulus();
endtask

logic debug_enable;

task automatic start_clean_test();
    debug_enable = 1'b0;
    clear_all();

    rst = 1'b1;
    repeat(2) @(posedge clk);

    clear_all();
    rst = 1'b0;
    @(posedge clk);
    
    debug_enable = 1'b1;
endtask
