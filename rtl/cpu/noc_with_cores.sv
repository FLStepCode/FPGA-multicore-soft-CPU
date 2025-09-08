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
            3: peekIdEncoded = 4'b1100;
            4: peekIdEncoded = 4'b0001;
            5: peekIdEncoded = 4'b0101;
            6: peekIdEncoded = 4'b1001;
            7: peekIdEncoded = 4'b1101;
            8: peekIdEncoded = 4'b0010;
            9: peekIdEncoded = 4'b0110;
            10: peekIdEncoded = 4'b1010;
            11: peekIdEncoded = 4'b1110;
            12: peekIdEncoded = 4'b0011;
            13: peekIdEncoded = 4'b0111;
            14: peekIdEncoded = 4'b1011;
            15: peekIdEncoded = 4'b1111;
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