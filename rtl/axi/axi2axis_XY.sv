module axi2axis_XY #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter MAX_ID_WIDTH = 4,

    parameter ROUTER_X = 0,
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter ROUTER_Y = 0,
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),

    parameter Ax_FIFO_LEN = 4,
    parameter W_FIFO_LEN = 4
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_in,
    axi_if.m m_axi_out,

    axis_if.s s_axis_in,
    axis_if.m m_axis_out
);

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + 8 + (MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH) * 2) - 1:0] RESERVED;
        logic [7:0] PACKET_COUNT;
        logic [MAX_ROUTERS_X_WIDTH-1:0] SOURCE_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] SOURCE_Y;
        logic [MAX_ROUTERS_X_WIDTH-1:0] DESTINATION_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] DESTINATION_Y;
    } routing_header;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [7:0] LEN;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } aw_subheader;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + ID_W_WIDTH) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
    } b_subheader;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + 32) - 1:0] RESERVED;
        logic [31:0] DATA;
    } w_data;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [7:0] LEN;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } ar_subheader;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + ID_R_WIDTH + 32) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [31:0] DATA;
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
    logic [2:0] DATA_arbiter_o;
    logic VALID_arbiter_o;
    logic READY_arbiter_i;

    always_comb begin
        AW = AW_SUBHEADER;
        AR = AR_SUBHEADER;
        B = B_SUBHEADER;
        R = R_DATA;

        DATA_arbiter_i = '{AR, AW, B, R};
        VALID_arbiter_i = {m_axi_out.RVALID, m_axi_out.BVALID, AWVALID_fifo, ARVALID_fifo};
    end

    stream_arbiter #(
        .DATA_WIDTH(3),
        .INPUT_NUM(4)
    ) stream_arbiter (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i(DATA_arbiter_i),
        .valid_i(VALID_arbiter_i),
        // .ready_o(READY_arbiter_o),

        .data_o(DATA_arbiter_o),
        .valid_o(VALID_arbiter_o),
        .ready_i(READY_arbiter_i)
    );


    // --- axis in fsm ---

    enum {GENERATE_HEADER, AW_SEND, AR_SEND, W_SEND, R_SEND, B_SEND} out_state, out_state_next;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            out_state <= GENERATE_HEADER;
        end
        else begin
            out_state <= out_state_next;
        end
    end

    always_comb begin
        out_state_next = GENERATE_HEADER;

        case (out_state)
            GENERATE_HEADER: begin
                if (VALID_arbiter_o && m_axis_out.TREADY) begin
                    case (DATA_arbiter_o)
                        AW_SUBHEADER: out_state_next = AW_SEND;
                        AR_SUBHEADER: out_state_next = AR_SEND;
                        R_DATA: out_state_next = R_SEND;
                        B_SUBHEADER: out_state_next = B_SEND;
                    endcase
                end
                else begin
                    out_state_next = GENERATE_HEADER;
                end
            end
            AW_SEND: begin
                if (m_axis_out.TREADY) begin
                    out_state_next = W_SEND;
                end
                else begin
                    out_state_next = AW_SEND;
                end
            end
            W_SEND: begin
                if (READY_arbiter_i) begin
                    out_state_next = GENERATE_HEADER;
                end
                else begin
                    out_state_next = W_SEND;
                end
            end
            AR_SEND: begin
                if (READY_arbiter_i) begin
                    out_state_next = GENERATE_HEADER;
                end
                else begin
                    out_state_next = AR_SEND;
                end
            end
            B_SEND: begin
                if (READY_arbiter_i) begin
                    out_state_next = GENERATE_HEADER;
                end
                else begin
                    out_state_next = B_SEND;
                end
            end
            R_SEND: begin
                if (READY_arbiter_i) begin
                    out_state_next = GENERATE_HEADER;
                end
                else begin
                    out_state_next = R_SEND;
                end
            end
        endcase
    end

    routing_header routing_header_out;
    aw_subheader aw_subheader_out;
    w_data w_data_out;
    b_subheader b_subheader_out;
    ar_subheader ar_subheader_out;
    r_data r_data_out;

    always_comb begin
        aw_subheader_out.PACKET_TYPE = AW_SUBHEADER;
        aw_subheader_out.RESERVED = '0;
        aw_subheader_out.ID = AWID_fifo;
        aw_subheader_out.ADDR = AWADDR_fifo;
        aw_subheader_out.LEN = AWLEN_fifo;
        aw_subheader_out.SIZE = AWSIZE_fifo;
        aw_subheader_out.BURST = AWBURST_fifo;

        w_data_out.PACKET_TYPE = W_DATA;
        w_data_out.RESERVED = '0;
        w_data_out.DATA = WDATA_fifo;

        b_subheader_out.PACKET_TYPE = B_SUBHEADER;
        b_subheader_out.RESERVED = '0;
        b_subheader_out.ID = m_axi_out.BID;

        ar_subheader_out.PACKET_TYPE = AR_SUBHEADER;
        ar_subheader_out.RESERVED = '0;
        ar_subheader_out.ID = ARID_fifo;
        ar_subheader_out.ADDR = ARADDR_fifo;
        ar_subheader_out.LEN = ARLEN_fifo;
        ar_subheader_out.SIZE = ARSIZE_fifo;
        ar_subheader_out.BURST = ARBURST_fifo;

        r_data_out.PACKET_TYPE = R_DATA;
        r_data_out.RESERVED = '0;
        r_data_out.ID = m_axi_out.RID;
        r_data_out.DATA = m_axi_out.RDATA;
    end

    always_comb begin
        case (out_state)
            GENERATE_HEADER: begin
                if (VALID_arbiter_o) begin
                    logic [MAX_ID_WIDTH-1:0] AXI_ID;

                    WREADY_fifo = '0;
                    READY_arbiter_i = '0;

                    m_axis_out.TSTRB = '1;
                    m_axis_out.TLAST = '0;
                    AWREADY_fifo = '0;
                    ARREADY_fifo = '0;
                    m_axi_out.RREADY = '0;
                    m_axi_out.BREADY = '0;
                    
                    AXI_ID = AWID_fifo;

                    routing_header_out.PACKET_TYPE = ROUTING_HEADER;
                    routing_header_out.RESERVED = '0;

                    if (DATA_arbiter_o == AW_SUBHEADER) begin
                        routing_header_out.DESTINATION_X = (AWID_fifo - 1) % MAX_ROUTERS_X;
                        routing_header_out.DESTINATION_Y = (AWID_fifo - 1) / MAX_ROUTERS_X;
                        routing_header_out.PACKET_COUNT = AWLEN_fifo + 2;
                    end
                    else if (DATA_arbiter_o == AR_SUBHEADER) begin
                        routing_header_out.DESTINATION_X = (ARID_fifo - 1) % MAX_ROUTERS_X;
                        routing_header_out.DESTINATION_Y = (ARID_fifo - 1) / MAX_ROUTERS_X;
                        routing_header_out.PACKET_COUNT = 1;
                    end
                    else if (DATA_arbiter_o == B_SUBHEADER) begin
                        routing_header_out.DESTINATION_X = BRESP_DESTINATION_X;
                        routing_header_out.DESTINATION_Y = BRESP_DESTINATION_Y;
                        routing_header_out.PACKET_COUNT = 1;
                    end
                    else if (DATA_arbiter_o == R_DATA) begin
                        routing_header_out.DESTINATION_X = RRESP_DESTINATION_X;
                        routing_header_out.DESTINATION_Y = RRESP_DESTINATION_Y;
                        routing_header_out.PACKET_COUNT = RRESP_LEN;
                    end

                    routing_header_out.SOURCE_X = ROUTER_X;
                    routing_header_out.SOURCE_Y = ROUTER_Y;

                    m_axis_out.TVALID = VALID_arbiter_o;
                    m_axis_out.TDATA = routing_header_out;
                end
                else begin
                    routing_header_out = '0;

                    WREADY_fifo = '0;
                    READY_arbiter_i = '0;

                    m_axis_out.TVALID = '0;
                    m_axis_out.TDATA = '0;
                    m_axis_out.TSTRB = '1;
                    m_axis_out.TLAST = '0;
                    AWREADY_fifo = '0;
                    ARREADY_fifo = '0;
                    m_axi_out.RREADY = '0;
                    m_axi_out.BREADY = '0;
                end
            end
            AW_SEND: begin
                routing_header_out = '0;

                WREADY_fifo = '0;
                READY_arbiter_i = '0;

                m_axis_out.TSTRB = '1;
                m_axis_out.TLAST = '0;
                AWREADY_fifo = '0;
                ARREADY_fifo = '0;
                m_axi_out.RREADY = '0;
                m_axi_out.BREADY = '0;

                m_axis_out.TVALID = '1;
                m_axis_out.TDATA = aw_subheader_out;
            end
            W_SEND: begin
                routing_header_out = '0;
                
                ARREADY_fifo = '0;
                m_axi_out.RREADY = '0;
                m_axi_out.BREADY = '0;

                m_axis_out.TVALID = WVALID_fifo;
                m_axis_out.TDATA = w_data_out;
                m_axis_out.TSTRB = WSTRB_fifo;
                m_axis_out.TLAST = WVALID_fifo & WLAST_fifo;

                WREADY_fifo = m_axis_out.TREADY;
                READY_arbiter_i = m_axis_out.TREADY & WVALID_fifo & WLAST_fifo;
                AWREADY_fifo = WVALID_fifo & WLAST_fifo;
            end
            AR_SEND: begin
                routing_header_out = '0;

                WREADY_fifo = '0;

                m_axis_out.TSTRB = '1;
                AWREADY_fifo = '0;
                m_axi_out.RREADY = '0;
                m_axi_out.BREADY = '0;

                m_axis_out.TVALID = ARVALID_fifo;
                m_axis_out.TDATA = ar_subheader_out;
                m_axis_out.TLAST = 1;

                READY_arbiter_i = ARVALID_fifo & m_axis_out.TREADY;
                ARREADY_fifo = m_axis_out.TREADY;
            end
            B_SEND: begin
                routing_header_out = '0;

                WREADY_fifo = '0;

                m_axis_out.TSTRB = '1;
                AWREADY_fifo = '0;
                ARREADY_fifo = '0;
                m_axi_out.RREADY = '0;

                m_axis_out.TVALID = m_axi_out.BVALID;
                m_axis_out.TDATA = b_subheader_out;
                m_axis_out.TLAST = 1;
                m_axi_out.BREADY = m_axis_out.TREADY;

                READY_arbiter_i = m_axis_out.TREADY;
            end
            R_SEND: begin
                routing_header_out = '0;

                WREADY_fifo = '0;

                m_axis_out.TSTRB = '1;
                AWREADY_fifo = '0;
                ARREADY_fifo = '0;
                m_axi_out.BREADY = '0;

                m_axis_out.TVALID = m_axi_out.RVALID;
                m_axis_out.TDATA = r_data_out;
                m_axis_out.TLAST = m_axi_out.RVALID & m_axi_out.RLAST;

                m_axi_out.RREADY = m_axis_out.TREADY;
                READY_arbiter_i = m_axis_out.TREADY & m_axi_out.RVALID & m_axi_out.RLAST;
            end
            default: begin
                routing_header_out = '0;

                WREADY_fifo = '0;
                READY_arbiter_i = '0;

                m_axis_out.TVALID = '0;
                m_axis_out.TDATA = '0;
                m_axis_out.TSTRB = '1;
                m_axis_out.TLAST = '0;
                AWREADY_fifo = '0;
                ARREADY_fifo = '0;
                m_axi_out.RREADY = '0;
                m_axi_out.BREADY = '0;
            end
        endcase
    end

    // assign m_axis_out.TREADY = '1;
    // --- axis out logic ---

    routing_header routing_header_in;
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
        routing_header_in = s_axis_in.TDATA;
        aw_subheader_in = s_axis_in.TDATA;
        w_data_in = s_axis_in.TDATA;
        b_subheader_in = s_axis_in.TDATA;
        ar_subheader_in = s_axis_in.TDATA;
        r_data_in = s_axis_in.TDATA;
    end

    always_comb begin
        case (s_axis_in.TDATA[39:37])
            ROUTING_HEADER: begin
                RRESP_LEN_next = RRESP_LEN;

                ROUTING_SOURCE_X_next = routing_header_in.SOURCE_X;
                ROUTING_SOURCE_Y_next = routing_header_in.SOURCE_Y;

                RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                s_axis_in.TREADY = '1;

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
                
                s_axi_in.BVALID = '0;
                s_axi_in.BID = '0;

                s_axi_in.RVALID = '0;
                s_axi_in.RID = '0;
                s_axi_in.RDATA = '0;
                s_axi_in.RLAST = '0;
            end
            AW_SUBHEADER: begin
                RRESP_LEN_next = RRESP_LEN;

                ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                BRESP_DESTINATION_X_next = ROUTING_SOURCE_X;
                BRESP_DESTINATION_Y_next = ROUTING_SOURCE_Y;

                s_axis_in.TREADY = m_axi_out.AWREADY;

                m_axi_out.AWVALID = s_axis_in.TVALID;
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
                
                s_axi_in.BVALID = '0;
                s_axi_in.BID = '0;

                s_axi_in.RVALID = '0;
                s_axi_in.RID = '0;
                s_axi_in.RDATA = '0;
                s_axi_in.RLAST = '0;                
            end
            AR_SUBHEADER: begin
                RRESP_LEN_next = ar_subheader_in.LEN + 1;

                ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                RRESP_DESTINATION_X_next = ROUTING_SOURCE_X;
                RRESP_DESTINATION_Y_next = ROUTING_SOURCE_Y;
                BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                s_axis_in.TREADY = m_axi_out.ARREADY;

                m_axi_out.AWVALID = '0;
                m_axi_out.AWID = '0;
                m_axi_out.AWADDR = '0;
                m_axi_out.AWLEN = '0;
                m_axi_out.AWSIZE = '0;
                m_axi_out.AWBURST = '0;

                m_axi_out.ARVALID = s_axis_in.TVALID;
                m_axi_out.ARID = ar_subheader_in.ID;
                m_axi_out.ARADDR = ar_subheader_in.ADDR;
                m_axi_out.ARLEN = ar_subheader_in.LEN;
                m_axi_out.ARSIZE = ar_subheader_in.SIZE;
                m_axi_out.ARBURST = ar_subheader_in.BURST;

                m_axi_out.WVALID = '0;
                m_axi_out.WDATA = '0;
                m_axi_out.WLAST = '0;
                m_axi_out.WSTRB = '0;
                
                s_axi_in.BVALID = '0;
                s_axi_in.BID = '0;

                s_axi_in.RVALID = '0;
                s_axi_in.RID = '0;
                s_axi_in.RDATA = '0;
                s_axi_in.RLAST = '0;                
            end
            W_DATA: begin
                RRESP_LEN_next = RRESP_LEN;

                ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                s_axis_in.TREADY = m_axi_out.WREADY;

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

                m_axi_out.WVALID = s_axis_in.TVALID;
                m_axi_out.WDATA = w_data_in.DATA;
                m_axi_out.WSTRB = s_axis_in.TSTRB;
                m_axi_out.WLAST = s_axis_in.TLAST;
                
                s_axi_in.BVALID = '0;
                s_axi_in.BID = '0;

                s_axi_in.RVALID = '0;
                s_axi_in.RID = '0;
                s_axi_in.RDATA = '0;
                s_axi_in.RLAST = '0;
                
            end
            B_SUBHEADER: begin
                RRESP_LEN_next = RRESP_LEN;

                ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                s_axis_in.TREADY = s_axi_in.BREADY;

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
                
                s_axi_in.BVALID = s_axis_in.TVALID;
                s_axi_in.BID = b_subheader_in.ID;

                s_axi_in.RVALID = '0;
                s_axi_in.RID = '0;
                s_axi_in.RDATA = '0;
                s_axi_in.RLAST = '0;
            end
            R_DATA: begin
                RRESP_LEN_next = RRESP_LEN;

                ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                s_axis_in.TREADY = s_axi_in.RREADY;

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
                
                s_axi_in.BVALID = '0;
                s_axi_in.BID = '0;

                s_axi_in.RVALID = s_axis_in.TVALID;
                s_axi_in.RID = r_data_in.ID;
                s_axi_in.RDATA = r_data_in.DATA;
                s_axi_in.RLAST = s_axis_in.TLAST;                
            end
            default: begin
                RRESP_LEN_next = RRESP_LEN;

                ROUTING_SOURCE_X_next = ROUTING_SOURCE_X;
                ROUTING_SOURCE_Y_next = ROUTING_SOURCE_Y;

                RRESP_DESTINATION_X_next = RRESP_DESTINATION_X;
                RRESP_DESTINATION_Y_next = RRESP_DESTINATION_Y;
                BRESP_DESTINATION_X_next = BRESP_DESTINATION_X;
                BRESP_DESTINATION_Y_next = BRESP_DESTINATION_Y;

                s_axis_in.TREADY = '1;

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
                
                s_axi_in.BVALID = '0;
                s_axi_in.BID = '0;

                s_axi_in.RVALID = '0;
                s_axi_in.RID = '0;
                s_axi_in.RDATA = '0;
                s_axi_in.RLAST = '0;
            end
        endcase
    end


endmodule