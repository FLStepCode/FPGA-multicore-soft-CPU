module fsm (
    input clk, rst_n,
    input  logic a, b,
    output logic c, d
);

    logic e;

    parameter S0 = 1'b0, S1 = 1'b1;

    logic state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
        end
        else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = S0;

        case (state)
            S0: begin
                if (a) begin
                    next_state = S1;
                end
                else begin
                    next_state = S0;
                end
            end
            S1: begin
                if (a) begin
                    next_state = S0;
                end
                else begin
                    next_state = S1;
                end
            end
        endcase
    end

    always_comb begin
        case (state)
            S0: c = 1'b0;
            S1: c = 1'b1;
        endcase
    end

    always_ff @(posedge clk) begin
        case (next_state)
            S0: e <= b; 
            S1: d <= e;
        endcase
    end
    
endmodule