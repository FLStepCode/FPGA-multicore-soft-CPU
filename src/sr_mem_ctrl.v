`include "src/sr_cpu.vh"

module sr_mem_ctrl (
    input clk, rst_n,
    input [31:0] memData,
    input [31:0] memAddress,
    input [2:0] memInstr,

    output reg[31:0] dataToCpu,
    output reg dataSent
);

    reg[31:0] ram [0:63];
    reg counter;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dataToCpu <= 32'hFFFFFFFF;
            dataSent <= 0;
            counter <= 0;

            for (i = 0; i < 64; i = i + 1) begin
                ram[i] = 0;
            end
        end
        else begin

            dataToCpu <= 32'hFFFFFFFF;
            dataSent <= 0;

            case (memInstr)
                `AGU_LOAD: begin
                    dataToCpu <= ram[memAddress];
                    dataSent <= 1;
                end
                `AGU_STORE: begin
                    ram[memAddress] <= memData;
                    counter <= 0;
                end
                default: begin
                    counter <= 0;
                end
            endcase
        end
    end
    
endmodule