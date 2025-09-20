module tb_queue(
    input clk, rst_n,
    input m_TVALID, s_TREADY,
    input [32-1:0] m_TDATA,
    output s_TVALID, m_TREADY,
    output [32-1:0] s_TDATA
);

    axis_if axis_in(), axis_out();

    assign axis_in.TVALID = m_TVALID;
    assign axis_in.TDATA = m_TDATA;
    assign m_TREADY = axis_in.TREADY;
 
    assign s_TVALID = axis_out.TVALID;
    assign s_TDATA = axis_out.TDATA;
    assign axis_out.TREADY = s_TREADY;
    
    queue queue_name(clk, rst_n, axis_in, axis_out);

endmodule