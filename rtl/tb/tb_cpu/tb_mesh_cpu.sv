module tb_mesh_cpu;

logic clk;
logic rst_n;

XY_mesh_dual_cpu dut (clk, rst_n);

always #1 clk = !clk;

initial begin

    $readmemh("single_core.hex", dut.cpu[0].instr.rom);

    dut.cpu[1].instr.rom = '{default:'0};
    dut.cpu[2].instr.rom = '{default:'0};
    dut.cpu[3].instr.rom = '{default:'0};
    dut.cpu[4].instr.rom = '{default:'0};
    dut.cpu[5].instr.rom = '{default:'0};
    dut.cpu[6].instr.rom = '{default:'0};
    dut.cpu[7].instr.rom = '{default:'0};
    dut.cpu[8].instr.rom = '{default:'0};
    dut.cpu[9].instr.rom = '{default:'0};
    dut.cpu[10].instr.rom = '{default:'0};
    dut.cpu[11].instr.rom = '{default:'0};
    dut.cpu[12].instr.rom = '{default:'0};
    dut.cpu[13].instr.rom = '{default:'0};
    dut.cpu[14].instr.rom = '{default:'0};
    dut.cpu[15].instr.rom = '{default:'0};

    $readmemh("ram_image_0.hex", dut.ram[0].generate_rams[0].coupled_ram.ram);
    $readmemh("ram_image_1.hex", dut.ram[1].generate_rams[0].coupled_ram.ram);
    $readmemh("ram_image_2.hex", dut.ram[2].generate_rams[0].coupled_ram.ram);
    $readmemh("ram_image_3.hex", dut.ram[3].generate_rams[0].coupled_ram.ram);
    $readmemh("ram_image_4.hex", dut.ram[4].generate_rams[0].coupled_ram.ram);

    dut.ram[10].generate_rams[0].coupled_ram.ram  [0:3] = '{1, 0, 0, 0};
    dut.ram[10].generate_rams[0].coupled_ram.ram  [4:7] = '{1, 0, 0, 0};
    dut.ram[10].generate_rams[0].coupled_ram.ram [8:11] = '{1, 0, 0, 0};
    dut.ram[10].generate_rams[0].coupled_ram.ram[12:15] = '{1, 0, 0, 0};
    dut.ram[10].generate_rams[0].coupled_ram.ram[16:19] = '{2, 0, 0, 0};
    dut.ram[10].generate_rams[0].coupled_ram.ram[20:23] = '{1, 0, 0, 0};
    dut.ram[10].generate_rams[0].coupled_ram.ram[24:27] = '{1, 0, 0, 0};
    dut.ram[10].generate_rams[0].coupled_ram.ram[28:31] = '{1, 0, 0, 0};
    dut.ram[10].generate_rams[0].coupled_ram.ram[32:35] = '{1, 0, 0, 0};

    clk = 1;
    rst_n = 0;
    #25;
    rst_n = 1;

    for (int i = 0; i < 100; i++) begin
        $display("Progress: %d/100", i);
        for (int j = 0; j < 40000; j++) begin
            @(posedge clk);
        end
    end

    $writememh("mem_dump_0.hex",   dut.ram[0].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_1.hex",   dut.ram[1].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_2.hex",   dut.ram[2].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_3.hex",   dut.ram[3].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_4.hex",   dut.ram[4].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_5.hex",   dut.ram[5].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_6.hex",   dut.ram[6].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_7.hex",   dut.ram[7].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_8.hex",   dut.ram[8].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_9.hex",   dut.ram[9].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_10.hex", dut.ram[10].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_11.hex", dut.ram[11].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_12.hex", dut.ram[12].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_13.hex", dut.ram[13].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_14.hex", dut.ram[14].generate_rams[0].coupled_ram.ram);
    $writememh("mem_dump_15.hex", dut.ram[15].generate_rams[0].coupled_ram.ram);
    $finish;
end
    
endmodule