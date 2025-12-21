module XY_mesh_dual_parallel #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter ID_W_WIDTH = 5,
    parameter ID_R_WIDTH = 5,

    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y)
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_in[MAX_ROUTERS_X*MAX_ROUTERS_Y],
    axi_if.m m_axi_out[MAX_ROUTERS_X*MAX_ROUTERS_Y]
);

    localparam ROUTING_HEADER_EFFECTIVE = 8 + (MAX_ROUTERS_X_WIDTH + MAX_ROUTERS_Y_WIDTH) * 2;
    localparam ROUTING_HEADER_WIDTH = (ROUTING_HEADER_EFFECTIVE / 8 + ((ROUTING_HEADER_EFFECTIVE % 8) != 0)) * 8;

    localparam AW_SUBHEADER_EFFECTIVE = ID_W_WIDTH + ADDR_WIDTH + 8 + 3 + 2;
    localparam AW_SUBHEADER_WIDTH = (AW_SUBHEADER_EFFECTIVE / 8 + ((AW_SUBHEADER_EFFECTIVE % 8) != 0)) * 8;

    localparam B_SUBHEADER_EFFECTIVE = ID_W_WIDTH;
    localparam B_SUBHEADER_WIDTH = (B_SUBHEADER_EFFECTIVE / 8 + ((B_SUBHEADER_EFFECTIVE % 8) != 0)) * 8;

    localparam W_DATA_EFFECTIVE = DATA_WIDTH;
    localparam W_DATA_WIDTH = (W_DATA_EFFECTIVE / 8 + ((W_DATA_EFFECTIVE % 8) != 0)) * 8;

    localparam AR_SUBHEADER_EFFECTIVE = ID_R_WIDTH + ADDR_WIDTH + 8 + 3 + 2;
    localparam AR_SUBHEADER_WIDTH = (AR_SUBHEADER_EFFECTIVE / 8 + ((AR_SUBHEADER_EFFECTIVE % 8) != 0)) * 8;

    localparam R_DATA_EFFECTIVE = ID_R_WIDTH + DATA_WIDTH;
    localparam R_DATA_WIDTH = (R_DATA_EFFECTIVE / 8 + ((R_DATA_EFFECTIVE % 8) != 0)) * 8;

    localparam COMP_1 = (ROUTING_HEADER_WIDTH > AW_SUBHEADER_WIDTH) ? ROUTING_HEADER_WIDTH : AW_SUBHEADER_WIDTH;
    localparam COMP_2 = (B_SUBHEADER_WIDTH > W_DATA_WIDTH) ? B_SUBHEADER_WIDTH : W_DATA_WIDTH;
    localparam COMP_3 = (AR_SUBHEADER_WIDTH > R_DATA_WIDTH) ? AR_SUBHEADER_WIDTH : R_DATA_WIDTH;

    localparam COMP_4 = (COMP_1 > COMP_2) ? COMP_1 : COMP_2;
    localparam AXIS_CHANNEL_WIDTH = (COMP_3 > COMP_4) ? COMP_3 : COMP_4;

    typedef enum logic [3:0] {
        HOME_REQ,
        HOME_RESP,
        NORTH_REQ,
        NORTH_RESP,
        EAST_REQ,
        EAST_RESP,
        SOUTH_REQ,
        SOUTH_RESP,
        WEST_REQ,
        WEST_RESP
    } index;
    
    axis_if #(
        .DATA_WIDTH(AXIS_CHANNEL_WIDTH),
        .ID_WIDTH(3)
    ) router_if[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][10]();

    axis_if #(
        .DATA_WIDTH(AXIS_CHANNEL_WIDTH),
        .ID_WIDTH(3)
    ) from_home[MAX_ROUTERS_Y][MAX_ROUTERS_X][2]();

    axis_if #(
        .DATA_WIDTH(AXIS_CHANNEL_WIDTH),
        .ID_WIDTH(3)
    ) router_in[MAX_ROUTERS_Y][MAX_ROUTERS_X][10]();

    generate
        genvar i;
        genvar j;

        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : zeroing_Y
            assign router_if[i][0][WEST_REQ].TVALID = '0;
            assign router_if[i][0][WEST_RESP].TVALID = '0;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_REQ].TVALID = '0;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_RESP].TVALID = '0;

            assign router_if[i][0][WEST_REQ].TREADY = '1;
            assign router_if[i][0][WEST_RESP].TREADY = '1;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_REQ].TREADY = '1;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_RESP].TREADY = '1;
        end

        for (i = 0; i < MAX_ROUTERS_X; i++) begin : zeroing_X
            assign router_if[0][i][NORTH_REQ].TVALID = '0;
            assign router_if[0][i][NORTH_RESP].TVALID = '0;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH_REQ].TVALID = '0;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH_RESP].TVALID = '0;

            assign router_if[0][i][NORTH_REQ].TREADY = '1;
            assign router_if[0][i][NORTH_RESP].TREADY = '1;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH_REQ].TREADY = '1;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH_RESP].TREADY = '1;
        end
    endgenerate

    generate
        for (i = 0; i < MAX_ROUTERS_Y; i++) begin : Y
            for (j = 0; j < MAX_ROUTERS_X; j++) begin : X
                
                axi2axis_XY #(
                    .ADDR_WIDTH(ADDR_WIDTH),
                    .DATA_WIDTH(DATA_WIDTH),
                    .ID_W_WIDTH(ID_W_WIDTH),
                    .ID_R_WIDTH(ID_R_WIDTH),
                    .AXIS_CHANNEL_WIDTH(AXIS_CHANNEL_WIDTH),

                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y)
                ) bridge (
                    .ACLK(ACLK),
                    .ARESETn(ARESETn),

                    .s_axi_in(s_axi_in[i * MAX_ROUTERS_X + j]),
                    .s_axis_req_in(router_if[i+1][j+1][HOME_REQ]),
                    .s_axis_resp_in(router_if[i+1][j+1][HOME_RESP]),

                    .m_axi_out(m_axi_out[i * MAX_ROUTERS_X + j]),
                    .m_axis_req_out(from_home[i][j][HOME_REQ]),
                    .m_axis_resp_out(from_home[i][j][HOME_RESP])
                );


                assign router_in[i][j][0].TVALID =                  from_home[i][j][HOME_REQ].TVALID;
                assign from_home[i][j][HOME_REQ].TREADY = router_in[i][j][0].TREADY;
                assign router_in[i][j][0].TDATA =                   from_home[i][j][HOME_REQ].TDATA;
                assign router_in[i][j][0].TID =                     from_home[i][j][HOME_REQ].TID;
                assign router_in[i][j][0].TSTRB =                   from_home[i][j][HOME_REQ].TSTRB;
                assign router_in[i][j][0].TLAST =                   from_home[i][j][HOME_REQ].TLAST;

                assign router_in[i][j][1].TVALID =                  from_home[i][j][HOME_RESP].TVALID;
                assign from_home[i][j][HOME_RESP].TREADY = router_in[i][j][1].TREADY;
                assign router_in[i][j][1].TDATA =                   from_home[i][j][HOME_RESP].TDATA;
                assign router_in[i][j][1].TID =                     from_home[i][j][HOME_RESP].TID;
                assign router_in[i][j][1].TSTRB =                   from_home[i][j][HOME_RESP].TSTRB;
                assign router_in[i][j][1].TLAST =                   from_home[i][j][HOME_RESP].TLAST;

                assign router_in[i][j][2].TVALID =                  router_if[i][j+1][SOUTH_REQ].TVALID;
                assign router_if[i][j+1][SOUTH_REQ].TREADY = router_in[i][j][2].TREADY;
                assign router_in[i][j][2].TDATA =                   router_if[i][j+1][SOUTH_REQ].TDATA;
                assign router_in[i][j][2].TID =                     router_if[i][j+1][SOUTH_REQ].TID;
                assign router_in[i][j][2].TSTRB =                   router_if[i][j+1][SOUTH_REQ].TSTRB;
                assign router_in[i][j][2].TLAST =                   router_if[i][j+1][SOUTH_REQ].TLAST;

                assign router_in[i][j][3].TVALID =                  router_if[i][j+1][SOUTH_RESP].TVALID;
                assign router_if[i][j+1][SOUTH_RESP].TREADY = router_in[i][j][3].TREADY;
                assign router_in[i][j][3].TDATA =                   router_if[i][j+1][SOUTH_RESP].TDATA;
                assign router_in[i][j][3].TID =                     router_if[i][j+1][SOUTH_RESP].TID;
                assign router_in[i][j][3].TSTRB =                   router_if[i][j+1][SOUTH_RESP].TSTRB;
                assign router_in[i][j][3].TLAST =                   router_if[i][j+1][SOUTH_RESP].TLAST;

                assign router_in[i][j][4].TVALID =                  router_if[i+1][j+2][WEST_REQ].TVALID;
                assign router_if[i+1][j+2][WEST_REQ].TREADY = router_in[i][j][4].TREADY;
                assign router_in[i][j][4].TDATA =                   router_if[i+1][j+2][WEST_REQ].TDATA;
                assign router_in[i][j][4].TID =                     router_if[i+1][j+2][WEST_REQ].TID;
                assign router_in[i][j][4].TSTRB =                   router_if[i+1][j+2][WEST_REQ].TSTRB;
                assign router_in[i][j][4].TLAST =                   router_if[i+1][j+2][WEST_REQ].TLAST;

                assign router_in[i][j][5].TVALID =                  router_if[i+1][j+2][WEST_RESP].TVALID;
                assign router_if[i+1][j+2][WEST_RESP].TREADY = router_in[i][j][5].TREADY;
                assign router_in[i][j][5].TDATA =                   router_if[i+1][j+2][WEST_RESP].TDATA;
                assign router_in[i][j][5].TID =                     router_if[i+1][j+2][WEST_RESP].TID;
                assign router_in[i][j][5].TSTRB =                   router_if[i+1][j+2][WEST_RESP].TSTRB;
                assign router_in[i][j][5].TLAST =                   router_if[i+1][j+2][WEST_RESP].TLAST;

                assign router_in[i][j][6].TVALID =                  router_if[i+2][j+1][NORTH_REQ].TVALID;
                assign router_if[i+2][j+1][NORTH_REQ].TREADY = router_in[i][j][6].TREADY;
                assign router_in[i][j][6].TDATA =                   router_if[i+2][j+1][NORTH_REQ].TDATA;
                assign router_in[i][j][6].TID =                     router_if[i+2][j+1][NORTH_REQ].TID;
                assign router_in[i][j][6].TSTRB =                   router_if[i+2][j+1][NORTH_REQ].TSTRB;
                assign router_in[i][j][6].TLAST =                   router_if[i+2][j+1][NORTH_REQ].TLAST;

                assign router_in[i][j][7].TVALID =                  router_if[i+2][j+1][NORTH_RESP].TVALID;
                assign router_if[i+2][j+1][NORTH_RESP].TREADY = router_in[i][j][7].TREADY;
                assign router_in[i][j][7].TDATA =                   router_if[i+2][j+1][NORTH_RESP].TDATA;
                assign router_in[i][j][7].TID =                     router_if[i+2][j+1][NORTH_RESP].TID;
                assign router_in[i][j][7].TSTRB =                   router_if[i+2][j+1][NORTH_RESP].TSTRB;
                assign router_in[i][j][7].TLAST =                   router_if[i+2][j+1][NORTH_RESP].TLAST;

                assign router_in[i][j][8].TVALID =                  router_if[i+1][j][EAST_REQ].TVALID;
                assign router_if[i+1][j][EAST_REQ].TREADY = router_in[i][j][8].TREADY;
                assign router_in[i][j][8].TDATA =                   router_if[i+1][j][EAST_REQ].TDATA;
                assign router_in[i][j][8].TID =                     router_if[i+1][j][EAST_REQ].TID;
                assign router_in[i][j][8].TSTRB =                   router_if[i+1][j][EAST_REQ].TSTRB;
                assign router_in[i][j][8].TLAST =                   router_if[i+1][j][EAST_REQ].TLAST;

                assign router_in[i][j][9].TVALID =                  router_if[i+1][j][EAST_RESP].TVALID;
                assign router_if[i+1][j][EAST_RESP].TREADY = router_in[i][j][9].TREADY;
                assign router_in[i][j][9].TDATA =                   router_if[i+1][j][EAST_RESP].TDATA;
                assign router_in[i][j][9].TID =                     router_if[i+1][j][EAST_RESP].TID;
                assign router_in[i][j][9].TSTRB =                   router_if[i+1][j][EAST_RESP].TSTRB;
                assign router_in[i][j][9].TLAST =                   router_if[i+1][j][EAST_RESP].TLAST;
                
                router_dual_parallel #(
                    .DATA_WIDTH(AXIS_CHANNEL_WIDTH),
                    .ID_WIDTH(3),
                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y)
                ) router (
                    .clk(ACLK),
                    .rst_n(ARESETn),

                    .in(router_in[i][j]),
                    .out(router_if[i+1][j+1])
                );

            end
        end
    endgenerate



endmodule