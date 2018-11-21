`include<defines.v>

module MMU(
	input wire clk,
	input wire rst,
	input wire [31:0] data_ramAddr_i,
	input wire [31:0] inst_ramAddr_i,
	input wire [3:0] ramOp_i,
	input wire [31:0] storeData_i,
	input wire [31:0] load_data_i,
	input wire [31:0] load_inst_i,
	
	output reg [3:0] ramOp_o,
	output reg [31:0] load_data_o,
	output reg [31:0] load_inst_o,
	output reg [31:0] storeData_o,
	output reg [19:0] instAddr_o,
	output reg [19:0] dataAddr_o,
	output reg [15:0] led_o,
	output reg [7:0] dpy0_o,
	output reg [7:0] dpy1_o
);

    wire [7:0] seg0_o;
    wire [7:0] seg1_o;
    SEG7_LUT seg0(
        .iDIG(storeData_i[3:0]),
        .oSEG1(seg0_o)
    );
    SEG7_LUT seg1(
        .iDIG(storeData_i[7:4]),
        .oSEG1(seg1_o)
    );
	always @(*) begin 
		if(rst == 1'b1) begin
			ramOp_o <= `MEM_NOP;
			load_data_o <= 32'b0;
			load_inst_o <= 32'b0;
			storeData_o <= 32'b0;
			instAddr_o <= 20'b0;
			dataAddr_o <= 20'b0;
			led_o <= 16'b0;
			dpy0_o <= 8'b0;
			dpy1_o <= 8'b0;
		end
		else if (data_ramAddr_i == 32'hbfd00400) begin
		    ramOp_o <= ramOp_i;
            load_data_o <= load_data_i;
            load_inst_o <= load_inst_i;
            storeData_o <= storeData_i;
            instAddr_o <= inst_ramAddr_i[21:2];
            dataAddr_o <= data_ramAddr_i[21:2];
            led_o <= storeData_i[15:0];
		end
		else if (data_ramAddr_i == 32'hbfd00408) begin
		    ramOp_o <= ramOp_i;
            load_data_o <= load_data_i;
            load_inst_o <= load_inst_i;
            storeData_o <= storeData_i;
            instAddr_o <= inst_ramAddr_i[21:2];
            dataAddr_o <= data_ramAddr_i[21:2];
		    dpy0_o <= seg0_o;
		    dpy1_o <= seg1_o;
		end
		else begin
			ramOp_o <= ramOp_i;
			load_data_o <= load_data_i;
			load_inst_o <= load_inst_i;
			
			storeData_o <= storeData_i;
			instAddr_o <= inst_ramAddr_i[21:2];
			dataAddr_o <= data_ramAddr_i[21:2];
		end
	end
endmodule

// #define LED_ADDR                0xbfd00400
// #define NUM_ADDR                0xbfd00408