module algorithm #(
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
    parameter CHANNEL_NUMBER = 5,
    parameter CHANNEL_NUMBER_WIDTH
    = $clog2(CHANNEL_NUMBER),
    parameter MAX_ROUTERS_X = 4,
    parameter MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    parameter MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter ROUTER_X = 0,
    parameter ROUTER_Y = 0
) (
    axis_if.s in,
    axis_if.m out [CHANNEL_NUMBER],

    input logic [MAX_ROUTERS_X_WIDTH-1:0] target_x,
    input logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y
);

    logic [CHANNEL_NUMBER_WIDTH-1:0] ctrl;
    logic [CHANNEL_NUMBER-1:0] selector;
    assign selector[0] =
    ((target_x == ROUTER_X) && (target_y == ROUTER_Y)) && out[0].TREADY;
    assign selector[1] = (target_y < ROUTER_Y) && out[1].TREADY;
    assign selector[2] = (target_x > ROUTER_X) && out[2].TREADY;
    assign selector[3] = (target_y > ROUTER_Y) && out[3].TREADY;
    assign selector[4] = (target_x < ROUTER_X) && out[4].TREADY;
    logic hit;
    assign hit = |selector;

    always_comb begin
        ctrl = '0;
        for (int i = 0; i < CHANNEL_NUMBER; i++) begin
            if(selector[CHANNEL_NUMBER - 1 - i]) begin
                ctrl = i;
            end
        end
    end

    axis_if_demux #(
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
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
    ) demux (
        in,
        hit,
        ctrl,
        out
    );

endmodule