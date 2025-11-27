module axi_master_loader #(
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 16,
    parameter ID_W_WIDTH   = 5,
    parameter ID_R_WIDTH   = 5,
    parameter FIFO_DEPTH   = 32,
    parameter LOADER_ID    = 0,

    parameter MAX_ID_WIDTH = (ID_W_WIDTH > ID_R_WIDTH) ? ID_W_WIDTH : ID_R_WIDTH
) (
    input  logic                    clk_i,
    input  logic                    arstn_i,

    input  logic [7:0]              req_depth_i,

    input  logic [MAX_ID_WIDTH-1:0] id_i,
    input  logic                    write_i,
    input  logic [7:0]              axlen_i,
    input  logic                    fifo_push_i,

    input  logic                    start_i,
    output logic                    idle_o,
    axi_if.m                        m_axi_o
);

    typedef enum logic[1:0] {
        IDLE,
        AX_HANDSHAKE,
        RESP_WAIT
    } states_t;

    logic [7:0] req_counter, req_counter_next;
    logic [7:0] trans_counter, trans_counter_next;
    logic [MAX_ID_WIDTH-1:0] id_rd;
    logic [7:0] axlen_rd;
    logic write_rd, fifo_valid_rd, fifo_ready_rd;
    logic [7:0] bresp_cnt, bresp_cnt_next, rresp_cnt, rresp_cnt_next;
    states_t state, state_next;

    logic ar_was, aw_was, w_was;
    logic ar_was_next, aw_was_next, w_was_next;


    assign m_axi_o.AWID    = id_rd;
    assign m_axi_o.AWADDR  = LOADER_ID << 2;
    assign m_axi_o.AWLEN   = axlen_rd;
    assign m_axi_o.AWSIZE  = $clog2(DATA_WIDTH/8);
    assign m_axi_o.AWBURST = 2'b01;

    assign m_axi_o.WDATA   = 'h30 + LOADER_ID;
    assign m_axi_o.WSTRB   = '1;

    assign m_axi_o.BREADY  = 1'b1;

    assign m_axi_o.ARID    = id_rd;
    assign m_axi_o.ARADDR  = LOADER_ID << 2;
    assign m_axi_o.ARLEN   = axlen_rd;
    assign m_axi_o.ARSIZE  = $clog2(DATA_WIDTH/8);
    assign m_axi_o.ARBURST = 2'b01;

    assign m_axi_o.RREADY = 1'b1;


    stream_fifo #(
        .DATA_WIDTH (MAX_ID_WIDTH + 1 + 8),
        .FIFO_LEN   (FIFO_DEPTH)
    ) u_stream_fifo (
        .ACLK    (clk_i),
        .ARESETn (arstn_i),

        .data_i  ({write_i, axlen_i, id_i}),
        .valid_i (fifo_push_i),
        .ready_o (), // NC

        .data_o  ({write_rd, axlen_rd, id_rd}),
        .valid_o (fifo_valid_rd),
        .ready_i (fifo_ready_rd)
    );

    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (!arstn_i) begin
            state <= IDLE;
            req_counter <= '0;
            trans_counter <= '0;
            bresp_cnt <= '0;
            rresp_cnt <= '0;
            aw_was <= '0;
            w_was <= '0;
        end
        else begin
            state <= state_next;
            req_counter <= req_counter_next;
            trans_counter <= trans_counter_next;
            bresp_cnt <= bresp_cnt_next;
            rresp_cnt <= rresp_cnt_next;
            aw_was <= aw_was_next;
            w_was <= w_was_next;
        end
    end

    always_comb begin
        state_next = state;
        
        case (state)
            IDLE: begin
                if (start_i && fifo_valid_rd) begin
                    state_next = AX_HANDSHAKE;
                end
                else begin
                    state_next = IDLE;
                end
            end
            AX_HANDSHAKE: begin
                if (fifo_ready_rd) begin
                    if (req_counter == 1) begin
                        state_next = RESP_WAIT;
                    end
                    else begin
                        state_next = AX_HANDSHAKE;
                    end
                end
                else begin
                    state_next = AX_HANDSHAKE;
                end
            end
            RESP_WAIT: begin
                if ((rresp_cnt == 0 && bresp_cnt == 1 && m_axi_o.BREADY && m_axi_o.BVALID) ||
                    (rresp_cnt == 1 && bresp_cnt == 0 && m_axi_o.RREADY && m_axi_o.RVALID && m_axi_o.RLAST) ||
                    (rresp_cnt == 1 && bresp_cnt == 1 && m_axi_o.RREADY && m_axi_o.RVALID && m_axi_o.RLAST && m_axi_o.BREADY && m_axi_o.BVALID)) begin
                    state_next = fifo_valid_rd ? AX_HANDSHAKE : IDLE;
                end
                else begin
                    state_next = RESP_WAIT;
                end
            end
        endcase
    end
    
    always_comb begin
        fifo_ready_rd = '0;
        req_counter_next = req_counter;
        trans_counter_next = trans_counter;
        bresp_cnt_next = bresp_cnt;
        rresp_cnt_next = rresp_cnt;
        aw_was_next = aw_was;
        w_was_next = w_was;
        
        m_axi_o.WVALID = '0;
        m_axi_o.WLAST = '0;
        m_axi_o.AWVALID = '0;
        m_axi_o.ARVALID = '0;

        fifo_ready_rd = '0;

        idle_o = '0;

        case (state)
            IDLE: begin
                req_counter_next = req_depth_i;
                idle_o = '1;
            end
            AX_HANDSHAKE: begin
                if (fifo_valid_rd) begin
                    if (write_rd) begin
                        m_axi_o.WVALID = (trans_counter <= axlen_rd);
                        m_axi_o.WLAST = (trans_counter == axlen_rd);
                        m_axi_o.AWVALID = !aw_was;

                        m_axi_o.ARVALID = '0;

                        aw_was_next = (aw_was | (m_axi_o.AWVALID & m_axi_o.AWREADY));
                        w_was_next  = (w_was | (m_axi_o.WVALID & m_axi_o.WREADY & m_axi_o.WLAST));

                        fifo_ready_rd = (w_was & aw_was_next) || (aw_was & w_was_next) || (aw_was_next & w_was_next);

                        aw_was_next = aw_was_next & ~fifo_ready_rd;
                        w_was_next  = w_was_next & ~fifo_ready_rd;

                        trans_counter_next = fifo_ready_rd ? '0 : (trans_counter + (m_axi_o.WVALID & m_axi_o.WREADY));
                    end
                    else begin
                        m_axi_o.WVALID = '0;
                        m_axi_o.WLAST = '0;
                        m_axi_o.AWVALID = '0;

                        m_axi_o.ARVALID = '1;

                        fifo_ready_rd = m_axi_o.ARVALID & m_axi_o.ARREADY;
                    end
                end
                else begin
                    m_axi_o.WVALID = '0;
                    m_axi_o.WLAST = '0;
                    m_axi_o.AWVALID = '0;

                    m_axi_o.ARVALID = '0;

                    fifo_ready_rd = '0;
                end

                bresp_cnt_next = bresp_cnt + (fifo_ready_rd & write_rd) - (m_axi_o.BVALID & m_axi_o.BREADY);
                rresp_cnt_next = rresp_cnt + (fifo_ready_rd & !write_rd) - (m_axi_o.RVALID & m_axi_o.RREADY & m_axi_o.RLAST);
                req_counter_next = req_counter - fifo_ready_rd;
            end
            RESP_WAIT: begin
                req_counter_next = req_depth_i;
                
                m_axi_o.WVALID = '0;
                m_axi_o.WLAST = '0;
                m_axi_o.AWVALID = '0;
                m_axi_o.ARVALID = '0;

                if (m_axi_o.BVALID && m_axi_o.BREADY) begin
                    bresp_cnt_next = bresp_cnt - 1;
                end

                if (m_axi_o.RVALID && m_axi_o.RREADY && m_axi_o.RLAST) begin
                    rresp_cnt_next = rresp_cnt - 1;
                end
            end
        endcase
    end
    
endmodule