module stream_fifo #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_LEN = 16,
    localparam ADDR_WIDTH = $clog2(FIFO_LEN)
) (
    input logic ACLK,
    input logic ARESETn,
    
    input logic [DATA_WIDTH-1:0] data_i,
    input logic valid_i,
    output logic ready_o,

    output logic [DATA_WIDTH-1:0] data_o,
    output logic valid_o,
    input logic ready_i
    
);

    logic [DATA_WIDTH-1:0] fifo_mem [FIFO_LEN];
    logic [ADDR_WIDTH-1:0] read_ptr, read_ptr_reg;
    logic [ADDR_WIDTH-1:0] write_ptr;
    logic [ADDR_WIDTH:0] count;

    assign ready_o = (count < FIFO_LEN);

    always @(posedge ACLK) begin
        if (valid_i && ready_o) begin
            fifo_mem[write_ptr] <= data_i;
        end
    end
    
    always @(posedge ACLK) begin
        data_o <= fifo_mem[read_ptr];
    end

    always_comb begin
        read_ptr = read_ptr_reg;
        if ((count > 0) && ready_i) begin
            read_ptr = (read_ptr_reg == (FIFO_LEN - 1)) ? 0 : read_ptr_reg + 1;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_ptr_reg <= 0;
            write_ptr <= 0;
        end
        else begin
            if (valid_i && ready_o) begin
                write_ptr <= (write_ptr == (FIFO_LEN - 1)) ? 0 : write_ptr + 1;
            end

            read_ptr_reg <= read_ptr;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            count <= 0;
			valid_o <= 0;
        end
        else begin
		    valid_o <= (count > 0) ? 1 : 0;
				
            if ((valid_i && ready_o) && !(valid_o && ready_i)) begin
                count <= count + 1;
            end

            if (!(valid_i && ready_o) && (valid_o && ready_i)) begin
                count <= count - 1;
		        valid_o <= (count - 1 > 0) ? 1 : 0;
            end
        end
    end
    
endmodule