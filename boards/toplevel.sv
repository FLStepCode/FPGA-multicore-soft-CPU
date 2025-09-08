`include "cpu/noc_with_cores.sv"
`include "cpu/uart.sv"
`include "mesh_4x4/inc/noc_XY.svh"
`include "boards/vga_driver.sv"

module toplevel (
    input logic clk, clk_25mhz, rst_n,
    output logic vs, hs,
    output logic [7:0] r, g, b
);


    logic [7:0] peekId;
    logic [31:0] peekAddress;

    logic [31:0] peekData;
    logic [31:0] peekDataReg;

    logic [10:0] x_coord, y_coord;
    logic canDisplay;

    integer pixel_num;
/*
    uart uart(
        .clk(clk), .rst_n(rst_n),
        .rx(rx), .tx(tx),
        
        .dataFromRX(dataFromRX), .validOut(validOut),
        .dataToTX(dataToTX), .validIn(validIn), .txReady(txReady),

        .clkRx(clkRx), .clkTx(clkTx)
    );
*/

    noc_with_cores nwc(
        .clk_25mhz(clk_25mhz), .clk(clk), .rst_n(rst_n),
        .peekAddress(peekAddress), .peekId(peekId[$clog2(`RN) - 1:0]), .peekData(peekData)
    );

    logic [7:0] peekData_div;
    assign peekData_div = peekData / 10;

    always_comb begin
        if (x_coord < 48 && y_coord < 88 && canDisplay) begin
            pixel_num = x_coord + y_coord * 48;
            peekId = 6 + pixel_num / 1024;
            peekAddress = pixel_num % 1024;
        end
        else begin
            pixel_num = 0;
            peekId = 15;
            peekAddress = 0;
        end
    end

    assign {r, g, b} = canDisplay ? {peekData_div[7:0], peekData_div[7:0], peekData_div[7:0]} : 0;

    vga_driver vd(
        .clk_25mhz(clk_25mhz),
        .rst_n(rst_n),
        .vs(vs),
        .hs(hs),
        .x_coord(x_coord),
        .y_coord(y_coord),
        .canDisplay(canDisplay)
    );
/*
    always_ff @(posedge clkRx or negedge rst_n) begin
        if (!rst_n) begin
            peekAddress <= 0;
            peekId <= 0;
            counterRx <= 0;
            oversampleCount <= 0;
            rxActive <= 1;
        end
        else begin

            if (txActive || oversampleCount != 0) begin
                rxActive <= 0;
                oversampleCount <= oversampleCount + 1;
            end
            else begin
                oversampleCount <= 0;
                rxActive <= 1;
                if (validOut) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (counterRx < 4) begin
                            peekAddress[counterRx*8 + i] <= dataFromRX[i];
                        end
                        else if (counterRx == 4) begin
                            peekId[i] <= dataFromRX[i];
                        end
                        else begin
                        end
                    end
                    if (counterRx < 4) begin
                        counterRx <= counterRx + 1;
                    end
                    else begin
                        oversampleCount <= 1;
                        counterRx <= 0;
                        rxActive <= 0;
                    end
                end
            end

        end
    end
*/
/*
    always_ff @(posedge clkTx or negedge rst_n) begin
        if (!rst_n) begin
            counterTx <= 0;
            txActive <= 0;
            peekId <= 0;
            peekAddress <= 0;
        end
        else begin

            validIn <= 0;
            if (!txActive) begin
                peekDataReg <= peekData;
                if (peekAddress == 1023) begin
                    peekAddress <= 0;
                    peekId <= (peekId == 15) ? 0 : peekId + 1;
                end
                else begin
                    peekAddress <= peekAddress + 1;
                end
                txActive <= 1;
            end
            else begin
                if (txReady && !validIn) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        dataToTX[i] <= peekDataReg[counterTx*8 + i];
                    end
                    validIn <= 1;
                    if (counterTx < 4) begin
                        counterTx <= counterTx + 1;
                    end
                    else begin
                        validIn <= 0;
                        counterTx <= 0;
                        txActive <= 0;
                    end
                end
            end

        end
    end
*/
    
endmodule