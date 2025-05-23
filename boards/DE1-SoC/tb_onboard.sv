`timescale 1ps/1ps
`include "boards/DE1-SoC/de1soc_onboard.sv"

module tb_onboard;
    
reg clk;
reg [9:0] SW;
reg [3:0] KEY_N;

wire [6:0] HEX0_N;
wire [6:0] HEX1_N;
wire [6:0] HEX2_N;
wire [6:0] HEX3_N;
wire [6:0] HEX4_N;
wire [6:0] HEX5_N;

integer i;

de1soc_onboard DUT (
    clk, SW, KEY_N, HEX0_N, HEX1_N, HEX2_N, HEX3_N, HEX4_N, HEX5_N
);

always #10 clk = ~clk;

always begin
    
    for (i = 0; i < 100; i = i + 1) begin
        @(posedge clk);
    end

    @(posedge clk) begin
        SW <= SW + 1;
        if (SW == 1023) begin
            KEY_N[2:0] <= KEY_N[2:0] - 1;
        end
    end

end

initial begin
    clk = 0;
    SW = 0;
    KEY_N = 4'b0111;

    #200;

    KEY_N = 4'b1111;

    #200000000 $stop;


end

endmodule
