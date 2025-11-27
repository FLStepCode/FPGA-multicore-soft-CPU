module router_dual_parallel #(
    parameter DATA_WIDTH = 32
    `ifdef TID_PRESENT
    ,
    parameter ID_WIDTH = 4
    `endif
    `ifdef TDEST_PRESENT
    ,
    parameter DEST_WIDTH = 4
    `endif
    `ifdef TUSER_PRESENT
    ,
    parameter USER_WIDTH = 4
    `endif
    ,
    parameter CHANNEL_NUMBER = 10,
    parameter CHANNEL_NUMBER_WIDTH
    = $clog2(CHANNEL_NUMBER),
    parameter BUFFER_LENGTH = 16,
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter MAX_PACKAGES = 4,
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0,
    parameter MAXIMUM_PACKAGES_NUMBER = 5,
    parameter MAXIMUM_PACKAGES_NUMBER_WIDTH
    = $clog2(MAXIMUM_PACKAGES_NUMBER - 1)
)(
    input clk, rst_n,
    axis_if.s in  [CHANNEL_NUMBER],
    axis_if.m out [CHANNEL_NUMBER]
);

    typedef struct packed {
        logic [DATA_WIDTH-1:0] TDATA;
        `ifdef TSTRB_PRESENT
        logic [(DATA_WIDTH/8)-1:0] TSTRB;
        `endif
        `ifdef TKEEP_PRESENT
        logic [(DATA_WIDTH/8)-1:0] TKEEP;
        `endif
        `ifdef TLAST_PRESENT
        logic TLAST;
        `endif
        `ifdef TID_PRESENT
        logic [ID_WIDTH-1:0] TID;
        `endif
        `ifdef TDEST_PRESENT
        logic [DEST_WIDTH-1:0] TDEST;
        `endif
        `ifdef TUSER_PRESENT
        logic [USER_WIDTH-1:0] TUSER;
        `endif
    } queue_datatype;

    axis_if #(
        .DATA_WIDTH(DATA_WIDTH)
        `ifdef TID_PRESENT
        ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
        ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
        ,
        .USER_WIDTH(USER_WIDTH)
        `endif
    ) 
    queue_out [CHANNEL_NUMBER](),
    arbiter_out_req(), arbiter_out_resp();
    
    logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant_req, current_grant_resp;
    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x_req, target_x_resp;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y_req, target_y_resp;

    axis_if #(
        .DATA_WIDTH(DATA_WIDTH)
        `ifdef TID_PRESENT
        ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
        ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
        ,
        .USER_WIDTH(USER_WIDTH)
        `endif
    ) 
    arb_req_axis [CHANNEL_NUMBER/2](), arb_resp_axis [CHANNEL_NUMBER/2](), alg_req_axis [CHANNEL_NUMBER/2](), alg_resp_axis [CHANNEL_NUMBER/2]();

    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER/2; i++) begin : interfaces_concat
            assign arb_req_axis[i].TVALID = queue_out[i*2].TVALID;
            assign queue_out[i*2].TREADY  = arb_req_axis[i].TREADY;
            assign arb_req_axis[i].TDATA  = queue_out[i*2].TDATA;
            assign arb_req_axis[i].TID    = queue_out[i*2].TID  ;
            assign arb_req_axis[i].TSTRB  = queue_out[i*2].TSTRB;
            assign arb_req_axis[i].TLAST  = queue_out[i*2].TLAST;

            
            assign arb_resp_axis[i].TVALID   = queue_out[i*2 + 1].TVALID;
            assign queue_out[i*2 + 1].TREADY = arb_resp_axis[i].TREADY;
            assign arb_resp_axis[i].TDATA    = queue_out[i*2 + 1].TDATA;
            assign arb_resp_axis[i].TID      = queue_out[i*2 + 1].TID  ;
            assign arb_resp_axis[i].TSTRB    = queue_out[i*2 + 1].TSTRB;
            assign arb_resp_axis[i].TLAST    = queue_out[i*2 + 1].TLAST;

            assign out[i*2].TVALID        = alg_req_axis[i].TVALID;
            assign alg_req_axis[i].TREADY = out[i*2].TREADY;
            assign out[i*2].TDATA         = alg_req_axis[i].TDATA;
            assign out[i*2].TID           = alg_req_axis[i].TID  ;
            assign out[i*2].TSTRB         = alg_req_axis[i].TSTRB;
            assign out[i*2].TLAST         = alg_req_axis[i].TLAST;

            assign out[i*2 + 1].TVALID     = alg_resp_axis[i].TVALID;
            assign alg_resp_axis[i].TREADY = out[i*2 + 1].TREADY;
            assign out[i*2 + 1].TDATA      = alg_resp_axis[i].TDATA;
            assign out[i*2 + 1].TID        = alg_resp_axis[i].TID  ;
            assign out[i*2 + 1].TSTRB      = alg_resp_axis[i].TSTRB;
            assign out[i*2 + 1].TLAST      = alg_resp_axis[i].TLAST;
        end
        
    endgenerate
    arbiter #(
        .DATA_WIDTH(DATA_WIDTH)
        `ifdef TID_PRESENT
        ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
        ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
        ,
        .USER_WIDTH(USER_WIDTH)
        `endif
        ,
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .MAXIMUM_PACKAGES_NUMBER(MAXIMUM_PACKAGES_NUMBER)
    ) arb_req (
        clk, rst_n,
        arb_req_axis,
        arbiter_out_req,
        current_grant_req,
        target_x_req,
        target_y_req
    );

    arbiter #(
        .DATA_WIDTH(DATA_WIDTH)
        `ifdef TID_PRESENT
        ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
        ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
        ,
        .USER_WIDTH(USER_WIDTH)
        `endif
        ,
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .MAXIMUM_PACKAGES_NUMBER(MAXIMUM_PACKAGES_NUMBER)
    ) arb_resp (
        clk, rst_n,
        arb_resp_axis,
        arbiter_out_resp,
        current_grant_resp,
        target_x_resp,
        target_y_resp
    );

    algorithm #(
        .DATA_WIDTH(DATA_WIDTH)
        `ifdef TID_PRESENT
        ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
        ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
        ,
        .USER_WIDTH(USER_WIDTH)
        `endif
        ,
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y)
    ) alg_req (
        clk, rst_n,
        arbiter_out_req,
        alg_req_axis,
        target_x_req,
        target_y_req
    );

    algorithm #(
        .DATA_WIDTH(DATA_WIDTH)
        `ifdef TID_PRESENT
        ,
        .ID_WIDTH(ID_WIDTH)
        `endif
        `ifdef TDEST_PRESENT
        ,
        .DEST_WIDTH(DEST_WIDTH)
        `endif
        `ifdef TUSER_PRESENT
        ,
        .USER_WIDTH(USER_WIDTH)
        `endif
        ,
        .CHANNEL_NUMBER(CHANNEL_NUMBER/2),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y)
    ) alg_resp (
        clk, rst_n,
        arbiter_out_resp,
        alg_resp_axis,
        target_x_resp,
        target_y_resp
    );

    generate
        for(i = 0; i < CHANNEL_NUMBER; i++) begin : axis_if_gen

            queue_datatype data_i, data_o;

            assign data_i.TDATA = in[i].TDATA;
            assign queue_out[i].TDATA = data_o.TDATA;
            
            `ifdef TSTRB_PRESENT
            assign data_i.TSTRB = in[i].TSTRB;
            assign queue_out[i].TSTRB = data_o.TSTRB;
            `endif
            `ifdef TKEEP_PRESENT
            assign data_i.TKEEP = in[i].TKEEP;
            assign queue_out[i].TKEEP = data_o.TKEEP;
            `endif
            `ifdef TLAST_PRESENT
            assign data_i.TLAST = in[i].TLAST;
            assign queue_out[i].TLAST = data_o.TLAST;
            `endif
            `ifdef TID_PRESENT
            assign data_i.TID = in[i].TID;
            assign queue_out[i].TID = data_o.TID;
            `endif
            `ifdef TDEST_PRESENT
            assign data_i.TDEST = in[i].TDEST;
            assign queue_out[i].TDEST = data_o.TDEST;
            `endif
            `ifdef TUSER_PRESENT
            assign data_i.TUSER = in[i].TUSER;
            assign queue_out[i].TUSER = data_o.TUSER;
            `endif

            stream_fifo #(
                .DATA_WIDTH($bits(data_i)),
                .FIFO_LEN(BUFFER_LENGTH)
            ) q (
                .ACLK(clk),
                .ARESETn(rst_n),
                
                .data_i(data_i),
                .valid_i(in[i].TVALID),
                .ready_o(in[i].TREADY),
                
                .data_o(data_o),
                .valid_o(queue_out[i].TVALID),
                .ready_i(queue_out[i].TREADY)
            );

        end
    endgenerate

    
endmodule
