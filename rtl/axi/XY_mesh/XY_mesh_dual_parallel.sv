module XY_mesh_dual_parallel #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter ID_W_WIDTH = 5,
    parameter ID_R_WIDTH = 5,
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
    ) from_home[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][2]();

    generate
        for (genvar i = 0; i < MAX_ROUTERS_Y; i++) begin
            assign router_if[i][0][WEST_REQ].TVALID = '0;
            assign router_if[i][0][WEST_RESP].TVALID = '0;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_REQ].TVALID = '0;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_RESP].TVALID = '0;

            assign router_if[i][0][WEST_REQ].TREADY = '1;
            assign router_if[i][0][WEST_RESP].TREADY = '1;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_REQ].TREADY = '1;
            assign router_if[i][MAX_ROUTERS_X+1][EAST_RESP].TREADY = '1;
        end

        for (genvar i = 0; i < MAX_ROUTERS_X; i++) begin
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
        for (genvar i = 0; i < MAX_ROUTERS_Y; i++) begin : Y
            for (genvar j = 0; j < MAX_ROUTERS_X; j++) begin : X
                
                axi2axis_XY #(
                    .ADDR_WIDTH(ADDR_WIDTH),
                    .DATA_WIDTH(DATA_WIDTH),
                    .ID_W_WIDTH(ID_W_WIDTH),
                    .ID_R_WIDTH(ID_R_WIDTH),
                    .MAX_ID_WIDTH(MAX_ID_WIDTH),
                    .AXIS_CHANNEL_WIDTH(AXIS_CHANNEL_WIDTH),

                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y),

                    .Ax_FIFO_LEN(Ax_FIFO_LEN),
                    .W_FIFO_LEN(W_FIFO_LEN)
                ) bridge (
                    .ACLK(ACLK),
                    .ARESETn(ARESETn),

                    .s_axi_in(s_axi_in[i * MAX_ROUTERS_X + j]),
                    .s_axis_req_in(router_if[i+1][j+1][HOME_REQ]),
                    .s_axis_resp_in(router_if[i+1][j+1][HOME_RESP]),

                    .m_axi_out(m_axi_out[i * MAX_ROUTERS_X + j]),
                    .m_axis_req_out(from_home[i+1][j+1][HOME_REQ]),
                    .m_axis_resp_out(from_home[i+1][j+1][HOME_RESP])
                );
                
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

                    .in('{from_home[i+1][j+1][HOME_REQ], from_home[i+1][j+1][HOME_RESP],
                            router_if[i][j+1][SOUTH_REQ], router_if[i][j+1][SOUTH_RESP],
                            router_if[i+1][j+2][WEST_REQ], router_if[i+1][j+2][WEST_RESP], 
                            router_if[i+2][j+1][NORTH_REQ],router_if[i+2][j+1][NORTH_RESP],
                            router_if[i+1][j][EAST_REQ], router_if[i+1][j][EAST_RESP]}),
                    .out(router_if[i+1][j+1])
                );

            end
        end
    endgenerate



endmodule