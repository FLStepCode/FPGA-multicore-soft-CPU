`include "mesh_3x3/inc/noc.svh"
`include "mesh_3x3/inc/noc_XY.svh"
`include "mesh_3x3/src/router.sv"

module noc(
    input clk,
    input rst_n,
    output[0:`PL-1] core_inputs[0:`Y-1][0:`X-1],
    input[0:`PL-1] core_outputs[0:`Y-1][0:`X-1],
	input core_availability_signals_out[0:`Y-1][0:`X-1],
	output core_availability_signals_in[0:`Y-1][0:`X-1]
);

wire [0:`PL-1] inputs[0:`Y + 1][0:`X + 1][0:`REN-1];

wire availability_signals[0:`Y + 1][0:`X + 1][0:`REN-1];

generate

    genvar i, j;
    for (i = 0; i <= `Y; i = i + 1)
    begin : init_avail_Y
        for (j = 0; j < `REN; j = j + 1)
        begin : init_avail_REN_1
            assign availability_signals[i][0][j] = 1;
            assign availability_signals[i][`X + 1][j] = 1;
        end
    end
	 
	 
    for (i = 0; i <= `X; i = i + 1)
    begin : init_avail_X
        for (j = 0; j < `REN; j = j + 1)
        begin : init_avail_REN_2
            assign availability_signals[0][i][j] = 1;
            assign availability_signals[`Y + 1][i][j] = 1;
        end
    end

    for (i = 1; i <= `X; i = i + 1)
    begin : init_packet_X
        assign inputs[1][i][1] = 0;
        assign inputs[`Y][i][3] = 0;
    end

    for (i = 1; i <= `Y; i = i + 1)
    begin : init_packet_Y
        assign inputs[i][1][4] = 0;
        assign inputs[i][`X][2] = 0;
    end
	 
endgenerate

generate
    genvar router_Y_iterator, router_X_iterator;
    for (router_Y_iterator = 1; router_Y_iterator <= `Y; router_Y_iterator = router_Y_iterator + 1)
    begin  : routers_Y
        for (router_X_iterator = 1; router_X_iterator <= `X; router_X_iterator = router_X_iterator + 1)
        begin  : routers_X

            assign core_availability_signals_in[router_Y_iterator-1][router_X_iterator-1] = availability_signals[router_Y_iterator][router_X_iterator][0];

            localparam lower = router_Y_iterator + 1;
            localparam right = router_X_iterator + 1;
            localparam upper = router_Y_iterator - 1;
            localparam left = router_X_iterator - 1;

            wire[0:`PL-1] outputs[0:`REN-1];
            assign core_inputs[router_Y_iterator-1][router_X_iterator-1] = outputs[0];
            assign inputs[upper][router_X_iterator][3] = outputs[1];
            assign inputs[router_Y_iterator][right][4] = outputs[2];
            assign inputs[lower][router_X_iterator][1] = outputs[3];
            assign inputs[router_Y_iterator][left][2] = outputs[4];

            wire signals_in[0:`REN-1];
            assign signals_in[0] = core_availability_signals_out[router_Y_iterator-1][router_X_iterator-1];
            assign signals_in[1] = availability_signals[upper][router_X_iterator][3];
            assign signals_in[2] = availability_signals[router_Y_iterator][right][4];
            assign signals_in[3] = availability_signals[lower][router_X_iterator][1];
            assign signals_in[4] = availability_signals[router_Y_iterator][left][2];

            router router(
                .clk(clk), .rst_n(rst_n),
                .inputs(inputs[router_Y_iterator][router_X_iterator]), .outputs(outputs),
                .signals_out(availability_signals[router_Y_iterator][router_X_iterator]), .signals_in(signals_in),
                .router_Y(router_Y_iterator - 1), .router_X(router_X_iterator - 1)
            );
			
			assign inputs[router_Y_iterator][router_X_iterator][0] = core_outputs[router_Y_iterator-1][router_X_iterator-1];
        end
    end
endgenerate

endmodule
