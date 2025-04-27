`include "mesh_3x3/inc/router.svh"

module arbiter (

    input clk, rst_n,

    input[0:`PL-1] input_[0:`REN-1],

    output wire[0:`PL-1] output_data,

    output reg[`REN_B-1:0] shift = 0
);
    wire[0:`REN-1] selector;
    wire[0:2*`REN-1] shifted_selector;
    wire[0:`REN-1] shifted_selector_sector;

    assign shifted_selector = {selector, selector} << shift;
    assign shifted_selector_sector = shifted_selector[0:`REN-1];

    genvar i;
    generate
        for (i = 0; i < `REN; i = i + 1)
        begin : arbiter_selector_generator
            assign selector[i] = input_[i][0];
        end
    endgenerate

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            shift <= 0;
        end
        else
        begin
            casex (shifted_selector_sector)
                5'b10000: 
                begin
                end
                5'bx1xxx: 
                begin
                    shift <= (shift + 1 >= `REN) ? shift + 1 - `REN : shift + 1;
                end
                5'bx01xx: 
                begin
                    shift <= (shift + 2 >= `REN) ? shift + 2 - `REN : shift + 2;
                end 
                5'bx001x: 
                begin
                    shift <= (shift + 3 >= `REN) ? shift + 3 - `REN : shift + 3;
                end
                5'bx0001: 
                begin
                    shift <= (shift + 4 >= `REN) ? shift + 4 - `REN : shift + 4;
                end
                default:
                begin
                    shift <= 0;
                end
            endcase
        end
    end

    assign output_data = input_[shift];
    
endmodule
