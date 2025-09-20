interface axis_if #(
    parameter DATA_WIDTH = 32
    `ifndef USE_LIGHT_STREAM
    ,
    parameter ID_WIDTH = 4,
    parameter DEST_WIDTH = 4,
    parameter USER_WIDTH = 4
    `endif
) ();

    // T channel 
    logic TVALID;
    logic TREADY;
    logic [DATA_WIDTH-1:0] TDATA;
    
    `ifndef USE_LIGHT_STREAM
    logic [(DATA_WIDTH/8)-1:0] TSTRB;
    logic [(DATA_WIDTH/8)-1:0] TKEEP;
    logic TLAST;
    logic [ID_WIDTH-1:0] TID;
    logic [DEST_WIDTH-1:0] TDEST;
    logic [DEST_WIDTH-1:0] TUSER;
    `endif

    modport m (
        input TREADY,
        output TVALID, TDATA

        `ifndef USE_LIGHT_STREAM
        , output TSTRB, TKEEP, TLAST, TID, TDEST, TUSER
        `endif
    );

    modport s (
        input TVALID, TDATA,
        output TREADY

        `ifndef USE_LIGHT_STREAM
        , input TSTRB, TKEEP, TLAST, TID, TDEST, TUSER
        `endif
    );
    
    
endinterface