// ===============================
// ROUTING
// ===============================
// Broadcast a todos

task automatic setup_full_broadcast_from_00();
    clear_all();

    inj_en_cfg[0][0] = 1'b1;

    // Source
    if (COLS > 1) sel_cfg[0][0][EAST]  = LOCAL;
    if (ROWS > 1) sel_cfg[0][0][SOUTH] = LOCAL;

    for (int r = 0; r < ROWS; r++) begin
        for (int c = 0; c < COLS; c++) begin

            // source ya configurado
            if (r == 0 && c == 0) begin
            end

            // primera columna: recibe desde NORTH
            else if (c == 0) begin
                sel_cfg[r][0][LOCAL] = NORTH;

                if (r < ROWS-1)
                    sel_cfg[r][0][SOUTH] = NORTH;

                if (COLS > 1)
                    sel_cfg[r][0][EAST] = NORTH;
            end

            // resto de columnas: recibe desde WEST
            else begin
                sel_cfg[r][c][LOCAL] = WEST;

                if (c < COLS-1)
                    sel_cfg[r][c][EAST] = WEST;
            end
        end
    end
endtask

// ruta Manhattan, Limpia ruta
task automatic route_one_to_one(
    input int src_r, input int src_c,
    input int dst_r, input int dst_c
);
    int cr, cc, inc_port;

    // Validaciones antes de iniciar. Comprobando que source se encuentra
    // dentro del rango del mesh
    if (src_r < 0 || src_r >= ROWS || src_c < 0 || src_c >= COLS)
        $fatal(1, "route_one_to_one: source fuera de rango (%0d,%0d)", src_r, src_c);

    if (dst_r < 0 || dst_r >= ROWS || dst_c < 0 || dst_c >= COLS)
        $fatal(1, "route_one_to_one: destination fuera de rango (%0d,%0d)", dst_r, dst_c);

    clear_route();

    cr = src_r;
    cc = src_c;
    inc_port = LOCAL;

    // Camino Horizontal (EAST/WEST)
    while (cc < dst_c) begin
        sel_cfg[cr][cc][EAST] = inc_port;
        cc++; 
        inc_port = WEST;
    end
    while (cc > dst_c) begin
        sel_cfg[cr][cc][WEST] = inc_port;
        cc--; 
        inc_port = EAST;
    end

    // Camino Vertical (NORTH/SOUTH)
    while (cr < dst_r) begin
        sel_cfg[cr][cc][SOUTH] = inc_port;
        cr++; 
        inc_port = NORTH;
    end
    while (cr > dst_r) begin
        sel_cfg[cr][cc][NORTH] = inc_port;
        cr--; 
        inc_port = SOUTH;
    end
    // Destino final
    sel_cfg[cr][cc][LOCAL] = inc_port; 
endtask

// ruta Manhattan, NO Limpia ruta
task automatic append_one_to_one_route(
    input int src_r, input int src_c,
    input int dst_r, input int dst_c
);
    int cr, cc, inc_port;

    if (src_r < 0 || src_r >= ROWS || src_c < 0 || src_c >= COLS)
        $fatal(1, "[FAIL] append_one_to_one_route: source fuera de rango (%0d,%0d)", src_r, src_c);

    if (dst_r < 0 || dst_r >= ROWS || dst_c < 0 || dst_c >= COLS)
        $fatal(1, "[FAIL] append_one_to_one_route: destination fuera de rango (%0d,%0d)", dst_r, dst_c);

    cr = src_r;
    cc = src_c;
    inc_port = LOCAL;

    // Horizontal
    while (cc < dst_c) begin
        sel_cfg[cr][cc][EAST] = inc_port;
        cc++;
        inc_port = WEST;
    end

    while (cc > dst_c) begin
        sel_cfg[cr][cc][WEST] = inc_port;
        cc--;
        inc_port = EAST;
    end

    // Vertical
    while (cr < dst_r) begin
        sel_cfg[cr][cc][SOUTH] = inc_port;
        cr++;
        inc_port = NORTH;
    end

    while (cr > dst_r) begin
        sel_cfg[cr][cc][NORTH] = inc_port;
        cr--;
        inc_port = SOUTH;
    end

    // Entrega PE local del destino
    sel_cfg[cr][cc][LOCAL] = inc_port;
endtask

task automatic route_via_mid_generic(
    input int src_r, input int src_c,
    input int mid_r, input int mid_c,
    input int dst_r, input int dst_c
);
    if (mid_r < 0 || mid_r >= ROWS || mid_c < 0 || mid_c >= COLS)
        $fatal(1, "[FAIL] route_via_mid_generic: midpoint fuera de rango (%0d,%0d)", mid_r, mid_c);

    clear_all();

    // source -> midpoint
    append_one_to_one_route(src_r, src_c, mid_r, mid_c);

    // midpoint -> destination
    append_one_to_one_route(mid_r, mid_c, dst_r, dst_c);

    // inj en source
    inj_en_cfg[src_r][src_c] = 1'b1;
endtask

// Helper para no escoger manualmente nodo mid
task automatic setup_long_via_mid();
    int mid_r, mid_c;

    // Select del nodo intermedio
    if (COLS >= 3) begin
        mid_r = 0;
        mid_c = COLS/2;
    end
    else if (ROWS >= 3) begin
        mid_r = ROWS/2;
        mid_c = 0;
    end
    else begin
        $fatal(1, "[FAIL] setup_long_via_mid requiere al menos 3 filas o 3 columnas");
    end

    route_via_mid_generic(0, 0, mid_r, mid_c, ROWS-1, COLS-1);
endtask

 // Ruta manual pasando por un PE intermedio
task automatic route_via_single_mid_2x2(
    input int src_r, input int src_c,
    input int mid_r, input int mid_c,
    input int dst_r, input int dst_c
);
    clear_all();
    repeat(2) @(posedge clk);

    // src -> mid
    sel_cfg[src_r][src_c][EAST] = LOCAL;

    // paso por PE intermedio
    sel_cfg[mid_r][mid_c][LOCAL] = WEST;
    sel_cfg[mid_r][mid_c][SOUTH] = LOCAL;

    // mid -> dst
    sel_cfg[dst_r][dst_c][LOCAL] = NORTH;
endtask
