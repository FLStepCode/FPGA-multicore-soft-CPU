`include "boards/toplevel.sv"

module de10standard (
    input CLOCK_50,
    input logic[3:0] KEY,
    output logic[7:0] VGA_R,
    output logic[7:0] VGA_G,
    output logic[7:0] VGA_B,
    output logic VGA_HS, VGA_VS,
    output logic VGA_CLK
);

    wire clk, clk_25mhz;

    cnt_div #(
      .DIV_CNT(500),
      .CLOCKS_HIGH(250)
    ) cd (
        .clk(CLOCK_50), .rst_n(KEY[3]),
        .clk_out(clk)
    );

    cnt_div #(
      .DIV_CNT(2),
      .CLOCKS_HIGH(1)
    ) cd2 (
        .clk(CLOCK_50), .rst_n(KEY[3]),
        .clk_out(clk_25mhz)
    );

    assign VGA_CLK = clk_25mhz;

    toplevel to(.clk_25mhz(clk_25mhz), .clk(clk), .rst_n(KEY[3]), .vs(VGA_VS), .hs(VGA_HS), .r(VGA_R), .g(VGA_G), .b(VGA_B));
    
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