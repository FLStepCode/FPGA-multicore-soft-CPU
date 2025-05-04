`timescale 1ps/1ps

`include "cpu/noc_with_cores.sv"

module tb;

reg clk = 0;
reg rst_n = 0;

reg [31:0] peekAddress;
reg [$clog2(9) - 1:0] peekId;
wire [31:0] peekData;

always #10 clk = ~clk;

noc_with_cores dut (
    .clk(clk), .rst_n(rst_n),
    .peekAddress(peekAddress), .peekId(peekId), .peekData(peekData)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        peekAddress <= 0;
        peekId <= 0;
    end
    else begin
        if (peekAddress < 1023) begin
            peekAddress <= peekAddress + 1;
        end
        else begin
            peekAddress <= 0;
            if (peekId < `RN) begin
                peekId <= peekId + 1;
            end
            else begin
                peekId <= 0;
            end
        end
    end
end

initial begin
    #20;
    rst_n = 1;
    #3000000;
    $stop;
end
    
endmodule