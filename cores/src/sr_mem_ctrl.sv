`include "cores/src/sr_cpu.vh"
`include "cores/src/sr_mem_ctrl.svh"

module sr_mem_ctrl #(
    parameter int NODE_ID = 0, NODE_COUNT = 8, RAM_CHUNK_SIZE = 1024, PACKET_ID_WIDTH = 5, TTL = 2048
) (
    input clk, rst_n,

    // CPU
    input [31:0] memData,
    input [31:0] memAddress,
    input [2:0] memInstr,
    output reg[31:0] dataToCpu,
    output reg instrSuccess,

    // RAM
    input [31:0] rdData,
    output reg [31:0] ramAddress,
    output reg [31:0] wrData,
    output reg we,

    // NOC
    input [63:0] packetIn, // | data[63:32] | address[31:0] |
    input [2:0] instrIn,
    input [$clog2(NODE_COUNT) - 1:0] nodeStart,
    input validIn,
    output readyToReceive,

    output reg [63:0] packetOut, // | data[63:32] | address[31:0] |
    output reg [2:0] instrOut,
    output reg [$clog2(NODE_COUNT) - 1:0] nodeDest,
    output reg [PACKET_ID_WIDTH - 1:0] packetId,
    output reg validOut,
    input splitterReady
);

    reg [1:0] counter;

    reg [63:0] packetInReg; // | data[63:32] | address[31:0] |
    reg [2:0] instrInReg; // | data[63:32] | address[31:0] |
    reg busy;

    `ifdef SIM
        integer latency = 0;
        string filename;
        integer fd;

        initial begin
            $sformat(filename, "latency_log_%0d.csv", NODE_ID);
        end

    `endif

    integer localtimer;

    assign readyToReceive = (counter == 0) ? 1 : 0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            packetInReg <= 64'd0;
            instrInReg <= 3'd0;
            packetOut <= 64'd0;
            instrOut <= 3'd0;
            validOut <= 0;
            packetId <= 0;
            busy <= 0;
            instrSuccess <= 0;
            localtimer <= 0;
        end
        else begin

            validOut <= 0;
            instrSuccess <= 0;
            we <= 0;

            if (instrSuccess) begin
                busy <= 0;
                `ifdef SIM
                    fd = $fopen(filename, "a");
                    $fwrite(fd, "%0d, %0d\n", $time, latency);
                    $fclose(fd);
                `endif
            end

            if (counter == 0) begin
                if (validIn) begin
                    counter <= counter + 1;
                    packetInReg <= packetIn;
                    instrInReg <= instrIn;
                end
                if (splitterReady) begin
                    if (memInstr != `AGU_IDLE) begin
                        nodeDest <= memAddress / RAM_CHUNK_SIZE;
                        packetOut <= {memData, memAddress % RAM_CHUNK_SIZE};
                        instrOut <= memInstr;
                        if (~busy) begin
                            packetId <= packetId + 1;
                            validOut <= 1;
                            busy <= 1;
                            localtimer <= 0;
                  
                            `ifdef SIM
                                latency <= 0;
                            `endif

                        end
                        else begin
                            if (localtimer < TTL) begin
                                `ifdef SIM
                                    latency <= latency + 1;
                                `endif
                                localtimer <= localtimer + 1;
                            end
                            else begin
                                localtimer <= 0;
                                validOut <= 1;
                            end
                        end
                    end
                end
                else begin
                    validOut <= validOut;
                end
            end
            else begin
                case (instrInReg)
                    `LOAD_REQUESTED: begin
                        if (splitterReady) begin
                            if (counter == 1) begin
                                counter <= counter + 1;
                                ramAddress <= packetInReg[31:0];
                            end
                            else if (counter == 2) begin
                                counter <= counter + 1;
                            end
                            else begin
                                counter <= 0;
                                nodeDest <= nodeStart;
                                packetOut <= {rdData, 32'hFFFFFFFF};
                                instrOut <= `LOAD_SATISFIED;
                                packetId <= packetId + 1;
                                validOut <= 1;
                                packetInReg <= 0;
                            end
                        end
                        else begin
                            validOut <= validOut;
                        end
                    end
                    `LOAD_SATISFIED: begin
                        counter <= 0;
                        dataToCpu <= packetInReg[63:32];
                        instrSuccess <= 1;
                        packetInReg <= 0;
                    end
                    `STORE_REQUESTED: begin
                        if (splitterReady) begin
                            counter <= 0;
                            nodeDest <= nodeStart;
                            packetOut <= {32'hFFFFFFFF, 32'hFFFFFFFF};
                            instrOut <= `STORE_SATISFIED;
                            packetId <= packetId + 1;
                            validOut <= 1;
                            packetInReg <= 0;

                            ramAddress <= packetInReg[31:0];
                            wrData <= packetInReg[63:32];
                            we <= 1;
                        end
                    end
                    `STORE_SATISFIED: begin
                        counter <= 0;
                        instrSuccess <= 1;
                        packetInReg <= 0;
                    end
                endcase
            end 
        end
    end
    
endmodule