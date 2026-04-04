// ===============================
// WAIT HELPERS (para comparar el dato final)
// ===============================
task automatic wait_for_value_at(
    input int r, input int c,
    input logic [DATA_W-1:0] expected
);
    // Espera bloqueante hasta observar valor esperado
    // Existe un tiempo maximo para evitar un bloqueo infinito
    int cycles;

    cycles = 0;
    while ((pe_out_obs[r][c] !== expected) && (cycles < MAX_WAIT_CYCLES)) begin
        @(posedge clk);
        cycles++;
    end

    if (pe_out_obs[r][c] !== expected) begin
        print_pe_outputs();
        $fatal(1,
            "[FAIL] Timeout wait_for_value_at: PE[%0d][%0d] no llego a %h en %0d ciclos. Valor actual=%h",
            r, c, expected, MAX_WAIT_CYCLES, pe_out_obs[r][c]
        );
    end
endtask

// WRAPPER PARA RUTA LARGA

task automatic wait_for_last_node(
    input logic [DATA_W-1:0] expected
);
    wait_for_value_at(ROWS-1, COLS-1, expected);
endtask

task automatic wait_for_two(
    input int r1, input int c1,
    input int r2, input int c2,
    input logic [DATA_W-1:0] expected
);
     // Sincroniza dos nodos
    int cycles;

    cycles = 0;
    while (!((pe_out_obs[r1][c1] == expected) &&
             (pe_out_obs[r2][c2] == expected)) &&
           (cycles < MAX_WAIT_CYCLES)) begin
        @(posedge clk);
        cycles++;
    end

    if (!((pe_out_obs[r1][c1] == expected) &&
          (pe_out_obs[r2][c2] == expected))) begin
        print_pe_outputs();
        $fatal(1,
            "[FAIL] Timeout wait_for_two: PE[%0d][%0d] o PE[%0d][%0d] no llegaron a %h",
            r1, c1, r2, c2, expected
        );
    end
endtask

task automatic wait_for_all(
    input int r1, input int c1,
    input int r2, input int c2,
    input int r3, input int c3,
    input logic [DATA_W-1:0] expected
);
    // Sincroniza tres nodos
    int cycles;

    cycles = 0;
    while (!((pe_out_obs[r1][c1] == expected) &&
             (pe_out_obs[r2][c2] == expected) &&
             (pe_out_obs[r3][c3] == expected)) &&
           (cycles < MAX_WAIT_CYCLES)) begin
        @(posedge clk);
        cycles++;
    end

    if (!((pe_out_obs[r1][c1] == expected) &&
          (pe_out_obs[r2][c2] == expected) &&
          (pe_out_obs[r3][c3] == expected))) begin
        print_pe_outputs();
        $fatal(1,
            "[FAIL] Timeout wait_for_all: no todos los nodos llegaron a %h",
            expected
        );
    end
endtask

task automatic wait_for_mesh_except_source(
    input int src_r, input int src_c,
    input logic [DATA_W-1:0] expected
);
    int cycles;
    bit done;

    cycles = 0;
    done   = 0;

    while (!done && cycles < MAX_WAIT_CYCLES) begin
        done = 1;

        for (int i = 0; i < ROWS; i++) begin
            for (int j = 0; j < COLS; j++) begin
                if (!(i == src_r && j == src_c)) begin
                    if (pe_out_obs[i][j] !== expected)
                        done = 0;
                end
            end
        end

        if (!done) begin
            @(posedge clk);
            cycles++;
        end
    end

    if (!done) begin
        print_pe_outputs();
        $fatal(1, "[FAIL] Timeout wait_for_mesh_except_source: no toda la malla llego a %h", expected);
    end
endtask
