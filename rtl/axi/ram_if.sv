interface ram_if #(
    parameter ADDR_WIDTH = 16,
    parameter BYTE_WIDTH = 8
) ();

    // Port a 
    logic [ADDR_WIDTH-1:0] addr_a;
    logic [BYTE_WIDTH-1:0] data_a;
    logic [BYTE_WIDTH-1:0] write_a;
    logic write_en_a;

    // Port b
    logic [ADDR_WIDTH-1:0] addr_b;
    logic [BYTE_WIDTH-1:0] data_b;
    logic [BYTE_WIDTH-1:0] write_b;
    logic write_en_b;

    modport m (
        // Port a 
        output addr_a, write_a, write_en_a,
        input data_a,

        // Port b
        output addr_b, write_b, write_en_b,
        input data_b
    );

    modport s (
        // Port a 
        input addr_a, write_a, write_en_a,
        output data_a,

        // Port b 
        input addr_b, write_b, write_en_b,
        output data_b
    );
    
    
endinterface