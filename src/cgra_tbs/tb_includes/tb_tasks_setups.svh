// ===============================
// SETUPS
// ===============================
task automatic setup_one_to_one(
    input int src_r, input int src_c,
    input int dst_r, input int dst_c
);
    clear_all();
    repeat(2) @(posedge clk);
    route_one_to_one(src_r, src_c, dst_r, dst_c);
    inj_en_cfg[src_r][src_c] = 1'b1;
endtask

// WRAPPER PARA RUTA LARGA

task automatic setup_long_one_to_one();
    setup_one_to_one(0, 0, ROWS-1, COLS-1);
endtask

// Broadcast simple a vecinos (derecha y abajo)
task automatic setup_broadcast_00_basic_2x2();
    clear_all();
    repeat(2) @(posedge clk);

    // distribuye hacia derecha y abajo
    sel_cfg[0][0][EAST]  = LOCAL;
    sel_cfg[0][0][SOUTH] = LOCAL;
    
    // Configuración de recepción
    sel_cfg[0][1][LOCAL] = WEST;
    sel_cfg[1][0][LOCAL] = NORTH;

    inj_en_cfg[0][0] = 1;
endtask
