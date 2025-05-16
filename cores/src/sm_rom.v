/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

// `define TEST
// `define SIM

`ifdef SIM
    `define PATH ""
`else
    `define PATH "./modelsim/"
`endif

module sm_rom
#(
    parameter SIZE = 128,
    NODE_ID = 0
) (
    input  [31:0] a,
    output [31:0] rd
);

    reg [31:0] rom [SIZE - 1:0];
    assign rd = rom [a];

    initial begin

        `ifdef TEST

            `ifdef SELF_WRITE

                if (NODE_ID == 1) begin
                    rom[0] = 32'h00500293;
                    rom[1] = 32'h005282b3;
                    rom[2] = 32'h5e51afa3;
                    rom[3] = 32'h5ff1a303;
                    rom[4] = 32'hfe000ae3;
                end
                else begin
                    rom[0] = 32'h00000063;
                end
            
            `elsif WRITE_TO_ANOTHER

                if (NODE_ID == 1) begin
                    rom[0] = 32'h00500293;
                    rom[1] = 32'h40018393;
                    rom[2] = 32'h5ff38393;
                    rom[3] = 32'h005282b3;
                    rom[4] = 32'h0053a023;
                    rom[5] = 32'h0003a303;
                    rom[6] = 32'hfe000ae3;
                end
                else begin
                    rom[0] = 32'h00000063;
                end
            
            `elsif CROSS_WRITE

                if (NODE_ID == 1) begin
                    rom[0] = 32'h00500293;
                    rom[1] = 32'h40018393;
                    rom[2] = 32'h5ff38393;
                    rom[3] = 32'h005282b3;
                    rom[4] = 32'h0053a023;
                    rom[5] = 32'h0003a303;
                    rom[6] = 32'hfe000ae3;
                end
                else if (NODE_ID == 2) begin
                    rom[0] = 32'h00500293;
                    rom[1] = 32'h20018393;
                    rom[2] = 32'h3ff38393;
                    rom[3] = 32'h005282b3;
                    rom[4] = 32'h0053a023;
                    rom[5] = 32'h0003a303;
                    rom[6] = 32'hfe000ae3;
                end
                else begin
                    rom[0] = 32'h00000063;
                end

            `elsif SIMULTANEOUS_READ

                if (NODE_ID != 1) begin
                    rom[0] = 32'h5ff1a303;
                    rom[1] = 32'hfe000ee3;
                end
                else begin
                    rom[0] = 32'h00500293;
                    rom[1] = 32'h5e51afa3;
                    rom[2] = 32'h00000063;
                end

            `endif
            
        `else
            if (NODE_ID == 0) begin
                $readmemh({`PATH, "instr_node_0.hex"}, rom);
            end
            else if (NODE_ID == 1) begin
                $readmemh({`PATH, "instr_node_1.hex"}, rom);
            end
            else if (NODE_ID == 2) begin
                $readmemh({`PATH, "instr_node_2.hex"}, rom);
            end
            else if (NODE_ID == 3) begin
                $readmemh({`PATH, "instr_node_3.hex"}, rom);
            end
            else if (NODE_ID == 4) begin
                $readmemh({`PATH, "instr_node_4.hex"}, rom);
            end
            else if (NODE_ID == 5) begin
                $readmemh({`PATH, "instr_node_5.hex"}, rom);
            end
            else if (NODE_ID == 6) begin
                $readmemh({`PATH, "instr_node_6.hex"}, rom);
            end
            else if (NODE_ID == 7) begin
                $readmemh({`PATH, "instr_node_7.hex"}, rom);
            end
            else if (NODE_ID == 8) begin
                $readmemh({`PATH, "instr_node_8.hex"}, rom);
            end

        `endif

    end
endmodule