module splitter #(parameter int NODE_ID = 0, NODE_COUNT = 8, QUEUE_DEPTH = 8, parameter int PACKET_ID_WIDTH = 5) (
    input  logic clk, ce, rst_n,
    input  logic [67 : 0] packet_in,
    input  logic [$clog2(NODE_COUNT) - 1 : 0] node_dest,
    input  logic valid_in,
    input  logic [PACKET_ID_WIDTH - 1 : 0] packet_id,
    output logic [1 + 2*$clog2(NODE_COUNT) + 17 + PACKET_ID_WIDTH - 1 + 2 : 0] output_data,
    output logic valid_out
);

reg [$clog2(NODE_COUNT) - 1 : 0] node_dest_encoded;

logic [67 : 0] queue [0 : QUEUE_DEPTH - 1];
logic [$clog2(NODE_COUNT) - 1 : 0] node_queue [0 : QUEUE_DEPTH - 1];  
logic [PACKET_ID_WIDTH - 1 : 0] id_queue [0 : QUEUE_DEPTH - 1];
logic [3 : 0] byte_counter;
logic [$clog2(QUEUE_DEPTH) : 0] head, tail, count; 
logic [$clog2(NODE_COUNT) - 1 : 0] node_in;
assign node_in = NODE_ID[$clog2(NODE_COUNT) - 1 : 0];

always_comb
begin
    case (node_dest)
        0: node_dest_encoded = 4'b0000;
        1: node_dest_encoded = 4'b0100;
        2: node_dest_encoded = 4'b1000;
        3: node_dest_encoded = 4'b0001;
        4: node_dest_encoded = 4'b0101;
        5: node_dest_encoded = 4'b1001;
        6: node_dest_encoded = 4'b0010;
        7: node_dest_encoded = 4'b0110;
        8: node_dest_encoded = 4'b1010;
        default: node_dest_encoded = 4'b1111;
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        head <= 0;
        tail <= 0;
        count <= 0;
        byte_counter <= 0;
        valid_out <= 0;
        output_data <= 0;
    end else if (ce) begin
        if (valid_in && count < QUEUE_DEPTH) begin
            queue[tail] <= packet_in;
            node_queue[tail] <= node_dest_encoded;
            id_queue[tail]   <= packet_id;   
            tail <= (tail + 1) % QUEUE_DEPTH;
            count <= count + 1;
        end

        if (count > 0) begin
            case (byte_counter)
                4'b0000:  begin
                    output_data <= {1'b1, node_queue[head], queue[head][67:51], id_queue[head], node_in, byte_counter[1:0]};
                    `ifdef TEST_OUT
                        $display("valid = %b node_start = %b node_finish = %b packet = %b packet_id = %d", 1'b1, node_in, node_queue[head], queue[head][31:24], id_queue[head]);
                    `endif
                    end
                4'b0001: begin
                    output_data <= {1'b1, node_queue[head], queue[head][50:34], id_queue[head], node_in, byte_counter[1:0]};
                    `ifdef TEST_OUT
                        $display("valid = %b node_start = %b node_finish = %b packet = %b packet_id = %d",  1'b1, node_in, node_queue[head], queue[head][23:16], id_queue[head]);
                    `endif
                end
                4'b0010: begin
                    output_data <= {1'b1, node_queue[head], queue[head][33:17], id_queue[head], node_in, byte_counter[1:0]};
                    `ifdef TEST_OUT
                        $display("valid = %b node_start = %b node_finish = %b packet = %b packet_id = %d",  1'b1, node_in, node_queue[head], queue[head][15:8], id_queue[head]);
                    `endif
                    end 
                4'b0011: begin
                    output_data <= {1'b1, node_queue[head], queue[head][16:0], id_queue[head], node_in, byte_counter[1:0]};
                    `ifdef TEST_OUT
                            $display("valid = %b node_start = %b node_finish = %b packet = %b packet_id = %d", 1'b1, node_in, node_queue[head], queue[head][7:0], id_queue[head]);
                    `endif
                    head <= (head + 1) % QUEUE_DEPTH; 
                    if (valid_in && count < QUEUE_DEPTH) begin
                        count <= count;
                    end
                    else begin
                        count <= count - 1;
                    end
                end
            endcase

            valid_out <= 1;
            byte_counter <= (byte_counter == 4'b0011) ? 0 : byte_counter + 1;
        end else begin
            valid_out <= 0;
            output_data <= 0;
        end
    end
end

endmodule