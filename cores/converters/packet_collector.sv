module packet_collector #( 
    parameter int NODE_COUNT = 8,
    parameter int PACKET_ID_WIDTH = 5,
    parameter int BUFFER_SIZE = 8
)(
    input  logic clk, rst_n, ce,
    input  logic [1 + 2*$clog2(NODE_COUNT) + PACKET_ID_WIDTH + 17 + 2 - 1:0] input_data,
    input  logic valid_in,

    output logic valid_out,
    output logic [67:0] packet_out,
    output logic [$clog2(NODE_COUNT)-1:0] node_start_out,
    output logic [$clog2(NODE_COUNT)-1:0] node_dest_out,
    output logic [PACKET_ID_WIDTH-1:0]    packet_id_out,
    input  logic send_signal
);

    localparam int NODE_W = $clog2(NODE_COUNT);
    localparam int ID_W   = PACKET_ID_WIDTH;

    typedef struct  {
        logic [16:0] data[4];
        logic [3:0] received_mask;
        logic [31:0] timestamp;
        logic [NODE_W-1:0] node_start;
        logic [NODE_W-1:0] node_dest;
        logic [ID_W-1:0] packet_id;
        logic valid;
    } packet_entry_t;

    packet_entry_t buffer[BUFFER_SIZE];
    logic [31:0] global_time;

    // Распаковка флита
    wire valid_bit = input_data[1 + 2*$clog2(NODE_COUNT) + PACKET_ID_WIDTH + 17 - 1 + 2];
    wire [NODE_W-1:0] node_dest  = input_data[2 * $clog2(NODE_COUNT) + PACKET_ID_WIDTH + 17 - 1 + 2: $clog2(NODE_COUNT) + PACKET_ID_WIDTH + 2 + 17];
    wire [1:0]        byte_index = input_data[1 : 0];
    wire [16:0]        data_byte  = input_data[17 + PACKET_ID_WIDTH - 1 + $clog2(NODE_COUNT) + 2 : PACKET_ID_WIDTH+ $clog2(NODE_COUNT) + 2];
    wire [ID_W-1:0]   packet_id  = input_data[$clog2(NODE_COUNT)  + PACKET_ID_WIDTH - 1 + 2 : 2 + $clog2(NODE_COUNT) ];
    wire [NODE_W-1:0] node_start = input_data[$clog2(NODE_COUNT)  + 2 - 1 :  2];
   
    
    integer i, j;
    logic [2:0] match_index, replace_index;
    logic match_found, free_found;
    logic [2:0] min_count;
    logic [31:0] min_time;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < BUFFER_SIZE; i++) buffer[i].valid <= 0;
            global_time <= 0;
            valid_out <= 0;
        end else if (ce && valid_in) begin
            valid_out <= 0;
            global_time <= global_time + 1;
            match_found = 0;
            free_found  = 0;
            
    `ifdef TEST_OUT
    $display("collector out: valid = %b node_start = %b node_finish = %b packet = %b packet_id = %d", valid_bit, node_start, node_dest, data_byte, packet_id);
    `endif
            if (send_signal) begin
                for (i = 0; i < BUFFER_SIZE; i++) begin
                    if (!valid_out && buffer[i].valid && (&buffer[i].received_mask))
                    begin
                        valid_out <= 1;
                        packet_out <= {buffer[i].data[0], buffer[i].data[1],
                                        buffer[i].data[2], buffer[i].data[3]};
                        node_start_out <= buffer[i].node_start;
                        node_dest_out  <= buffer[i].node_dest;
                        packet_id_out  <= packet_id;
                        for (j = 0; j < i; j = j + 1) begin
                            buffer[j].valid <= buffer[j].valid;
                        end
                        buffer[i].valid <= 0;
                    end
                end
            end
            if (valid_bit) begin
                for (i = 0; i < BUFFER_SIZE; i++) begin
                    if (buffer[i].valid &&
                        buffer[i].node_start == node_start &&
                        buffer[i].packet_id == packet_id) begin
                        match_index = i;
                        match_found = 1;
                    end
                end
                if (match_found) begin
                    buffer[match_index].data[byte_index] <= data_byte;
                    buffer[match_index].received_mask[byte_index] <= 1'b1;
                    buffer[match_index].timestamp <= global_time;

                    
                end else begin
                    for (i = 0; i < BUFFER_SIZE; i++) begin
                        if (!buffer[i].valid && !free_found) begin
                            replace_index = i;
                            free_found = 1;
                        end
                    end
                    if (!free_found) begin
                        min_count = 4;
                        min_time = 32'hFFFFFFFF;
                        for (i = 0; i < BUFFER_SIZE; i++) begin
                            logic [2:0] count;
                            count = 0;
                            for (int b = 0; b < 4; b++) begin
                                count += buffer[i].received_mask[b];
                            end
                            if (buffer[i].valid && count < min_count) begin
                                min_count = count;
                                min_time  = buffer[i].timestamp;
                                replace_index = i;
                            end else if (buffer[i].valid && count == min_count &&
                                        buffer[i].timestamp < min_time) begin
                                min_time = buffer[i].timestamp;
                                replace_index = i;
                            end
                        end
                    end

                    buffer[replace_index].valid           <= 1;
                    buffer[replace_index].received_mask   <= 0;
                    buffer[replace_index].data[byte_index]<= data_byte;
                    buffer[replace_index].received_mask[byte_index] <= 1;
                    buffer[replace_index].node_start      <= node_start;
                    buffer[replace_index].node_dest       <= node_dest;
                    buffer[replace_index].packet_id       <= packet_id;
                    buffer[replace_index].timestamp       <= global_time;
                end
            end
        end else begin
            valid_out <= 0;
        end
    end

endmodule