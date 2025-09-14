module stream_arbiter #(
    parameter DATA_WIDTH = 32,
    parameter OUTPUT_NUM = 2,
    parameter ADDR_WIDTH = $clog2(OUTPUT_NUM)
) (
    input logic ACLK,
    input logic ARESETn,

    input logic [DATA_WIDTH-1:0] data_i [OUTPUT_NUM],
    input logic [OUTPUT_NUM-1:0] valid_i,
    output logic [OUTPUT_NUM-1:0] ready_o,

    output logic [DATA_WIDTH-1:0] data_o,
    output logic valid_o,
    input logic ready_i
);

    logic [ADDR_WIDTH-1:0] current_grant;
    logic [ADDR_WIDTH-1:0] next_grant;
    logic [ADDR_WIDTH-1:0] increment;

    logic [OUTPUT_NUM*2 - 1:0] shifted_valid_i;

    assign shifted_valid_i = {valid_i, valid_i} >> current_grant;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            current_grant <= 0;
        end
        else begin
            if (ready_i) begin
                current_grant <= next_grant;
            end
        end
    end

    always_comb begin
        next_grant = current_grant;
        increment = 0;
        for (int i = OUTPUT_NUM-1; i > 0; i--) begin
            if (shifted_valid_i[i]) begin
                increment = i;
            end
        end

        next_grant = (next_grant + increment) >= OUTPUT_NUM ? (next_grant + increment - OUTPUT_NUM) : (next_grant + increment);
    end

    always_comb begin

        ready_o = '0;

        valid_o = valid_i[current_grant];
        data_o = data_i[current_grant];
        ready_o[current_grant] = ready_i;
    end
    
endmodule