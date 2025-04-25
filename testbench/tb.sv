`timescale 1ps/1ps
`include "board/de10lite/de10lite.sv"

module tb;

reg clk = 0;
reg[1:0] KEY = 2'b10;
wire[7:0] HEX0;
wire[7:0] HEX1;
wire[7:0] HEX2;
wire[7:0] HEX3;
wire[7:0] HEX4;
wire[7:0] HEX5;

de10lite de10lite
(
    .CLOCK_50(clk),
    .KEY(KEY),
    .SW(10'b0000000000),
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5)
);

localparam CLK_PERIOD = 2;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    #200;
    KEY[0] = 1;
    #10000;
    $finish;
end

endmodule