module tb_cpu (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        awready,
    output logic        awvalid,
    output logic [3:0]  awid,
    output logic [15:0] awaddr,
    output logic [7:0]  awlen,
    output logic [2:0]  awsize,
    output logic [1:0]  awburst,

    input  logic        wready,
    output logic        wvalid,
    output logic [7:0]  wdata,
    output logic        wstrb,
    output logic        wlast,

    input  logic        bvalid,
    input  logic [3:0]  bid,
    output logic        bready,

    input  logic        arready,
    output logic        arvalid,
    output logic [3:0]  arid,
    output logic [15:0] araddr,
    output logic [7:0]  arlen,
    output logic [2:0]  arsize,
    output logic [1:0]  arburst,

    input  logic        rvalid,
    input  logic [3:0]  rid,
    input  logic [7:0]  rdata,
    input  logic        rlast,
    output logic        rready
);

    axi_if #(
        .DATA_WIDTH(8)
    ) s_axi();

    always_comb begin
        s_axi.AWREADY = awready ;
        awvalid = s_axi.AWVALID ;
        awid    = s_axi.AWID    ;
        awaddr  = s_axi.AWADDR  ;
        awlen   = s_axi.AWLEN   ;
        awsize  = s_axi.AWSIZE  ;
        awburst = s_axi.AWBURST ;

        s_axi.WREADY  =  wready ;
        wvalid  = s_axi.WVALID  ;
        wdata   = s_axi.WDATA   ;
        wstrb   = s_axi.WSTRB   ;
        wlast   = s_axi.WLAST   ;

        s_axi.BVALID  = bvalid  ;
        s_axi.BID     = bid     ;
        bready  = s_axi.BREADY  ;

        s_axi.ARREADY = arready ;
        arvalid = s_axi.ARVALID ;
        arid    = s_axi.ARID    ;
        araddr  = s_axi.ARADDR  ;
        arlen   = s_axi.ARLEN   ;
        arsize  = s_axi.ARSIZE  ;
        arburst = s_axi.ARBURST ;

        s_axi.RVALID  = rvalid  ;
        s_axi.RID     = rid     ;
        s_axi.RDATA   = rdata   ;
        s_axi.RLAST   = rlast   ;
        rready  = s_axi.RREADY  ;
    end

    sr_cpu_axi dut
    (
        .clk   (clk),  
        .rst_n (rst_n),

        .s_axi (s_axi)
    );
    
endmodule