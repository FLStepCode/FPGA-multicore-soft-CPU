module axi2axis_XY #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter MAX_ID_WIDTH = 4,
    parameter AXIS_CHANNEL_WIDTH = 40,

    parameter ROUTER_X = 0,
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X-1),
    parameter ROUTER_Y = 0,
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y-1),

    parameter Ax_FIFO_LEN = 4,
    parameter W_FIFO_LEN = 4
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_in,
    axi_if.m m_axi_out,

    axis_if.s s_axis_resp_in,
    axis_if.m m_axis_resp_out,

    axis_if.s s_axis_req_in,
    axis_if.m m_axis_req_out
);

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (8 + (MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH) * 2) - 1:0] RESERVED;
        logic [7:0] PACKET_COUNT;
        logic [MAX_ROUTERS_X_WIDTH-1:0] SOURCE_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] SOURCE_Y;
        logic [MAX_ROUTERS_X_WIDTH-1:0] DESTINATION_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] DESTINATION_Y;
    } routing_header;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [7:0] LEN;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } aw_subheader;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (ID_W_WIDTH) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
    } b_subheader;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (DATA_WIDTH) - 1:0] RESERVED;
        logic [DATA_WIDTH-1:0] DATA;
    } w_data;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [7:0] LEN;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } ar_subheader;

    typedef struct packed {
        logic [AXIS_CHANNEL_WIDTH - (ID_R_WIDTH + DATA_WIDTH) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [DATA_WIDTH-1:0] DATA;
    } r_data;

    // AW channel
    logic AWVALID_fifo;
    logic AWREADY_fifo;
    logic [ID_W_WIDTH-1:0] AWID_fifo;
    logic [ADDR_WIDTH-1:0] AWADDR_fifo;
    logic [7:0] AWLEN_fifo;
    logic [2:0] AWSIZE_fifo;
    logic [1:0] AWBURST_fifo;

    // W channel
    logic WVALID_fifo;
    logic WREADY_fifo;
    logic [DATA_WIDTH-1:0] WDATA_fifo;
    logic [(DATA_WIDTH/8)-1:0] WSTRB_fifo;
    logic WLAST_fifo;

    // AR channel 
    logic ARVALID_fifo;
    logic ARREADY_fifo;
    logic [ID_R_WIDTH-1:0] ARID_fifo;
    logic [ADDR_WIDTH-1:0] ARADDR_fifo;
    logic [7:0] ARLEN_fifo;
    logic [2:0] ARSIZE_fifo;
    logic [1:0] ARBURST_fifo;

    // response coordinate logic
    logic [8:0] RRESP_LEN, RRESP_LEN_next;
    logic [MAX_ROUTERS_X_WIDTH-1:0] ROUTING_SOURCE_X, ROUTING_SOURCE_X_next;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] ROUTING_SOURCE_Y, ROUTING_SOURCE_Y_next;
    logic [MAX_ROUTERS_X_WIDTH-1:0] RRESP_DESTINATION_X, RRESP_DESTINATION_X_next;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] RRESP_DESTINATION_Y, RRESP_DESTINATION_Y_next;
    logic [MAX_ROUTERS_X_WIDTH-1:0] BRESP_DESTINATION_X, BRESP_DESTINATION_X_next;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] BRESP_DESTINATION_Y, BRESP_DESTINATION_Y_next;

    stream_fifo #(
        .DATA_TYPE(logic [ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2 - 1:0]),
        .FIFO_LEN(Ax_FIFO_LEN)
    ) stream_fifo_aw (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({s_axi_in.AWID, s_axi_in.AWADDR, s_axi_in.AWLEN, s_axi_in.AWSIZE, s_axi_in.AWBURST}),
        .valid_i(s_axi_in.AWVALID),
        .ready_o(s_axi_in.AWREADY),

        .data_o({AWID_fifo, AWADDR_fifo, AWLEN_fifo, AWSIZE_fifo, AWBURST_fifo}),
        .valid_o(AWVALID_fifo),
        .ready_i(AWREADY_fifo)
    );

    stream_fifo #(
        .DATA_TYPE(logic [DATA_WIDTH + (DATA_WIDTH/8) + 1 - 1:0]),
        .FIFO_LEN(W_FIFO_LEN)
    ) stream_fifo_w (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({s_axi_in.WDATA, s_axi_in.WSTRB, s_axi_in.WLAST}),
        .valid_i(s_axi_in.WVALID),
        .ready_o(s_axi_in.WREADY),

        .data_o({WDATA_fifo, WSTRB_fifo, WLAST_fifo}),
        .valid_o(WVALID_fifo),
        .ready_i(WREADY_fifo)
    );

    stream_fifo #(
        .DATA_TYPE(logic [ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2 - 1:0]),
        .FIFO_LEN(Ax_FIFO_LEN)
    ) stream_fifo_ar (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({s_axi_in.ARID, s_axi_in.ARADDR, s_axi_in.ARLEN, s_axi_in.ARSIZE, s_axi_in.ARBURST}),
        .valid_i(s_axi_in.ARVALID),
        .ready_o(s_axi_in.ARREADY),

        .data_o({ARID_fifo, ARADDR_fifo, ARLEN_fifo, ARSIZE_fifo, ARBURST_fifo}),
        .valid_o(ARVALID_fifo),
        .ready_i(ARREADY_fifo)
    );
    
    
    logic [3:0] VALID_arbiter_i;

    packet_type AW;
    packet_type AR;
    packet_type B;
    packet_type R;

    logic [2:0] DATA_arbiter_i [4];
    logic [2:0] request_data_o, response_data_o;
    logic request_valid_o, response_valid_o;
    logic request_ready_i, response_ready_i;

    always_comb begin
        AW = AW_SUBHEADER;
        AR = AR_SUBHEADER;
        B = B_SUBHEADER;
        R = R_DATA;
    end

    stream_arbiter #(
        .DATA_WIDTH(3),
        .INPUT_NUM(2)
    ) u_stream_arbiter_req (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i('{AR, AW}),
        .valid_i('{AWVALID_fifo, ARVALID_fifo}),
        // .ready_o(READY_arbiter_o),

        .data_o(request_data_o),
        .valid_o(request_valid_o),
        .ready_i(request_ready_i)
    );

    stream_arbiter #(
        .DATA_WIDTH(3),
        .INPUT_NUM(2)
    ) u_stream_arbiter_resp (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i('{R, B}),
        .valid_i('{m_axi_out.BVALID, m_axi_out.RVALID}),
        // .ready_o(READY_arbiter_o),

        .data_o(response_data_o),
        .valid_o(response_valid_o),
        .ready_i(response_ready_i)
    );


    enum {GENERATE_HEADER, AW_SEND, AR_SEND, W_SEND, R_SEND, B_SEND} out_resp_state, out_resp_state_next, out_req_state, out_req_state_next;

    routing_header routing_header_req_out, routing_header_resp_out;
    aw_subheader aw_subheader_out;
    w_data w_data_out;
    b_subheader b_subheader_out;
    ar_subheader ar_subheader_out;
    r_data r_data_out;

    always_comb begin
        aw_subheader_out.RESERVED = '0;
        aw_subheader_out.ID = AWID_fifo;
        aw_subheader_out.ADDR = AWADDR_fifo;
        aw_subheader_out.LEN = AWLEN_fifo;
        aw_subheader_out.SIZE = AWSIZE_fifo;
        aw_subheader_out.BURST = AWBURST_fifo;

        w_data_out.RESERVED = '0;
        w_data_out.DATA = WDATA_fifo;

        b_subheader_out.RESERVED = '0;
        b_subheader_out.ID = m_axi_out.BID;

        ar_subheader_out.RESERVED = '0;
        ar_subheader_out.ID = ARID_fifo;
        ar_subheader_out.ADDR = ARADDR_fifo;
        ar_subheader_out.LEN = ARLEN_fifo;
        ar_subheader_out.SIZE = ARSIZE_fifo;
        ar_subheader_out.BURST = ARBURST_fifo;

        r_data_out.RESERVED = '0;
        r_data_out.ID = m_axi_out.RID;
        r_data_out.DATA = m_axi_out.RDATA;
    end


    // --- req fsm ---

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            out_req_state <= GENERATE_HEADER;
        end
        else begin
            out_req_state <= out_req_state_next;
        end
    end

    always_comb begin
        out_req_state_next = GENERATE_HEADER;

        case (out_req_state)
            GENERATE_HEADER: begin
                if (request_valid_o && m_axis_req_out.TREADY) begin
                    case (request_data_o)
                        AW_SUBHEADER: out_req_state_next = AW_SEND;
                        AR_SUBHEADER: out_req_state_next = AR_SEND;
                    endcase
                end
                else begin
                    out_req_state_next = GENERATE_HEADER;
                end
            end
            AW_SEND: begin
                if (m_axis_req_out.TVALID && m_axis_req_out.TREADY) begin
                    out_req_state_next = W_SEND;
                end
                else begin
                    out_req_state_next = AW_SEND;
                end
            end
            W_SEND: begin
                if (WREADY_fifo && WVALID_fifo && WLAST_fifo) begin
                    out_req_state_next = GENERATE_HEADER;
                end
                else begin
                    out_req_state_next = W_SEND;
                end
            end
            AR_SEND: begin
                if (ARREADY_fifo && ARVALID_fifo) begin
                    out_req_state_next = GENERATE_HEADER;
                end
                else begin
                    out_req_state_next = AR_SEND;
                end
            end
            default: begin
                out_req_state_next = GENERATE_HEADER;
            end
        endcase
    end

    always_comb begin
        case (out_req_state)
            GENERATE_HEADER: begin
                if (request_valid_o) begin
                    routing_header_req_out.RESERVED = '0;

                    if (request_data_o == AW_SUBHEADER) begin
                        routing_header_req_out.DESTINATION_X = (AWID_fifo - 1) % MAX_ROUTERS_X;
                        routing_header_req_out.DESTINATION_Y = (AWID_fifo - 1) / MAX_ROUTERS_X;
                        routing_header_req_out.PACKET_COUNT = AWLEN_fifo + 2;
                    end
                    else if (request_data_o == AR_SUBHEADER) begin
                        routing_header_req_out.DESTINATION_X = (ARID_fifo - 1) % MAX_ROUTERS_X;
                        routing_header_req_out.DESTINATION_Y = (ARID_fifo - 1) / MAX_ROUTERS_X;
                        routing_header_req_out.PACKET_COUNT = 1;
                    end
                    else begin
                        routing_header_req_out = '0;
                    end

                    routing_header_req_out.SOURCE_X = ROUTER_X;
                    routing_header_req_out.SOURCE_Y = ROUTER_Y;


                    WREADY_fifo = '0;
                    request_ready_i = '0;

                    m_axis_req_out.TID = ROUTING_HEADER;
                    m_axis_req_out.TVALID = '1;
                    m_axis_req_out.TDATA = routing_header_req_out;
                    m_axis_req_out.TSTRB = '1;
                    m_axis_req_out.TLAST = '0;
                    AWREADY_fifo = '0;
                    ARREADY_fifo = '0;
                end
                else begin
                    routing_header_req_out = '0;

                    WREADY_fifo = '0;
                    request_ready_i = '0;

                    m_axis_req_out.TID = '0;
                    m_axis_req_out.TVALID = '0;
                    m_axis_req_out.TDATA = '0;
                    m_axis_req_out.TSTRB = '1;
                    m_axis_req_out.TLAST = '0;
                    AWREADY_fifo = '0;
                    ARREADY_fifo = '0;
                end
            end
            AW_SEND: begin
                routing_header_req_out = '0;

                WREADY_fifo = '0;
                request_ready_i = '0;

                m_axis_req_out.TID = AW_SUBHEADER;
                m_axis_req_out.TVALID = '1;
                m_axis_req_out.TDATA = aw_subheader_out;
                m_axis_req_out.TSTRB = '1;
                m_axis_req_out.TLAST = '0;
                AWREADY_fifo = '0;
                ARREADY_fifo = '0;

            end
            W_SEND: begin
                routing_header_req_out = '0;
                
                WREADY_fifo = m_axis_req_out.TREADY;
                request_ready_i = m_axis_req_out.TREADY & WVALID_fifo & WLAST_fifo;

                m_axis_req_out.TID = W_DATA;
                m_axis_req_out.TVALID = WVALID_fifo;
                m_axis_req_out.TDATA = w_data_out;
                m_axis_req_out.TSTRB = WSTRB_fifo;
                m_axis_req_out.TLAST = WVALID_fifo & WLAST_fifo;
                AWREADY_fifo = m_axis_req_out.TREADY & WVALID_fifo & WLAST_fifo;
                ARREADY_fifo = '0;
            end
            AR_SEND: begin
                routing_header_req_out = '0;

                WREADY_fifo = '0;
                request_ready_i = ARVALID_fifo & m_axis_req_out.TREADY;

                m_axis_req_out.TID = AR_SUBHEADER;
                m_axis_req_out.TVALID = ARVALID_fifo;
                m_axis_req_out.TDATA = ar_subheader_out;
                m_axis_req_out.TSTRB = '1;
                m_axis_req_out.TLAST = 1;
                AWREADY_fifo = '0;
                ARREADY_fifo = m_axis_req_out.TREADY;
            end
            default: begin
                routing_header_req_out = '0;

                WREADY_fifo = '0;
                request_ready_i = '0;

                m_axis_req_out.TID = '0;
                m_axis_req_out.TVALID = '0;
                m_axis_req_out.TDATA = '0;
                m_axis_req_out.TSTRB = '1;
                m_axis_req_out.TLAST = '0;
                AWREADY_fifo = '0;
                ARREADY_fifo = '0;
            end
        endcase
    end


    // --- resp fsm ---
    
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            out_resp_state <= GENERATE_HEADER;
        end
        else begin
            out_resp_state <= out_resp_state_next;
        end
    end

    always_comb begin
        out_resp_state_next = GENERATE_HEADER;

        case (out_resp_state)
            GENERATE_HEADER: begin
                if (response_valid_o && m_axis_resp_out.TREADY) begin
                    case (response_data_o)
                        B_SUBHEADER: out_resp_state_next = B_SEND;
                        R_DATA: out_resp_state_next = R_SEND;
                    endcase
                end
                else begin
                    out_resp_state_next = GENERATE_HEADER;
                end
            end
            B_SEND: begin
                if (m_axi_out.BVALID && m_axi_out.BREADY) begin
                    out_resp_state_next = GENERATE_HEADER;
                end
                else begin
                    out_resp_state_next = B_SEND;
                end
            end
            R_SEND: begin
                if (m_axi_out.RVALID && m_axi_out.RREADY && m_axi_out.RLAST) begin
                    out_resp_state_next = GENERATE_HEADER;
                end
                else begin
                    out_resp_state_next = R_SEND;
                end
            end
            default: begin
                out_resp_state_next = GENERATE_HEADER;
            end
        endcase
    end

    always_comb begin
        case (out_resp_state)
            GENERATE_HEADER: begin
                if (response_valid_o) begin

                    routing_header_resp_out.RESERVED = '0;

                    if (response_data_o == B_SUBHEADER) begin
                        routing_header_resp_out.DESTINATION_X = BRESP_DESTINATION_X;
                        routing_header_resp_out.DESTINATION_Y = BRESP_DESTINATION_Y;
                        routing_header_resp_out.PACKET_COUNT = 1;
                    end
                    else if (response_data_o == R_DATA) begin
                        routing_header_resp_out.DESTINATION_X = RRESP_DESTINATION_X;
                        routing_header_resp_out.DESTINATION_Y = RRESP_DESTINATION_Y;
                        routing_header_resp_out.PACKET_COUNT = RRESP_LEN;
                    end
                    else begin
                        routing_header_resp_out = '0;
                    end
                    routing_header_resp_out.SOURCE_X = ROUTER_X;
                    routing_header_resp_out.SOURCE_Y = ROUTER_Y;

                    response_ready_i = '0;

                    m_axis_resp_out.TID = ROUTING_HEADER;
                    m_axis_resp_out.TVALID = '1;
                    m_axis_resp_out.TDATA = routing_header_resp_out;
                    m_axis_resp_out.TSTRB = '1;
                    m_axis_resp_out.TLAST = '0;
                    m_axi_out.RREADY = '0;
                    m_axi_out.BREADY = '0;
                end
                else begin
                    routing_header_resp_out = '0;

                    response_ready_i = '0;

                    m_axis_resp_out.TID = '0;
                    m_axis_resp_out.TVALID = '0;
                    m_axis_resp_out.TDATA = '0;
                    m_axis_resp_out.TSTRB = '1;
                    m_axis_resp_out.TLAST = '0;
                    m_axi_out.RREADY = '0;
                    m_axi_out.BREADY = '0;
                end
            end
            B_SEND: begin
                routing_header_resp_out = '0;

                response_ready_i = m_axis_resp_out.TREADY;

                m_axis_resp_out.TID = B_SUBHEADER;
                m_axis_resp_out.TVALID = m_axi_out.BVALID;
                m_axis_resp_out.TDATA = b_subheader_out;
                m_axis_resp_out.TSTRB = '1;
                m_axis_resp_out.TLAST = 1;
                m_axi_out.RREADY = '0;
                m_axi_out.BREADY = m_axis_resp_out.TREADY;
            end
            R_SEND: begin
                routing_header_resp_out = '0;

                response_ready_i = m_axis_resp_out.TREADY & m_axi_out.RVALID & m_axi_out.RLAST;

                m_axis_resp_out.TID = R_DATA;
                m_axis_resp_out.TVALID = m_axi_out.RVALID;
                m_axis_resp_out.TDATA = r_data_out;
                m_axis_resp_out.TSTRB = '1;
                m_axis_resp_out.TLAST = m_axi_out.RVALID & m_axi_out.RLAST;
                m_axi_out.BREADY = '0;
                m_axi_out.RREADY = m_axis_resp_out.TREADY;
            end
            default: begin
                routing_header_resp_out = '0;

                response_ready_i = '0;

                m_axis_resp_out.TID = '0;
                m_axis_resp_out.TVALID = '0;
                m_axis_resp_out.TDATA = '0;
                m_axis_resp_out.TSTRB = '1;
                m_axis_resp_out.TLAST = '0;
                m_axi_out.RREADY = '0;
                m_axi_out.BREADY = '0;
            end
        endcase
    end

    // --- axis in logic ---

    routing_header routing_header_req_in, routing_header_resp_in;
    aw_subheader aw_subheader_in;
    w_data w_data_in;
    b_subheader b_subheader_in;
    ar_subheader ar_subheader_in;
    r_data r_data_in;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RRESP_LEN <= 0;
            ROUTING_SOURCE_X <= 0;
            ROUTING_SOURCE_Y <= 0;
            RRESP_DESTINATION_X <= 0;
            RRESP_DESTINATION_Y <= 0;
            BRESP_DESTINATION_X <= 0;
            BRESP_DESTINATION_Y <= 0;
        end
        else begin
            RRESP_LEN <= RRESP_LEN_next;
            ROUTING_SOURCE_X <= ROUTING_SOURCE_X_next;
            ROUTING_SOURCE_Y <= ROUTING_SOURCE_Y_next;
            RRESP_DESTINATION_X <= RRESP_DESTINATION_X_next;
            RRESP_DESTINATION_Y <= RRESP_DESTINATION_Y_next;
            BRESP_DESTINATION_X <= BRESP_DESTINATION_X_next;
            BRESP_DESTINATION_Y <= BRESP_DESTINATION_Y_next;
        end
    end


    always_comb begin
        routing_header_req_in = s_axis_req_in.TDATA;
        routing_header_resp_in = s_axis_resp_in.TDATA;

        aw_subheader_in = s_axis_req_in.TDATA;
        w_data_in = s_axis_req_in.TDATA;
        b_subheader_in = s_axis_resp_in.TDATA;
        ar_subheader_in = s_axis_req_in.TDATA;
        r_data_in = s_axis_resp_in.TDATA;
    end

    always_comb begin
        if (s_axis_req_in.TVALID) begin
            case (s_axis_req_in.TID)
                ROUTING_HEADER: begin
                    RRESP_LEN_next = RRESP_LEN;

                    ROUTING_SOURCE_X_next = routing_header_req_in.SOURCE_X;
                    ROUTING_SOURCE_Y_next = routing_header_req_in.SOURCE_Y;

                    RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                    RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                    BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                    BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                    s_axis_req_in.TREADY = '1;

                    m_axi_out.AWVALID = '0;
                    m_axi_out.AWID = '0;
                    m_axi_out.AWADDR = '0;
                    m_axi_out.AWLEN = '0;
                    m_axi_out.AWSIZE = '0;
                    m_axi_out.AWBURST = '0;

                    m_axi_out.ARVALID = '0;
                    m_axi_out.ARID = '0;
                    m_axi_out.ARADDR = '0;
                    m_axi_out.ARLEN = '0;
                    m_axi_out.ARSIZE = '0;
                    m_axi_out.ARBURST = '0;

                    m_axi_out.WVALID = '0;
                    m_axi_out.WDATA = '0;
                    m_axi_out.WLAST = '0;
                    m_axi_out.WSTRB = '0;
                end
                AW_SUBHEADER: begin
                    RRESP_LEN_next = RRESP_LEN;

                    ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                    ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                    RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                    RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;

                    if (m_axi_out.AWREADY) begin
                        BRESP_DESTINATION_X_next = ROUTING_SOURCE_X;
                        BRESP_DESTINATION_Y_next = ROUTING_SOURCE_Y;
                    end
                    else begin
                        BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                        BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;
                    end

                    s_axis_req_in.TREADY = m_axi_out.AWREADY;

                    m_axi_out.AWVALID = s_axis_req_in.TVALID;
                    m_axi_out.AWID = aw_subheader_in.ID;
                    m_axi_out.AWADDR = aw_subheader_in.ADDR;
                    m_axi_out.AWLEN = aw_subheader_in.LEN;
                    m_axi_out.AWSIZE = aw_subheader_in.SIZE;
                    m_axi_out.AWBURST = aw_subheader_in.BURST;

                    m_axi_out.ARVALID = '0;
                    m_axi_out.ARID = '0;
                    m_axi_out.ARADDR = '0;
                    m_axi_out.ARLEN = '0;
                    m_axi_out.ARSIZE = '0;
                    m_axi_out.ARBURST = '0;

                    m_axi_out.WVALID = '0;
                    m_axi_out.WDATA = '0;
                    m_axi_out.WLAST = '0;
                    m_axi_out.WSTRB = '0;              
                end
                AR_SUBHEADER: begin
                    RRESP_LEN_next = ar_subheader_in.LEN + 1;

                    ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                    ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                    BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                    BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                    if (m_axi_out.ARREADY) begin
                        RRESP_DESTINATION_X_next = ROUTING_SOURCE_X;
                        RRESP_DESTINATION_Y_next = ROUTING_SOURCE_Y;
                    end
                    else begin
                        RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                        RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                    end

                    s_axis_req_in.TREADY = m_axi_out.ARREADY;

                    m_axi_out.AWVALID = '0;
                    m_axi_out.AWID = '0;
                    m_axi_out.AWADDR = '0;
                    m_axi_out.AWLEN = '0;
                    m_axi_out.AWSIZE = '0;
                    m_axi_out.AWBURST = '0;

                    m_axi_out.ARVALID = s_axis_req_in.TVALID;
                    m_axi_out.ARID = ar_subheader_in.ID;
                    m_axi_out.ARADDR = ar_subheader_in.ADDR;
                    m_axi_out.ARLEN = ar_subheader_in.LEN;
                    m_axi_out.ARSIZE = ar_subheader_in.SIZE;
                    m_axi_out.ARBURST = ar_subheader_in.BURST;

                    m_axi_out.WVALID = '0;
                    m_axi_out.WDATA = '0;
                    m_axi_out.WLAST = '0;
                    m_axi_out.WSTRB = '0;             
                end
                W_DATA: begin
                    RRESP_LEN_next = RRESP_LEN;

                    ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                    ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                    RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                    RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                    BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                    BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                    s_axis_req_in.TREADY = m_axi_out.WREADY;

                    m_axi_out.AWVALID = '0;
                    m_axi_out.AWID = '0;
                    m_axi_out.AWADDR = '0;
                    m_axi_out.AWLEN = '0;
                    m_axi_out.AWSIZE = '0;
                    m_axi_out.AWBURST = '0;

                    m_axi_out.ARVALID = '0;
                    m_axi_out.ARID = '0;
                    m_axi_out.ARADDR = '0;
                    m_axi_out.ARLEN = '0;
                    m_axi_out.ARSIZE = '0;
                    m_axi_out.ARBURST = '0;

                    m_axi_out.WVALID = s_axis_req_in.TVALID;
                    m_axi_out.WDATA = w_data_in.DATA;
                    m_axi_out.WSTRB = s_axis_req_in.TSTRB;
                    m_axi_out.WLAST = s_axis_req_in.TLAST;
                end
                default: begin
                    RRESP_LEN_next = RRESP_LEN;

                    ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                    ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                    RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                    RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                    BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                    BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                    s_axis_req_in.TREADY = '1;

                    m_axi_out.AWVALID = '0;
                    m_axi_out.AWID = '0;
                    m_axi_out.AWADDR = '0;
                    m_axi_out.AWLEN = '0;
                    m_axi_out.AWSIZE = '0;
                    m_axi_out.AWBURST = '0;

                    m_axi_out.ARVALID = '0;
                    m_axi_out.ARID = '0;
                    m_axi_out.ARADDR = '0;
                    m_axi_out.ARLEN = '0;
                    m_axi_out.ARSIZE = '0;
                    m_axi_out.ARBURST = '0;

                    m_axi_out.WVALID = '0;
                    m_axi_out.WDATA = '0;
                    m_axi_out.WLAST = '0;
                    m_axi_out.WSTRB = '0;
                end
            endcase
        end
        else begin
            RRESP_LEN_next = RRESP_LEN;

            ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
            ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

            RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
            RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
            BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
            BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

            s_axis_req_in.TREADY = '1;

            m_axi_out.AWVALID = '0;
            m_axi_out.AWID = '0;
            m_axi_out.AWADDR = '0;
            m_axi_out.AWLEN = '0;
            m_axi_out.AWSIZE = '0;
            m_axi_out.AWBURST = '0;

            m_axi_out.ARVALID = '0;
            m_axi_out.ARID = '0;
            m_axi_out.ARADDR = '0;
            m_axi_out.ARLEN = '0;
            m_axi_out.ARSIZE = '0;
            m_axi_out.ARBURST = '0;

            m_axi_out.WVALID = '0;
            m_axi_out.WDATA = '0;
            m_axi_out.WLAST = '0;
            m_axi_out.WSTRB = '0;
        end
    end

    always_comb begin
        if (s_axis_resp_in.TVALID) begin
            case (s_axis_resp_in.TID)
                ROUTING_HEADER: begin
                    s_axis_resp_in.TREADY = '1;
                    
                    s_axi_in.BVALID = '0;
                    s_axi_in.BID = '0;

                    s_axi_in.RVALID = '0;
                    s_axi_in.RID = '0;
                    s_axi_in.RDATA = '0;
                    s_axi_in.RLAST = '0;
                end
                B_SUBHEADER: begin
                    s_axis_resp_in.TREADY = s_axi_in.BREADY;

                    s_axi_in.BVALID = s_axis_resp_in.TVALID;
                    s_axi_in.BID = b_subheader_in.ID;

                    s_axi_in.RVALID = '0;
                    s_axi_in.RID = '0;
                    s_axi_in.RDATA = '0;
                    s_axi_in.RLAST = '0;
                end
                R_DATA: begin
                    s_axis_resp_in.TREADY = s_axi_in.RREADY;

                    s_axi_in.BVALID = '0;
                    s_axi_in.BID = '0;

                    s_axi_in.RVALID = s_axis_resp_in.TVALID;
                    s_axi_in.RID = r_data_in.ID;
                    s_axi_in.RDATA = r_data_in.DATA;
                    s_axi_in.RLAST = s_axis_resp_in.TLAST;                
                end
                default: begin
                    s_axis_resp_in.TREADY = '1;

                    s_axi_in.BVALID = '0;
                    s_axi_in.BID = '0;

                    s_axi_in.RVALID = '0;
                    s_axi_in.RID = '0;
                    s_axi_in.RDATA = '0;
                    s_axi_in.RLAST = '0;
                end
            endcase
        end
        else begin
            s_axis_resp_in.TREADY = '1;

            s_axi_in.BVALID = '0;
            s_axi_in.BID = '0;

            s_axi_in.RVALID = '0;
            s_axi_in.RID = '0;
            s_axi_in.RDATA = '0;
            s_axi_in.RLAST = '0;
        end
    end


endmodule