module router #(
    parameter DATA_WIDTH = 32,
    parameter CHANNEL_NUMBER = 5,
    parameter MAX_ROUTERS_X = 4,
    localparam MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    localparam MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter MAX_PACKAGES = 4,
    parameter router_X = 0,
    parameter router_Y = 0
)(
    input clk, rst_n,
    axis_if.s in [0:CHANNEL_NUMBER-1],
    axis_if.m out [0:CHANNEL_NUMBER-1]
);


    
endmodule
