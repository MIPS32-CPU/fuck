module MEM(
    input wire clk,
    input wire rst,
    input wire [4:0] writeAddr_i,
    input wire writeEnable_i,
    input wire [1:0] writeHILO_i,
    input wire [31:0] HI_data_i,
    input wire [31:0] LO_data_i,
    
    input wire [31:0] storeData_i,
    input wire [3:0] ramOp_i,
    input wire success_i,
    input wire [31:0] load_data_i,
    
    output reg [4:0] writeAddr_o,
    output reg writeEnable_o,
    output reg [1:0] writeHILO_o,
    output reg [31:0] HI_data_o,
    output reg [31:0] LO_data_o,
    
    output reg [3:0] ramOp_o,
    output reg [31:0] ramAddr_o,
 	output reg [31:0] storeData_o,
    
    output reg pauseRequest
);

    always @ (*) begin
        if (rst == 1'b1) begin 
            HI_data_o <= 32'b0;
            LO_data_o <= 32'b0;
            writeEnable_o <= 1'b0;
            writeAddr_o <= 5'b0;
            writeHILO_o <= 2'b00;
            ramOp_o <= `MEM_NOP;
            ramAddr_o <= 32'b0;
            storeData_o <= 32'b0;
            pauseRequest <= 1'b0;
            
        end else begin
            HI_data_o <= HI_data_i;
            LO_data_o <= LO_data_i;
            writeEnable_o <= writeEnable_i;
            writeAddr_o <= writeAddr_i;
            writeHILO_o <= writeHILO_i;
            ramOp_o <= ramOp_i;
            ramAddr_o <= LO_data_i;
            storeData_o <= storeData_i;
            
            //pauseRequest <= 1'b0;
            if(ramOp_i == `MEM_NOP) begin
            	pauseRequest <= 1'b0;
            end else if(success_i == 1'b0) begin
            	pauseRequest <= 1'b1;
            end	else begin
            	pauseRequest <= 1'b0;
            	LO_data_o <= load_data_i;
            end
        end
    end
endmodule