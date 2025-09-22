module router #(
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
    parameter BUFFER_LENGTH = 4,
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
    arbiter_out();

    logic [MAX_ROUTERS_X_WIDTH-1:0] target_x;
    logic [MAX_ROUTERS_Y_WIDTH-1:0] target_y;

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
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .MAXIMUM_PACKAGES_NUMBER(MAXIMUM_PACKAGES_NUMBER)
    ) arb (
        clk, rst_n,
        queue_out,
        arbiter_out.m,
        target_x,
        target_y
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
        .CHANNEL_NUMBER(CHANNEL_NUMBER),
        .MAX_ROUTERS_X(MAX_ROUTERS_X),
        .MAX_ROUTERS_Y(MAX_ROUTERS_Y),
        .ROUTER_X(ROUTER_X),
        .ROUTER_Y(ROUTER_Y)
    ) alg (
        arbiter_out.s,
        out,
        target_x,
        target_y
    );

    generate
        genvar i;
        for(i = 0; i < CHANNEL_NUMBER; i++) begin : axis_if_gen
            queue #(
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
                .BUFFER_LENGTH(BUFFER_LENGTH)
            ) q (
                clk, rst_n,
                in[i],
                queue_out[i].m
            );

        end
    endgenerate

    
endmodule
