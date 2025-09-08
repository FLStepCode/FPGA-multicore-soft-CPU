module vga_driver (
    input clk_25mhz, rst_n,
    output logic vs, hs,
    output logic [10:0] x_coord, y_coord,
    output logic canDisplay
);

    logic [10:0] x_counter, y_counter;

	 always_comb begin
	     if(x_counter>=144 && x_counter<784) x_coord = x_counter-144;
		  else x_coord = 0;
		  if(y_counter>=35 && y_counter < 515) y_coord = y_counter-35;
		  else y_coord = 0; 
	 end

     assign canDisplay = (x_counter>=144 && x_counter<784 && y_counter>=35 && y_counter < 515) ? 1 : 0;
	 
    always @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
            x_counter <= 0;
            y_counter <= 0;
        end
        else begin
            if (x_counter < 799) begin
                x_counter <= x_counter + 1;
            end
            else begin
                x_counter <= 0;
                y_counter <= (y_counter < 525) ? y_counter + 1 : 0;
            end
        end
    end

    assign hs = (x_counter < 96) ? 0 : 1;                                                 
	 assign vs = (y_counter < 2) ? 0 : 1;
    
endmodule