module queue #(
    parameter DATA_WIDTH = 32,
    `ifndef USE_LIGHT_STREAM
    parameter ID_WIDTH = 4,
    parameter DEST_WIDTH = 4,
    parameter USER_WIDTH = 4,
    `endif
    parameter BUFFER_LENGTH = 4
) (
    input clk, rst_n,
    axis_if.s in,
    axis_if.m out
);

    typedef struct packed {
        logic [DATA_WIDTH-1:0] TDATA;
        
        `ifndef USE_LIGHT_STREAM
        logic [(DATA_WIDTH/8)-1:0] TSTRB;
        logic [(DATA_WIDTH/8)-1:0] TKEEP;
        logic TLAST;
        logic [ID_WIDTH-1:0] TID;
        logic [DEST_WIDTH-1:0] TDEST;
        logic [DEST_WIDTH-1:0] TUSER;
        `endif

    } stored_axis_t;

    localparam buffer_width = 2**$clog2($bits(stored_axis_t));

    logic [buffer_width-1:0] queue_buffers [BUFFER_LENGTH];
    stored_axis_t stored_axis_r, stored_axis_w;

    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_write;
    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_read;

    logic yes_data;

    always_comb begin
        stored_axis_r = queue_buffers[ptr_read];

        stored_axis_w.TDATA = in.TDATA;

        `ifndef USE_LIGHT_STREAM
        stored_axis_w.TSTRB = in.TSTRB;
        stored_axis_w.TKEEP = in.TKEEP;
        stored_axis_w.TLAST = in.TLAST;
        stored_axis_w.TID   = in.TID;
        stored_axis_w.TDEST = in.TDEST;
        stored_axis_w.TUSER = in.TUSER;
        `endif

    end

    always_ff @(posedge clk) begin
        out.TDATA <= stored_axis_r.TDATA;

        `ifndef USE_LIGHT_STREAM 
        out.TSTRB <= stored_axis_r.TSTRB;
        out.TKEEP <= stored_axis_r.TKEEP;
        out.TLAST <= stored_axis_r.TLAST;
        out.TID   <= stored_axis_r.TID;
        out.TDEST <= stored_axis_r.TDEST;
        out.TUSER <= stored_axis_r.TUSER;
        `endif

        out.TVALID <= yes_data;
    end

    always_ff @(posedge clk or negedge rst_n)
    begin
        if(!rst_n) begin
            ptr_write <= '0;
            ptr_read <= '0;
            in.TREADY <= 1'b1;
            yes_data <= 0;
        end else begin
            if(in.TVALID && in.TREADY) begin
                queue_buffers[ptr_write] <= stored_axis_w;
                ptr_write = (ptr_write + 1'b1) % BUFFER_LENGTH;
                yes_data <= 1'b1;
            end
            if(out.TREADY && yes_data) begin
                ptr_read = (ptr_read + 1'b1) % BUFFER_LENGTH;
                in.TREADY <= 1'b1;
            end
            if(in.TVALID && in.TREADY) begin
                if(ptr_write == ptr_read) begin
                    in.TREADY <= 1'b0;
                end
            end
            if(out.TREADY && yes_data) begin
                if(ptr_write == ptr_read) begin
                    yes_data <= 1'b0;
                end
            end
        end
    end

endmodule
