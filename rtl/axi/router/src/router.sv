module router #(
    parameter DATA_WIDTH = 32
    `ifndef USE_LIGHT_STREAM
    ,
    parameter ID_WIDTH = 4,
    parameter DEST_WIDTH = 4,
    parameter USER_WIDTH = 4,
    `endif
    parameter CHANNEL_NUMBER = 5,
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter MAX_PACKAGES = 4,
    parameter router_X = 0,
    parameter router_Y = 0
)(
    input clk, rst_n,
    axis_if.s in  [CHANNEL_NUMBER],
    axis_if.m out [CHANNEL_NUMBER]
);


    
endmodule
