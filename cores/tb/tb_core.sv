`timescale 1ps/1ps
`include "cores/src/sm_top.v"


module tb;

reg clk = 1;
reg rst_n = 0;

always #5 clk = ~clk;

sm_top dut(
    .clkIn(clk),
    .rst_n(rst_n),
    .clkDivide(1),
    .clkEnable(1),
    .regAddr(0)
);

initial begin
    #10;
    rst_n = 1;
    #1000;
    $stop;
end

endmodule