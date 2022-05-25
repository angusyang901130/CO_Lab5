`timescale 1ns/1ps

module Decoder(
    input      [32-1:0] instr_i,
    output reg          Branch,
    output reg          ALUSrc,
    output reg          RegWrite,
    output reg [2-1:0]  ALUOp,
    output reg          MemRead,
    output reg          MemWrite,
    output reg          MemtoReg,
    output reg          Jump
);

//Internal Signals
wire    [7-1:0]     opcode;
wire    [3-1:0]     funct3;
wire    [3-1:0]     Instr_field;
wire    [9:0]       Ctrl_o;

/* Write your code HERE */

assign opcode = instr_i[7-1:0];
assign funct3 = instr_i[14:12];
assign Instr_field = {instr_i[30], funct3};

parameter [7-1:0] Rtype =  7'b0110011;
parameter [7-1:0] Itype =  7'b0010011;
parameter [7-1:0] load =   7'b0000011;
parameter [7-1:0] store =  7'b0100011;
parameter [7-1:0] branch = 7'b1100011;
parameter [7-1:0] jal =    7'b1101111;
parameter [7-1:0] jalr =   7'b1100111;

assign Ctrl_o[9] = (opcode == Rtype) || (opcode == Itype) || (opcode == load) || (opcode == jal) || (opcode == jalr); // RegWrite
assign Ctrl_o[8] = (opcode == branch); // branch
assign Ctrl_o[7] = (opcode == jal) || (opcode == jalr); // jump
assign Ctrl_o[6] = (opcode == load);
//assign Ctrl_o[5] = (instr_i == jal) || (instr_i == jalr); // memtoreg
assign Ctrl_o[4] = (opcode == load); // memread
assign Ctrl_o[3] = (opcode == store); // memwrite
assign Ctrl_o[2] = (opcode == Itype) || (opcode == load) || (opcode == store); // ALUSrc
assign Ctrl_o[1] = (opcode == Rtype) || (opcode == Itype); // ALUOp[1]
assign Ctrl_o[0] = (opcode == Itype) || (opcode == branch); // ALUOp[0]


endmodule







