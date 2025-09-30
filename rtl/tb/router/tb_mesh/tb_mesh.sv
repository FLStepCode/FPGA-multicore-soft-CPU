module tb_mesh (
    input aclk,
    input aresetn,

    output logic awready[9],
    input  logic awvalid[9],
    input  logic [3:0] awid[9],
    input  logic [19:0] awaddr[9],
    input  logic [7:0] awlen[9],
    input  logic [2:0] awsize[9],
    input  logic [1:0] awburst[9],

    output logic wready[9],
    input  logic wvalid[9],
    input  logic [31:0] wdata[9],
    input  logic [3:0] wstrb[9],
    input  logic wlast[9],

    output logic bvalid[9],
    output logic [3:0] bid[9],
    input  logic bready[9],

    output logic arready[9],
    input  logic arvalid[9],
    input  logic [3:0] arid[9],
    input  logic [19:0] araddr[9],
    input  logic [7:0] arlen[9],
    input  logic [2:0] arsize[9],
    input  logic [1:0] arburst[9],

    output logic rvalid[9],
    output logic [3:0] rid[9],
    output logic [31:0] rdata[9],
    output logic rlast[9],
    input  logic rready[9]
    
);
    axi_if axi[9](), axi_ram[9]();

    generate
        for (genvar i = 0; i < 9; i++) begin : map_wires
            always_comb begin
                axi[i].AWVALID = awvalid[i];
                axi[i].AWID    = awid[i];
                axi[i].AWADDR  = awaddr[i];
                axi[i].AWLEN   = awlen[i];
                axi[i].AWSIZE  = awsize[i];
                axi[i].AWBURST = awburst[i];
                awready[i]     = axi[i].AWREADY;

                axi[i].WVALID = wvalid[i];
                axi[i].WDATA  = wdata[i];
                axi[i].WSTRB  = wstrb[i];
                axi[i].WLAST  = wlast[i];
                wready[i]     = axi[i].WREADY;
                
                bvalid[i]     = axi[i].BVALID;
                bid[i]        = axi[i].BID;
                axi[i].BREADY = bready[i];
                
                axi[i].ARVALID = arvalid[i];
                axi[i].ARID    = arid[i];
                axi[i].ARADDR  = araddr[i];
                axi[i].ARLEN   = arlen[i];
                axi[i].ARSIZE  = arsize[i];
                axi[i].ARBURST = arburst[i];
                arready[i]     = axi[i].ARREADY;

                rvalid[i]     = axi[i].RVALID;
                rid[i]        = axi[i].RID;
                rdata[i]      = axi[i].RDATA;
                rlast[i]      = axi[i].RLAST;
                axi[i].RREADY = rready[i];
            end
        end
    endgenerate

    XY_mesh dut (
        .ACLK(aclk),
        .ARESETn(aresetn),

        .s_axi_in(axi),
        .m_axi_out(axi_ram)
    );

    generate
        for (genvar i = 0; i < 9; i++) begin : map_rams
            axi_ram #(
                .ID(i + 1)
            ) ram (
                .clk(aclk),
                .rst_n(aresetn),
                .axi_s(axi_ram[i])
            );
        end
    endgenerate
    
endmodule