module axi2axis_XY #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter MAX_ID_WIDTH = 4,

    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
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
        logic [40 - (PACKET_TYPE_WIDTH + 8 + MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH) - 1:0] RESERVED;
        logic [8:0] PACKET_COUNT;
        logic [MAX_ROUTERS_X_WIDTH-1:0] COORDINATE_X;
        logic [MAX_ROUTERS_Y_WIDTH-1:0] COORDINATE_Y;
    } routing_header;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + ID_W_WIDTH + ADDR_WIDTH + 3 + 2) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } aw_subheader;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + + ID_W_WIDTH) - 1:0] RESERVED;
        logic [ID_W_WIDTH-1:0] ID;
    } b_subheader;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + 31) - 1:0] RESERVED;
        logic [31:0] DATA;
    } w_data;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + ID_R_WIDTH + ADDR_WIDTH + 3 + 2) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [ADDR_WIDTH-1:0] ADDR;
        logic [2:0] SIZE;
        logic [1:0] BURST;
    } ar_subheader;

    typedef struct packed {
        packet_type PACKET_TYPE;
        logic [40 - (PACKET_TYPE_WIDTH + ID_R_WIDTH + 31) - 1:0] RESERVED;
        logic [ID_R_WIDTH-1:0] ID;
        logic [31:0] DATA;
    } r_data;

    // AW channel
    logic [ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2 - 1:0] data_o_aw;
    logic AWVALID_fifo;
    logic AWREADY_fifo;

    // W channel
    logic WVALID_fifo;
    logic WREADY_fifo;
    logic [DATA_WIDTH-1:0] WDATA_fifo;
    logic [(DATA_WIDTH/8)-1:0] WSTRB_fifo;
    logic WLAST_fifo;

    // AR channel 
    logic [ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2 - 1:0] data_o_ar;
    logic ARVALID_fifo;
    logic ARREADY_fifo;

    // arbiter output
    logic AxTYPE_arbiter;
    logic AxVALID_arbiter;
    logic AxREADY_arbiter;
    logic [ID_W_WIDTH-1:0] AxID_arbiter;
    logic [ADDR_WIDTH-1:0] AxADDR_arbiter;
    logic [7:0] AxLEN_arbiter;
    logic [2:0] AxSIZE_arbiter;
    logic [1:0] AxBURST_arbiter;


    stream_fifo #(
        .DATA_WIDTH(ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2),
        .FIFO_LEN(Ax_FIFO_LEN)
    ) stream_fifo_aw (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({s_axi_in.AWID, s_axi_in.AWADDR, s_axi_in.AWLEN, s_axi_in.AWSIZE, s_axi_in.AWBURST}),
        .valid_i(s_axi_in.AWVALID),
        .ready_o(s_axi_in.AWREADY),

        .data_o(data_o_aw),
        .valid_o(AWVALID_fifo),
        .ready_i(AWREADY_fifo)
    );

    stream_fifo #(
        .DATA_WIDTH(DATA_WIDTH + (DATA_WIDTH/8) + 1),
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
        .DATA_WIDTH(ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2),
        .FIFO_LEN(Ax_FIFO_LEN)
    ) stream_fifo_ar (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i({s_axi_in.ARID, s_axi_in.ARADDR, s_axi_in.ARLEN, s_axi_in.ARSIZE, s_axi_in.ARBURST}),
        .valid_i(s_axi_in.ARVALID),
        .ready_o(s_axi_in.ARREADY),

        .data_o(data_o_ar),
        .valid_o(ARVALID_fifo),
        .ready_i(ARREADY_fifo)
    );

    logic [1 + MAX_ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 - 1:0] data_i_arbiter [2];
    logic [1:0] valid_i_arbiter;
    logic [1:0] ready_o_arbiter;

    assign data_i_arbiter[0] = {1'b0, data_o_aw};
    assign valid_i_arbiter[0] = AWVALID_fifo;
    assign AWREADY_fifo = ready_o_arbiter[0];

    assign data_i_arbiter[1] = {1'b1, data_o_ar};
    assign valid_i_arbiter[1] = ARVALID_fifo;
    assign ARREADY_fifo = ready_o_arbiter[1];

    stream_arbiter #(
        .DATA_WIDTH(1 + MAX_ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2),
        .INPUT_NUM(2)
    ) stream_arbiter_ax (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .data_i(data_i_arbiter),
        .valid_i(valid_i_arbiter),
        .ready_o(ready_o_arbiter),

        .data_o({AxTYPE_arbiter, AxID_arbiter, AxADDR_arbiter, AxLEN_arbiter, AxSIZE_arbiter, AxBURST_arbiter}),
        .valid_o(AxVALID_arbiter),
        .ready_i(AxREADY_arbiter)
    );


    // --- axis in fsm ---

    enum {GENERATE_HEADER, AW_SEND, AR_SEND, W_SEND} out_state, out_state_next;
    integer packet_out_counter, packet_out_counter_next;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            out_state <= GENERATE_HEADER;
            packet_out_counter <= 0;
        end
        else begin
            out_state <= out_state_next;
            packet_out_counter <= packet_out_counter_next;
        end
    end

    always_comb begin
        out_state_next = GENERATE_HEADER;

        case (out_state)
            GENERATE_HEADER: begin
                if (AxVALID_arbiter && m_axis_out.TREADY) begin
                    if (AxTYPE_arbiter == 0) begin
                        out_state_next = AW_SEND;
                    end
                    else begin
                        out_state_next = AR_SEND;
                    end
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
                if (AxREADY_arbiter) begin
                    out_state_next = GENERATE_HEADER;
                end
                else begin
                    out_state_next = W_SEND;
                end
            end
            AR_SEND: begin
                if (AxREADY_arbiter) begin
                    out_state_next = GENERATE_HEADER;
                end
                else begin
                    out_state_next = AR_SEND;
                end
            end
        endcase
    end

    routing_header routing_header_out;
    aw_subheader aw_subheader_out;
    ar_subheader ar_subheader_out;
    w_data w_data_out;

    always_comb begin

        routing_header_out = '0;
        aw_subheader_out = '0;
        ar_subheader_out = '0;
        w_data_out = '0;

        AxREADY_arbiter = '0;
        m_axis_out.TVALID = '0;
        WREADY_fifo = '0;
        packet_out_counter_next = '0;

        case (out_state)
            GENERATE_HEADER: begin
                routing_header_out.PACKET_TYPE = ROUTING_HEADER;
                routing_header_out.RESERVED = '0;
                routing_header_out.COORDINATE_X = (AxID_arbiter - 1) % MAX_ROUTERS_X;
                routing_header_out.COORDINATE_Y = (AxID_arbiter - 1) / MAX_ROUTERS_X;

                if (AxTYPE_arbiter == 0) begin
                    routing_header_out.PACKET_COUNT = AxLEN_arbiter + 2;
                    packet_out_counter_next = AxLEN_arbiter + 2;
                end
                else begin
                    routing_header_out.PACKET_COUNT = 1;
                    packet_out_counter_next = 1;
                end

                m_axis_out.TVALID = AxVALID_arbiter;
                m_axis_out.TDATA = routing_header_out;
            end
            AW_SEND: begin
                aw_subheader_out.PACKET_TYPE = AW_SUBHEADER;
                aw_subheader_out.RESERVED = '0;
                aw_subheader_out.ID = AxID_arbiter;
                aw_subheader_out.ADDR = AxADDR_arbiter;
                aw_subheader_out.SIZE = AxSIZE_arbiter;
                aw_subheader_out.BURST = AxBURST_arbiter;

                packet_out_counter_next = packet_out_counter;

                m_axis_out.TVALID = 1;
                m_axis_out.TDATA = aw_subheader_out;

                if (m_axis_out.TREADY) begin
                    packet_out_counter_next = packet_out_counter - 1;
                end
            end
            W_SEND: begin
                w_data_out.PACKET_TYPE = W_DATA;
                w_data_out.RESERVED = '0;
                w_data_out.DATA = WDATA_fifo;
                
                m_axis_out.TDATA = w_data_out;

                WREADY_fifo = 1;

                if (WVALID_fifo) begin
                    m_axis_out.TVALID = 1;
                    packet_out_counter_next = packet_out_counter - 1;
                    if (WLAST_fifo) begin
                        AxREADY_arbiter = 1;
                    end
                end
                else begin
                    m_axis_out.TVALID = 0;
                    AxREADY_arbiter = 0;
                    packet_out_counter_next = packet_out_counter;
                end
                
            end
            AR_SEND: begin
                ar_subheader_out.PACKET_TYPE = AR_SUBHEADER;
                ar_subheader_out.RESERVED = '0;
                ar_subheader_out.ID = AxID_arbiter;
                ar_subheader_out.ADDR = AxADDR_arbiter;
                ar_subheader_out.SIZE = AxSIZE_arbiter;
                ar_subheader_out.BURST = AxBURST_arbiter;

                m_axis_out.TVALID = 1;
                m_axis_out.TDATA = ar_subheader_out;

                if (m_axis_out.TREADY) begin
                    packet_out_counter_next = packet_out_counter - 1;
                    AxREADY_arbiter = 1;
                end
                else begin
                    packet_out_counter_next = packet_out_counter;
                    AxREADY_arbiter = 0;
                end
            end
        endcase
    end

    
    // --- axis out fsm ---

    enum {RECEIVE_HEADER, SEND_AXI_RESPONSE} in_state, in_state_next;
    integer packet_in_counter, packet_in_counter_next;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            in_state <= RECEIVE_HEADER;
            packet_in_counter <= 0;
        end
        else begin
            in_state <= in_state_next;
            packet_in_counter <= packet_in_counter_next;
        end
    end

    always_comb begin
        in_state_next = RECEIVE_HEADER;

        case (in_state)
            RECEIVE_HEADER: begin
                if (s_axis_in.TVALID && s_axis_in.TREADY) begin
                    in_state_next = SEND_AXI_RESPONSE;
                end
                else begin
                    in_state_next = RECEIVE_HEADER;
                end
            end
            SEND_AXI_RESPONSE: begin
                if (s_axis_in.TVALID) begin
                    if (s_axis_in.TDATA[39:37] == B_SUBHEADER && s_axi_in.BREADY) begin
                        in_state_next = RECEIVE_HEADER;
                    end
                    else if (s_axis_in.TDATA[39:37] == R_DATA && s_axi_in.RREADY) begin
                        if (packet_in_counter_next == 0) begin
                            in_state_next = RECEIVE_HEADER;
                        end
                        else begin
                            in_state_next = SEND_AXI_RESPONSE;
                        end
                    end
                    else begin
                        in_state_next = SEND_AXI_RESPONSE;
                    end
                end
                else begin
                    in_state_next = SEND_AXI_RESPONSE;
                end
            end
        endcase
    end

    routing_header routing_header_in;
    b_subheader b_subheader_in;
    r_data r_data_in;

    always_comb begin

        routing_header_in = '0;
        b_subheader_in = '0;
        r_data_in = '0;

        s_axis_in.TREADY = '0;
        s_axi_in.BVALID = '0;
        s_axi_in.BID = '0;
        s_axi_in.RVALID = '0;
        s_axi_in.RID = '0;
        s_axi_in.RDATA = '0;
        packet_in_counter_next = packet_in_counter;
        
        case (in_state)
            RECEIVE_HEADER: begin
                routing_header_in = s_axis_in.TDATA;
                s_axis_in.TREADY = '1;

                if (s_axis_in.TVALID) begin
                    packet_in_counter_next = routing_header_in.PACKET_COUNT;
                end
                else begin
                    packet_in_counter_next = packet_in_counter;
                end
            end
            SEND_AXI_RESPONSE: begin
                if (s_axis_in.TDATA[39:37] == B_SUBHEADER && s_axis_in.TVALID) begin
                    b_subheader_in = s_axis_in.TDATA;
                    s_axi_in.BVALID = '1;

                    if (s_axi_in.BREADY) begin
                        s_axis_in.TREADY = '1;
                        packet_in_counter_next = '0;
                    end
                    else begin
                        s_axis_in.TREADY = '0;
                        packet_in_counter_next = packet_in_counter;
                    end
                end
                else if (s_axis_in.TDATA[39:37] == R_DATA && s_axis_in.TVALID) begin
                    r_data_in = s_axis_in.TDATA;
                    s_axi_in.RVALID = '1;
                    s_axi_in.RLAST = (packet_in_counter == 1);
                    s_axi_in.RID = r_data_in.ID;
                    s_axi_in.RDATA = r_data_in.DATA;

                    if (s_axi_in.RREADY) begin
                        s_axis_in.TREADY = '1;
                        packet_in_counter_next = packet_in_counter - 1;
                    end
                    else begin
                        s_axis_in.TREADY = '0;
                        packet_in_counter_next = packet_in_counter;
                    end
                end
                else begin
                    s_axis_in.TREADY = '0;
                    s_axi_in.BVALID = '0;
                    s_axi_in.BID = '0;
                    s_axi_in.RVALID = '0;
                    s_axi_in.RID = '0;
                    s_axi_in.RDATA = '0;
                    packet_in_counter_next = packet_in_counter;
                end
            end
        endcase
    end


endmodule