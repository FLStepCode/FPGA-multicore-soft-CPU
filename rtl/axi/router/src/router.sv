module router #(
    parameter DATA_WIDTH = 32,
    parameter REN = 5,
    parameter CS = 2,
    parameter MAX_PACKAGES = 4,
    parameter router_X = 0,
    parameter router_Y = 0
)(
    input clk, rst_n,
    axis_if.s in [0:REN-1], axis_if.m out [0:REN-1]
);


    
endmodule
