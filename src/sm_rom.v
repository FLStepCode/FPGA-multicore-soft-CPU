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
        rom[1] = 32'h00530333;
        rom[2] = 32'h025303b3;
        rom[3] = 32'h000382b3;
        rom[4] = 32'h0071a023;
        rom[5] = 32'h0071a0a3;
        rom[6] = 32'h0001a283;
        rom[7] = 32'h0011a303;
        rom[8] = 32'h007383b3;

    end

endmodule
