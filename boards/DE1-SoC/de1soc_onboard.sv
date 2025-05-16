`include "boards/toplevel_onboard.sv"

module de1soc_onboard (
    input CLOCK_50,
    input [9:0] SW,
    input [3:0] KEY_N,
    output [6:0] HEX0_N,
    output [6:0] HEX1_N,
    output [6:0] HEX2_N,
    output [6:0] HEX3_N,
    output [6:0] HEX4_N,
    output [6:0] HEX5_N
);

    wire clk;
    wire[31:0] peekData;

    cnt_div cd (
        .clk(CLOCK_50), .rst_n(KEY_N[3]),
        .clk_out(clk)
    );

    toplevel_onboard to (
        .clk(clk), .rst_n(KEY_N[3]),
        .peekAddress({22'd0, SW}), .peekId({1'b0, ~KEY_N[2:0]}), .peekData(peekData)
    );

    hex_to_seven hts0 (peekData[3:0], HEX0_N);
    hex_to_seven hts1 (peekData[7:4], HEX1_N);
    hex_to_seven hts2 (peekData[11:8], HEX2_N);
    hex_to_seven hts3 (peekData[15:12], HEX3_N);
    hex_to_seven hts4 (peekData[19:16], HEX4_N);
    hex_to_seven hts5 (peekData[23:20], HEX5_N);
    
endmodule


module hex_to_seven (
	input[3:0] in,
	output reg[7:0] out
);

	always @*
    begin
        case (in)
            0: out = 8'b11000000; 
            1: out = 8'b11111001; 
            2: out = 8'b10100100; 
            3: out = 8'b10110000; 
            4: out = 8'b10011001; 
            5: out = 8'b10010010; 
            6: out = 8'b10000010; 
            7: out = 8'b11111000; 
            8: out = 8'b10000000; 
            9: out = 8'b10010000; 
            10: out = 8'b10001000; 
            11: out = 8'b10000011; 
            12: out = 8'b11000110; 
            13: out = 8'b10100001; 
            14: out = 8'b10000110; 
            15: out = 8'b10001110;
            default: out = 8'b11111111;
        endcase
    end

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