module sr_axi_adapter
(
    input   logic         clk,        // clock
    input   logic         rst_n,      // reset

    input   logic         mem_wr_i,
    input   logic [15:0]  mem_addr_i,
    input   logic         mem_req_valid_i,
    output  logic         mem_req_ready_o,
    input   logic         mem_resp_ready_i,
    output  logic         mem_resp_valid_o,
    input   logic [31:0]  mem_wdata_i,
    output  logic [31:0]  mem_rdata_o,

    axi_if.m m_axi
);

    logic [1:0] w_data_count;
    logic [1:0] r_data_count;
    logic aw_handshake_was;

    assign m_axi.AWVALID = mem_req_valid_i & mem_wr_i & !aw_handshake_was;
    assign m_axi.AWID    = (mem_addr_i >> 12) + 1;
    assign m_axi.AWADDR  = mem_addr_i;
    assign m_axi.AWLEN   = 'h3;
    assign m_axi.AWSIZE  = 'h0;
    assign m_axi.AWBURST = 'b01;

    assign m_axi.ARVALID = mem_req_valid_i & !mem_wr_i;
    assign m_axi.ARID    = (mem_addr_i >> 12) + 1;
    assign m_axi.ARADDR  = mem_addr_i;
    assign m_axi.ARLEN   = 'h3;
    assign m_axi.ARSIZE  = 'h0;
    assign m_axi.ARBURST = 'b01;

    assign m_axi.WVALID  = mem_req_valid_i & mem_wr_i;
    assign m_axi.WLAST   = (w_data_count == 3);
    assign m_axi.WDATA   = mem_wdata_i[w_data_count * 8 +: 8];
    assign m_axi.WSTRB   = '1;

    assign m_axi.RREADY  = '1;

    assign m_axi.BREADY  = !(m_axi.RVALID && m_axi.RREADY && m_axi.RLAST);

    assign mem_req_ready_o = mem_wr_i ? m_axi.WVALID & m_axi.WREADY & m_axi.WLAST : m_axi.ARREADY;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_data_count <= '0;
            aw_handshake_was <= '0;
        end
        else begin
            if (m_axi.AWVALID && m_axi.AWREADY) begin
                aw_handshake_was <= '1;
            end
            if (m_axi.WVALID & m_axi.WREADY & m_axi.WLAST) begin
                aw_handshake_was <= '0;
            end

            if (m_axi.WVALID && m_axi.WREADY) begin
                w_data_count <= w_data_count + 1;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_data_count <= '0;
            mem_resp_valid_o <= '0;
        end
        else begin
            if (m_axi.RVALID && m_axi.RREADY) begin
                mem_rdata_o[r_data_count * 8 +: 8] <= m_axi.RDATA;
                r_data_count <= r_data_count + 1;
            end

            if ((m_axi.RVALID && m_axi.RREADY && m_axi.RLAST) || (m_axi.BVALID && m_axi.BREADY))begin
                mem_resp_valid_o <= '1;
            end
            else begin
                mem_resp_valid_o <= '0;
            end
        end
    end


endmodule