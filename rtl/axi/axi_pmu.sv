module axi_pmu (
    input  logic aclk,
    input  logic aresetn,

    axi_if.mon mon_axi
);

    typedef struct packed {
        logic [63:0] idle;
        logic [63:0] outstanding;
        logic [63:0] ar_stall;
        logic [63:0] ar_handshake;
        logic [63:0] rvalid_stall;
        logic [63:0] rready_stall;
        logic [63:0] r_handshake;
    } read_counters;

    typedef struct packed {
        logic [63:0] idle;
        logic [63:0] outstanding;
        logic [63:0] responding;
        logic [63:0] aw_stall;
        logic [63:0] aw_handshake;
        logic [63:0] wvalid_stall;
        logic [63:0] wready_stall;
        logic [63:0] w_handshake;
        logic [63:0] bvalid_stall;
        logic [63:0] bready_stall;
        logic [63:0] b_handshake;
    } write_counters;


    read_counters rc;
    write_counters wc;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rc <= '0;
        end
        else begin
            if (!mon_axi.ARVALID && (rc.outstanding == 0)) begin
                rc.idle <= rc.idle + 1;
            end

            if (mon_axi.ARVALID && mon_axi.ARREADY) begin
                if (!(mon_axi.RVALID && mon_axi.RREADY && mon_axi.RLAST)) begin
                    rc.outstanding <= rc.outstanding + 1;
                end
            end
            else begin
                if (mon_axi.RVALID && mon_axi.RREADY && mon_axi.RLAST) begin
                    rc.outstanding <= rc.outstanding - 1;
                end
            end


            // --- //
            if (mon_axi.ARVALID && !mon_axi.ARREADY) begin
                rc.ar_stall <= rc.ar_stall + 1;
            end

            if (mon_axi.ARVALID && mon_axi.ARREADY) begin
                rc.ar_handshake <= rc.ar_handshake + 1;
            end


            // --- //
            if ((rc.outstanding != 0) && !mon_axi.RVALID) begin
                rc.rvalid_stall <= rc.rvalid_stall + 1;
            end
            
            if (mon_axi.RVALID && !mon_axi.RREADY) begin
                rc.rvalid_stall <= rc.rvalid_stall + 1;
            end

            if (mon_axi.RVALID && mon_axi.RREADY) begin
                rc.r_handshake <= rc.r_handshake + 1;
            end
        end
    end

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wc <= '0;
        end
        else begin
            if (!mon_axi.AWVALID && (wc.outstanding == 0)) begin
                wc.idle <= wc.idle + 1;
            end

            if (mon_axi.AWVALID && mon_axi.AWREADY) begin
                if (!(mon_axi.BVALID && mon_axi.BREADY)) begin
                    wc.outstanding <= wc.outstanding + 1;
                end
            end
            else begin
                if (mon_axi.BVALID && mon_axi.BREADY) begin
                    wc.outstanding <= wc.outstanding - 1;
                end
            end

            if (mon_axi.BVALID && mon_axi.BVALID) begin
                if (!(mon_axi.WVALID && mon_axi.WREADY && mon_axi.WLAST)) begin
                    wc.responding <= wc.responding - 1;
                end
            end
            else begin
                if (mon_axi.WVALID && mon_axi.WREADY && mon_axi.WLAST) begin
                    wc.responding <= wc.responding + 1;
                end
            end


            // --- //
            if (mon_axi.AWVALID && !mon_axi.AWREADY) begin
                wc.aw_stall <= wc.aw_stall + 1;
            end

            if (mon_axi.AWVALID && mon_axi.AWREADY) begin
                wc.aw_handshake <= wc.aw_handshake + 1;
            end


            // --- //
            if ((wc.outstanding != 0) && !mon_axi.WVALID) begin
                wc.wvalid_stall <= wc.wvalid_stall + 1;
            end

            if (mon_axi.WVALID && !mon_axi.WREADY) begin
                wc.wready_stall <= wc.wready_stall + 1;
            end
            
            if (mon_axi.WVALID && mon_axi.WREADY) begin
                wc.w_handshake <= wc.w_handshake + 1;
            end


            // --- //
            if ((wc.responding != 0) && !mon_axi.BVALID) begin
                wc.bvalid_stall <= wc.bvalid_stall + 1;
            end

            if (mon_axi.BVALID && !mon_axi.BREADY) begin
                wc.bready_stall <= wc.bready_stall + 1;
            end
            
            if (mon_axi.BVALID && mon_axi.BREADY) begin
                wc.b_handshake <= wc.b_handshake + 1;
            end
        end
    end
    
endmodule