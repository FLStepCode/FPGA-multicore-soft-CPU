module de10standard_top(

    input              CLOCK_50,
    input    [ 3: 0]   KEY,
    input    [ 9: 0]   SW,
    output   [ 9: 0]   LEDR, 

    inout    [35: 0]   GPIO
);

    cosim_top top (
        .clk_i   (CLOCK_50),
        .arstn_i (KEY[0]),
        .rx_i    (GPIO[0]),
        .tx_o    (GPIO[1])
    );

endmodule
