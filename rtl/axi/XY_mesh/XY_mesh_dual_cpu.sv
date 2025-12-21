module XY_mesh_dual_cpu (
    input logic clk,
    input logic rst_n
);

    axi_if #(
        .DATA_WIDTH(8),
        .ID_R_WIDTH(5),
        .ID_W_WIDTH(5)
    ) m_axi[16](), s_axi[16]();

    sr_cpu_axi cpu[16]
    (
        .clk   ({16{clk}}),  
        .rst_n ({16{rst_n}}),

        .m_axi (m_axi)
    );

    axi_ram #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(12)
    ) ram[16] (
        .clk   ({16{clk}}),
        .rst_n ({16{rst_n}}),
        .axi_s (s_axi)
    );

    XY_mesh_dual mesh(
        .ACLK      (clk),
        .ARESETn   (rst_n),

        .s_axi_in  (m_axi),
        .m_axi_out (s_axi)
    );

endmodule