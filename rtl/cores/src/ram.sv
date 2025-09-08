`ifdef SIM
    `define PATH ""
`else
    `define PATH "./modelsim/"
`endif

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
            ram[ramAddress] = wrData;
        rdData <= ram[ramAddress];
    end

    always @(posedge clk)
    begin
        peekData <= ram[peekAddress];
    end

    initial begin
        if (NODE_ID == 0) begin
            $readmemh({`PATH, "ram_image_0.hex"}, ram);
        end
        else if (NODE_ID == 1) begin
            $readmemh({`PATH, "ram_image_1.hex"}, ram);
        end
        else if (NODE_ID == 2) begin
            $readmemh({`PATH, "ram_image_2.hex"}, ram);
        end
        else if (NODE_ID == 3) begin
            $readmemh({`PATH, "ram_image_3.hex"}, ram);
        end
        else if (NODE_ID == 4) begin
            $readmemh({`PATH, "ram_image_4.hex"}, ram);
        end
        else if (NODE_ID == 5) begin
            $readmemh({`PATH, "ram_image_5.hex"}, ram);
        end
        else if (NODE_ID == 6) begin
            for (i = 0; i < RAM_SIZE; i = i + 1) begin
                ram[i] = 0;
            end
            `ifdef SIM
                #5000000;
                $writememh("output_image_chunk_0.hex", ram);
            `endif
        end
        else if (NODE_ID == 7) begin
            for (i = 0; i < RAM_SIZE; i = i + 1) begin
                ram[i] = 0;
            end
            `ifdef SIM
                #5000000;
                $writememh("output_image_chunk_1.hex", ram);
            `endif
        end
        else if (NODE_ID == 8) begin
            for (i = 0; i < RAM_SIZE; i = i + 1) begin
                ram[i] = 0;
            end
            `ifdef SIM
                #5000000;
                $writememh("output_image_chunk_2.hex", ram);
            `endif
        end
        else if (NODE_ID == 9) begin
            for (i = 0; i < RAM_SIZE; i = i + 1) begin
                ram[i] = 0;
            end
            `ifdef SIM
                #5000000;
                $writememh("output_image_chunk_3.hex", ram);
            `endif
        end
        else if (NODE_ID == 10) begin
            for (i = 0; i < RAM_SIZE; i = i + 1) begin
                ram[i] = 0;
            end
            `ifdef SIM
                #5000000;
                $writememh("output_image_chunk_4.hex", ram);
            `endif
        end
        else begin
            for (i = 0; i < RAM_SIZE; i = i + 1) begin
                ram[i] = 0;
            end
        end
    end

endmodule