/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

`include "cores/src/sr_cpu.vh"
`include "cores/src/sm_register.v"
`include "cores/src/sm_rom.v"

module sr_cpu #(
    parameter NODE_ID = 0
) (
    input           clk,        // clock
    input           rst_n,      // reset
    input   [ 4:0]  regAddr,    // debug access reg address
    output  [31:0]  regData,    // debug access reg data

    // connection to ram controller
    input[31:0] dataToCpu,
    input instrSuccess,
    output[31:0] dataFromCpu,
    output[31:0] ramAddress,
    output[2:0] aguInstructionOut
);

    wire    [31:0]  imAddr;
    wire    [31:0]  imData;
    sm_rom #(.NODE_ID(NODE_ID)) reset_rom(imAddr, imData);

    //control wires
    wire        aluZero;
    wire        pcSrc;
    wire        regWrite;
    wire        aluSrc;
    wire  [1:0] wdSrc;
    wire  [2:0] aluControl;
    wire  [2:0] aguControl;
    wire        cpuPause_n;

    //instruction decode wires
    wire [ 6:0] cmdOp;
    wire [ 4:0] rd;
    wire [ 2:0] cmdF3;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 6:0] cmdF7;
    wire [31:0] immI;
    wire [31:0] immB;
    wire [31:0] immU;
    wire [31:0] immS;

    //program counter
    wire [31:0] pc;
    wire [31:0] pcBranch = pc + immB;
    wire [31:0] pcPlus4  = pc + 4;
    wire [31:0] pcNext   = cpuPause_n ? (pcSrc ? pcBranch : pcPlus4) : pc;
    sm_register r_pc(clk, rst_n, pcNext, pc);

    //program memory access
    assign imAddr = pc >> 2;
    wire [31:0] instr = rst_n ? imData : 0;

    //data memory access

    //instruction decode
    sr_decode id (
        .instr      ( instr        ),
        .cmdOp      ( cmdOp        ),
        .rd         ( rd           ),
        .cmdF3      ( cmdF3        ),
        .rs1        ( rs1          ),
        .rs2        ( rs2          ),
        .cmdF7      ( cmdF7        ),
        .immI       ( immI         ),
        .immB       ( immB         ),
        .immU       ( immU         ), 
        .immS       ( immS         )
    );

    //register file
    wire [31:0] rd0;
    wire [31:0] rd1;
    wire [31:0] rd2;
    reg [31:0] wd3;

    sm_register_file rf (
        .clk        ( clk          ),
        .a0         ( regAddr      ),
        .a1         ( rs1          ),
        .a2         ( rs2          ),
        .a3         ( rd           ),
        .rd0        ( rd0          ),
        .rd1        ( rd1          ),
        .rd2        ( rd2          ),
        .wd3        ( wd3          ),
        .we3        ( regWrite     )
    );

    //debug register access
    assign regData = (regAddr != 0) ? rd0 : pc;

    //alu
    wire [31:0] srcB = aluSrc ? immI : rd2;
    wire [31:0] aluResult;

    sr_alu alu (
        .srcA       ( rd1          ),
        .srcB       ( srcB         ),
        .oper       ( aluControl   ),
        .zero       ( aluZero      ),
        .result     ( aluResult    ) 
    );

    sr_agu agu (
        .srcR1      ( rd1          ),
        .srcI       ( immI         ),
        .srcS       ( immS         ),
        .srcD       ( rd2          ),
        .oper       ( aguControl   ),
        .memData    ( dataFromCpu   ),
        .memAddress ( ramAddress ),
        .memInstr   ( aguInstructionOut ),
        .cpuPause_n  ( cpuPause_n ),
        .instrSuccess( instrSuccess )
    );

    always @(*) begin
        case (wdSrc)
            2'b00: wd3 = aluResult;
            2'b01: wd3 = immU;
            default: wd3 = dataToCpu;
        endcase
    end

    //control
    sr_control sm_control (
        .cmdOp      ( cmdOp        ),
        .cmdF3      ( cmdF3        ),
        .cmdF7      ( cmdF7        ),
        .aluZero    ( aluZero      ),
        .pcSrc      ( pcSrc        ),
        .regWrite   ( regWrite     ),
        .aluSrc     ( aluSrc       ),
        .wdSrc      ( wdSrc        ),
        .aluControl ( aluControl   ),
        .aguControl ( aguControl   ) 
    );



endmodule

module sr_decode
(
    input      [31:0] instr,
    output     [ 6:0] cmdOp,
    output     [ 4:0] rd,
    output     [ 2:0] cmdF3,
    output     [ 4:0] rs1,
    output     [ 4:0] rs2,
    output     [ 6:0] cmdF7,
    output reg [31:0] immI,
    output reg [31:0] immB,
    output reg [31:0] immU,
    output reg [31:0] immS 
);
    assign cmdOp = instr[ 6: 0];
    assign rd    = instr[11: 7];
    assign cmdF3 = instr[14:12];
    assign rs1   = instr[19:15];
    assign rs2   = instr[24:20];
    assign cmdF7 = instr[31:25];

    // I-immediate
    always @ (*) begin
        immI[10: 0] = instr[30:20];
        immI[31:11] = { 21 {instr[31]} };
    end

    // B-immediate
    always @ (*) begin
        immB[    0] = 1'b0;
        immB[ 4: 1] = instr[11:8];
        immB[10: 5] = instr[30:25];
        immB[   11] = instr[7];
        immB[31:12] = { 20 {instr[31]} };
    end

    // U-immediate
    always @ (*) begin
        immU[11: 0] = 12'b0;
        immU[31:12] = instr[31:12];
    end

    // S-immediate
    always @ (*) begin
        immS[31: 12] = { 20 {1'b0} };
        immS[11: 5] = instr[31:25];
        immS[4:0] = instr[11:7];
    end

endmodule

module sr_control
(
    input     [ 6:0] cmdOp,
    input     [ 2:0] cmdF3,
    input     [ 6:0] cmdF7,
    input            aluZero,
    output           pcSrc, 
    output reg       regWrite, 
    output reg       aluSrc,
    output reg [1:0] wdSrc,
    output reg [2:0] aluControl,
    output reg [2:0] aguControl
);
    reg          branch;
    reg          condZero;
    assign pcSrc = branch & (aluZero == condZero);

    always @ (*) begin
        branch      = 1'b0;
        condZero    = 1'b0;
        regWrite    = 1'b0;
        aluSrc      = 1'b0;
        wdSrc       = 2'b00;
        aluControl  = `ALU_IDLE;
        aguControl  = `AGU_IDLE;

        casez( {cmdF7, cmdF3, cmdOp} )
            { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  } : begin regWrite = 1'b1; aluControl = `ALU_ADD;  end
            { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   } : begin regWrite = 1'b1; aluControl = `ALU_OR;   end
            { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  } : begin regWrite = 1'b1; aluControl = `ALU_SRL;  end
            { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU } : begin regWrite = 1'b1; aluControl = `ALU_SLTU; end
            { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  } : begin regWrite = 1'b1; aluControl = `ALU_SUB;  end
            { `RVF7_MUL,  `RVF3_MUL,  `RVOP_MUL  } : begin regWrite = 1'b1; aluControl = `ALU_MUL;  end

            { `RVF7_ANY,  `RVF3_ADDI, `RVOP_ADDI } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD; end
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_LUI  } : begin regWrite = 1'b1; wdSrc  = 2'b01; end
            { `RVF7_ANY,  `RVF3_LW,   `RVOP_LW   } : begin regWrite = 1'b1; wdSrc  = 2'b10; aguControl = `AGU_LOAD; end
            { `RVF7_ANY,  `RVF3_SW,   `RVOP_SW   } : begin aguControl = `AGU_STORE; end

            { `RVF7_ANY,  `RVF3_BEQ,  `RVOP_BEQ  } : begin; branch = 1'b1; condZero = 1'b1; aluControl = `ALU_SUB; end
            { `RVF7_ANY,  `RVF3_BNE,  `RVOP_BNE  } : begin branch = 1'b1; aluControl = `ALU_SUB; end
            default: begin
            end
        endcase
    end
