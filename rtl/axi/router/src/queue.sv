module queue #(
    parameter DATA_WIDTH = 32,
    parameter BUFFER_LENGTH = 4
) (
    input clk, rst_n,
    axis_if.s in,
    axis_if.m out
);

    logic [DATA_WIDTH-1:0] queue_buffers [0:BUFFER_LENGTH-1];
    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_write;
    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_read;

    always_ff @(posedge clk) begin
        out.TDATA <= queue_buffers[ptr_read];
    end

    always_ff @(posedge clk or negedge rst_n)
    begin
        if(!rst_n) begin
            ptr_write <= '0;
            ptr_read <= '0;
            in.TREADY <= 1'b1;
            out.TVALID <= 1'b0;
        end else begin
            if(in.TVALID && in.TREADY) begin
                queue_buffers[ptr_write] <= in.TDATA;
                ptr_write = (ptr_write + 1'b1) % BUFFER_LENGTH;
                out.TVALID <= 1'b1;
            end
            if(out.TREADY && out.TVALID) begin
                ptr_read = (ptr_read + 1'b1) % BUFFER_LENGTH;
                in.TREADY <= 1'b1;
            end
            if(in.TVALID && in.TREADY) begin
                if(ptr_write == ptr_read) begin
                    in.TREADY <= 1'b0;
                end
            end
            if(out.TREADY && out.TVALID) begin
                if(ptr_write == ptr_read) begin
                    out.TVALID <= 1'b0;
                end
            end
        end
    end

endmodule
