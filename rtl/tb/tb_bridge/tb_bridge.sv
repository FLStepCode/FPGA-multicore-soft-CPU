module tb_bridge (
    input  logic aclk,
    input  logic aresetn,

    output logic a_awready,
    input  logic a_awvalid,
    input  logic [3:0] a_awid,
    input  logic [15:0] a_awaddr,
    input  logic [7:0] a_awlen,
    input  logic [2:0] a_awsize,
    input  logic [1:0] a_awburst,

    output logic a_wready,
    input  logic a_wvalid,
    input  logic [31:0] a_wdata,
    input  logic [3:0] a_wstrb,
    input  logic a_wlast,

    output logic a_bvalid,
    output logic [3:0] a_bid,
    input  logic a_bready,

    output logic a_arready,
    input  logic a_arvalid,
    input  logic [3:0] a_arid,
    input  logic [15:0] a_araddr,
    input  logic [7:0] a_arlen,
    input  logic [2:0] a_arsize,
    input  logic [1:0] a_arburst,

    output logic a_rvalid,
    output logic [3:0] a_rid,
    output logic [31:0] a_rdata,
    output logic a_rlast,
    input  logic a_rready,

    input  logic a_tready,
    output logic a_tvalid,
    output logic [39:0] a_tdata,

    output logic b_tready,
    input  logic b_tvalid,
    input  logic [39:0] b_tdata
);

    axi_if axi_master(), axi_slave();
    axis_if #(.DATA_WIDTH(40)) axis_master(), axis_slave();

    always_comb begin
        axi_master.AWVALID = a_awvalid;
        axi_master.AWID    = a_awid;
        axi_master.AWADDR  = a_awaddr;
        axi_master.AWLEN   = a_awlen;
        axi_master.AWSIZE  = a_awsize;
        axi_master.AWBURST = a_awburst;
        a_awready         = axi_master.AWREADY;

        axi_master.WVALID = a_wvalid;
        axi_master.WDATA  = a_wdata;
        axi_master.WSTRB  = a_wstrb;
        axi_master.WLAST  = a_wlast;
        a_wready         = axi_master.WREADY;
        
        a_bvalid = axi_master.BVALID;
        a_bid    = axi_master.BID;
        axi_master.BREADY = a_bready;
        
        axi_master.ARVALID = a_arvalid;
        axi_master.ARID    = a_arid;
        axi_master.ARADDR  = a_araddr;
        axi_master.ARLEN   = a_arlen;
        axi_master.ARSIZE  = a_arsize;
        axi_master.ARBURST = a_arburst;
        a_arready         = axi_master.ARREADY;

        a_rvalid = axi_master.RVALID;
        a_rid    = axi_master.RID;
        a_rdata  = axi_master.RDATA;
        a_rlast  = axi_master.RLAST;
        axi_master.RREADY = a_rready;


        axis_slave.TREADY = a_tready;
        a_tdata = axis_slave.TDATA;
        a_tvalid = axis_slave.TVALID;

        b_tready = axis_master.TREADY;
        axis_master.TDATA = b_tdata;
        axis_master.TVALID = b_tvalid;
    end

    axi2axis_XY dut (
        .ACLK(aclk),
        .ARESETn(aresetn),
        
        .s_axi_in(axi_master),
        .m_axi_out(axi_slave),
        
        .s_axis_in(axis_master),
        .m_axis_out(axis_slave)
    );
    
endmodule