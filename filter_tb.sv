/* Testbench for the filter that creates a fifo buffer and accumulator 
*/
module filter_tb();

	// port declarations
	logic clk, reset, rd, wr, empty, full, en;
	logic [23:0] w_data, in, r_data, q;
	
	// assign internal signals to only read when full and divide data by 8
	// before inputting data into buffer and accumulator.
	assign rd = full;
	assign w_data = {{3{in[23]}}, in[23:3]};
	assign en = wr;

	// module instantiations for fifo buffer and accumulator to act as FIR filter.
	fifo fifo_dut (.*);
	accumulator accumulator_dut(.*);
	
	// define simulated clock
	parameter CLOCK_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end // initial clock
	
	// testbench that inputs multiples of 8 into buffer and accumulator
	// for simplified calculations, until buffer is full.
	initial begin
		reset <= 1; 			 				@(posedge clk);
		reset <= 0; wr <= 1;	in <= 24'd8;	@(posedge clk);
		in <= -24'd16;		 					@(posedge clk);
		in <= 24'd24; 	 						@(posedge clk);
		in <= -24'd32; 	 						@(posedge clk);
		in <= 24'd40;							@(posedge clk);
		in <= -24'd48;		 					@(posedge clk);
		in <= 24'd56;		 					@(posedge clk);
		in <= -24'd64; 	 						@(posedge clk);
		in <= 24'd72;		 					@(posedge clk);
												@(posedge clk);
												@(posedge clk);
												@(posedge clk);
		$stop; // pause the simulation
	end // initial
	
endmodule