module tb_cpu (
    input  logic        clk,
    input  logic        rst_n
);

    axi_if #(
        .DATA_WIDTH(8),
        .ID_R_WIDTH(5),
        .ID_W_WIDTH(5)
    ) m_axi();

    sr_cpu_axi cpu
    (
        .clk   (clk),  
        .rst_n (rst_n),

        .m_axi (m_axi)
    );

    axi_ram #(
        .DATA_WIDTH(8)
    ) ram (
        .clk   (clk),
        .rst_n (rst_n),
        .axi_s (m_axi)
    );
    
endmodule