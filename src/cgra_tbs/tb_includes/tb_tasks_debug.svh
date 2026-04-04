// ===============================
// DEBUG
// ===============================

task automatic print_pe_outputs();
    // Dump del estado actual de todos los PEs
    $display("---- PE OUTPUTS ----");
    for (int i = 0; i < ROWS; i++) begin
        for (int j = 0; j < COLS; j++) begin
            $display("PE[%0d][%0d] in=%h out=%h",
                i, j, pe_in_obs[i][j], pe_out_obs[i][j]);
        end
    end
    $display("--------------------");
endtask

task automatic print_if_activity();
    bit activity;

    activity = 0;
    for (int i = 0; i < ROWS; i++) begin
        for (int j = 0; j < COLS; j++) begin
            if (|pe_in_obs[i][j] || |pe_out_obs[i][j]) begin
                activity = 1;
            end
        end
    end

    if (activity) begin
        $display("T=%0t FLOW:", $time);
        print_pe_outputs();
    end
endtask

always @(posedge clk) begin
    if (debug_enable)
        print_if_activity();
end
