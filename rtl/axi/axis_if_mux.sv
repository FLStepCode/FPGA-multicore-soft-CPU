module axis_if_mux #(
    parameter CHANNEL_NUMBER = 5,
    parameter CHANNEL_NUMBER_WIDTH = $clog2(CHANNEL_NUMBER),
    parameter DATA_WIDTH = 32
    `ifndef USE_LIGHT_STREAM
    ,
    parameter ID_WIDTH = 4,
    parameter DEST_WIDTH = 4,
    parameter USER_WIDTH = 4
    `endif
) (
    axis_if.s in [CHANNEL_NUMBER],
    input logic en,
    input logic [CHANNEL_NUMBER_WIDTH-1:0] ctrl,
    axis_if.m out
);
    // T channel 
    logic TVALID [CHANNEL_NUMBER];
    logic TREADY [CHANNEL_NUMBER];
    logic [DATA_WIDTH-1:0] TDATA [CHANNEL_NUMBER];
    
    `ifndef USE_LIGHT_STREAM
    logic [(DATA_WIDTH/8)-1:0] TSTRB [CHANNEL_NUMBER];
    logic [(DATA_WIDTH/8)-1:0] TKEEP [CHANNEL_NUMBER];
    logic TLAST [CHANNEL_NUMBER];
    logic [ID_WIDTH-1:0] TID [CHANNEL_NUMBER];
    logic [DEST_WIDTH-1:0] TDEST [CHANNEL_NUMBER];
    logic [DEST_WIDTH-1:0] TUSER [CHANNEL_NUMBER];
    `endif

    generate
        genvar i;
        for (i = 0; i < CHANNEL_NUMBER; i++) begin : interface_deassembler
            
            assign in[i].TREADY = TREADY[i];

            // T channel 
            assign TVALID[i] = in[i].TVALID;
            assign TDATA [i] = in[i].TDATA;
            
            `ifndef USE_LIGHT_STREAM
            assign TSTRB[i] = in[i].TSTRB;
            assign TKEEP[i] = in[i].TKEEP;
            assign TLAST[i] = in[i].TLAST;
            assign TID[i]   = in[i].TID;
            assign TDEST[i] = in[i].TDEST;
            assign TUSER[i] = in[i].TUSER;
            `endif
            
        end
    endgenerate

    always_comb begin

        // T channel 
        out.TVALID = '0;
        out.TDATA  = '0;
        
        `ifndef USE_LIGHT_STREAM
        out.TSTRB = '0;
        out.TKEEP = '0;
        out.TLAST = '0;
        out.TID =   '0;
        out.TDEST = '0;
        out.TUSER = '0;
        `endif

        for(int i = 0; i < CHANNEL_NUMBER; i++)
            TREADY[i] = '0;

        if(en) begin
            
            // T channel 
            out.TVALID = TVALID[ctrl];
            out.TDATA  = TDATA[ctrl];
            
            `ifndef USE_LIGHT_STREAM
            out.TSTRB = TSTRB[ctrl];
            out.TKEEP = TKEEP[ctrl];
            out.TLAST = TLAST[ctrl];
            out.TID =   TID[ctrl];
            out.TDEST = TDEST[ctrl];
            out.TUSER = TUSER[ctrl];
            `endif

            TREADY[ctrl] = out.TREADY;
        end

    end

endmodule