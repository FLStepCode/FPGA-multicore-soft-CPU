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
    ram_if.m ram_ports,
    axi_if.s axi_s

);

    enum { READING_ADDRESS, REQUESTING_DATA, RESPONDING }
    r_state, r_state_next,
    w_state,  w_state_next;

    localparam bytewise_width = DATA_WIDTH/8;
    logic [7:0] bytewise_RDATA [bytewise_width-1:0];
    logic [7:0] bytewise_WDATA [bytewise_width-1:0];

    generate
        genvar gen_i, gen_j;
        for (gen_i = 0; gen_i < bytewise_width; gen_i++) begin : i_bytewise_generate_block
            for (gen_j = 0; gen_j < 8; gen_j++) begin : j_bytewise_generate_block
                assign axi_s.RDATA[gen_i*8 + gen_j] = bytewise_RDATA[gen_i][gen_j];
                assign bytewise_WDATA[gen_i][gen_j] = axi_s.WDATA[gen_i*8 + gen_j];
            end
        end
    endgenerate

    // AR channel 
    logic [ID_W_WIDTH-1:0] ARID;
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0] ARLEN;
    logic [bytewise_width-1:0] ARSIZE;
    logic [bytewise_width-1:0] ARSIZE_CUR;
    logic [1:0] ARBURST;

    // AW channel 
    logic [ID_W_WIDTH-1:0] AWID;
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0] AWLEN;
    logic [bytewise_width-1:0] AWSIZE;
    logic [bytewise_width-1:0] AWSIZE_CUR;
    logic [(DATA_WIDTH/8)-1:0] WSTRB;
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
        ram_ports.addr_a = ARADDR;
        axi_s.RLAST = 1'b0;
        axi_s.RID = ARID;
        ram_ports.write_en_a = 1'b0;
        ram_ports.write_a = '0;

        case (r_state)
            READING_ADDRESS: begin
                r_state_next = READING_ADDRESS;
                axi_s.ARREADY = 1'b1;
                if(axi_s.ARVALID)
                    r_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA: begin  
                r_state_next = REQUESTING_DATA;
                if(ARSIZE_CUR == ARSIZE) begin
                    r_state_next = RESPONDING;
                end
            end
            RESPONDING: begin
                r_state_next = RESPONDING;
                axi_s.RVALID = 1'b1;
                if(axi_s.RREADY) begin
                    r_state_next = REQUESTING_DATA;
                end
                if(ARLEN == 8'o0) begin
                    axi_s.RLAST = 1'b1;
                    if(axi_s.RREADY)
                        r_state_next = READING_ADDRESS;
                end
            end
            default:;
        endcase
        
        axi_s.AWREADY = 1'b0;
        axi_s.WREADY = 1'b0;
        w_state_next = READING_ADDRESS;
        ram_ports.write_en_b = 1'b0;
        ram_ports.addr_b = AWADDR;
        ram_ports.write_b = bytewise_WDATA[AWSIZE_CUR];
        axi_s.BID = AWID;
        axi_s.BVALID = 1'b0;

        case (w_state)
            READING_ADDRESS: begin
                w_state_next = READING_ADDRESS;
                axi_s.AWREADY = 1'b1;
                if(axi_s.AWVALID)
                    w_state_next = REQUESTING_DATA;
            end
            REQUESTING_DATA: begin
                w_state_next = REQUESTING_DATA;
                if(axi_s.WVALID) begin
                    ram_ports.write_en_b = WSTRB[AWSIZE_CUR];
                    if(AWSIZE_CUR == AWSIZE-1'b1) begin
                        if(AWLEN == 1'b0 || axi_s.WLAST) begin
                            w_state_next = RESPONDING;
                        end else begin
                            axi_s.WREADY = 1'b1;
                        end
                    end
                end
            end
            RESPONDING: begin
                w_state_next = RESPONDING;
                axi_s.BVALID = 1'b1;
                if(axi_s.BREADY)
                    w_state_next = REQUESTING_DATA;
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
                ARSIZE <= 1'b1 << axi_s.ARSIZE;
                ARBURST <= axi_s.ARBURST;
            end
            REQUESTING_DATA: begin
                if(ARSIZE_CUR != 1'b0)
                    bytewise_RDATA[ARSIZE_CUR-1] <= ram_ports.data_a;
                ARSIZE_CUR <= ARSIZE_CUR + 1'b1;
                if(ARSIZE_CUR == ARSIZE) begin
                    ARSIZE_CUR <= 1'b1;
                    ARLEN <= ARLEN - 1'b1;
                end
                // Address shift logic
                case (ARBURST)
                    2'b01: ARADDR <= ARADDR + ARSIZE;
                    2'b10: begin
                        if(ARADDR + ARSIZE > 2**ADDR_WIDTH-1)
                            ARADDR <= ARSIZE + ARADDR - 2**ADDR_WIDTH-1;
                        else
                            ARADDR <= ARADDR + ARSIZE;
                    end
                endcase
                RESPONDING: begin
                    if(axi_s.RREADY)
                        for(int i = 0; i < bytewise_width; i++)
                            bytewise_RDATA[i] <= '0;
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
                WSTRB <= axi_s.WSTRB;
                AWBURST <= axi_s.AWBURST;
            end
            REQUESTING_DATA: begin
                if(axi_s.RVALID) begin
                    AWSIZE_CUR <= AWSIZE_CUR + 1'b1;
                    if(AWSIZE_CUR == AWSIZE - 1'b1) begin
                        AWSIZE_CUR <= '0;
                        AWLEN <= AWLEN - 1'b1;
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
                    endcase
                end
            end
            default:;
        endcase

    end
    end : LogicBlock

endmodule : axi2ram
