`timescale 1ns/10ps

//   Rn = source reg 1 (instr[9:5])
//   Rm = source reg 2 (Reg2Loc picks Rm=[20:16] or Rd=[4:0])
//   Rd = destination  (LinkReg picks Rd=[4:0] or 5'd30 for BL)
//   Da = value read from Rn port  |  Db = value read from Rm port for both reg file
//   Branch flush AS ENABLE_FLUSH=1: squash delay slot after taken branch

module cpu #(parameter ENABLE_FLUSH = 0) (clk, reset);
    input logic clk, reset;

    // IF
    logic [63:0] PC_IF, PCplus4_IF, pc4_Br, nextPC;
    logic [31:0] instr_IF;

    // ID
    logic [31:0] instr_ID;
    logic [63:0] PC_ID, PCplus4_ID;
    logic        Reg2Loc_ID, ALUSrc_ID, ImmSel_ID, MemToReg_ID, LinkReg_ID,
                 RegWrite_ID, MemRead_ID, MemWrite_ID, SetFlags_ID,
                 UncondBr_ID, BrSel_ID, BZero_ID, BLess_ID;
    logic [1:0]  ALUOp_ID;
    logic [2:0]  ALUcntrl_ID;
    logic [4:0]  Rn_ID, Rm_ID, Rd_ID;
    logic [63:0] Da_ID, Db_raw, Db_lo, Db_ID;
    logic [63:0] imm9_ext, imm12_ext, aluImm_ID;
    logic [63:0] condOff19, brOff26, brOffsetRaw, brOffsetX4, brTargetPC_ID;
    logic [1:0]  forwardDb;
    logic        N_use, V_use;
    logic        isZero_ID, lessThan_ID, cbzHit_ID, ltHit_ID;
    logic        BranchS, useRegTarget_ID, redirect_ID;
    logic        stall, flush_IFID, bubble_IDEX;

    // EX
    logic        RegWrite_EX, MemToReg_EX, MemRead_EX, MemWrite_EX,
                 SetFlags_EX, LinkReg_EX, ALUSrc_EX;
    logic [2:0]  ALUcntrl_EX;
    logic [4:0]  Rn_EX, Rm_EX, Rd_EX;
    logic [63:0] Da_EX, Db_EX, aluImm_EX, PCplus4_EX;
    logic [1:0]  forwardA, forwardB;
    logic [63:0] fwdA_lo, fwdB_lo, aluA, DbFwd, aluB, aluResult, exResult;
    logic        aluN, aluZ, aluV, aluC;
    logic        Nflag, Zflag, Vflag, Cflag;

    // MEM
    logic        RegWrite_MEM, MemToReg_MEM, MemRead_MEM, MemWrite_MEM;
    logic [4:0]  Rd_MEM;
    logic [63:0] exResult_MEM, storeData_MEM, Dout_MEM, memStageValue_MEM;

    // WB
    logic        RegWrite_WB, MemToReg_WB;
    logic [4:0]  Rd_WB;
    logic [63:0] exResult_WB, Dout_WB, wbData;

    // not needed or dummy variables for flags
    logic uN0, uZ0, uV0, uC0, uN1, uZ1, uV1, uC1;


    // IF: fetch, and pick the next PC while selecting signals from ID
    alu pcPlus4Adder (.A(PC_IF), .B(64'd4), .cntrl(3'b010), .result(PCplus4_IF), .negative(uN0), .zero(uZ0), 
                        .overflow(uV0), .carry_out(uC0));

    // taken mux is taking either the pc+4 which is originally or brtarget 
    mux2_1_64 takenMux    (.out(pc4_Br), .select(BranchS), .in0(PCplus4_IF),  .in1(brTargetPC_ID));
    mux2_1_64 brTargetMux (.out(nextPC), .select(useRegTarget_ID), .in0(pc4_Br), .in1(Db_ID));

    // can just use the pipeline reg and don't need a separate pc register from last lab
    pipelineReg #(64) pcReg (.q(PC_IF), .d(nextPC), .flush(1'b0), .hold(stall), .reset(reset), .clk(clk));
    instructmem imem (.address(PC_IF), .instruction(instr_IF), .clk(clk));

    // IF/ID pipeline registers with pcReg above too
    pipelineReg #(32) if_id_instr (.q(instr_ID), .d(instr_IF), .flush(flush_IFID), .hold(stall), .reset(reset), .clk(clk));
    pipelineReg #(64) if_id_pc    (.q(PC_ID), .d(PC_IF), .flush(flush_IFID), .hold(stall), .reset(reset), .clk(clk));
    pipelineReg #(64) if_id_pc4   (.q(PCplus4_ID), .d(PCplus4_IF), .flush(flush_IFID), .hold(stall), .reset(reset), .clk(clk));

    // ID: decode while reading the registers and taking care of branches conditions
    control_Unit ctrl (.Reg2Loc(Reg2Loc_ID), .ALUSrc(ALUSrc_ID), .ImmSel(ImmSel_ID),
                       .ALUOp(ALUOp_ID), .MemToReg(MemToReg_ID), .LinkReg(LinkReg_ID),
                       .RegWrite(RegWrite_ID), .MemRead(MemRead_ID), .MemWrite(MemWrite_ID),
                       .SetFlags(SetFlags_ID), .UncondBr(UncondBr_ID), .BrSel(BrSel_ID),
                       .BZero(BZero_ID), .BLess(BLess_ID), .opcode(instr_ID[31:21]));

    ALU_control alu_dec (.cntrl(ALUcntrl_ID), .ALUop(ALUOp_ID), .instruction(instr_ID));

    assign Rn_ID = instr_ID[9:5]; 
    // need the 20-16 for R types of add/sub and Rt/Rd for CBZ, BR/stur etc.
    mux2_1_5bits reg2LocMux  (.out(Rm_ID), .select(Reg2Loc_ID), .in0(instr_ID[4:0]), .in1(instr_ID[20:16]));
    mux2_1_5bits linkAddrMux (.out(Rd_ID), .select(LinkReg_ID), .in0(instr_ID[4:0]), .in1(5'd30));

    // negedge write regfile: WB commits mid-cycle, ID sees so we can read/write on the same clock cycle
    // changed my reg file from just dff to dffNeg as thats when reg file is getting rewritten but 
    // all other operations are being done with pos edge like pipelines/mem etc registers 
    regfile rf (.ReadData1(Da_ID), .ReadData2(Db_raw), .WriteData(wbData),
                .ReadRegister1(Rn_ID), .ReadRegister2(Rm_ID),
                .WriteRegister(Rd_WB), .RegWrite(RegWrite_WB),
                .reset(reset), .clk(clk));

    // One forwarding_unit produces three selects because we read registers in two
    // stages of forwardA/B pick freshest values into the ALU in EX (from MEM or WB),
    // and forwardDb picks freshest value into branch_unit in ID (from EX or MEM) as with different instruction came before it
    forwarding_unit fwd (
        .Rn_EX(Rn_EX), .Rm_EX(Rm_EX), .Rm_ID(Rm_ID),
        .Rd_EX(Rd_EX), .RegWrite_EX(RegWrite_EX), .MemRead_EX(MemRead_EX),
        .Rd_MEM(Rd_MEM), .RegWrite_MEM(RegWrite_MEM),
        .Rd_WB(Rd_WB),   .RegWrite_WB(RegWrite_WB),
        .forwardA(forwardA), .forwardB(forwardB), .forwardDb(forwardDb));

    // Db 2-level forward mux, same shape as forwardA/forwardB in EX
    //   00 = regfile's Db_raw 
    //   01 = memStageValue_MEM (producer 2 stages back)
    //   10 = exResult          (producer 1 stage back, combinational)
    // priority EX > MEM > regfile for "ADDI X0 / CBZ X0" and "ADDI X4 / BR X4" back-to-back pairs in the benchmarks
    mux2_1_64 dbFwd0 (.out(Db_lo), .select(forwardDb[0]), .in0(Db_raw), .in1(memStageValue_MEM));
    mux2_1_64 dbFwd1 (.out(Db_ID), .select(forwardDb[1]), .in0(Db_lo),  .in1(exResult));

    // ALU immediate
    signExtend #(.WIDTH(9)) extDAddr9 (imm9_ext,  instr_ID[20:12]);
    zeroExtend  extImm12  (imm12_ext, instr_ID[21:10]);
    mux2_1_64 immMux (.out(aluImm_ID), .select(ImmSel_ID), .in0(imm9_ext), .in1(imm12_ext));

    // Branch target = PC_ID + (SE(imm) << 2)
    signExtend #(.WIDTH(19)) extCond19 (condOff19, instr_ID[23:5]);
    signExtend #(.WIDTH(26)) extBr26 (brOff26,   instr_ID[25:0]);
    mux2_1_64 brImmMux (.out(brOffsetRaw), .select(UncondBr_ID), .in0(condOff19), .in1(brOff26));
    LSL_2bit  shiftBy4 (.out(brOffsetX4), .in(brOffsetRaw));
    alu brTargetAdder (.A(PC_ID), .B(brOffsetX4), .cntrl(3'b010), .result(brTargetPC_ID), .negative(uN1), .zero(uZ1), .overflow(uV1), .carry_out(uC1));

    // FLAG EX-FORWARD FOR B.LT
    // If instruction in EX has SetFlag_EX=1 for ADDS/SUBS, only then use aluN/aluV in the current cycle or use the flag register for setflag to 0
    mux2_1 nUseMux (.out(N_use), .select(SetFlags_EX), .in({aluN, Nflag}));
    mux2_1 vUseMux (.out(V_use), .select(SetFlags_EX), .in({aluV, Vflag}));

    // BRANCH CONDITION and redirect = takePCRel OR useRegTarget 
    zero64 zeroCheck (.out(isZero_ID), .in(Db_ID));  //similar to the alu zero conditions for Db_ID checking 0
    xor #0.05 xorNV     (lessThan_ID,  N_use,  V_use); //for signed LT checking from the flags
    and #0.05 ltGate    (ltHit_ID,  BLess_ID, lessThan_ID); //checking the BLT path with CU signals for BLEss
    and #0.05 cbzGate   (cbzHit_ID,  BZero_ID, isZero_ID);  //checking the CBZ path with CU signals for Bzero
    or  #0.05 takeGate  (BranchS,    UncondBr_ID,  cbzHit_ID, ltHit_ID);  //checking the signals as if either the Uncond, cbzHit, Lt hit is true
    assign useRegTarget_ID = BrSel_ID;  // BR uses register-indirect target; wire BrSel straight through as the useRegTarget select
    or  #0.05 redirGate (redirect_ID, BranchS, useRegTarget_ID); //flush the IF/ID pipeline register when a branch is taken or when a register target is used for redirect



    // hazard_unit: covering load use stall + branch instruction flush with enable flush  
    hazard_unit #(.ENABLE_FLUSH(ENABLE_FLUSH)) hzd (.MemRead_EX(MemRead_EX), .Rd_EX(Rd_EX), .Rn_ID(Rn_ID), .Rm_ID(Rm_ID), 
                              .redirect_ID(redirect_ID), .stall(stall), .flush_IFID(flush_IFID), .bubble_IDEX(bubble_IDEX));



    // ID/EX all the pipeline registers 
    pipelineReg #(10) id_ex_ctrl ( .q({RegWrite_EX, MemToReg_EX, MemRead_EX, MemWrite_EX, SetFlags_EX, LinkReg_EX, ALUSrc_EX, ALUcntrl_EX}),
        .d({RegWrite_ID, MemToReg_ID, MemRead_ID, MemWrite_ID, SetFlags_ID, LinkReg_ID, ALUSrc_ID, ALUcntrl_ID}), .flush(bubble_IDEX), .hold(1'b0), .reset(reset), .clk(clk));
855 267 7451  prof finance compay 26663227

    pipelineReg #(64) id_ex_da  (.q(Da_EX),      .d(Da_ID),      .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(64) id_ex_db  (.q(Db_EX),      .d(Db_ID),      .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(64) id_ex_imm (.q(aluImm_EX),  .d(aluImm_ID),  .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(64) id_ex_pc4 (.q(PCplus4_EX), .d(PCplus4_ID), .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(5)  id_ex_rn  (.q(Rn_EX),      .d(Rn_ID),      .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(5)  id_ex_rm  (.q(Rm_EX),      .d(Rm_ID),      .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(5)  id_ex_rd  (.q(Rd_EX),      .d(Rd_ID),      .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));


    // EX: case 1-2 EX forwarding and main ALU with aluSrc muxes
    mux2_1_64 fwdA0 (.out(fwdA_lo), .select(forwardA[0]), .in0(Da_EX),   .in1(wbData));
    mux2_1_64 fwdA1 (.out(aluA),    .select(forwardA[1]), .in0(fwdA_lo), .in1(memStageValue_MEM));
    mux2_1_64 fwdB0 (.out(fwdB_lo), .select(forwardB[0]), .in0(Db_EX),   .in1(wbData));
    mux2_1_64 fwdB1 (.out(DbFwd),   .select(forwardB[1]), .in0(fwdB_lo), .in1(memStageValue_MEM));

    mux2_1_64 aluSrcMux (.out(aluB), .select(ALUSrc_EX), .in0(DbFwd), .in1(aluImm_EX));
    alu mainALU (.A(aluA), .B(aluB), .cntrl(ALUcntrl_EX), .result(aluResult), .negative(aluN), .zero(aluZ), .overflow(aluV), .carry_out(aluC));
    // BL's writeback value is PC+4 from prev stages and muxing it as the EX output so the forwarding path handles the link register
    // exResult = the EX stage's output as ALU result for arithmetic, memory address for LDUR/STUR, or PC+4 for BL
    mux2_1_64 linkValueMux (.out(exResult), .select(LinkReg_EX), .in0(aluResult), .in1(PCplus4_EX));

    // flag registers
    D_FF_en negFlag  (.q(Nflag), .d(aluN), .en(SetFlags_EX), .reset(reset), .clk(clk));
    D_FF_en zeroFlag (.q(Zflag), .d(aluZ), .en(SetFlags_EX), .reset(reset), .clk(clk));
    D_FF_en ovfFlag  (.q(Vflag), .d(aluV), .en(SetFlags_EX), .reset(reset), .clk(clk));
    D_FF_en carFlag  (.q(Cflag), .d(aluC), .en(SetFlags_EX), .reset(reset), .clk(clk));

    // EX/MEM pipeline registers to hold the values
    pipelineReg #(4)  ex_mem_ctrl ( .q({RegWrite_MEM, MemToReg_MEM, MemRead_MEM, MemWrite_MEM}), .d({RegWrite_EX,  MemToReg_EX,  MemRead_EX,  MemWrite_EX}), .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));


    pipelineReg #(64) ex_mem_val (.q(exResult_MEM), .d(exResult), .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(64) ex_mem_st (.q(storeData_MEM), .d(DbFwd),   .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(5)  ex_mem_rd (.q(Rd_MEM), .d(Rd_EX),   .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));


    // MEM: data memory and the MEM stage forwarding value
    datamem dmem (.address(exResult_MEM), .write_enable(MemWrite_MEM), .read_enable(MemRead_MEM), .write_data(storeData_MEM),
                    .clk(clk), .xfer_size(4'd8), .read_data(Dout_MEM));

    mux2_1_64 memValueMux (.out(memStageValue_MEM), .select(MemToReg_MEM), .in0(exResult_MEM), .in1(Dout_MEM));



    // MEM/WB state registers 
    pipelineReg #(1)  mem_wb_regw  (.q(RegWrite_WB), .d(RegWrite_MEM), .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(1)  mem_wb_m2r (.q(MemToReg_WB), .d(MemToReg_MEM), .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(64) mem_wb_exval (.q(exResult_WB), .d(exResult_MEM),  .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(64) mem_wb_dout  (.q(Dout_WB), .d(Dout_MEM), .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));
    pipelineReg #(5)  mem_wb_rd (.q(Rd_WB), .d(Rd_MEM), .flush(1'b0), .hold(1'b0), .reset(reset), .clk(clk));

    // WB: MemToReg mux for last stage
    mux2_1_64 WB_Mux (.out(wbData), .select(MemToReg_WB), .in0(exResult_WB), .in1(Dout_WB));



endmodule






module zero64 (out, in);
    output logic out;
    input  logic [63:0] in;
    logic [15:0] nor4;
    logic [3:0]  and4;

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : each4
            nor #0.05 zg (nor4[i], in[i*4], in[i*4+1], in[i*4+2], in[i*4+3]);
        end
    endgenerate

    and #0.05 a0 (and4[0], nor4[0],  nor4[1],  nor4[2],  nor4[3]);
    and #0.05 a1 (and4[1], nor4[4],  nor4[5],  nor4[6],  nor4[7]);
    and #0.05 a2 (and4[2], nor4[8],  nor4[9],  nor4[10], nor4[11]);
    and #0.05 a3 (and4[3], nor4[12], nor4[13], nor4[14], nor4[15]);
    and #0.05 aF (out,     and4[0],  and4[1],  and4[2],  and4[3]);
endmodule