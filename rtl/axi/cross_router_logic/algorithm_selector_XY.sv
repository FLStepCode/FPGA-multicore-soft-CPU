module algorithm_selector #(
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0,
    parameter CHANNEL_NUMBER = 5
) (
    input  logic [MAX_ROUTERS_X_WIDTH-1:0] target_x,
    input  logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y,
    output logic [CHANNEL_NUMBER-1:0]      selector
);
    assign selector[0] = ((target_x == ROUTER_X) && (target_y == ROUTER_Y));
    assign selector[1] = (target_y < ROUTER_Y);
    assign selector[2] = (target_x > ROUTER_X);
    assign selector[3] = (target_y > ROUTER_Y);
    assign selector[4] = (target_x < ROUTER_X);
endmodule