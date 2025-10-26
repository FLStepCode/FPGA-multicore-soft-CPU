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

    axi_if.m s_axi
);

    logic [1:0] w_data_count;
    logic [1:0] r_data_count;
    logic aw_handshake_was;

    assign s_axi.AWVALID = mem_req_valid_i & mem_wr_i & !aw_handshake_was;
    assign s_axi.AWID    = mem_addr_i >> $clog2(4096) + 9;
    assign s_axi.AWADDR  = mem_addr_i;
    assign s_axi.AWLEN   = 'h3;
    assign s_axi.AWSIZE  = 'h0;
    assign s_axi.AWBURST = 'b01;

    assign s_axi.ARVALID = mem_req_valid_i & !mem_wr_i;
    assign s_axi.ARID    = mem_addr_i >> $clog2(4096) + 9;
    assign s_axi.ARADDR  = mem_addr_i;
    assign s_axi.ARLEN   = 'h3;
    assign s_axi.ARSIZE  = 'h0;
    assign s_axi.ARBURST = 'b01;

    assign s_axi.WVALID  = mem_req_valid_i & mem_wr_i;
    assign s_axi.WLAST   = (w_data_count == 3);
    assign s_axi.WDATA   = mem_wdata_i[w_data_count * 8 +: 8];
    assign s_axi.WSTRB   = '1;

    assign s_axi.RREADY  = '1;

    assign s_axi.BREADY  = !(s_axi.RVALID && s_axi.RREADY && s_axi.RLAST);

    assign mem_req_ready_o = mem_wr_i ? s_axi.WVALID & s_axi.WREADY & s_axi.WLAST : s_axi.ARREADY;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_data_count <= '0;
            aw_handshake_was <= '0;
        end
        else begin
            if (s_axi.AWVALID && s_axi.AWREADY) begin
                aw_handshake_was <= '1;
            end
            if (s_axi.WVALID & s_axi.WREADY & s_axi.WLAST) begin
                aw_handshake_was <= '0;
            end

            if (s_axi.WVALID && s_axi.WREADY) begin
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
            if (s_axi.RVALID && s_axi.RREADY) begin
                mem_rdata_o[r_data_count * 8 +: 8] <= s_axi.RDATA;
                r_data_count <= r_data_count + 1;
            end

            if ((s_axi.RVALID && s_axi.RREADY && s_axi.RLAST) || (s_axi.BVALID && s_axi.BREADY))begin
                mem_resp_valid_o <= '1;
            end
            else begin
                mem_resp_valid_o <= '0;
            end
        end
    end


endmodule