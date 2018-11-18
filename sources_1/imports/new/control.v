module control(
	input wire rst,
	input wire stall_from_exe,//stall request from EXE
	input wire stall_from_id,
	input wire stall_from_mem,
	/*stall[0] pc stall
	stall[1] IF stall
	stall[2] ID stall
	stall[3] EXE stall
	stall[4] MEM stall
	stall[5] WB stall*/
	output reg [5:0] stall
);
	always @(*) begin
		if(rst == 1'b1) begin
			stall <= 6'b0;
		end else if(stall_from_mem == 1'b1) begin
			stall <= 6'b011111;	
		end else if(stall_from_exe == 1'b1) begin
			stall <= 6'b001111;
		end else if(stall_from_id == 1'b1) begin
			stall <= 6'b000111;
		end else begin
			stall <= 6'b0;
		end
	end
endmodule