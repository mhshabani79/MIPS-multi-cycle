`timescale 1 ns/1 ns
module tb1();
	logic clk,rst;
	logic [31:0] memory[0:65536];
	logic [31:0] register[0:31];
	
	DATA_PATH uut0(register,clk,rst,memory);
	
	initial begin
		 clk=0;
		repeat(3000)
			#50 clk=~clk;
		$stop;
	end
	initial begin
		 rst=1;
		#100 rst=0;
	end
	
endmodule
