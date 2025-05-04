module uart #(
    parameter int BAUD_RATE = 115_200, CLK_FREQ = 50_000_000
) (
    input logic clk,
    input logic rst_n,
    input logic rx,
    output logic tx,
    output logic [7:0] dataFromRX,
    output logic validOut,
    input logic [7:0] dataToTX,
    input logic validIn
);

    logic clkRx, clkTx;

    uartClockGen #(.BAUD_RATE(BAUD_RATE), .CLK_FREQ(CLK_FREQ)) u_uartClockGen (
        .clk(clk),
        .rst_n(rst_n),
        .clkRx(clkRx),
        .clkTx(clkTx)
    );

    uartRx u_uartRx (
        .clkRx(clkRx),
        .rst_n(rst_n),
        .dataFromRX(dataFromRX),
        .validOut(validOut),
        .rx(rx)
    );

    uartTx u_uartTx (
        .clkTx(clkTx),
        .rst_n(rst_n),
        .dataToTX(dataToTX),
        .validIn(validIn),
        .tx(tx)
    );

endmodule


module uartRx (
    input logic clkRx,
    input logic rst_n,
    output logic [7:0] dataFromRX,
    output logic validOut,
    input logic rx
);

    logic [2:0] countData;
    logic [2:0] countClock;

    parameter [1:0] IDLE = 2'b00, DATA = 2'b01, STOP = 2'b10;
    logic [1:0] state;

    always_ff @(posedge clkRx or negedge rst_n) begin
        if (!rst_n) begin
            countClock <= 0;
            countData <= 0;
            dataFromRX <= 0;
            validOut <= 0;
            state <= IDLE;
        end
        else begin

            case (state)

                IDLE: begin
                    dataFromRX <= 0;
                    validOut <= 0;
                    countData <= 0;

                    if (rx) begin
                        countClock <= 0;
                    end
                    else begin
                        countClock <= countClock + 1;
                        if (countClock == 8) begin
                            state <= DATA;
                        end
                    end

                end

                DATA: begin
                    validOut <= 0;
                    countClock <= countClock + 1;

                    if (countClock == 8) begin
                        dataFromRX[countData] <= rx;
                        if (countData < 7) begin
                            countData <= countData + 1;
                        end
                        else begin
                            countData <= 0;
                            state <= STOP;
                        end
                    end

                end

                STOP: begin
                    countClock <= countClock + 1;
                    if (countClock == 8) begin
                        if (rx) begin
                            validOut <= 1;
                        end
                        else begin
                            validOut <= 0;
                        end
                        state <= IDLE;
                        countClock <= 0;
                    end
                end

                default: begin
                    countClock <= 0;
                    countData <= 0;
                    dataFromRX <= 0;
                    validOut <= 0;
                    state <= IDLE;
                end

            endcase

        end
    end
    

endmodule


module uartTx (
    input logic clkTx,
    input logic rst_n,
    input logic [7:0] dataToTX,
    input logic validIn,
    output logic tx
);

    logic [2:0] countData;
    logic [7:0] dataToTXReg;

    parameter [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    logic [1:0] state;

    always_ff @(posedge clkTx or negedge rst_n) begin
        if (!rst_n) begin
            countData <= 0;
            tx <= 1;
            state <= IDLE;
        end
        else begin

            case (state)

                IDLE: begin
                    tx <= 1;
                    countData <= 0;

                    if (validIn) begin
                        dataToTXReg <= dataToTX;
                        state <= START;
                    end
                end

                START: begin
                    tx <= 0;
                    countData <= 0;
                    state <= DATA;
                end

                DATA: begin
                    tx <= dataToTXReg[countData];
                    countData <= countData + 1;
                    if (countData == 7) begin
                        state <= STOP;
                    end
                end

                STOP: begin
                    tx <= 1;
                    countData <= 0;
                    state <= IDLE;
                end

            endcase

        end
    end

endmodule


module uartClockGen #(
    parameter int BAUD_RATE = 115_200, CLK_FREQ = 50_000_000
) (
    input logic clk,
    input logic rst_n,
    output logic clkRx,
    output logic clkTx
);

    parameter int DIVIDER_RX = CLK_FREQ / (2 * BAUD_RATE * 16);
    parameter int DIVIDER_TX = CLK_FREQ / (2 * BAUD_RATE);

    integer counterRx;
    integer counterTx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counterRx <= 0;
            clkRx <= 0;
        end else begin
            if (counterRx == DIVIDER_RX - 1) begin
                clkRx <= ~clkRx;
                counterRx <= 0;
            end else begin
                counterRx <= counterRx + 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counterTx <= 0;
            clkTx <= 0;
        end else begin
            if (counterTx == DIVIDER_TX - 1) begin
                clkTx <= ~clkTx;
                counterTx <= 0;
            end else begin
                counterTx <= counterTx + 1;
            end
        end
    end

endmodule