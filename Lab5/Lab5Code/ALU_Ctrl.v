`timescale 1ns/1ps

module ALU_Ctrl(
    input       [4-1:0] instr,
    input       [2-1:0] ALUOp,
    output reg  [4-1:0] ALU_Ctrl_o
);
/* Write your code HERE */

always @(*) begin
    case(ALUOp)
        2'b00: ALU_Ctrl_o <= 4'b0010;
        2'b01: ALU_Ctrl_o <= 4'b0110;
        2'b10:
            begin
                case(instr) 
                    4'b0000: ALU_Ctrl_o <= 4'b0010; // add
                    4'b1000: ALU_Ctrl_o <= 4'b0110; // sub
                    4'b0111: ALU_Ctrl_o <= 4'b0000; // and
                    4'b0110: ALU_Ctrl_o <= 4'b0001; // or
                    4'b0010: ALU_Ctrl_o <= 4'b0111; // slt
                    4'b0100: ALU_Ctrl_o <= 4'b1100; // xor
                    4'b0001: ALU_Ctrl_o <= 4'b1101; // sll
                    4'b1101: ALU_Ctrl_o <= 4'b1110; // sra
                endcase
            end
        2'b11: alu_ctrl_reg <= 4'b0010;
    endcase
end

endmodule
