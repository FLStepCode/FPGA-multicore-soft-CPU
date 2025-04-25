`include "mesh_3x3/inc/router.svh"

module algorithm
(
    input[0:`PL-1] from_arbiter,
    input[`CS-1:0] router_X,
    input[`CS-1:0] router_Y,
    input[`REN_B-1:0] shift,
    output shift_signals[0:`REN-1],
    input availability_signals_in[0:`REN-1],
    output wire[0:`PL-1] outputs[0:`REN-1]
);

    wire[`CS-1:0] destination_X = from_arbiter[1:`CS];
    wire[`CS-1:0] destination_Y = from_arbiter[`CS+1:2*`CS];

    wire[0:4] selector;
    assign selector[0] = ((destination_X == router_X) & (destination_Y == router_Y)) & availability_signals_in[0] & from_arbiter[0];
    assign selector[1] = (destination_Y < router_Y) & availability_signals_in[1] & from_arbiter[0];
    assign selector[2] = (destination_X > router_X) & availability_signals_in[2] & from_arbiter[0];
    assign selector[3] = (destination_Y > router_Y) & availability_signals_in[3] & from_arbiter[0];
    assign selector[4] = (destination_X < router_X) & availability_signals_in[4] & from_arbiter[0];

    wire shift_required = selector[0] | selector[1] | selector[2] | selector[3] | selector[4];
    
    
    assign shift_signals[0] = shift_required & (shift == 0);
    assign shift_signals[1] = shift_required & (shift == 1);
    assign shift_signals[2] = shift_required & (shift == 2);
    assign shift_signals[3] = shift_required & (shift == 3);
    assign shift_signals[4] = shift_required & (shift == 4);

    wire[0:`PL-1] check_selector[0:`REN-1];

    generate
        genvar i, j;
        for (i = 0; i < `PL; i = i + 1 ) begin : generate_outputs_bits_core
            assign outputs[0][i] = from_arbiter[i] & selector[0];
        end

        for (i = 0; i < `PL; i = i + 1 ) begin : generate_outputs_bits_north
            assign outputs[1][i] = from_arbiter[i] & selector[1];
        end

        for (i = 0; i < `PL; i = i + 1 ) begin : generate_outputs_bits_east
            assign outputs[2][i] = from_arbiter[i] & selector[2] & !selector[1] & !selector[3];
        end

        for (i = 0; i < `PL; i = i + 1 ) begin : generate_outputs_bits_south
            assign outputs[3][i] = from_arbiter[i] & selector[3];
        end

        for (i = 0; i < `PL; i = i + 1 ) begin : generate_outputs_bits_west
            assign outputs[4][i] = from_arbiter[i] & selector[4] & !selector[1] & !selector[3];
        end

    endgenerate

endmodule