/* accumulator
	takes the input signals clock, reset, enable, and read and write data 
	to return the output signal q - the noise-reduced average of the last 8 sound values from the original sound
*/
module accumulator(clk, reset, en, r_data, w_data, q);
	// inputs
	input logic clk, reset, en; 			// clock and reset from board, enable decides when to update the output
	input logic [23:0] r_data, w_data;	// r_data is read from the FIFO buffer, w_data is read from the original unfiltered sound
	
	// output - described in header
	output logic [23:0] q;
	
	// determines output value:
	// if board reset - set output to 0
	// if this accumulator is enabled - update the value of the output
	// otherwise, hold the output's value
	always_ff @(posedge clk) begin
		if (reset)
			q <= 0;
		else if (en)
			q <= q + r_data * -1 + w_data;
		else
			q <= q;
	end //always_ff
	
endmodule //accumulator