module packet_collector #( 
    parameter int NODE_COUNT = 8,
    parameter int PACKET_ID_WIDTH = 5,
    parameter int BUFFER_SIZE = 8
)(
    input  logic clk, rst_n, ce,
    input  logic [1 + 2*$clog2(NODE_COUNT) + PACKET_ID_WIDTH + 17 + 2 - 1:0] input_data,
    output logic collector_ready,

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
        logic [16:0] data[0:3];
        logic [0:3] received_mask;
        logic [31:0] timestamp;
        logic [NODE_W-1:0] node_start;
        logic [NODE_W-1:0] node_dest;
        logic [ID_W-1:0] packet_id;
        logic valid;
    } packet_entry_t;

    packet_entry_t buffer[BUFFER_SIZE];
    logic [31:0] global_time;

    logic [1 + 2*$clog2(NODE_COUNT) + PACKET_ID_WIDTH + 17 + 2 - 1:0] input_data_ff;

    // Распаковка флита
    wire valid_bit_comb;
    wire [NODE_W-1:0] node_dest_comb;
    wire [16:0]        data_byte_comb;
    wire [ID_W-1:0]   packet_id_comb;
    wire [NODE_W-1:0] node_start_comb;
    wire [1:0]        byte_index_comb;

    wire valid_bit;
    wire [NODE_W-1:0] node_dest;
    wire [16:0]        data_byte;
    wire [ID_W-1:0]   packet_id;
    wire [NODE_W-1:0] node_start;
    wire [1:0]        byte_index;

    assign {valid_bit_comb, node_dest_comb, data_byte_comb, packet_id_comb, node_start_comb, byte_index_comb} = input_data;
    assign {valid_bit, node_dest, data_byte, packet_id, node_start, byte_index} = input_data_ff;
   
    
    integer i, j;
    logic [5:0] match_index, replace_index;
    logic match_found, free_found;
    logic [2:0] min_count;
    logic [31:0] min_time;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < BUFFER_SIZE; i++) buffer[i].valid <= 0;
            global_time <= 0;
            valid_out <= 0;
            collector_ready <= 1;
            match_found <= 0;
            match_index <= 0;
            free_found <= 0;
            replace_index <= 0;
            input_data_ff <= 68'd0;
        end else if (ce) begin
            valid_out <= 0;
            global_time <= global_time + 1;
            
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
            

            free_found <= 0;
            match_found <= 0;

            if (valid_bit_comb && collector_ready) begin
                input_data_ff <= input_data;
                collector_ready <= 0;

                for (i = 0; i < BUFFER_SIZE; i++) begin
                    if (!buffer[i].valid) begin
                        if (i != replace_index) begin
                            replace_index <= i;
                            free_found <= 1;
                            collector_ready <= 1;
                        end
                    end
                end
                for (i = 0; i < BUFFER_SIZE; i++) begin
                    if (buffer[i].valid &&
                        buffer[i].node_start == node_start_comb &&
                        buffer[i].packet_id == packet_id_comb) begin
                        match_index <= i;
                        match_found <= 1;
                        free_found <= 0;
                        collector_ready <= 1;
                    end
                end
                if (free_found && node_start_comb == node_start && packet_id_comb == packet_id) begin
                    match_found <= 1;
                    match_index <= replace_index;
                    free_found <= 0;
                end
            end
            else if (!collector_ready) begin

                for (i = 0; i < BUFFER_SIZE; i++) begin
                    if (buffer[i].valid &&
                        buffer[i].node_start == node_start &&
                        buffer[i].packet_id == packet_id) begin
                        match_index <= i;
                        match_found <= 1;
                        free_found <= 0;

                        collector_ready <= 1;
                    end
                    else if (!buffer[i].valid) begin
                        if (i != replace_index) begin
                            replace_index <= i;
                            free_found <= 1;
                            collector_ready <= 1;
                        end
                    end
                end

            end
            
            if (valid_bit) begin

                if (match_found) begin
                    buffer[match_index].data[byte_index] <= data_byte;
                    buffer[match_index].received_mask[byte_index] <= 1'b1;
                    buffer[match_index].timestamp <= global_time;
                end
                else if (free_found) begin
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