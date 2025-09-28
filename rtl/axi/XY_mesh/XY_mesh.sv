module XY_mesh #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter MAX_ID_WIDTH = 4,

    parameter MAX_ROUTERS_X = 3,
    parameter MAX_ROUTERS_Y = 3,

    parameter Ax_FIFO_LEN = 4,
    parameter W_FIFO_LEN = 4
) (
    input ACLK, ARESETn,

    axi_if.s s_axi_in[MAX_ROUTERS_X*MAX_ROUTERS_Y],
    axi_if.m m_axi_out[MAX_ROUTERS_X*MAX_ROUTERS_Y]
);

    typedef enum logic [2:0] {
        HOME,
        NORTH,
        EAST,
        SOUTH,
        WEST
    } index;
    
    axis_if #(
        .DATA_WIDTH(40)
    ) router_if[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2][5]();

    axis_if #(
        .DATA_WIDTH(40)
    ) from_home[MAX_ROUTERS_Y+2][MAX_ROUTERS_X+2]();

    generate
        for (genvar i = 0; i < MAX_ROUTERS_Y; i++) begin
            assign router_if[i][0][WEST].TVALID = '0;
            assign router_if[i][MAX_ROUTERS_X+1][EAST].TVALID = '0;

            assign router_if[i][0][WEST].TREADY = '1;
            assign router_if[i][MAX_ROUTERS_X+1][EAST].TREADY = '1;
        end

        for (genvar i = 0; i < MAX_ROUTERS_X; i++) begin
            assign router_if[0][i][NORTH].TVALID = '0;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH].TVALID = '0;

            assign router_if[0][i][NORTH].TREADY = '1;
            assign router_if[MAX_ROUTERS_Y+1][i][SOUTH].TREADY = '1;
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
                    .s_axis_in(router_if[i+1][j+1][HOME]),

                    .m_axi_out(m_axi_out[i * MAX_ROUTERS_X + j]),
                    .m_axis_out(from_home[i+1][j+1])
                );

                router #(
                    .DATA_WIDTH(40),
                    .ROUTER_X(j),
                    .MAX_ROUTERS_X(MAX_ROUTERS_X),
                    .ROUTER_Y(i),
                    .MAX_ROUTERS_Y(MAX_ROUTERS_Y)
                ) router (
                    .clk(ACLK),
                    .rst_n(ARESETn),

                    .in('{from_home[i+1][j+1], router_if[i][j+1][SOUTH], router_if[i+1][j+2][WEST], router_if[i+2][j+1][NORTH], router_if[i+1][j][EAST]}),
                    .out(router_if[i+1][j+1])
                );

            end
        end
    endgenerate



endmodule