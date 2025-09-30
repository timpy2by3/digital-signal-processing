// part3:
// top-level module for LabsLand to compile for full part 3 (mic, onboard ROM sound, filtered) sound functionality.
module part3 (CLOCK_50, CLOCK2_50, KEY, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
		        AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT, SW, LEDR);
	// determines how large the filter buffer should be (higher = more filtered)
	parameter N = 5;
	
	// board input/outputs
	input CLOCK_50, CLOCK2_50;
	input [0:0] KEY;
	input logic [9:0] SW;
	output logic [9:0] LEDR;
	
	// I2C Audio/Video config interface
	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	
	// Audio CODEC
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;
	
	// Local wires.
	wire read_ready, write_ready, read, write;	// signals to decide whether the audio codec can read/write
	wire [23:0] readdata_left, readdata_right; 	//	contains the mic recording's data to be read to the left/right channel
	wire [23:0] unfiltered_L, unfiltered_R;		// unfiltered audio for each channel after selecting between ROM sound and mic sound
	wire [23:0] fifo_in_L, fifo_in_R;				// audio signal after getting divided to put in fifo buffer
	wire [23:0] fifo_out_L, fifo_out_R;				// last audio signal from the fifo buffer, to help keep the filtered sound accurate
	wire [23:0] filtered_L, filtered_R;				// filtered audio for each channel after going through the fifo buffer and accumulator
	wire [23:0] writedata_left, writedata_right;	// data that ultimately gets written to the speakers
	wire reset = ~KEY[0];
	
	// status LEDs to make sure switches work
	assign LEDR[9] = SW[9];
	assign LEDR[8] = SW[8];
	
	// FOR LEFT AND RIGHT CHANNEL
	// audio channel name
	// choose between filtered/unfiltered 
	// in unfiltered choose between ROM sound and mic sound
	// use unfiltered value / 8 to get value to add to filtered
	
	// left channel
	assign writedata_left = SW[8] ? filtered_L : unfiltered_L;
	assign unfiltered_L 	 = SW[9] ? sound : readdata_left;
	assign fifo_in_L		 = {{N{unfiltered_L[23]}}, unfiltered_L[23:N]};
	
	// right channel
	assign writedata_right = SW[8] ? filtered_R : unfiltered_R;
	assign unfiltered_R	  = SW[9] ? sound : readdata_right;
	assign fifo_in_R		  = {{N{unfiltered_R[23]}}, unfiltered_R[23:N]};
	
	// codec can only read/write when it's ready to do both
	assign read = read_ready & write_ready;
	assign write = read_ready & write_ready;
	
	// controls going through the ROM to get the saved pitch
	logic [15:0] current;	// keeps track of the current address in the ROM
	logic [23:0] sound;		// copies the audio data at ROM[current]
	
	//	uses the above two signals and the clock to read data from the ROM
	sound_storage rom(.address(current), .clock(CLOCK_50), .q(sound)); 

	// read from ROM to produce stored sound
	//	if we're at the last address where there's a sound (will always be 47999 for our ROM file)
	//	or we're resetting -> the next address will be 0 {beginning of the ROM}
	// if we're writing -> increment the current address
	//	if none of these things are happening, hold the current address, as the ROM is not being used.
	always_ff @(posedge CLOCK_50) begin
		if (current == 16'd47999 | reset)
			current <= 0;
		else if (write)
			current <= current + 1;
		else
		    current <= current;
	end //always_ff
	
	// fifo buffers to help remove noise from the recording (feeds to accumulator)
	fifo #(24, N) bufferL(.clk(CLOCK_50), .reset, .rd(LEDR[1] & write), .wr(SW[8] & write), .empty(LEDR[0]), .full(LEDR[1]), .w_data(fifo_in_L), .r_data(fifo_out_L));
	fifo #(24, N) bufferR(.clk(CLOCK_50), .reset, .rd(LEDR[3] & write), .wr(SW[8] & write), .empty(LEDR[2]), .full(LEDR[3]), .w_data(fifo_in_R), .r_data(fifo_out_R));
	
	// accumulators to help remove noise from the recording
	accumulator accumulateL(.clk(CLOCK_50), .reset, .w_data(fifo_in_L), .r_data(fifo_out_L), .q(filtered_L), .en(SW[8] & write));
	accumulator accumulateR(.clk(CLOCK_50), .reset, .w_data(fifo_in_R), .r_data(fifo_out_R), .q(filtered_R), .en(SW[8] & write));

/////////////////////////////////////////////////////////////////////////////////
// Audio CODEC interface. 
//
// The interface consists of the following wires:
// read_ready, write_ready - CODEC ready for read/write operation 
// readdata_left, readdata_right - left and right channel data from the CODEC
// read - send data from the CODEC (both channels)
// writedata_left, writedata_right - left and right channel data to the CODEC
// write - send data to the CODEC (both channels)
// AUD_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio CODEC
// I2C_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio/Video Config module
/////////////////////////////////////////////////////////////////////////////////
	clock_generator my_clock_gen(
		// inputs
		CLOCK2_50,
		reset,

		// outputs
		AUD_XCK
	);

	audio_and_video_config cfg(
		// Inputs
		CLOCK_50,
		reset,

		// Bidirectionals
		FPGA_I2C_SDAT,
		FPGA_I2C_SCLK
	);

	audio_codec codec(
		// Inputs
		CLOCK_50,
		reset,

		read,	write,
		writedata_left, writedata_right,

		AUD_ADCDAT,

		// Bidirectionals
		AUD_BCLK,
		AUD_ADCLRCK,
		AUD_DACLRCK,

		// Outputs
		read_ready, write_ready,
		readdata_left, readdata_right,
		AUD_DACDAT
	);
endmodule //part3