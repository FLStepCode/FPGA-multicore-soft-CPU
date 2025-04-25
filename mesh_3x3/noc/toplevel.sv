`include "mesh_3x3/inc/noc.svh"
`include "mesh_3x3/inc/noc_XY.svh"
`include "mesh_3x3/noc/noc.sv"
`include "generators/generators.sv"
`include "generators/packet_collector.sv"
`include "generators/splitter.sv"

`define GAUSSIAN

module toplevel (
    input clk, rst_n,
    input core_availability_signals_out[0:`Y-1][0:`X-1],
    input  logic [31:0] packet_in,
    input  logic [31:0] lfsr1_in, lfsr2_in, lfsr3_in, lfsr4_in,

    output[31:0] assembler_packets[0:`Y-1][0:`X-1],
    output[4:0] assembler_ids[0:`Y-1][0:`X-1],
    output [$clog2(9)-1:0] node_dest_out[0:`Y-1][0:`X-1]
);

    wire[$clog2(9)-1:0] node_start_out[0:`Y-1][0:`X-1];
    wire[0:`PL-1] core_inputs[0:`Y-1][0:`X-1];
    wire[0:`PL-1] core_outputs[0:`Y-1][0:`X-1];

    generate
        genvar i, j;

        for (i = 0; i < `Y; i = i + 1)
        begin : rows
            for (j = 0; j < `X; j = j + 1)
            begin : columns

                if (i == j)
                begin
                    generator_splitter #(.NODE_ID(j + i * `X), .NODE_COUNT(9)) core (
                        .clk(clk), .ce(1'b1), .rst(~rst_n),
                        .network_busy(~core_availability_signals_out[i][j]),
                        .output_data(core_outputs[i][j]), .packet_in(packet_in),
                        .lfsr1_in(lfsr1_in + i * 3), .lfsr2_in(lfsr2_in - j * 2), .lfsr3_in(lfsr3_in- i), .lfsr4_in(lfsr4_in + j)
                    );
                end
                else
                begin
                    assign core_outputs[i][j] = 0;
                end
					 
					packet_collector #(.NODE_COUNT(9)) receiver (
                    .clk(clk), .ce(1'b1), .rst(~rst_n),
                    .valid_in(1'b1), .input_data(core_inputs[i][j]),
                    .packet_out(assembler_packets[i][j]),
                    .node_start_out(node_start_out[i][j]), .node_dest_out(node_dest_out[i][j]), .packet_id_out(assembler_ids[i][j])
                );

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


module generator_splitter #(
    parameter int NODE_ID = 0, NODE_COUNT = 8, QUEUE_DEPTH = 8,
    parameter int PACKET_ID_WIDTH = 5
) (
    input  logic clk, ce, rst,
    input  logic network_busy,
    input  logic [31:0] packet_in,
    input  logic [31:0] lfsr1_in, lfsr2_in, lfsr3_in, lfsr4_in,

    output logic [1 + 2*$clog2(NODE_COUNT) + 8 + PACKET_ID_WIDTH - 1 + 2 : 0] output_data,
    output logic valid_out
);

    wire valid;
    wire[31:0] packet;
    wire[$clog2(NODE_COUNT)-1:0] node_dest;
    wire[PACKET_ID_WIDTH-1:0] packet_id;

    `ifdef SEQUENTIAL
    sequential_traffic_generator #(.NODE_ID(NODE_ID), .NODE_COUNT(NODE_COUNT), .PACKET_ID_WIDTH(PACKET_ID_WIDTH)) generator (
        .clk(clk), .rst(rst), .network_busy(network_busy),
        .valid(valid), .packet(packet), .node_dest(node_dest), .packet_id(packet_id), .packet_in(packet_in)
    );
    `endif

    `ifdef GAUSSIAN
    gaussian_traffic_generator #(.NODE_ID(NODE_ID), .NODE_COUNT(NODE_COUNT), .PACKET_ID_WIDTH(PACKET_ID_WIDTH)) generator (
        .clk(clk), .rst(rst), .valid(valid), 
        .packet(packet), .node_dest(node_dest), .packet_id(packet_id),
        .lfsr1_in(lfsr1_in), .lfsr2_in(lfsr2_in), .lfsr3_in(lfsr3_in), .lfsr4_in(lfsr4_in)
    );
    `endif

    splitter #(.NODE_ID(NODE_ID), .NODE_COUNT(NODE_COUNT), .QUEUE_DEPTH(QUEUE_DEPTH), .PACKET_ID_WIDTH(PACKET_ID_WIDTH)) splitter (
        .clk(clk), .ce(~network_busy), .rst(rst),
        .packet_in(packet), .node_dest(node_dest), .valid_in(valid), .packet_id(packet_id),
        .output_data(output_data), .valid_out(valid_out)
    );

endmodule