`include "mesh_3x3/inc/noc.svh"
`include "mesh_3x3/inc/noc_XY.svh"
`include "mesh_3x3/noc/noc.sv"
`include "cores/src/cpu_with_ram.sv"

module noc_with_cores (
    input clk, rst_n,

    input [31:0] peekAddress,
    input [$clog2(`RN) - 1:0] peekId,
    output [31:0] peekData
);

    wire cores_ready[0:`Y-1][0:`X-1];
    wire network_ready[0:`Y-1][0:`X-1];

    wire[0:`PL-1] core_inputs[0:`Y-1][0:`X-1];
    wire[0:`PL-1] core_outputs[0:`Y-1][0:`X-1];

    wire[31:0] peekRam[0:`Y-1][0:`X-1];
    reg[$clog2(`RN) - 1:0] peekIdEncoded;

    assign peekData = peekRam[peekIdEncoded[1:0]][peekIdEncoded[3:2]];

    always_comb
    begin
        case (peekId)
            0: peekIdEncoded = 4'b0000;
            1: peekIdEncoded = 4'b0100;
            2: peekIdEncoded = 4'b1000;
            3: peekIdEncoded = 4'b0001;
            4: peekIdEncoded = 4'b0101;
            5: peekIdEncoded = 4'b1001;
            6: peekIdEncoded = 4'b0010;
            7: peekIdEncoded = 4'b0110;
            8: peekIdEncoded = 4'b1010;
            default: peekIdEncoded = 4'b1111;
        endcase
    end

    generate
        genvar i, j;

        for (i = 0; i < `Y; i = i + 1)
        begin : rows
            for (j = 0; j < `X; j = j + 1)
            begin : columns

                if (1)
                begin
                    cpu_with_ram #(
                        .NODE_ID(i * `Y + j)
                    ) core (
                        .clk(clk), .rst_n(rst_n),

                        .collectorReady(cores_ready[i][j]),
                        .flitIn(core_inputs[i][j]),

                        .networkReady(network_ready[i][j]),
                        .flitOut(core_outputs[i][j]),

                        .peekAddress(peekAddress),
                        .peekData(peekRam[i][j])
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
        .cores_ready(cores_ready),
        .network_ready(network_ready)
    );
    
endmodule