`include "cores/src/sr_cpu.vh"
`include "cores/src/sr_mem_ctrl.svh"

module sr_mem_ctrl #(
    parameter int NODE_ID = 0, NODE_COUNT = 8, RAM_CHUNK_SIZE = 1024, PACKET_ID_WIDTH = 5
) (
    input clk, rst_n,

    // CPU
    input [31:0] memData,
    input [31:0] memAddress,
    input [2:0] memInstr,
    output reg[31:0] dataToCpu,
    output reg dataSent,

    // RAM
    input [31:0] rdData,
    output reg [31:0] ramAddress,
    output reg [31:0] wrData,
    output reg we,

    // NOC
    input [67:0] packetIn, // | unused[67] | data[66:35] | address[34:3] | instr[2:0] |
    input [$clog2(NODE_COUNT) - 1:0] nodeStart,
    input validIn,

    output reg [67:0] packetOut, // | unused[71:67] | data[66:35] | address[34:3] | instr[2:0] |
    output reg [$clog2(NODE_COUNT) - 1:0] nodeDest,
    output reg [PACKET_ID_WIDTH - 1:0] packetId,
    output reg validOut
);

    reg [1:0] counter;
    reg [71:0] packetInReg; // | unused[71:67] | data[66:35] | address[34:3] | instr[2:0] |
    reg load_flag;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            packetInReg <= 67'd0;
            packetOut <= 67'd0;
            validOut <= 0;
            packetId <= 0;
            load_flag <= 0;
        end
        else begin

            validOut <= 0;
            dataSent <= 0;
            we <= 0;

            if (dataSent) begin
                load_flag <= 0;
            end

            if (counter == 0) begin
                if (validIn) begin
                    counter <= counter + 1;
                    packetInReg <= packetIn;
                end
                if (memInstr != `AGU_IDLE) begin
                    nodeDest <= memAddress / RAM_CHUNK_SIZE;
                    packetOut <= {5'd0, memData, memAddress % RAM_CHUNK_SIZE, memInstr};
                    if (memInstr == `AGU_LOAD && ~load_flag) begin
                        packetId <= packetId + 1;
                        validOut <= 1;
                        load_flag <= 1;
                    end
                    else if (memInstr != `AGU_LOAD) begin
                        packetId <= packetId + 1;
                        validOut <= 1;
                    end
                end
                else begin
                    packetOut <= 67'b0;
                end
            end
            else begin
                validOut <= 0;
                case (packetInReg[2:0])
                    `LOAD_REQUESTED: begin
                        if (counter == 1) begin
                            counter <= counter + 1;
                            ramAddress <= packetInReg[34:3];
                        end
                        else begin
                            counter <= 0;
                            nodeDest <= nodeStart;
                            packetOut <= {1'b0, rdData, 32'hFFFFFFFF, `LOAD_SATISFIED};
                            packetId <= packetId + 1;
                            validOut <= 1;
                            packetInReg <= 0;
                        end
                    end
                    `LOAD_SATISFIED: begin
                        counter <= 0;
                        dataToCpu <= packetInReg[66:35];
                        dataSent <= 1;
                        packetInReg <= 0;
                    end
                    `STORE_TO_RAM: begin
                        counter <= 0;
                        ramAddress <= packetInReg[34:3];
                        wrData <= packetInReg[66:35];
                        we <= 1;
                        packetInReg <= 0;
                    end
                endcase
            end
        end
    end
    
endmodule