/******************************************
Regulations for the names of the wires:
ONLY define the OUTPUT wires of the parts.
In fact, one wire can link two ends.
*******************************************/

module CPU(
    input wire clk,
    input wire rst,
    
    
    output wire [19:0] instAddr_o,
	output wire [19:0] dataAddr_o,
	
	output wire inst_WE_n_o,
	output wire inst_OE_n_o,
	output wire inst_CE_n_o,
	output wire [3:0] inst_be_n_o,
	
	output wire data_WE_n_o,
	output wire data_OE_n_o,
	output wire data_CE_n_o,
	output wire [3:0] data_be_n_o,
	
	inout wire [31:0] inst_io,
	inout wire [31:0] data_io
);
	
    //link the pc and IF/ID
    wire [31:0] pc_pc_o;
    
    //link IF/ID and ID
    wire [31:0] IF_ID_pc_o;
    wire [31:0] IF_ID_inst_o;
    
    //link ID and registers , ID/EX
    wire [31:0] reg_readData1_o, reg_readData2_o;
    wire [31:0] HILO_HI_data_o, HILO_LO_data_o;
    wire [4:0] ID_readAddr1_o, ID_readAddr2_o;
    wire ID_readEnable1_o, ID_readEnable2_o;
    wire ID_writeEnable_o;
    wire [4:0] ID_writeAddr_o;
    wire [31:0] ID_oprand1_o, ID_oprand2_o;
    wire [4:0] ID_ALUop_o;
    wire ID_branchEnable_o;
    wire [31:0] ID_branchAddr_o;
    wire [1:0] ID_writeHILO_o;
    wire ID_signed_o;
    wire [31:0] ID_inst_o, ID_pc_o;
    wire ID_pause_o;
    
    //link ID/EX and EX
    wire [4:0] ID_EX_ALUop_o;
    wire [31:0] ID_EX_oprand1_o, ID_EX_oprand2_o;
    wire [4:0] ID_EX_writeAddr_o;
    wire ID_EX_writeEnable_o;
    wire [1:0] ID_EX_writeHILO_o;
    wire ID_EX_signed_o;
    wire [31:0] ID_EX_inst_o, ID_EX_pc_o;
    
    //link EX and EX/MEM
    wire [31:0] EX_HI_data_o, EX_LO_data_o;
    wire [4:0] EX_writeAddr_o;
    wire EX_writeEnable_o;
    wire [1:0] EX_writeHILO_o;
    wire [31:0] EX_dividend_o, EX_divider_o;
    wire EX_pause_o, EX_signed_o, EX_start_o;
    wire [31:0] EX_storeData_o;
    wire [3:0] EX_ramOp_o;
       
    //link EX/MEM and MEM
    wire [31:0] EX_MEM_HI_data_o, EX_MEM_LO_data_o;
    wire [4:0] EX_MEM_writeAddr_o;
    wire EX_MEM_writeEnable_o;
    wire [1:0] EX_MEM_writeHILO_o;
    wire [31:0] EX_MEM_storeData_o;
    wire [3:0] EX_MEM_ramOp_o;
     
    //link MEM and MEM/WB
    wire [31:0] MEM_HI_data_o, MEM_LO_data_o;
    wire [4:0] MEM_writeAddr_o;
    wire MEM_writeEnable_o;
    wire [1:0] MEM_writeHILO_o;
    wire [3:0] MEM_ramOp_o;
    wire [31:0] MEM_ramAddr_o;
    wire [31:0] MEM_storeData_o;
    wire MEM_pause_o;
     
    //link MEM/WB and registers
    wire [31:0] MEM_WB_HI_data_o, MEM_WB_LO_data_o;
    wire [4:0] MEM_WB_writeAddr_o;
    wire MEM_WB_writeEnable_o; 
    wire [1:0] MEM_WB_writeHILO_o;
    
    //pause signal
    wire [5:0] ctr_stall_o;
    
    //div module
    wire [63:0] DIV_result_o;
    wire DIV_success_o;
    
    //inst_sram control
    wire [31:0] base_load_data_o; 
    wire [19:0] base_ramAddr_o;
    wire base_CE_n_o, base_WE_n_o, base_OE_n_o;
    wire [3:0] base_be_n_o;
    
    //data_sram control
     wire [31:0] ext_load_data_o; 
     wire [19:0] ext_ramAddr_o;
     wire ext_success_o, ext_CE_n_o, ext_WE_n_o, ext_OE_n_o;
     wire [3:0] ext_be_n_o;
    
    //MMU
    wire [31:0] MMU_load_data_o, MMU_load_inst_o, MMU_storeData_o;
    wire [3:0] MMU_ramOp_o;
    wire [19:0] MMU_instAddr_o, MMU_dataAddr_o;
    
    
    assign inst_CE_n_o = base_CE_n_o,  inst_WE_n_o = base_WE_n_o, 
    	   inst_OE_n_o = base_OE_n_o;
    assign inst_be_n_o = base_be_n_o;
    assign instAddr_o = base_ramAddr_o;
    
	assign data_CE_n_o = ext_CE_n_o,  data_WE_n_o = ext_WE_n_o, 
		   data_OE_n_o = ext_OE_n_o;
	assign data_be_n_o = ext_be_n_o;
	assign dataAddr_o = ext_ramAddr_o;
    
    pc pc0(
        .clk(clk),                              .rst(rst), 
        .branchEnable_i(ID_branchEnable_o),    	.branchAddr_i(ID_branchAddr_o), 
        .pc_o(pc_pc_o),							.stall(ctr_stall_o)
    );
    
    
    
    IF_ID IF_ID0(
        .clk(clk),                              .rst(rst), 
        .pc_i(pc_pc_o),                         .inst_i(MMU_load_inst_o), 
        .pc_o(IF_ID_pc_o),                      .inst_o(IF_ID_inst_o),
        .stall(ctr_stall_o)
    );
    
    
    
    ID ID0(
        .clk(clk),                              .rst(rst), 
        .inst_i(IF_ID_inst_o),                  .pc_i(IF_ID_pc_o), 
        .readData1_i(reg_readData1_o),          .readData2_i(reg_readData2_o),
        .HI_data_i(HILO_HI_data_o),				.LO_data_i(HILO_LO_data_o),
        .EX_writeEnable_i(EX_writeEnable_o),	.EX_writeAddr_i(EX_writeAddr_o),
        .EX_writeHI_data_i(EX_HI_data_o),		.EX_writeLO_data_i(EX_LO_data_o),
        .EX_writeHILO_i(EX_writeHILO_o),		.MEM_writeEnable_i(MEM_writeEnable_o),
        .MEM_writeAddr_i(MEM_writeAddr_o), 		.MEM_writeHI_data_i(MEM_HI_data_o),
        .MEM_writeLO_data_i(MEM_LO_data_o),		.MEM_writeHILO_i(MEM_writeHILO_o),
        .readAddr1_o(ID_readAddr1_o),           .readAddr2_o(ID_readAddr2_o), 
        .readEnable1_o(ID_readEnable1_o),       .readEnable2_o(ID_readEnable2_o), 
        .writeEnable_o(ID_writeEnable_o),       .writeAddr_o(ID_writeAddr_o),
        .oprand1_o(ID_oprand1_o),               .oprand2_o(ID_oprand2_o), 
        .branchEnable_o(ID_branchEnable_o),     .branchAddr_o(ID_branchAddr_o), 
        .ALUop_o(ID_ALUop_o),					.writeHILO_o(ID_writeHILO_o),
        .signed_o(ID_signed_o),					.inst_o(ID_inst_o),
        .pc_o(ID_pc_o),							.pauseRequest(ID_pause_o),
        .EX_ramOp_i(EX_ramOp_o)
    );
    
    
    registers regs0(
        .clk(clk),                              .rst(rst), 
        .readEnable1_i(ID_readEnable1_o),       .readEnable2_i(ID_readEnable2_o), 
        .readAddr1_i(ID_readAddr1_o),           .readAddr2_i(ID_readAddr2_o),
        .writeEnable_i(MEM_WB_writeEnable_o),   .writeAddr_i(MEM_WB_writeAddr_o), 
        .writeData_i(MEM_WB_LO_data_o),         .readData1_o(reg_readData1_o), 
        .readData2_o(reg_readData2_o)
    );
    
    
    
    ID_EX ID_EX0(
        .clk(clk),                              .rst(rst), 
        .ALUop_i(ID_ALUop_o),                   .oprand1_i(ID_oprand1_o), 
        .oprand2_i(ID_oprand2_o),               .writeAddr_i(ID_writeAddr_o),
        .writeEnable_i(ID_writeEnable_o),       .ALUop_o(ID_EX_ALUop_o), 
        .oprand1_o(ID_EX_oprand1_o),            .oprand2_o(ID_EX_oprand2_o), 
        .writeAddr_o(ID_EX_writeAddr_o),        .writeEnable_o(ID_EX_writeEnable_o),
        .writeHILO_i(ID_writeHILO_o),			.writeHILO_o(ID_EX_writeHILO_o),
        .stall(ctr_stall_o),					.signed_o(ID_EX_signed_o),
        .signed_i(ID_signed_o),					.inst_i(ID_inst_o),
        .pc_i(ID_pc_o),							.inst_o(ID_EX_inst_o),
        .pc_o(ID_EX_pc_o)
    );
    
   
    
    EX EX0(
    	.clk(clk), 								.rst(rst), 
    	.ALUop_i(ID_EX_ALUop_o),				.writeHILO_i(ID_EX_writeHILO_o),
    	.oprand1_i(ID_EX_oprand1_o),			.oprand2_i(ID_EX_oprand2_o), 			
    	.writeAddr_i(ID_EX_writeAddr_o),		.writeEnable_i(ID_EX_writeEnable_o), 	
    	.HI_data_o(EX_HI_data_o),				.LO_data_o(EX_LO_data_o),				
    	.writeHILO_o(EX_writeHILO_o),			.writeAddr_o(EX_writeAddr_o),			
    	.writeEnable_o(EX_writeEnable_o),		.signed_o(EX_signed_o),
    	.start_o(EX_start_o),					.divider_o(EX_divider_o),
    	.dividend_o(EX_dividend_o),				.result_div_i(DIV_result_o),
    	.success_i(DIV_success_o),				.pauseRequest(EX_pause_o),
    	.signed_i(ID_EX_signed_o),				.inst_i(ID_EX_inst_o),
    	.pc_i(ID_EX_pc_o),						.ramOp_o(EX_ramOp_o),
    	.storeData_o(EX_storeData_o)
    );
    
    
    
    EX_MEM EX_MEM0(
    	.clk(clk), 								.rst(rst), 
    	.HI_data_i(EX_HI_data_o),				.LO_data_i(EX_LO_data_o),
    	.writeAddr_i(EX_writeAddr_o), 			.writeHILO_i(EX_writeHILO_o),
    	.writeEnable_i(EX_writeEnable_o), 		.HI_data_o(EX_MEM_HI_data_o),
    	.LO_data_o(EX_MEM_LO_data_o),			.writeHILO_o(EX_MEM_writeHILO_o),
    	.writeAddr_o(EX_MEM_writeAddr_o), 		.writeEnable_o(EX_MEM_writeEnable_o),
    	.stall(ctr_stall_o),					.storeData_i(EX_storeData_o),
    	.ramOp_i(EX_ramOp_o),					.storeData_o(EX_MEM_storeData_o),
    	.ramOp_o(EX_MEM_ramOp_o)
    );
    
  
    
    MEM MEM0(
    	.clk(clk), 								.rst(rst), 
        .HI_data_i(EX_MEM_HI_data_o),			.LO_data_i(EX_MEM_LO_data_o),			
        .writeAddr_i(EX_MEM_writeAddr_o), 		.writeHILO_i(EX_MEM_writeHILO_o),
        .LO_data_o(MEM_LO_data_o),				.HI_data_o(MEM_HI_data_o),
        .writeEnable_i(EX_MEM_writeEnable_o), 	.writeHILO_o(MEM_writeHILO_o),
        .writeAddr_o(MEM_writeAddr_o), 			.writeEnable_o(MEM_writeEnable_o),
        .storeData_i(EX_MEM_storeData_o),		.ramOp_i(EX_MEM_ramOp_o),
        .storeData_o(MEM_storeData_o),			.ramOp_o(MEM_ramOp_o),
        .ramAddr_o(MEM_ramAddr_o),				.load_data_i(MMU_load_data_o),
        .success_i(ext_success_o),				.pauseRequest(MEM_pause_o)
    );
    

    
   	MEM_WB MEM_WB0(
		.clk(clk), 								.rst(rst), 
		.HI_data_i(MEM_HI_data_o),				.LO_data_i(MEM_LO_data_o),			
		.writeAddr_i(MEM_writeAddr_o), 			.writeHILO_i(MEM_writeHILO_o),
		.LO_data_o(MEM_WB_LO_data_o),			.HI_data_o(MEM_WB_HI_data_o),
		.writeEnable_i(MEM_writeEnable_o), 		.writeHILO_o(MEM_WB_writeHILO_o),
		.writeAddr_o(MEM_WB_writeAddr_o), 		.writeEnable_o(MEM_WB_writeEnable_o),
		.stall(ctr_stall_o)
        );
    
    
    
    HILO HILO0(
    	.clk(clk),								.rst(rst),
    	.writeEnable_i(MEM_WB_writeHILO_o),		.HI_data_i(MEM_WB_HI_data_o),
    	.LO_data_i(MEM_WB_LO_data_o),			.HI_data_o(HILO_HI_data_o),
    	.LO_data_o(HILO_LO_data_o)
    );
    
    control control0(
    	.rst(rst),								.stall_from_exe(EX_pause_o),
    	.stall(ctr_stall_o),					.stall_from_id(ID_pause_o),
    	.stall_from_mem(MEM_pause_o)
    );
    
    div div0(
    	.clk(clk),								.rst(rst),
    	.signed_i(EX_signed_o),					.dividend_i(EX_dividend_o),
    	.divider_i(EX_divider_o),				.start_i(EX_start_o),
    	.concell_i(1'b0),						.result_o(DIV_result_o),
    	.success_o(DIV_success_o)
    );
    
    sram_control sram_control0(
    	.clk50(clk),							.rst(rst),
    	.ramAddr_i(MMU_dataAddr_o),				.storeData_i(MMU_storeData_o),
    	.ramOp_i(MMU_ramOp_o),					.loadData_o(MMU_load_data_o),
    	.CE_n_o(ext_CE_n_o),					.WE_n_o(ext_WE_n_o),						
    	.OE_n_o(ext_OE_n_o),					.be_n_o(ext_be_n_o),
    	.data_io(data_io),						.success_o(ext_success_o),
    	.ramAddr_o(ext_ramAddr_o)
    );
    
    MMU MMU0(
    	.rst(rst),
    	.data_ramAddr_i(MEM_ramAddr_o),
    	.inst_ramAddr_i(pc_pc_o),
    	.ramOp_i(MEM_ramOp_o),
    	.storeData_i(MEM_storeData_o),
    	.load_data_i(ext_load_data_o),
    	.load_inst_i(base_load_data_o),
    	
    	.ramOp_o(MMU_ramOp_o),
    	.load_data_o(MMU_load_data_o),
    	.load_inst_o(MMU_load_inst_o),
    	.storeData_o(MMU_storeData_o),
    	.instAddr_o(MMU_instAddr_o),
    	.dataAddr_o(MMU_dataAddr_o)
    );
    
    inst_sram_control inst_sram_control0(
		.rst(rst),
		.ramAddr_i(MMU_instAddr_o),
	
		.loadData_o(base_load_data_o),
		.WE_n_o(base_WE_n_o),
		.OE_n_o(base_OE_n_o),
		.CE_n_o(base_CE_n_o),
		.be_n_o(base_be_n_o),
		.ramAddr_o(base_ramAddr_o),
	
		.data_io(inst_io)
    );

endmodule
    
    
    
