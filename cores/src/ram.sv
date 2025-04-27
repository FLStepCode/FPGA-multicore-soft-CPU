module ram (
    input clk, rst_n,
    input [31:0] ramAddress,
    input [31:0] wrData,
    input we,
    output reg [31:0] rdData
);
    
    reg [31:0] ram [0:1023];

    always_ff @(posedge clk)
    begin
        if (we)
            ram[ramAddress] <= wrData;
        rdData <= ram[ramAddress];
    end

endmodule