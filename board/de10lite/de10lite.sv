`include "mesh_3x3/inc/noc_XY.svh"
`include "mesh_3x3/noc/toplevel.sv"

module de10lite (
    input CLOCK_50,
    input CLOCK2_50,
    input[1:0] KEY,
    input[9:0] SW,
    output[9:0] LEDR,
    output[7:0] HEX0,
    output[7:0] HEX1,
    output[7:0] HEX2,
    output[7:0] HEX3,
    output[7:0] HEX4,
    output[7:0] HEX5
);
    wire clock_network;

    cnt_div #(.DIV_CNT(4), .CLOCKS_HIGH(2)) clock_divider(
        .clk(CLOCK_50),
        .rst_n(KEY[0]),
        .clk_out(clock_network)
    );
    
    assign LEDR[0] = clock_network | SW[9];

    reg core_availability_signals_out[0:`Y-1][0:`X-1];

    initial begin
        int i, j;
        for (i = 0; i < `Y; i = i + 1)
        begin
            for (j = 0; j < `X; j = j + 1)
            begin
                core_availability_signals_out[i][j] = 1;
            end
        end
    end

    wire[31:0] assembler_packets[0:`Y-1][0:`X-1];

    wire [1:0] counter_X = SW[1:0];
    wire [1:0] counter_Y = SW[3:2];

    toplevel toplevel(
        .clk(clock_network | SW[9]), .rst_n(KEY[0]),
        .core_availability_signals_out(core_availability_signals_out),
        .lfsr1_in(32'hA5A5A5A5), .lfsr2_in(32'h5A5A5A5A), .lfsr3_in(32'h3C3C3C3C), .lfsr4_in(32'h3C3C3C3C),
        .assembler_packets(assembler_packets)
    );

    hex_to_seven hex_to_seven_0(.in(assembler_packets[counter_Y][counter_X][3:0]), .out(HEX0));
    hex_to_seven hex_to_seven_1(.in(assembler_packets[counter_Y][counter_X][7:4]), .out(HEX1));
    hex_to_seven hex_to_seven_2(.in(assembler_packets[counter_Y][counter_X][11:8]), .out(HEX2));
    hex_to_seven hex_to_seven_3(.in(assembler_packets[counter_Y][counter_X][15:12]), .out(HEX3));
    hex_to_seven hex_to_seven_4(.in(assembler_packets[counter_Y][counter_X][19:16]), .out(HEX4));
    hex_to_seven hex_to_seven_5(.in(assembler_packets[counter_Y][counter_X][23:20]), .out(HEX5));

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