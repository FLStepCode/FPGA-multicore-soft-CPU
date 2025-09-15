module tb_axi_memory;

    `timescale 1ps/1ps

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
        .DATA_WIDTH(DATA_WIDTH),
        .BYTE_WIDTH(BYTE_WIDTH)
    ) axi_r (.clk(ACLK), .rst_n(ARESETn), .axi_s(axi_i.s));

    task am_write(
        // AW channel 
        logic [ID_W_WIDTH-1:0] AWID,
        logic [ADDR_WIDTH-1:0] AWADDR,
        logic [7:0] AWLEN,
        logic [2:0] AWSIZE,
        logic [1:0] AWBURST,

        // W channel
        logic [DATA_WIDTH-1:0] WDATA [$],
        logic [(DATA_WIDTH/8)-1:0] WSTRB [$]

    );

    axi_i.AWID = AWID;
    axi_i.AWADDR = AWADDR;
    axi_i.AWLEN = AWLEN;
    axi_i.AWSIZE = AWSIZE;
    axi_i.AWBURST = AWBURST;

    axi_i.AWVALID = 1'b1;
    if(!axi_i.AWREADY) begin
        @(negedge axi_i.AWREADY);
    end
    @(posedge ACLK);

    axi_i.AWID = '0;
    axi_i.AWADDR = '0;
    axi_i.AWLEN = '0;
    axi_i.AWSIZE = '0;
    axi_i.AWBURST = '0;
    axi_i.AWVALID = '0;

    for(int i = 0; i < AWLEN+1; i++) begin
        @(posedge ACLK);
        axi_i.WLAST = i == AWLEN;
        axi_i.WDATA = WDATA[i];
        axi_i.WSTRB = WSTRB[i];
        axi_i.WVALID = 1'b1;

        if(!axi_i.WREADY) begin
            @(posedge axi_i.WREADY);
        end
        @(posedge ACLK);
        axi_i.WLAST = '0;
        axi_i.WDATA = '0;
        axi_i.WSTRB = '0;
        axi_i.WVALID = '0;
    end

    $display("Kakayanit' huinya");

    while(!axi_i.BVALID)
        @(posedge ACLK);

    @(posedge ACLK);
    axi_i.BREADY = 1'b1;

    @(posedge ACLK);
    axi_i.BREADY = 1'b0;
    @(posedge ACLK);

    endtask : am_write

    initial begin
        ACLK = 1'b0;
        ARESETn = 1'b0;
        #10
        ARESETn = 1'b1;
        fork
            begin
                am_write(
                1, // AWID
                1, // AWADDR
                0, // AWLEN
                2, // AWSIZE
                1, // AWBURST

                {32'hFFFF0000},
                {4'hF}
            );
            $finish;
            end
            #1000 $finish;
        join
        
    end

endmodule : tb_axi_memory