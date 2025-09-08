`include "boards/toplevel.sv"

module de10standard (
    input CLOCK_50,
    input [9:0] SW,
    input [3:0] KEY,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5,
    input GPIO_in,
    output GPIO_out
);

    wire clk;
    wire[31:0] peekData;

    cnt_div cd (
        .clk(CLOCK_50), .rst_n(KEY[3]),
        .clk_out(clk)
    );

    toplevel to(.clk(clk), .rst_n(KEY[3]), .rx(GPIO_in), .tx(GPIO_out));
    
endmodule

module cnt_div
#(
    parameter DIV_CNT = 50,
    parameter WIDTH = $clog2(DIV_CNT),
    parameter CLOCKS_HIGH = 25
)
(
    input  clk,
    input  rst_n,
    output clk_out
);

   
   reg [WIDTH-1:0] cnt = 0;

   always@(posedge clk or negedge rst_n)
     begin
        if(!rst_n)
          cnt <= {WIDTH{1'b0}};
        else if(cnt == DIV_CNT-1)
          cnt <= {WIDTH{1'b0}};
        else
          cnt <= cnt + 1'b1;
     end
   
   assign clk_out = ~((cnt < CLOCKS_HIGH) ? 1'b1 : 1'b0);
   
endmodule