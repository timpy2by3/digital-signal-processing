/* Register file module for specified data and address bus widths.
 * Asynchronous read port (r_addr -> r_data) and synchronous write
 * port (w_data -> w_addr if w_en).
 */
module reg_file #(parameter DATA_WIDTH=8, ADDR_WIDTH=2)
                (clk, w_data, w_en, full, w_addr, r_addr, r_data);

	input  logic clk, w_en, full;
	input  logic [ADDR_WIDTH-1:0] w_addr, r_addr;
	input  logic [DATA_WIDTH-1:0] w_data;
	output logic [DATA_WIDTH-1:0] r_data;
	
	// array declaration (registers)
	logic [DATA_WIDTH-1:0] array_reg [0:2**ADDR_WIDTH-1];
	
	// read and write operation (synchronous)
	// if write is enabled the write the write data to the write address
	// if read is enabled then output the data at the read address, else output 0
	always_ff @(posedge clk) begin
	   if (w_en)
		   array_reg[w_addr] <= w_data;
		if (full)
			r_data <= array_reg[r_addr];
		else
			r_data <= 0;
	end // always_ff
endmodule  // reg_file