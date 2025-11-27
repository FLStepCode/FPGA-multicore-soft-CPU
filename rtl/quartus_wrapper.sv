module quartus_wrapper (
    input  logic        aclk,
    input  logic        aresetn,
    
    input  logic [3:0]  core_select,

    input  logic [4:0]  pmu_addr,
    output logic [63:0] pmu_data_o,

    input  logic [7:0]  req_depth_i,
    input  logic [5:0]  id_i,
    input  logic        write_i,
    input  logic [7:0]  axlen_i,
    input  logic        fifo_push_i,
    input  logic        start_i,
    output logic        idle_o
);

    logic [63:0] pmu_data_os[16];

    assign pmu_data_o = pmu_data_os[core_select];
    assign idle_o = idle[core_select];

    logic [5:0] id [16];
    logic       write [16];
    logic [7:0] axlen [16];
    logic       fifo_push [16];
    logic       idle [16];

    axi_if #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(8),
        .ID_W_WIDTH(5),
        .ID_R_WIDTH(5)
    ) axi[16](), axi_ram[16]();

    generate
        genvar i;
        for (i = 0; i < 16; i++) begin : map_wires
            
            always_comb begin
                id[i] = (core_select == i) ? id_i : '0;
                write[i] = (core_select == i) ? write_i : '0;
                axlen[i] = (core_select == i) ? axlen_i : '0;
                fifo_push[i] = (core_select == i) ? fifo_push_i : '0;
            end

            axi_pmu pmu (
                .aclk    (aclk),
                .aresetn (aresetn),
                .mon_axi (axi[i]),
                .addr_i  (pmu_addr),
                .data_o  (pmu_data_os[i])
            );

            axi_master_loader #(
                .DATA_WIDTH(8),
                .ADDR_WIDTH(8),
                .ID_W_WIDTH(5),
                .ID_R_WIDTH(5)
            ) loader (
                .clk_i       (aclk),
                .arstn_i     (aresetn),
                .req_depth_i (req_depth_i),
                .id_i        (id[i]),
                .write_i     (write[i]),
                .axlen_i     (axlen[i]),
                .fifo_push_i (fifo_push[i]),
                .start_i     (start_i),
                .idle_o      (idle[i]),
                .m_axi_o     (axi[i])
            );
        end
    endgenerate

    XY_mesh_dual_parallel #(
        .ADDR_WIDTH(8)
    ) dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_in(axi),
        .m_axi_out(axi_ram)
    );

    generate
        for (i = 0; i < 16; i++) begin : map_rams
            axi_ram #(
                .DATA_WIDTH(8),
                .ADDR_WIDTH(8),
                .ID_W_WIDTH(5),
                .ID_R_WIDTH(5)
            ) ram (
                .clk(aclk),
                .rst_n(aresetn),
                .axi_s(axi_ram[i])
            );
        end

    endgenerate
    
endmodule