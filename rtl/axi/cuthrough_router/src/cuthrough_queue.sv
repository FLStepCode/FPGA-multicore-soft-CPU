module queue #(
    parameter DATA_WIDTH = 32
    `ifdef TID_PRESENT
    ,
    parameter ID_WIDTH = 4
    `endif
    `ifdef TDEST_PRESENT
    ,
    parameter DEST_WIDTH = 4
    `endif
    `ifdef TUSER_PRESENT
    ,
    parameter USER_WIDTH = 4
    `endif
    ,
    parameter BUFFER_LENGTH = 16
) (
    input clk, rst_n,
    axis_if.s in,
    axis_if.m out
    output logic half_full
);

    typedef struct packed {
        logic [DATA_WIDTH-1:0] TDATA;
        
        `ifdef TSTRB_PRESENT
        logic [(DATA_WIDTH/8)-1:0] TSTRB;
        `endif
        `ifdef TKEEP_PRESENT
        logic [(DATA_WIDTH/8)-1:0] TKEEP;
        `endif
        `ifdef TLAST_PRESENT
        logic TLAST;
        `endif
        `ifdef TID_PRESENT
        logic [ID_WIDTH-1:0] TID;
        `endif
        `ifdef TDEST_PRESENT
        logic [DEST_WIDTH-1:0] TDEST;
        `endif
        `ifdef TUSER_PRESENT
        logic [USER_WIDTH-1:0] TUSER;
        `endif

    } stored_axis_t;

    stored_axis_t queue_buffers [BUFFER_LENGTH];
    stored_axis_t stored_axis_r, stored_axis_w;

    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_write;
    logic [$clog2(BUFFER_LENGTH)-1:0] ptr_read;

    localparam HALF_WAY_POINT = BUFFER_LENGTH/2;

    logic yes_data;

    logic [$clog2(BUFFER_LENGTH):0] distance;

    always_comb begin
        stored_axis_r = queue_buffers[ptr_read];

        stored_axis_w.TDATA = in.TDATA;

        `ifdef TSTRB_PRESENT
        stored_axis_w.TSTRB = in.TSTRB;
        `endif
        `ifdef TKEEP_PRESENT
        stored_axis_w.TKEEP = in.TKEEP;
        `endif
        `ifdef TLAST_PRESENT
        stored_axis_w.TLAST = in.TLAST;
        `endif
        `ifdef TID_PRESENT
        stored_axis_w.TID   = in.TID;
        `endif
        `ifdef TDEST_PRESENT
        stored_axis_w.TDEST = in.TDEST;
        `endif
        `ifdef TUSER_PRESENT
        stored_axis_w.TUSER = in.TUSER;
        `endif

    end

    always_ff @(posedge clk) begin
        out.TDATA <= stored_axis_r.TDATA;

        `ifdef TSTRB_PRESENT 
        out.TSTRB <= stored_axis_r.TSTRB;
        `endif
        `ifdef TKEEP_PRESENT
        out.TKEEP <= stored_axis_r.TKEEP;
        `endif
        `ifdef TLAST_PRESENT
        out.TLAST <= stored_axis_r.TLAST;
        `endif
        `ifdef TID_PRESENT
        out.TID   <= stored_axis_r.TID;
        `endif
        `ifdef TDEST_PRESENT
        out.TDEST <= stored_axis_r.TDEST;
        `endif
        `ifdef TUSER_PRESENT
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

    always_comb begin
        distance = ptr_write - ptr_read;
        if(distance[$clog2(BUFFER_LENGTH)]) begin
            distance = ~distance;
            distance = distance + 1'b1;
        end

        half_full = distance > HALF_WAY_POINT;
    end

endmodule
