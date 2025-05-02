module sequential_traffic_generator #(parameter int NODE_ID, NODE_COUNT, PACKET_ID_WIDTH) (
    input  logic clk,
    input  logic rst_n,
    input  logic network_busy,
    input  logic [31:0] packet_in,
    output logic valid,
    output logic [31:0] packet,
    output logic [$clog2(NODE_COUNT)-1:0] node_dest,
    output logic [PACKET_ID_WIDTH-1:0] packet_id
);
    logic [$clog2(NODE_COUNT)-1:0] current_dest;
    logic [2:0] cycle_counter;
    logic [PACKET_ID_WIDTH-1:0] id;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 0;
            //packet <= 32'hDEADBEEF;
            packet <= packet_in;
            node_dest <= 0;
            current_dest <= (NODE_ID == 0) ? 1 : 0;
            id <= 0;
            cycle_counter <= 0;
        end else begin
            if (!network_busy) begin
                if (cycle_counter == 3'd7) begin
                    packet <= packet_in;
                    node_dest <= current_dest;
                    id <= id + 1;
                    valid <= 1;
                    current_dest <= ((current_dest + 1) % NODE_COUNT == NODE_ID) ?
                                    (current_dest + 2) % NODE_COUNT :
                                    (current_dest + 1) % NODE_COUNT;
                    cycle_counter <= 0;
                end else begin
                    valid <= 0;
                    cycle_counter <= cycle_counter + 1;
                end
            end else valid <= 0;
        end
    end
    
    assign packet_id = id;

endmodule


module gaussian_traffic_generator #(parameter int NODE_ID, NODE_COUNT, PACKET_ID_WIDTH, parameter int LN2_PERIOD = 4) (
    input  logic clk,
    input  logic rst_n,
    output logic valid,
    output logic [31:0] packet,
    output logic [$clog2(NODE_COUNT)-1:0] node_dest,
    output logic [PACKET_ID_WIDTH-1:0]    packet_id,

    input  logic[31:0] lfsr1_in, lfsr2_in, lfsr3_in, lfsr4_in
);
    logic [31:0] lfsr1, lfsr2, lfsr3, lfsr4;
    logic [LN2_PERIOD-1:0] sample;
    logic [31:0] gaussian_value;
    logic [PACKET_ID_WIDTH-1:0] id;
    parameter MASK = {LN2_PERIOD{1'b0}};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid       <= 0;
            packet      <= 0;
            node_dest   <= 0;
            id          <=0;
            lfsr1       <= lfsr1_in;
            lfsr2       <= lfsr2_in;
            lfsr3       <= lfsr3_in;
            lfsr4       <= lfsr4_in;
        end else begin
            lfsr1 <= {lfsr1[30:0], lfsr1[31] ^ lfsr1[21]};
            lfsr2 <= {lfsr2[30:0], lfsr2[31] ^ lfsr2[25]};
            lfsr3 <= {lfsr3[30:0], lfsr3[31] ^ lfsr3[18]};
            lfsr4 <= {lfsr4[30:0], lfsr4[31] ^ lfsr4[14]};
            sample <= lfsr1[LN2_PERIOD-1:0];
            gaussian_value <= (lfsr1 + lfsr2 + lfsr3 + lfsr4) >> 2;
            if (sample == MASK) begin
                packet      <= gaussian_value;
                node_dest   <= (lfsr1 % NODE_COUNT == NODE_ID) ? (lfsr1 + 1) % NODE_COUNT : lfsr1 % NODE_COUNT;
                valid       <= 1;
                id          <= id + 1;
            end else valid  <= 0;
        end
    end
    
    assign packet_id = id;    
    
endmodule