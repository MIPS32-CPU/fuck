module pc(
    input wire clk,
    input wire rst,
    input wire branchEnable_i,
    input wire [31:0] branchAddr_i,
    input wire [5:0] stall,
    
    output reg [31:0] pc_o
    //output reg [3:0] ramOp_o
    );
    
    always @ (posedge clk) begin
        if(rst == 1'b1) begin
            pc_o <= 32'h80000000;
        end else if(stall[0] == 1'b0) begin
            if(branchEnable_i == 1'b1) begin
                pc_o <= branchAddr_i;
                
            end else begin
                pc_o <= pc_o + 4'h4;
                
            end
        end 
    end
 endmodule
