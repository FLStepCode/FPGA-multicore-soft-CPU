`define TEST

module ram #( 
    parameter int RAM_SIZE = 1024, NODE_ID = 0
) (
    input clk, rst_n,
    input [31:0] ramAddress,
    input [31:0] wrData,
    input we,
    output reg [31:0] rdData,

    input [31:0] peekAddress,
    output reg [31:0] peekData
);
    
    integer i;
    reg [31:0] ram [0:1023];

    always @(posedge clk)
    begin
        if (we)
            ram[ramAddress] <= wrData;
        rdData <= ram[ramAddress];
    end

    always @(posedge clk)
    begin
        peekData <= ram[peekAddress];
    end

    initial begin
        if (NODE_ID == 0) begin
            $readmemh("image_chunk_1.hex", ram);
        end
        else if (NODE_ID == 1) begin
            $readmemh("image_chunk_2.hex", ram);
        end
        else if (NODE_ID == 2) begin
            ram[0] = 1;
            ram[1] = 1;
            ram[2] = 1;
            ram[3] = 1;
            ram[4] = 2;
            ram[5] = 1;
            ram[6] = 1;
            ram[7] = 1;
            ram[8] = 1;
        end
        else if (NODE_ID == 3) begin
            for (i = 0; i < RAM_SIZE; i = i + 1) begin
                ram[i] = 0;
            end
            `ifdef TEST
                #2000000;
                $writememh("D:/noc_with_cores/modelsim/output_image_chunk_1.hex", ram);
            `endif
        end
        else if (NODE_ID == 4) begin
            for (i = 0; i < RAM_SIZE; i = i + 1) begin
                ram[i] = 0;
            end
            `ifdef TEST
                #2000000;
                $writememh("D:/noc_with_cores/modelsim/output_image_chunk_2.hex", ram);
            `endif
        end
        else begin
            for (i = 0; i < RAM_SIZE; i = i + 1) begin
                ram[i] = 0;
            end
        end
    end

endmodule