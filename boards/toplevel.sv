`include "cpu/noc_with_cores.sv"
`include "cpu/uart.sv"
`include "mesh_3x3/inc/noc_XY.svh"

module toplevel (
    input logic clk, rst_n,
    input logic rx,
    output logic tx,
    output logic clkRx, clkTx
);
    integer i;

    integer counterRx, counterTx;
    logic [3:0] oversampleCount;

    logic [7:0] dataFromRX;
    logic validOut;
    logic [7:0] dataToTX;
    logic validIn;
    logic txReady;


    logic [7:0] peekId;
    logic [31:0] peekAddress;

    logic [31:0] peekData;
    logic [31:0] peekDataReg;

    logic rxActive, txActive;

    uart uart(
        .clk(clk), .rst_n(rst_n),
        .rx(rx), .tx(tx),
        
        .dataFromRX(dataFromRX), .validOut(validOut),
        .dataToTX(dataToTX), .validIn(validIn), .txReady(txReady),

        .clkRx(clkRx), .clkTx(clkTx)
    );

    noc_with_cores nwc(
        .clk(clk), .rst_n(rst_n),
        .peekAddress(peekAddress), .peekId(peekId[$clog2(`RN) - 1:0]), .peekData(peekData)
    );

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

    always_ff @(posedge clkTx or negedge rst_n) begin
        if (!rst_n) begin
            counterTx <= 0;
            txActive <= 0;
        end
        else begin

            validIn <= 0;

            if (rxActive) begin
                txActive <= 0;
            end
            else begin
                if (!txActive) begin
                    peekDataReg <= peekData;
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
    end

    
endmodule