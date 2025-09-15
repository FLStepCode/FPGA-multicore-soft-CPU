module axi_ram 
#(
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter BYTE_WIDTH = 8
) (
	input clk, rst_n,
    axi_if.s axi_s
);

ram_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .BYTE_WIDTH(BYTE_WIDTH)
) ram_i ();

axi2ram #(
    .ID_W_WIDTH(ID_W_WIDTH),
    .ID_R_WIDTH(ID_R_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
    ) axi (
        .clk(clk), .rst_n(rst_n),
        .ram_ports(ram_i.m),
        .axi_s(axi_s)
    );

ram #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .BYTE_WIDTH(BYTE_WIDTH)
    ) coupled_ram (
        .clk_a(clk), .clk_b(clk),
        .ports(ram_i.s)
    );
  
endmodule : axi_ram