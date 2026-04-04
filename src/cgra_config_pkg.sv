//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2026 06:25:05 PM
// Design Name: 
// Module Name: cgra_config_pkg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


package cgra_config_pkg;

    parameter int ROWS    = 3;
    parameter int COLS    = 3;
    parameter int DATA_W  = 32;
    
    // Mesh : LOCAL + N + S + E + W
    parameter int N_PORTS = 5;
    
    parameter int SEL_W = $clog2(N_PORTS + 1);
    
    localparam int LOCAL = 0;
    localparam int NORTH = 1;
    localparam int SOUTH = 2;
    localparam int EAST  = 3;
    localparam int WEST  = 4;
    localparam int NONE  = N_PORTS;

endpackage