`include "mesh_3x3/inc/noc.svh"
`include "mesh_3x3/inc/noc_XY.svh"
`include "mesh_3x3/noc/noc.sv"
`include "cores/src/cpu_with_ram.sv"

module toplevel (
    input clk, rst_n
);

    wire core_availability_signals_out[0:`Y-1][0:`X-1];
    wire[$clog2(9)-1:0] node_start_out[0:`Y-1][0:`X-1];
    wire[0:`PL-1] core_inputs[0:`Y-1][0:`X-1];
    wire[0:`PL-1] core_outputs[0:`Y-1][0:`X-1];

    generate
        genvar i, j;

        for (i = 0; i < `Y; i = i + 1)
        begin : rows
            for (j = 0; j < `X; j = j + 1)
            begin : columns

                assign core_availability_signals_out[i][j] = 1; 

                if (1)
                begin
                    cpu_with_ram #(
                        .NODE_ID(i * `Y + j)
                    ) core (
                        .clk(clk), .rst_n(rst_n),
                        .flitIn(core_inputs[i][j]),
                        .flitOut(core_outputs[i][j])
                    );
                end
                else
                begin
                    assign core_outputs[i][j] = 0;
                end

            end
        end

    endgenerate


    noc noc(
        .clk(clk), .rst_n(rst_n),
        .core_inputs(core_inputs),
        .core_outputs(core_outputs),
        .core_availability_signals_out(core_availability_signals_out)
    );
    
endmodule