endmodule

module sr_alu
(
    input  [31:0] srcA,
    input  [31:0] srcB,
    input  [ 2:0] oper,
    output        zero,
    output reg [31:0] result
);
    always @ (*) begin
        case (oper)
            default   : result = srcA + srcB;
            `ALU_ADD  : result = srcA + srcB;
            `ALU_OR   : result = srcA | srcB;
            `ALU_SRL  : result = srcA >> srcB [4:0];
            `ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
            `ALU_SUB  : result = srcA - srcB;
            `ALU_MUL  : result = srcA * srcB;
        endcase
    end

    assign zero   = (result == 0);
endmodule

module sr_agu (
    input [31:0] srcR1,
    input [31:0] srcI,
    input [31:0] srcS,
    input [31:0] srcD,
    input [2:0] oper,
    output reg [31:0] memData,
    output reg [31:0] memAddress,
    output reg [2:0] memInstr,
    output reg cpuPause_n,
    input instrSuccess
);

    reg counter;

    integer i;

    always @(*) begin
        case (oper)
            default: begin
                memAddress = 32'hFFFFFFFF;
                memInstr = 0;
                memData = 32'hFFFFFFFF;
                cpuPause_n = 1;
            end
            `AGU_LOAD: begin
                memAddress = srcR1 + srcI;
                memInstr = oper;
                memData = 32'hFFFFFFFF;
                cpuPause_n = instrSuccess;
            end
            `AGU_STORE: begin
                memAddress = srcR1 + srcS;
                memInstr = oper;
                memData = srcD;
                cpuPause_n = instrSuccess;
            end
        endcase
    end

endmodule

module sm_register_file
(
    input         clk,
    input  [ 4:0] a0,
    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd0,
    output [31:0] rd1,
    output [31:0] rd2,
    input  [31:0] wd3,
    input         we3
);
    reg [31:0] rf [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
        begin
            rf[i] = 0;
        end
    end

    assign rd0 = (a0 != 0) ? rf [a0] : 32'b0;
    assign rd1 = (a1 != 0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf [a2] : 32'b0;

    always @ (posedge clk)
        if(we3) rf [a3] <= wd3;
endmodule
