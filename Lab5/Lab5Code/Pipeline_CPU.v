`timescale 1ns/1ps
module Pipeline_CPU(
    clk_i,
    rst_i
);

//I/O port
input         clk_i;
input         rst_i;

//Internal Signals
wire [31:0] PC_i;           // input in IF, output in IF
wire [31:0] PC_o;           // input in IF, output in IF, input in IF/ID
wire [31:0] MUXMemtoReg_o;  // input in ID, input in EXE, output in WB
wire [31:0] ALUResult;      // output in EXE, input in EXE
wire [31:0] MUXALUSrc_o;    // output in EXE, input in EXE
wire [31:0] Decoder_o;      // output in ID, input in ID
wire [31:0] RSdata_o;       // output in ID, input in ID/EXE
wire [31:0] RTdata_o;       // output in ID, input in ID/EXE
wire [31:0] Imm_Gen_o;      // output in ID, input in ID/EXE, 
wire [31:0] ALUSrc1_o;      // output in EXE, input in EXE
wire [31:0] ALUSrc2_o;      // output in EXE, input in EXE
wire [31:0]  MUX_control_o;  // output in ID, input in ID/EXE 

wire [31:0] PC_Add_Immediate;   // input in IF, output in ID
wire [1:0] ALUOp;               // output in ID, input in ID
wire PC_write;                  // input in IF, output in ID
wire ALUSrc;                    // output in ID, input in ID
wire RegWrite;                  // output in ID, input in ID
wire Branch;                    // output in ID, input in ID
wire MUXControl;                // generated by hazard detection unit // output in ID, input in ID
wire Jump;                      // output in ID, input in ID
wire [31:0] SL1_o;              // output in ID, input in ID
wire [3:0] ALU_Ctrl_o;          // output in EXE, input in EXE
wire ALU_zero;                  // output in EXE, input in EXE
wire Branch_zero;
wire MUXPCSrc;                  // input in IF
wire [31:0] DM_o;               // output in MEM, input in MEM
wire MemtoReg;                  // output in ID, 
wire MemRead;                   // output in ID, input in ID
wire MemWrite;                  // output in ID, 
wire [1:0] ForwardA;            // output in EXE, input in EXE
wire [1:0] ForwardB;            // output in EXE, input in EXE
wire [31:0] PC_Add4;            // input in IF, output in IF


//Pipeline Register Signals
//IFID
wire [31:0] IFID_PC_o;          
wire [31:0] IFID_Instr_o;       
wire IFID_Write;                
wire IFID_Flush;                
wire [31:0]IFID_PC_Add4_o;       

//IDEXE
wire [31:0] IDEXE_Instr_o;
wire [2:0] IDEXE_WB_o;
wire [1:0] IDEXE_Mem_o;
wire [2:0] IDEXE_Exe_o;
wire [31:0] IDEXE_PC_o;
wire [31:0] IDEXE_RSdata_o;
wire [31:0] IDEXE_RTdata_o;
wire [31:0] IDEXE_ImmGen_o;
wire [3:0] IDEXE_Instr_30_14_12_o;
wire [4:0] IDEXE_Instr_11_7_o;
wire [31:0]IDEXE_PC_add4_o;

//EXEMEM
wire [31:0] EXEMEM_Instr_o;
wire [2:0] EXEMEM_WB_o;
wire [1:0] EXEMEM_Mem_o;
wire [31:0] EXEMEM_PCsum_o;
wire EXEMEM_Zero_o;
wire [31:0] EXEMEM_ALUResult_o; 
wire [31:0] EXEMEM_RTdata_o;
wire [4:0]  EXEMEM_Instr_11_7_o;
wire [31:0] EXEMEM_PC_Add4_o;

//MEMWB
wire [2:0] MEMWB_WB_o;
wire [31:0] MEMWB_DM_o;
wire [31:0] MEMWB_ALUresult_o;
wire [4:0]  MEMWB_Instr_11_7_o;
wire [31:0] MEMWB_PC_Add4_o;

// wire
wire [31:0] imm_4 = 4;          // input in IF
wire [31:0] imm_zero = 0;       // input in ID
wire [31:0] instr;              // output in IF, input in IF/ID
wire [7:0] MUX_control_8bit_o;

assign Decoder_o = {24'b0, RegWrite, MemtoReg, MemRead, MemWrite, ALUSrc, ALUOp};
assign IFID_Flush = (BRanch & Branch_zero) | Jump;
assign MUX_control_8bit_o = MUX_control_o;
assign Branch_zero = (RSdata_o - RTdata_o == 0);
assign MUXPCSrc = (Branch & Branch_zero) | Jump;

// IF 
MUX_2to1 MUX_PCSrc(
    .data0_i(PC_Add4),
    .data1_i(PC_Add_Immediate),
    .select_i(MUXPCSrc),
    .data_o(PC_i)
);

ProgramCounter PC(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .PCwrite(PC_write),
    .pc_i(PC_i),
    .pc_o(PC_o)
);

Adder PC_plus_4_Adder(
    .src1_i(PC_o),
    .src2_i(imm_4),
    .sum_o(PC_Add4)
);

Instr_Memory IM(
    .addr_i(PC_o),
    .instr_o(instr)
);

IFID_register IFtoID(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .flush(IFID_Flush),
    .IFID_write(IFID_Write),
    .address_i(PC_o),
    .instr_i(instr),
    .pc_add4_i(PC_Add4),
    .address_o(IFID_PC_o),
    .instr_o(IFID_Instr_o),
    .pc_add4_o(IFID_PC_Add4_o)
);

// ID
Hazard_detection Hazard_detection_obj(
    .IFID_regRs(instr[19:15]),
    .IFID_regRt(instr[24:20]),
    .IDEXE_regRd(instr[11:7]),
    .IDEXE_memRead(IDEXE_Mem_o[1]),
    .PC_write(PC_write),
    .IFID_write(IFID_Write),
    .control_output_select(MUXControl)
);

MUX_2to1 MUX_control(
    .data0_i(imm_zero),
    .data1_i(Decoder_o),
    .select_i(MUXControl),
    .data_o(MUX_control_o)
);

Decoder Decoder(
    .instr_i(instr),
    .Branch(Branch),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .ALUOp(ALUOp),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .MemtoReg(MemtoReg),
    .Jump(Jump)
);

Reg_File RF(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .RSaddr_i(instr[19:15]),
    .RTaddr_i(instr[24:20]),
    .RDaddr_i(MEMWB_Instr_11_7_o),
    .RDdata_i(MUXMemtoReg_o),
    .RegWrite_i(MEMWB_WB_o[2]),
    .RSdata_o(RSdata_o),
    .RTdata_o(RTdata_o)
);

Imm_Gen ImmGen(
    .instr_i(instr),
    .Imm_Gen_o(Imm_Gen_o)
);

Shift_Left_1 SL1(
    data_i(Imm_Gen_o),
    data_o(SL1_o)
);

Adder Branch_Adder(
    .src1_i(IFID_PC_o),
    .src2_i(SL1_o),
    .sum_o(PC_Add_Immediate)
);

IDEXE_register IDtoEXE(
    .clk_i (clk_i),
    .rst_i(rst_i),
    .instr_i(IFID_Instr_o),
    .WB_i(MUX_control_8bit_o[7:5]),
    .Mem_i(MUX_control_8bit_o[4:3]),
    .Exe_i(MUX_control_8bit_o[2:0]),
    .data1_i(RSdata_o),
    .data2_i(RTdata_o),
    .immgen_i(Imm_Gen_o),
    .alu_ctrl_instr({IFID_Instr_o[30], IFID_Instr_o[14:12]}),
    .WBreg_i(IFID_Instr[11:7]),
    .pc_add4_i(IFID_PC_Add4_o),
    .instr_o(IDEXE_Instr_o),
    .WB_o(IDEXE_WB_o),
    .Mem_o(IDEXE_Mem_o),
    .Exe_o(IDEXE_Exe_o),
    .data1_o(IDEXE_RSdata_o),
    .data2_o(IDEXE_RTdata_o),
    .immgen_o(IDEXE_ImmGen_o),
    .alu_ctrl_input(IDEXE_Instr_30_14_12_o),
    .WBreg_o(IDEXE_Instr_11_7_o),
    .pc_add4_o(IDEXE_PC_add4_o)
);

// EXE
MUX_2to1 MUX_ALUSrc(
    .data0_i(IDEXE_RTdata_o),
    .data1_i(IDEXE_ImmGen_o),
    .select_i(IDEXE_Exe_o[2]),
    .data_o(MUXALUSrc_o)
);

ForwardingUnit FWUnit(
    .IDEXE_RS1(IDEXE_RSdata_o),
    .IDEXE_RS2(IDEXE_RTdata_o),
    .EXEMEM_RD(EXEMEM_Instr_11_7_o),
    .MEMWB_RD(MEMWB_Instr_11_7_o),
    .EXEMEM_RegWrite(EXEMEM_WB_o[2]),
    .MEMWB_RegWrite(MEMWB_WB_o[2]),
    .ForwardA(ForwardA),
    .ForwardB(ForwardB)
);

MUX_3to1 MUX_ALU_src1(
    .data0_i(IDEXE_RSdata_o),
    .data1_i(MUXMemtoReg_o),
    .data2_i(EXEMEM_ALUResult_o),
    .select_i(ForwardA),
    .data_o(ALUSrc1_o)
);

MUX_3to1 MUX_ALU_src2(
    .data0_i(MUXALUSrc_o),
    .data1_i(MUXMemtoReg_o),
    .data2_i(EXEMEM_ALUResult_o),
    .select_i(ForwardB),
    .data_o(ALUSrc2_o)
);

ALU_Ctrl ALU_Ctrl(
    .instr(IDEXE_Instr_30_14_12_o),
    .ALUOp(IDEXE_Exe_o[1:0]),
    .ALU_Ctrl_o(ALU_Ctrl_o)
);

alu alu(
    .rst_n(rst_i),
    .src1(ALUSrc1_o),
    .src2(ALUSrc2_o),
    .ALU_control(ALU_Ctrl_o),
    .result(ALUResult),
    .Zero(ALU_zero)
);

EXEMEM_register EXEtoMEM(
    .clk_i(clk_i),
	.rst_i(rst_i),
	.instr_i(IDEXE_Instr_o),
	.WB_i(IDEXE_WB_o),
	.Mem_i(IDEXE_Mem_o),
	.zero_i(ALU_zero),
	.alu_ans_i(ALUResult),
	.rtdata_i(ALUSrc2_o),
	.WBreg_i(IDEXE_Instr_11_7_o),
	.pc_add4_i(IDEXE_PC_add4_o),
	.instr_o(EXEMEM_Instr_o),
	.WB_o(EXEMEM_WB_o),
	.Mem_o(EXEMEM_Mem_o),
	.zero_o(EXEMEM_Zero_o),
	.alu_ans_o(EXEMEM_ALUResult_o),
	.rtdata_o(EXEMEM_RTdata_o),
	.WBreg_o(EXEMEM_Instr_11_7_o),
	.pc_add4_o(EXEMEM_PC_Add4_o)
);

// MEM
Data_Memory Data_Memory(
    .clk_i(clk_i),
    .addr_i(EXEMEM_ALUResult_o),
    .data_i(EXEMEM_RTdata_o),
    .MemRead_i(EXEMEM_Mem_o[1]),
    .MemWrite_i(EXEMEM_Mem_o[0]),
    .data_o(DM_o)
);

MEMWB_register MEMtoWB(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .WB_i(EXEMEM_WB_o),
    .DM_i(DM_o),
    .alu_ans_i(EXEMEM_ALUResult_o),
    .WBreg_i(EXEMEM_Instr_11_7_o),
    .pc_add4_i(EXEMEM_PC_Add4_o),
    .WB_o(MEMWB_WB_o),
    .DM_o(MEMWB_DM_o),
    .alu_ans_o(MEMWB_ALUresult_o),
    .WBreg_o(MEMWB_Instr_11_7_o),
    .pc_add4_o(MEMWB_PC_Add4_o)
);

// WB
MUX_3to1 MUX_MemtoReg(
    .data0_i(MEMWB_ALUresult_o),
    .data1_i(MEMWB_DM_o),
    .data2_i(MEMWB_PC_Add4_o),
    .select_i(MEMWB_WB_o[1:0]),
    .data_o(MUXMemtoReg_o)
);

endmodule



