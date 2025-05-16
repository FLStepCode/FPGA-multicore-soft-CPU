`include "mesh_3x3/inc/noc.svh"
`include "cpu/noc_with_cores.sv"

module toplevel_onboard (
    input clk, rst_n,
    input[31:0] peekAddress,
    input [$clog2(`RN) - 1:0] peekId,
    output[31:0] peekData
);

    noc_with_cores nwc(
        .clk(clk), .rst_n(rst_n),
        .peekAddress(peekAddress), .peekId(peekId[$clog2(`RN) - 1:0]), .peekData(peekData)
    );
    
endmodule