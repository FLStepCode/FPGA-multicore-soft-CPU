module axi2ram
#(
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter BYTE_WIDTH = 8
)
(
	input clk, rst_n,
    ram_if.m ram_ports[DATA_WIDTH/BYTE_WIDTH],
    axi_if.s axi_s

);
    localparam WSRTB_W = DATA_WIDTH/BYTE_WIDTH;

    logic [ADDR_WIDTH-1:0] addr_a [DATA_WIDTH/BYTE_WIDTH];
    logic [BYTE_WIDTH-1:0] data_a [DATA_WIDTH/BYTE_WIDTH];
    logic [BYTE_WIDTH-1:0] write_a [DATA_WIDTH/BYTE_WIDTH];
    logic write_en_a [DATA_WIDTH/BYTE_WIDTH];
    
    logic [ADDR_WIDTH-1:0] addr_b [DATA_WIDTH/BYTE_WIDTH];
    logic [BYTE_WIDTH-1:0] data_b [DATA_WIDTH/BYTE_WIDTH];
    logic [BYTE_WIDTH-1:0] write_b [DATA_WIDTH/BYTE_WIDTH];
    logic write_en_b [DATA_WIDTH/BYTE_WIDTH];

    generate
        for (genvar i = 0; i < (DATA_WIDTH/BYTE_WIDTH); i++) begin
            always_comb begin
                ram_ports[i].addr_a = addr_a[i];
                data_a[i] = ram_ports[i].data_a;
                ram_ports[i].write_a = write_a[i];
                ram_ports[i].write_en_a = write_en_a[i];
                
                ram_ports[i].addr_b = addr_b[i];
                data_b[i] = ram_ports[i].data_b;
                ram_ports[i].write_b = write_b[i];
                ram_ports[i].write_en_b = write_en_b[i];
            end
        end
    endgenerate

    enum { READING_ADDRESS, REQUESTING_DATA, RESPONDING }
    r_state, r_state_next,
    w_state,  w_state_next;

    // AR channel 
    logic [ID_W_WIDTH-1:0] ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [1:0] ARBURST;

    // AW channel 
    logic [ID_W_WIDTH-1:0] AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [1:0] AWBURST;

    always_ff @( posedge clk or negedge rst_n ) begin : StateSwitchBlock
        if(!rst_n) begin            
            r_state <= READING_ADDRESS;
            w_state <= READING_ADDRESS;
        end else begin
            r_state <= r_state_next;
            w_state <= w_state_next;
        end
    end : StateSwitchBlock

    always_comb begin : FSMOutputBlock
        r_state_next = READING_ADDRESS;

        axi_s.ARREADY = 1'b0;
        axi_s.RVALID = 1'b0;
        axi_s.RLAST = 1'b0;
        axi_s.RID = ARID;

        for (int i = 0; i < WSRTB_W; i++) begin
            addr_a[i] = ARADDR;
            write_en_a[i] = 1'b0;
            write_a[i] = '0;
            axi_s.RDATA[i*8 +: 8] = data_a[i];
        end

                
        case (r_state)
            READING_ADDRESS: begin
                r_state_next = READING_ADDRESS;
                axi_s.ARREADY = 1'b1;
                if(axi_s.ARVALID)
                    r_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA:
                r_state_next = RESPONDING;
            RESPONDING: begin
                r_state_next = RESPONDING;
                axi_s.RVALID = 1'b1;
                if(ARLEN == 8'o0) begin
                    axi_s.RLAST = 1'b1;
                    if(axi_s.RREADY)
                        r_state_next = READING_ADDRESS;
                end
            end
            default:;
        endcase
        
        w_state_next = READING_ADDRESS;

        axi_s.AWREADY = 1'b0;
        axi_s.WREADY = 1'b0;
        axi_s.BID = AWID;
        axi_s.BVALID = 1'b0;

        for (int i = 0; i < WSRTB_W; i++) begin
            write_en_b[i] = 1'b0;
            addr_b[i] = AWADDR;
            write_b[i] = axi_s.WDATA[i*8 +: 8];
        end

        case (w_state)
            READING_ADDRESS: begin
                w_state_next = READING_ADDRESS;
                axi_s.AWREADY = 1'b1;
                if(axi_s.AWVALID)
                    w_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA: begin

                axi_s.WREADY = 1'b1;
                w_state_next = REQUESTING_DATA;

                for (int i = 0; i < WSRTB_W; i++) begin
                    write_en_b[i] = axi_s.WSTRB[i];
                end

                if(axi_s.WVALID) begin
                    if(AWLEN == 1'b0 || axi_s.WLAST) begin
                        w_state_next = RESPONDING;
                    end
                end
            end
            RESPONDING: begin
                w_state_next = RESPONDING;
                axi_s.BVALID = 1'b1;
                if(axi_s.BREADY)
                    w_state_next = READING_ADDRESS;
            end
            default:;
        endcase

    end : FSMOutputBlock

    always_ff @( posedge clk or negedge rst_n ) begin : LogicBlock
    if(!rst_n) begin
        ARID <= '0;
        ARADDR <= '0;
        ARLEN <= '0;
        ARSIZE <= '0;
        ARBURST <= '0;

        AWID <= '0;
        AWADDR <= '0;
        AWLEN <= '0;
        AWSIZE <= '0;
        AWBURST <= '0;

    end else begin
        case (r_state)
            READING_ADDRESS: begin
                ARID <= axi_s.ARID;
                ARADDR <= axi_s.ARADDR;
                ARLEN <= axi_s.ARLEN;
                ARSIZE <= 1'b1 << axi_s.ARSIZE;
                ARBURST <= axi_s.ARBURST;
            end
            REQUESTING_DATA: begin
                if(axi_s.RREADY) begin
                    ARLEN <= (ARLEN == 0) ? '0 : ARLEN - 1'b1;

                    case (ARBURST)
                        2'b01: begin
                            ARADDR <= ARADDR + 1'b1;
                        end
                        2'b10: begin
                            if(ARADDR + 1'b1 > 2**ADDR_WIDTH-1) begin
                                ARADDR <= '0;
                            end
                            else begin
                                ARADDR <= ARADDR + 1'b1;
                            end
                        end
                    endcase

                end
            end
            RESPONDING: begin
                if(axi_s.RREADY) begin
                    ARLEN <= (ARLEN == 0) ? '0 : ARLEN - 1'b1;

                    case (ARBURST)
                        2'b01: begin
                            ARADDR <= ARADDR + 1'b1;
                        end
                        2'b10: begin
                            if(ARADDR + 1'b1 > 2**ADDR_WIDTH-1) begin
                                ARADDR <= '0;
                            end
                            else begin
                                ARADDR <= ARADDR + 1'b1;
                            end
                        end
                    endcase

                end
            end
            default:;
        endcase

        case (w_state)
            READING_ADDRESS: begin
                AWID <= axi_s.AWID;
                AWADDR <= axi_s.AWADDR;
                AWLEN <= axi_s.AWLEN;
                AWSIZE <= 1'b1 << axi_s.AWSIZE;
                AWBURST <= axi_s.AWBURST;
            end
            REQUESTING_DATA: begin
                if(axi_s.WVALID) begin
                    AWLEN <= (AWLEN == 0) ? '0 : AWLEN - 1'b1;
                    // Address shift logic
                    case (AWBURST)
                        2'b01: AWADDR <= AWADDR + 1'b1;
                        2'b10: begin
                            if(AWADDR + 1'b1 > 2**ADDR_WIDTH-1)
                                AWADDR <= '0;
                            else
                                AWADDR <= AWADDR + 1'b1;
                        end
                    endcase
                end
            end
            default:;
        endcase

    end
    end : LogicBlock

endmodule : axi2ram
