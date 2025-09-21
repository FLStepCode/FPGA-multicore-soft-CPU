module arbiter #(
    parameter CHANNEL_NUMBER = 5,
    localparam CHANNEL_NUMBER_WIDTH
    = $clog2(CHANNEL_NUMBER),
    parameter MAX_ROUTERS_X = 4,
    localparam MAX_ROUTERS_X_WIDTH
    = $clog2(MAX_ROUTERS_X),
    parameter MAX_ROUTERS_Y = 4,
    localparam MAX_ROUTERS_Y_WIDTH
    = $clog2(MAX_ROUTERS_Y),
    parameter MAXIMUM_PACKAGES_NUMBER = 5,
    localparam MAXIMUM_PACKAGES_NUMBER_WIDTH
    = $clog2(MAXIMUM_PACKAGES_NUMBER - 1)
) (
    input clk, rst_n,

    axis_if.s [CHANNEL_NUMBER] in,
    axis_if.m out,

    output [COORDINATE_WIDTH*2-1:0] target_coordinates
);
   
    logic [CHANNEL_NUMBER_WIDTH-1:0] current_grant;
    logic [CHANNEL_NUMBER_WIDTH-1:0] next_grant;
    logic [CHANNEL_NUMBER_WIDTH-1:0] increment;

    logic [CHANNEL_NUMBER-1:0] valid_i;
    logic [CHANNEL_NUMBER*2 - 1:0] shifted_valid_i;
    logic [MAXIMUM_PACKAGES_NUMBER_WIDTH-1:0]
    packages_read, packages_left;
    
    axis_if.s inter_in = in[current_grant];
    axis_if_connector axis_if_connector(inter_in, out);

    generate
	    genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : valid_gen
            assign valid_i[i] = in[i].TVALID;
        end
    endgenerate

    assign shifted_valid_i = {valid_i, valid_i} >> current_grant;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_grant <= 0;
        end
        else begin
            if (out.TREADY) begin
                current_grant <= next_grant;
            end
        end
    end

    always_comb begin
        next_grant = current_grant;
        increment = 0;
        for (int i = CHANNEL_NUMBER-1; i > 0; i--) begin
            if (shifted_valid_i[i]) begin
                increment = i;
            end
        end

        next_grant = (next_grant + increment) >= CHANNEL_NUMBER ?
        (next_grant + increment - CHANNEL_NUMBER):
        (next_grant + increment);
        
        packages_read = in[0].TDATA[
            2*COORDINATE_WIDTH+MAXIMUM_PACKAGES_NUMBER_WIDTH-1:
            2*COORDINATE_WIDTH
            ];


    end

    
endmodule
