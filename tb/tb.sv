`timescale 1ps/1ps

`define SIM

`include "boards/toplevel.sv"

module tb;

reg clk = 0;
reg clk_25mhz = 0;
reg rst_n = 0;

integer f;

wire vs, hs;
wire [7:0] r, g, b;

always #10 clk = ~clk;
always #20 clk_25mhz = ~clk_25mhz;

always @(posedge clk_25mhz) $fwrite(f, "%0d ns: %b %b %b %b %b\n", $time, hs, vs, r, g, b);

toplevel dut (
    .clk(clk), .clk_25mhz(clk_25mhz), .rst_n(rst_n),
    .vs(vs), .hs(hs),
    .r(r), .g(g), .b(b)
);


initial begin
    f = $fopen("output.txt", "w");
    #20;
    rst_n = 1;
    #5000000;
    #40000000;
    $fclose(f);
    $stop;
end
    
endmodule