module tb_axi_memory;

    parameter ID_W_WIDTH = 4;
    parameter ID_R_WIDTH = 4;
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter BYTE_WIDTH = 8;

    logic ACLK, ARESETn;

    always #10 ACLK = ~ACLK;

    axi_if #(
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
        ) axi_i();

    axi_ram #(
        .ID_W_WIDTH(ID_W_WIDTH),
        .ID_R_WIDTH(ID_R_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
        .BYTE_WIDTH(BYTE_WIDTH)
    ) (.clk(ACLK), .rst_n(ARESETn), axi_s(axi_i.s));

    task am_write(
        axi_if.m axi_m,

        // AW channel 
        logic [ID_W_WIDTH-1:0] AWID,
        logic [ADDR_WIDTH-1:0] AWADDR,
        logic [7:0] AWLEN,
        logic [2:0] AWSIZE,
        logic [1:0] AWBURST,

        // W channel
        logic [DATA_WIDTH-1:0] WDATA [$];
        logic [(DATA_WIDTH/8)-1:0] WSTRB [$];

    )

    axi_m.AWID = AWID;
    axi_m.AWADDR = AWADDR;
    axi_m.AWLEN = AWLEN;
    axi_m.AWSIZE = AWSIZE;
    axi_m.AWBURST = AWBURST;

    axi_m.AWVALID = 1'b1;
    while(!axi_m.AWREADY) begin
        @posedge ACLK;
    end
    @posedge ACLK;

    axi_m.AWID = '0;
    axi_m.AWADDR = '0;
    axi_m.AWLEN = '0;
    axi_m.AWSIZE = '0;
    axi_m.AWBURST = '0;
    axi_m.AWVALID = '0;

    for(int i = 0; i < AWLEN+1; i++) begin
        @posedge ACLK;
        axi_m.WLAST = i == AWLEN;
        axi_m.WDATA = WDATA[i];
        axi_m.WSTRB = WSTRB[i];
        axi_m.WVALID = 1'b1;

        while(!axi_m.WREADY) begin
            @posedge ACLK;
        end
        @posedge ACLK;
        axi_m.WLAST = '0;
        axi_m.WDATA = '0;
        axi_m.WSTRB = '0;
        axi_m.WVALID = '0;
    end

    endtask : am_write

    initial begin
        fork
            am_write(
                axi_i.m,

                1, // AWID
                1, // AWADDR
                0, // AWLEN
                0, // AWSIZE
                1, // AWBURST

                {32'hFFFF},
                {4'hF}
            );
        join
        $finish;
    end

endmodule : tb_axi_memory