module ram #(
    parameter ADDR_WIDTH = 16,
    parameter BYTE_WIDTH = 8
) (
    input clk_a, clk_b,
    ram_if.s ports
);

logic [BYTE_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];

always_ff @( posedge clk_a ) begin : mem_a
    begin
        if(ports.write_en_a)
            ram[ports.addr_a] = ports.write_a;
        ports.data_a <= ram[ports.addr_a];
    end
end

always_ff @( posedge clk_b ) begin : mem_b
    begin
        if(ports.write_en_b)
            ram[ports.addr_b] = ports.write_b;
        ports.data_b <= ram[ports.addr_b];
    end
end
    
endmodule