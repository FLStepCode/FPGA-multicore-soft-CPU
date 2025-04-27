/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

module sm_rom
#(
    parameter SIZE = 64
)
(
    input  [31:0] a,
    output [31:0] rd
);
    reg [31:0] rom [SIZE - 1:0];
    assign rd = rom [a];

    initial begin
        //$readmemh ("src/add_mul_testing.hex", rom);
        rom[0] = 32'h00500293;
        rom[1] = 32'h00528293;
        rom[2] = 32'h0e51afa3;
        rom[3] = 32'h0ff1a303;
        rom[4] = 32'hfe000ae3;

    end

endmodule
