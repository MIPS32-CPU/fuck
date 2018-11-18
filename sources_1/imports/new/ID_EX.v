`include<defines.v>

module ID_EX(
    input wire clk,
    input wire rst,
    input wire [4:0] ALUop_i,
    input wire [31:0] oprand1_i,
    input wire [31:0] oprand2_i,
    input wire [4:0] writeAddr_i,
    input wire writeEnable_i,
    input wire [1:0] writeHILO_i,
    input wire [5:0] stall,
    input wire signed_i,
    input wire [31:0] inst_i,
    input wire [31:0] pc_i,
    
    output reg [4:0] ALUop_o,
    output reg [31:0] oprand1_o,
    output reg [31:0] oprand2_o,
    output reg [4:0] writeAddr_o,
    output reg writeEnable_o,
    output reg [1:0] writeHILO_o,
    output reg signed_o,
    output reg [31:0] inst_o,
    output reg [31:0] pc_o
);

    always @ (posedge clk) begin
        if(rst == 1'b1) begin
            ALUop_o <= `ALU_NOP;
            oprand1_o <= 32'b0;
            oprand2_o <= 32'b0;
            writeAddr_o <= 5'b0;
            writeEnable_o <= 1'b0;
            writeHILO_o <= 2'b0;
            signed_o <= 1'b0;
            inst_o <= 32'b0;
            pc_o <= 32'b0;
        end else if(stall[2] == 1'b1 && stall[3] == 1'b0) begin
        	ALUop_o <= `ALU_NOP;
			oprand1_o <= 32'b0;
			oprand2_o <= 32'b0;
			writeAddr_o <= 5'b0;
			writeEnable_o <= 1'b0;
			writeHILO_o <= 2'b0;
			signed_o <= 1'b0;
			inst_o <= 32'b0;
			pc_o <= 32'b0;
        end else if(stall[2] == 1'b0) begin
            ALUop_o <= ALUop_i;
            oprand1_o <= oprand1_i;
            oprand2_o <= oprand2_i;
            writeEnable_o <= writeEnable_i;
            writeAddr_o <= writeAddr_i;
            writeHILO_o <= writeHILO_i; 
            signed_o <= signed_i;
            inst_o <= inst_i;
            pc_o <= pc_i;
        end
    end
endmodule