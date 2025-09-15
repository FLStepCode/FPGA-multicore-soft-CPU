module axi_ram
#(
    parameter ID_W_WIDTH = 4,
    parameter ID_R_WIDTH = 4,
    parameter ADDR_WIDTH = 32,
    
    parameter DATA_WIDTH = 32
)
(
	input clk, rst_n,
    ram_if_m ram_ports,
    axi_if.s axi_s

);

    enum { READING_ADDRESS, REQUESTING_DATA }
    r_state, r_state_next;
    enum { READING_ADDRESS, REQUESTING_DATA, RESPONDING }
    w_state,  w_state_next;

    localparam bytewise_width = DATA_WIDTH/8;
    logic [7:0] bytewise_RDATA [2:0];
    logic [7:0] bytewise_WDATA [2:0];

    generate
        genvar gen_i, gen_j;
        for (gen_i = 0; gen_i < bytewise_width; gen_i++) begin
            for (gen_j = 0; gen_j < 8; gen_j++) begin
                assign axi_s.RDATA[gen_i*8 + gen_j] = bytewise_RDATA[gen_i][gen_j];
                assign bytewise_WDATA[gen_i][gen_j] = axi_s.WDATA[gen_i*8 + gen_j];
            end
        end
    endgenerate

    // AR channel 
    logic [ID_W_WIDTH-1:0] ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0] ARLEN;
    logic [2:0] ARSIZE;
    logic [2:0] ARSIZE_CUR;
    logic [1:0] ARBURST;

    // AW channel 
    logic [ID_W_WIDTH-1:0] AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0] AWLEN;
    logic [2:0] AWSIZE;
    logic [2:0] AWSIZE_CUR;
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

        axi_s.ARREADY = 1'b0;
        axi_s.RVALID = 1'b0;
        r_state_next = READING_ADDRESS;
        ram_ports.addr_a = '0;
        axi_s.RDATA = '0;
        axi_s.RLAST = 1'b0;

        case (r_state)
            READING_ADDRESS: begin
                axi_s.ARREADY = 1'b1;
                if(axi_s.ARVALID)
                    r_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA: begin
                ram_ports.addr_a = ARADDR;
                r_state_next = READING_DATA;
                axi_s.RVALID = 1'b1;
                if (ARLEN == 8'b0) begin
                    axi_s.RLAST = 1'b1;
                    if(ARSIZE_CUR == ARSIZE - 1'b1 || ARLEN == 8'b0) begin
                        r_state_next = READING_ADDRESS;
                    end
                end
            end
            default:
        endcase
        
        axi_s.WRREADY = 1'b0;
        axi_s.WREADY = 1'b0;
        w_state_next = READING_ADDRESS;
        ram_ports.write_en_b = 1'b0;
        ram_ports.addr_b = '0;
        ram_ports.write_b = '0;

        case (w_state)
            READING_ADDRESS: begin
                axi_s.WREADY = 1'b1;
                if(axi_s.WRVALID)
                    w_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA: begin
            end
            default:
        endcase

    end : FSMOutputBlock

    always_ff @( posedge clk or negedge rst_n ) begin : LogicBlock
    if(!rst_n) begin
        ARID <= '0;
        ARADDR <= '0;
        ARLEN <= '0;
        ARSIZE <= '0;
        ARSIZE_CUR <= '0;
        ARBURST <= '0;

        AWID <= '0;
        AWADDR <= '0;
        AWLEN <= '0;
        AWSIZE <= '0;
        AWSIZE_CUR <= '0;
        AWBURST <= '0;

    end else begin
        case (r_state)
            READING_ADDRESS: begin
                ARID <= axi_s.ARID;
                ARADDR <= axi_s.ARADDR;
                ARLEN <= axi_s.ARLEN;
                ARSIZE <= axi_s.ARSIZE;
                ARBURST <= axi_s.ARBURST;
            end
            REQUESTING_DATA: begin
                axi_s.RDATA = ram_ports.data_a;
                ARSIZE_CUR <= ARSIZE_CUR + 1'b1;
                if(ARSIZE_CUR == ARSIZE - 1'b1) begin
                    ARSIZE_CUR <= '0;
                    ARLEN <= ARLEN - 1'b1;
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
                endcase
                if(axi_s.s.RREADY) begin
                    ARSIZE_CUR <= ARSIZE_CUR + 1'b1;
                    if(ARSIZE_CUR == ARSIZE - 1'b1) begin
                        ARSIZE_CUR <= '0;
                        ARLEN <= ARLEN - 1'b1;
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
                    endcase
                end
            end
            default: 
        endcase

        case (w_state)
            READING_ADDRESS: begin
                AWID <= axi_s.AWID;
                AWADDR <= axi_s.AWADDR;
                AWLEN <= axi_s.AWLEN;
                AWSIZE <= axi_s.AWSIZE;
                AWBURST <= axi_s.AWBURST;
            end
            REQUESTING_DATA: begin
                if(axi_s.s.RREADY) begin
                    ARSIZE_CUR <= ARSIZE_CUR + 1'b1;
                    if(ARSIZE_CUR == ARSIZE - 1'b1) begin
                        ARSIZE_CUR <= '0;
                        ARLEN <= ARLEN - 1'b1;
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
                    endcase
                end
            end
            default: 
        endcase

    end
    end : LogicBlock

endmodule : axi_ram
