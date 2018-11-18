`include<defines.v>

module ID(
    input wire clk,
    input wire rst,
    input wire [31:0] inst_i,
    input wire [31:0] pc_i,
    
    input wire [31:0] readData1_i,
    input wire [31:0] readData2_i,
    
    //data from HILO registers
    input wire [31:0] HI_data_i,
    input wire [31:0] LO_data_i,
    
    //EX bypass signals  
    input wire [4:0] EX_writeAddr_i,
    input wire EX_writeEnable_i,
    input wire[1:0] EX_writeHILO_i,
    input wire [31:0] EX_writeHI_data_i,
    input wire [31:0] EX_writeLO_data_i,
    
    //MEM bypass signals
    input wire [4:0] MEM_writeAddr_i,
    input wire MEM_writeEnable_i,
    input wire [1:0] MEM_writeHILO_i,
    input wire [31:0] MEM_writeHI_data_i,
    input wire [31:0] MEM_writeLO_data_i,
    
    //about the load conflict
    input wire [3:0] EX_ramOp_i,
    
    output reg [4:0] readAddr1_o,
    output reg [4:0] readAddr2_o,
    output reg readEnable1_o,
    output reg readEnable2_o,
    output reg [4:0] writeAddr_o,
    output reg writeEnable_o,
    
    output reg [1:0] writeHILO_o,
    
    output reg [31:0] oprand1_o,
    output reg [31:0] oprand2_o,
    output reg branchEnable_o,
    output reg [31:0] branchAddr_o,
    output reg [4:0] ALUop_o,
    output reg signed_o,
    
    output wire [31:0] inst_o,
    output wire [31:0] pc_o,
    output reg pauseRequest
);
	assign inst_o = inst_i;
	assign pc_o = pc_i;
	
    wire [5:0] inst_op = inst_i[31:26];
    wire [4:0] inst_rs = inst_i[25:21];
    wire [4:0] inst_rt = inst_i[20:16];
    wire [4:0] inst_rd = inst_i[15:11];
    wire [4:0] inst_shamt = inst_i[10:6];
    wire [5:0] inst_func = inst_i[5:0];
    
    reg [1:0] readHILO;
    reg [31:0] imm;
    
    wire load_conflict;
    wire [31:0] pc_plus_4, pc_plus_8;
    
    assign pc_plus_4 = pc_i + 32'h4;
    assign pc_plus_8 = pc_i + 32'h8;
    
    //get the stall request 
    assign load_conflict = (EX_ramOp_i == `MEM_LW) || 
    					   (EX_ramOp_i == `MEM_LB) || 
    					   (EX_ramOp_i == `MEM_LH) || 
    					   (EX_ramOp_i == `MEM_LBU) || 
    					   (EX_ramOp_i == `MEM_LHU);
    always @(*) begin
    	if(rst == 1'b1) begin
    		pauseRequest <= 1'b0;
    	end else begin
    		if(EX_writeAddr_i == readAddr1_o && readEnable1_o == 1'b1 || 
    		   EX_writeAddr_i == readAddr2_o && readEnable2_o == 1'b1) begin
    			pauseRequest <= load_conflict;
    		end else begin
    			pauseRequest <= 1'b0;
    		end
    	end
    end
    								
    
    //get the first operand
    always @ (*) begin
    	if (rst == 1'b1) begin
    		oprand1_o <= 32'b0;
    	end else if(readHILO == 2'b10 && EX_writeHILO_i[1] == 1'b1) begin
    		oprand1_o <= EX_writeHI_data_i;
    	end else if(readHILO == 2'b01 && EX_writeHILO_i[0] == 1'b1) begin
    		oprand1_o <= EX_writeLO_data_i;
    	end else if(readHILO == 2'b10 && MEM_writeHILO_i[1] == 1'b1) begin
    		oprand1_o <= MEM_writeHI_data_i;
    	end else if(readHILO == 2'b01 && MEM_writeHILO_i[0] == 1'b1) begin
    		oprand1_o <= MEM_writeLO_data_i;
    	end else if(readHILO == 2'b10) begin
    		oprand1_o <= HI_data_i;
    	end else if(readHILO == 2'b01) begin
    		oprand1_o <= LO_data_i;	
    	end else if(readEnable1_o == 1'b1 && EX_writeEnable_i == 1'b1 &&
    				EX_writeAddr_i == readAddr1_o) begin
    		oprand1_o <= EX_writeLO_data_i;
  		end else if(readEnable1_o == 1'b1 && MEM_writeEnable_i == 1'b1 &&
  					MEM_writeAddr_i == readAddr1_o) begin
  			oprand1_o <= MEM_writeLO_data_i;
  		end else if(readEnable1_o == 1'b1) begin
  			oprand1_o <= readData1_i;
  		end else if(readEnable1_o == 1'b0) begin
  			oprand1_o <= imm;
  		end else begin
  			oprand1_o <= 32'b0;
  		end
  	end
  	
  	//get the second oprand
  	always @ (*) begin
		if (rst == 1'b1) begin
			oprand2_o <= 32'b0;
		end else if(readEnable2_o == 1'b1 && EX_writeEnable_i == 1'b1 &&
					EX_writeAddr_i == readAddr2_o) begin
			oprand2_o <= EX_writeLO_data_i;
		end else if(readEnable2_o == 1'b1 && MEM_writeEnable_i == 1'b1 &&
					MEM_writeAddr_i == readAddr2_o) begin
			oprand2_o <= MEM_writeLO_data_i;
		end else if(readEnable2_o == 1'b1) begin
			oprand2_o <= readData2_i;
		end else if(readEnable2_o == 1'b0) begin
			oprand2_o <= imm;
		end else begin
			oprand2_o <= 32'b0;
		end
	end
    	
    //decode the instructions	
    always @ (*) begin
        if(rst == 1'b1) begin
            readAddr1_o <= 5'b0;
            readAddr2_o <= 5'b0;
            readEnable1_o <= 1'b0;
            readEnable2_o <= 1'b0;
            readHILO <= 2'b00;
            imm <= 32'b0;
            writeAddr_o <= 4'b0;
            writeEnable_o <= 1'b0;
            branchEnable_o <= 1'b0;
            branchAddr_o <= 32'b0;
            writeHILO_o <= 2'b00;
            ALUop_o <= `ALU_NOP;
            signed_o <= 1'b0;
            
         end else begin
         	//assign the default values
			readAddr1_o <= 5'b0;
			readAddr2_o <= 5'b0;
			readEnable1_o <= 1'b0;
			readEnable2_o <= 1'b0;
			readHILO <= 2'b00;
			imm <= 32'b0;
			writeAddr_o <= 5'b0;
			writeEnable_o <= 1'b0;
			branchEnable_o <= 1'b0;
			branchAddr_o <= 32'b0;
			ALUop_o <= `ALU_NOP;
			writeHILO_o <= 2'b00;
			signed_o <= 1'b0;
			
          	case (inst_op)
                
                /**********load/store instructions***********/
                `OP_SW: begin
                	readEnable1_o <= 1'b1;
                	readAddr1_o <= inst_rs;
                	readEnable2_o <= 1'b1;
                	readAddr2_o <= inst_rt;
                	ALUop_o <= `ALU_SW;	
                end
                
                `OP_SB: begin
                	readEnable1_o <= 1'b1;
                	readAddr1_o <= inst_rs;
                	readEnable2_o <= 1'b1;
                	readAddr2_o <= inst_rt;
                	ALUop_o <= `ALU_SB;
                end
                
                `OP_SH: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					readEnable2_o <= 1'b1;
					readAddr2_o <= inst_rt;
					ALUop_o <= `ALU_SH;
				end
                
                `OP_LW: begin
                	readEnable1_o <= 1'b1;
                	readAddr1_o <= inst_rs;
                	writeEnable_o <= 1'b1;
                	writeAddr_o <= inst_rt;
                	imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                	ALUop_o <= `ALU_LW;
                end
                
                `OP_LB: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_LB;
				end
				
				`OP_LH: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_LH;
				end
				
				`OP_LBU: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_LBU;
				end
								
				`OP_LHU: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_LHU;
				end
                /**********load/store end*********/
                
                `OP_ADDI: begin
                	readEnable1_o <= 1'b1;
                	readAddr1_o <= inst_rs;
                	writeEnable_o <= 1'b1;
                	writeAddr_o <= inst_rt;
                	imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                	signed_o <= 1'b1;
                	ALUop_o <= `ALU_ADD;
                end
                
                `OP_ADDIU: begin
                	readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_ADD;
				end
				
				`OP_SLTI: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					signed_o <= 1'b1;
					ALUop_o <= `ALU_SLT;
				end
				
				`OP_SLTIU: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_SLT;
				end
				
				`OP_ANDI: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					imm <= {16'b0, inst_i[15:0]};
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					ALUop_o <= `ALU_AND;
				end
				
				
                `OP_ORI: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					imm <= {16'b0, inst_i[15:0]};
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					ALUop_o <= `ALU_OR;	
				end
				
				`OP_XORI: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					imm <= {16'b0, inst_i[15:0]};
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					ALUop_o <= `ALU_XOR;	
				end
				
				
				`OP_LUI: begin
					imm <= {inst_i[15:0], 16'b0};
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					ALUop_o <= `ALU_MOV;
				end
					
				`OP_J: begin
    				branchEnable_o <= 1'b1;
    				branchAddr_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b0};
    			end
    			
    			`OP_JAL: begin
    				branchEnable_o <= 1'b1;
					writeEnable_o <= 1'b1;
					writeAddr_o <= 5'd31;
					ALUop_o <= `ALU_BAJ;
					imm <= pc_plus_8;
    				branchAddr_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b0};
    			end
    			
    			`OP_BEQ: begin
    				readEnable1_o <= 1'b1;
    				readAddr1_o <= inst_rs;
    				readEnable2_o <= 1'b1;
    				readAddr2_o <= inst_rt;
    				
    				if(oprand1_o == oprand2_o) begin
    					branchEnable_o <= 1'b1;
    					branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
    				end else begin
    					branchEnable_o <= 1'b0;
    				end
    			end
    			
    			`OP_BNE: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					readEnable2_o <= 1'b1;
					readAddr2_o <= inst_rt;
					
					if(oprand1_o != oprand2_o) begin
						branchEnable_o <= 1'b1;
						branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
					end else begin
						branchEnable_o <= 1'b0;
					end
				end
    			
    			`OP_BLEZ: begin
    				readEnable1_o <= 1'b1;
    				readAddr1_o <= inst_rs;
    				
    				if(oprand1_o[31] == 1'b1 || oprand1_o == 32'b0) begin
    					branchEnable_o <= 1'b1;
    					branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
					end else begin
						branchEnable_o <= 1'b0;
					end
				end
    			
    			`OP_BGTZ: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					
					if(oprand1_o[31] != 1'b1 && oprand1_o != 32'b0) begin
						branchEnable_o <= 1'b1;
						branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
					end else begin
						branchEnable_o <= 1'b0;
					end
				end
                				
            	`OP_SPECIAL: begin
            		case(inst_func)
            			`FUNC_ADD: begin
            				readEnable1_o <= 1'b1;
            				readAddr1_o <= inst_rs;
            				readEnable2_o <= 1'b1;
            				readAddr2_o <= inst_rt;
            				writeEnable_o <= 1'b1;
            				writeAddr_o <= inst_rd;
            				signed_o <= 1'b1;
            				ALUop_o <= `ALU_ADD;
            			end
            			
            			`FUNC_ADDU: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_ADD;
						end
						
						`FUNC_SUB: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							signed_o <= 1'b1;
							ALUop_o <= `ALU_SUB;
						end
            			
            			`FUNC_SUBU: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_SUB;
						end
						
						`FUNC_AND: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_AND;
						end
						
						`FUNC_OR: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_OR;
						end
						
						`FUNC_XOR: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_XOR;
						end	

						`FUNC_NOR: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_NOR;
						end	
						
						`FUNC_SLT: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							signed_o <= 1'b1;
							ALUop_o <= `ALU_SLT;
						end	

						`FUNC_SLTU: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_SLT;
						end	

						`FUNC_SLL: begin	
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rt;
							imm <= inst_shamt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_SLL;
						end

						`FUNC_SRL: begin	
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rt;
							imm <= inst_shamt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_SRL;
						end

						`FUNC_SRA: begin	
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rt;
							imm <= inst_shamt;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_SRA;
						end

						`FUNC_SLLV: begin	
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rt;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rs;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_SLL;
						end

						`FUNC_SRLV: begin	
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rt;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rs;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_SRL;
						end

						`FUNC_SRAV: begin	
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rt;
							readEnable2_o <= 1'b1;
							readAddr2_o <= inst_rs;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							ALUop_o <= `ALU_SRA;
						end

						`FUNC_MULT: begin
            				writeHILO_o <= 2'b11;
            				readEnable1_o <= 1'b1;
            				readAddr1_o <= inst_rs;
            				readEnable2_o <= 1'b1;
            				readAddr2_o <= inst_rt;
							signed_o <= 1'b1;
            				ALUop_o <= `ALU_MULT;
            			end

						`FUNC_MULTU: begin
							writeHILO_o <= 2'b11;
            				readEnable1_o <= 1'b1;
            				readAddr1_o <= inst_rs;
            				readEnable2_o <= 1'b1;
            				readAddr2_o <= inst_rt;
            				ALUop_o <= `ALU_MULT;
            			end

						`FUNC_DIV: begin
            				writeHILO_o <= 2'b11;
            				readEnable1_o <= 1'b1;
            				readAddr1_o <= inst_rs;
            				readEnable2_o <= 1'b1;
            				readAddr2_o <= inst_rt;
							signed_o <= 1'b1;
            				ALUop_o <= `ALU_DIV;
            			end

						`FUNC_DIVU: begin
            				writeHILO_o <= 2'b11;
            				readEnable1_o <= 1'b1;
            				readAddr1_o <= inst_rs;
            				readEnable2_o <= 1'b1;
            				readAddr2_o <= inst_rt;
            				ALUop_o <= `ALU_DIV;
            			end

            			`FUNC_MFHI: begin
            				readHILO <= 2'b10;
            				writeEnable_o <= 1'b1;
            				writeAddr_o <= inst_rd;
            				ALUop_o <= `ALU_MOV;
            			end
            			
            			`FUNC_MTHI: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
            				writeHILO_o <= 2'b10;
            				ALUop_o <= `ALU_MOV;
            			end
            			
            			`FUNC_MFLO: begin
            				readHILO <= 2'b01;
            				writeEnable_o <= 1'b1;
            				writeAddr_o <= inst_rd;
            				ALUop_o <= `ALU_MOV;
            			end
            			
            			`FUNC_MTLO: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
            				writeHILO_o <= 2'b01;
            				ALUop_o <= `ALU_MOV;
            			end

						`FUNC_JR: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							branchEnable_o <= 1'b1;
							branchAddr_o <= oprand1_o;
						end
						
						`FUNC_JALR: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rd;
							imm <= pc_plus_8;
							ALUop_o <= `ALU_BAJ;
							
							branchEnable_o <= 1'b1;
							branchAddr_o <= oprand1_o;
						end
            		endcase
            	end

				`OP_REGIMM: begin
					case(inst_rt) 
						`RT_BLTZ: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							
							if(oprand1_o[31] == 1'b1) begin
								branchEnable_o <= 1'b1;
								branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
							end else begin
								branchEnable_o <= 1'b0;
							end
						end
						
						`RT_BGEZ: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							
							if(oprand1_o[31] == 1'b0) begin
								branchEnable_o <= 1'b1;
								branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
							end else begin
								branchEnable_o <= 1'b0;
							end
						end
						
						`RT_BLTZAL: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							writeEnable_o <= 1'b1;
							writeAddr_o <= 5'd31;
							imm <= pc_plus_8;
							ALUop_o <= `ALU_BAJ;
							
							if(oprand1_o[31] == 1) begin
								branchEnable_o <= 1'b1;
								branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
							end else begin
								branchEnable_o <= 1'b0;
							end
						end
						
						`RT_BGEZAL: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							writeEnable_o <= 1'b1;
							writeAddr_o <= 5'd31;
							imm <= pc_plus_8;
							ALUop_o <= `ALU_BAJ;
							
							if(oprand1_o[31] == 0) begin
								branchEnable_o <= 1'b1;
								branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
							end else begin
								branchEnable_o <= 1'b0;
							end
						end
					endcase
				end

            endcase
        end
    end
endmodule
      