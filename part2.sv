// part2:
// top-level module for LabsLand to compile for full part 2 (mic, onboard ROM sound) sound functionality.
module part2 (CLOCK_50, CLOCK2_50, KEY, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
		        AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT, SW, LEDR);
	// board inputs
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
	wire read_ready, write_ready, read, write;
	wire [23:0] readdata_left, readdata_right;
	wire [23:0] writedata_left, writedata_right;
	wire reset = ~KEY[0];
	
	// status LED to make sure switch works
	assign LEDR[9] = SW[9];
	
	// select the sound output for both channels:
	// switch on means ROM sound, switch off means mic sound
	assign writedata_left = SW[9] ? sound : readdata_left;
	assign writedata_right = SW[9] ? sound : readdata_right;
	
	// codec can only read or write when it can do both
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
	//  pif we're writing -> increment the current address
	//	if none of these things are happening, hold the current address, as the ROM is not being used.
	always_ff @(posedge CLOCK_50) begin
		if (current == 16'd47999 | reset)
			current <= 0;
		else if (write)
			current <= current + 1;
		else
		    current <= current;
	end //always_ff

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

endmodule	//part2



	