module axi_ram
#(parameter RDATA_WIDTH=8, parameter RADDR_WIDTH=6, parameter CONTROL_WIDTH=2)
(
	input clk, rst_n,

    axi_if.s

);

	// Объявление памяти
	logic [RDATA_WIDTH-1:0] ram[2**RADDR_WIDTH-1:0];

    enum { READY, OCCUPIED }
    ar_state, ar_state_next,
    r_state,  r_state_next,
    aw_state, aw_state_next,
    w_state,  w_state_next,
    b_state,  b_state_next;

    // AW channel 
    logic [ID_W_WIDTH-1:0] AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [1:0] AWBURST;

    // AR channel 
    logic [ID_W_WIDTH-1:0] ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [1:0] ARBURST;

    always_ff @( posedge clk or negedge rst_n ) begin : StateSwitchBlock
        if(!rst_n) begin            
            ar_state <= READY;
            ar_state_next <= READY;

            r_state <= READY;
            r_state_next <= READY;
 
            aw_state <= READY;
            aw_state_next <= READY;

            w_state <= READY;
            w_state_next <= READY;

            b_state <= READY;
            b_state_next <= READY;
        end else begin
            ar_state <= ar_state_next;
            r_state <= r_state_next;
            aw_state <= aw_state_next;
            w_state <= w_state_next;
            b_state <= b_state_next;
        end
    end : StateSwitchBlock

    always_comb begin : FSMOutputBlock
        case (aw_state)
            OCCUPIED:
                axi_if.s.AWREADY = 1'b0;
            default:
                axi_if.s.AWREADY = 1'b1;
        endcase : aw_state

        case (w_state)
            OCCUPIED:
                axi_if.s.WREADY = 1'b0;
            default:
                axi_if.s.WREADY = 1'b1;
        endcase : w_state

        case (b_state)
            OCCUPIED:
                axi_if.s.BVALID = 1'b1;
            default:
                axi_if.s.BVALID = 1'b0;
        endcase : b_state

        case (ar_state)
            OCCUPIED:
                axi_if.s.ARREADY = 1'b0;
            default:
                axi_if.s.ARREADY = 1'b1;
        endcase : ar_state

        case (r_state)
            OCCUPIED:
                axi_if.s.RVALID = 1'b1;
            default:
                axi_if.s.RVALID = 1'b0;
        endcase : r_state
    end : FSMOutputBlock

    always_ff @( posedge clk or negedge rst_n ) begin : LogicBlock
        begin
            case (ar_state)
                READY:
                if(axi_if.s.ARVALID) begin
                    ar_state_next <= OCCUPIED;
                    r_state_next  <= OCCUPIED;
                    ARID <= axi.s.ARID;
                    ARADDR <= axi.s.ARADDR;
                    ARLEN <= axi.s.ARLEN;
                    ARSIZE <= axi.s.ARSIZE;
                    ARBURST <= axi.s.ARBURST;
                end 
                default: // OCCUPIED
            endcase : ar_state
            case (r_state)
                OCCUPIED: 
                begin
                    // Read logic
                    axi_if.s.RDATA <= ram[ARADDR];
                    if(axi_if.s.RREADY) begin
                        if((ARLEN & 8'hFE) == 8'h00) begin
                            r_state_next <= READY;
                            ar_state_next <= READY;
                            axi_f.s.RLAST <= 1'b1;
                        end
                        // Address shift logic
                        case (ARBURST)
                            2'b01: ARADDR <= ARADDR + ARSIZE;
                            2'b10: begin
                                if(ARADDR + ARSIZE > 2**ADDR_WIDTH-1)
                                    ARADDR <= ARSIZE + ARADDR - 2*ADDR_WIDTH-1;
                                else
                                    ARADDR <= ARADDR + ARSIZE;
                            end
                            default: 
                        endcase
                    end
                end
                default: begin // READY
                    axi_if.s.RDATA <= '0;
                    axi_f.s.RLAST <= 1'b0;
                end
            endcase : r_state
            case (aw_state)
                READY:
                if(axi_if.s.AWVALID) begin
                    aw_state_next <= OCCUPIED;
                    AWID <= axi.s.AWID;
                    AWADDR <= axi.s.AWADDR;
                    AWLEN <= axi.s.AWLEN;
                    AWSIZE <= axi.s.AWSIZE;
                    AWBURST <= axi.s.AWBURST;
                end 
                default: // OCCUPIED
            endcase : aw_state
            case (w_state)
                READY:
                if(aw_state == OCCUPIED && axi.s.WVALID) begin
                    if((AWLEN & 8'hFE) == 8'h00 || axi_f.s.WLAST) begin
                        w_state_next <= OCCUPIED;
                        b_state_next <= OCCUPIED;
                    end
                    // Write logic
                    for (localparam i = 0; i < AWSIZE; i = i + 1) begin
                        if(WSTRB[i])
                            ram[AWADDR + i] <= axi.s.WDATA[8*(i+1)-1:8*i];
                    end
                    // Address shift logic
                    case (AWBURST)
                        2'b01: AWADDR <= AWADDR + AWSIZE;
                        2'b10: begin
                            if(AWADDR + AWSIZE > 2**ADDR_WIDTH-1)
                                AWADDR <= AWSIZE + AWADDR - 2*ADDR_WIDTH-1;
                            else
                                AWADDR <= AWADDR + AWSIZE;
                        end
                        default: 
                    endcase
                end
                default: // OCCUPIED
            endcase : w_state
            case (b_state)
                OCCUPIED: begin
                    if(axi_if.s.BREADY) begin
                        b_state_next <= READY;
                        aw_state_next <= READY;
                    end
                    axi_if.s.BID <= AWID;
                end
                default: // READY
                    axi_if.s.BID <= '0;
            endcase : b_state
        end
    end : LogicBlock

endmodule : axi_ram
