`include "cores/src/sr_cpu.v"
`include "cores/src/ram.sv"
`include "cores/src/sr_mem_ctrl.sv"
`include "cores/converters/splitter.sv"
`include "cores/converters/packet_collector.sv"

module cpu_with_ram #(parameter int NODE_ID = 0, NODE_COUNT = 9, SPLITTER_DEPTH = 1, COLLECTOR_DEPTH = 8, parameter int PACKET_ID_WIDTH = 5) (
    input  logic clk, rst_n,

    output logic collectorReady,
    input logic [1 + 2*$clog2(NODE_COUNT) + 16 + 3 + PACKET_ID_WIDTH + 2 - 1 : 0] flitIn,

    input logic networkReady,
    output logic [1 + 2*$clog2(NODE_COUNT) + 16 + 3 + PACKET_ID_WIDTH + 2 - 1 : 0] flitOut,

    input logic [31:0] peekAddress,
    output logic [31:0] peekData
);
    // CPU-Controller
    wire[31:0] dataToCpu;
    wire[31:0] dataFromCpu;
    wire[31:0] logicalRamAddress;
    wire[2:0] instr;
    wire dataReceived;
    wire instrTaken;

    // Controller-RAM
    wire[31:0] rdData;
    wire[31:0] physicalRamAddress;
    wire[31:0] wrData;
    wire we;

    // Controller-Spliiter
    wire[63:0] packetOut;
    wire[2:0] instrOut;
    wire[$clog2(NODE_COUNT) - 1 : 0] nodeDest;
    wire[PACKET_ID_WIDTH-1:0] packetId;
    wire validControllerSplitter;
    wire splitterReady;

    // Controller-Collector
    wire validCollectorRam;
    wire readFromCollector;
    wire [67:0] packetIn;
    wire [2:0] instrIn;
    wire [$clog2(NODE_COUNT)-1:0] nodeStart;

    sr_cpu #(.NODE_ID(NODE_ID)) core (
        .clk(clk), .rst_n(rst_n),
        .dataToCpu(dataToCpu),
        .dataReceived(dataReceived),
        .instrTaken(instrTaken),
        .dataFromCpu(dataFromCpu),
        .ramAddress(logicalRamAddress),
        .aguInstructionOut(instr)
    );

    sr_mem_ctrl #(
        .NODE_ID(NODE_ID), .NODE_COUNT(NODE_COUNT), .RAM_CHUNK_SIZE(1024), .PACKET_ID_WIDTH(PACKET_ID_WIDTH)
    ) mc (

        // CPU
        .clk(clk), .rst_n(rst_n),
        .memData(dataFromCpu),
        .memAddress(logicalRamAddress),
        .memInstr(instr),
        .dataToCpu(dataToCpu),
        .dataSent(dataReceived),
        .instrTaken(instrTaken),

        // RAM
        .rdData(rdData),
        .ramAddress(physicalRamAddress),
        .wrData(wrData),
        .we(we),

        // splitter/collector
        .packetIn(packetIn),
        .instrIn(instrIn),
        .nodeStart(nodeStart),
        .validIn(validCollectorRam),
        .readyToReceive(readFromCollector),

        .packetOut(packetOut),
        .instrOut(instrOut), 
        .nodeDest(nodeDest),
        .packetId(packetId),
        .validOut(validControllerSplitter),
        .splitterReady(splitterReady)
    );

    ram #(
        .RAM_SIZE(1024), .NODE_ID(NODE_ID)
    ) ram (
        .clk(clk), .rst_n(rst_n),
        .ramAddress(physicalRamAddress),
        .wrData(wrData),
        .we(we),
        .rdData(rdData),

        .peekAddress(peekAddress),
        .peekData(peekData)
    );

    splitter #(
        .NODE_ID(NODE_ID), .NODE_COUNT(NODE_COUNT), .QUEUE_DEPTH(SPLITTER_DEPTH), .PACKET_ID_WIDTH(PACKET_ID_WIDTH)
    ) spl (
        .clk(clk), .ce(1'b1), .rst_n(rst_n),
        .packet_in(packetOut),
        .instr_in(instrOut),
        .node_dest(nodeDest),
        .valid_in(validControllerSplitter),
        .packet_id(packetId),
        .splitter_ready(splitterReady),

        .network_ready(networkReady),
        .output_data(flitOut),
        .valid_out()
    );

    packet_collector #( 
        .NODE_COUNT(NODE_COUNT), .PACKET_ID_WIDTH(PACKET_ID_WIDTH), .BUFFER_SIZE(COLLECTOR_DEPTH)
    ) pc (
        .clk(clk), .rst_n(rst_n), .ce(1'b1),
        .input_data(flitIn),
        .collector_ready(collectorReady),

        .valid_out(validCollectorRam),
        .packet_out(packetIn),
        .instr_out(instrIn),
        .node_start_out(nodeStart),
        .node_dest_out(),
        .packet_id_out(),
        .send_signal(readFromCollector)
    );
    
endmodule