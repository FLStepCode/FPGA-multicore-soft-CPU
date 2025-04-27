`timescale 1ps/1ps

`include "mesh_3x3/noc/toplevel.sv"

module tb;

reg clk = 0;
reg rst_n = 0;

always #10 clk = ~clk;

toplevel dut (
    .clk(clk), .rst_n(rst_n)
);

initial begin
    #20;
    rst_n = 1;
    #10000;
    $stop;
end
    
endmodule