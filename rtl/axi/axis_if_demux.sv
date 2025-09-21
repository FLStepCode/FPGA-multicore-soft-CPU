module axis_if_demux #(
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
    axis_if.s in,
    input logic en,
    input logic [CHANNEL_NUMBER_WIDTH-1:0] ctrl,
    axis_if.m out [CHANNEL_NUMBER]
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
            
            assign TREADY[i] = out[i].TREADY;

            // T channel 
            assign out[i].TVALID = TVALID[i];
            assign out[i].TDATA  = TDATA[i];
            
            `ifndef USE_LIGHT_STREAM
            assign out[i].TSTRB = TSTRB[i];
            assign out[i].TKEEP = TKEEP[i];
            assign out[i].TLAST = TLAST[i];
            assign out[i].TID   = TID[i];
            assign out[i].TDEST = TDEST[i];
            assign out[i].TUSER = TUSER[i];
            `endif
            
        end
    endgenerate

    always_comb begin

        in.TREADY = '0;

        for(int i = 0; i < CHANNEL_NUMBER; i++) begin
            TVALID[i] = '0;
            TDATA[i]  = '0;
        
            `ifndef USE_LIGHT_STREAM
            TSTRB[i] = '0;
            TKEEP[i] = '0;
            TLAST[i] = '0;
            TID[i] =   '0;
            TDEST[i] = '0;
            TUSER[i] = '0;
            `endif

        end

        if(en) begin

            in.TREADY = TREADY[ctrl];
            
            // T channel 
            TVALID[ctrl] = in.TVALID;
            TDATA[ctrl]  = in.TDATA;
            
            `ifndef USE_LIGHT_STREAM
            TSTRB[ctrl] = in.TSTRB;
            TKEEP[ctrl] = in.TKEEP;
            TLAST[ctrl] = in.TLAST;
            TID[ctrl] =   in.TID;
            TDEST[ctrl] = in.TDEST;
            TUSER[ctrl] = in.TUSER;
            `endif
				
        end

    end

endmodule