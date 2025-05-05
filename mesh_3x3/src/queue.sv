`include "mesh_3x3/inc/queue.svh"

module queue (
    input clk, rst_n,
    input[0:`PL-1] data_in,
    input shift_signal,
    output wire[0:`PL-1] data_out,
    output reg availability_signal = 1

);

    integer i;

    reg[0:`PL-1] queue_buffers[0:`EN-1];
    reg[`EN_B:0] ptr_write = 0;
    reg[`EN_B:0] ptr_read = 0;
    reg empty_flag = 1;

    initial
    begin
        int i;
        for (i = 0; i < `EN; i = i + 1) // initialize queue at 0
        begin
            queue_buffers[i] = 0;
        end
    end

    assign data_out = empty_flag ? 0 : queue_buffers[ptr_read];

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            for (i = 0; i < `EN; i++)
            begin
                queue_buffers[i] <= 0;
            end
            ptr_write <= 0;
            ptr_read <= 0;
            empty_flag <= 1;
            availability_signal <= 1;
        end
        else
        begin
            casez({data_in[0], availability_signal, shift_signal, empty_flag})
                4'b110? : begin
                    queue_buffers[ptr_write] <= data_in;
                    ptr_write <= (ptr_write + 1) % `EN;
                    availability_signal <= ((ptr_write + 1) % `EN) != ptr_read;
                    empty_flag <= 0;
                end
                4'b1110 : begin
                    queue_buffers[ptr_write] <= data_in;
                    ptr_write <= (ptr_write + 1) % `EN;
                    ptr_read <= (ptr_read + 1) % `EN;
                end
                4'b1111 : begin
                    queue_buffers[ptr_write] <= data_in;
                    ptr_write <= (ptr_write + 1) % `EN;
                    empty_flag <= 0;
                end
                4'b1010 : begin
                    ptr_read <= (ptr_read + 1) % `EN;
                    availability_signal <= 1;
                    empty_flag <= ptr_write == ((ptr_read + 1) % `EN);
                end
                4'b0?10 : begin
                    ptr_read <= (ptr_read + 1) % `EN;
                    availability_signal <= 1;
                    empty_flag <= ptr_write == ((ptr_read + 1) % `EN);
                end
                default: begin
                end
            endcase
        end

    end

endmodule
