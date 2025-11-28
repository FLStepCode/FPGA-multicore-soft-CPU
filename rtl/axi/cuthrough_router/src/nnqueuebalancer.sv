module nnbalancer #(
    parameter DATA_WIDTH          = 32
    `ifdef TID_PRESENT
    ,
    parameter ID_WIDTH            = 4
    `endif
    `ifdef TDEST_PRESENT
    ,
    parameter DEST_WIDTH          = 4
    `endif
    `ifdef TUSER_PRESENT
    ,
    parameter USER_WIDTH          = 4
    `endif
    ,
    parameter CHANNEL_NUMBER_IN   = 5,
    parameter CHANNEL_NUMBER_OUT  = 5
) (
    axis_if.s in  [CHANNEL_NUMBER_IN ],
    axis_if.m out [CHANNEL_NUMBER_OUT],

    input logic [CHANNEL_NUMBER_OUT-1:0] selector [CHANNEL_NUMBER_IN]

);

  logic [$clog2(CHANNEL_NUMBER_OUT)-1:0] out_iterator, in_iterator;
  logic [CHANNEL_NUMBER_IN] input_map_dst_source [CHANNEL_NUMBER_OUT];
  logic output_taken_map [CHANNEL_NUMBER_OUT];

  always_comb begin
    output_taken_map = '0;
    for (out_iterator = '0; out_iterator < CHANNEL_NUMBER_OUT; out_iterator++) begin
      for(in_iterator = '0; in_iterator != CHANNEL_NUMBER_IN || !output_taken_map[out_iterator]; in_iterator++) begin
        //
      end
    end
  end

  axis_if_mux;  
endmodule