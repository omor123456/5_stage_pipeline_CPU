
//   (A) EX-stage ALU operands in main ALU cases
//     forwardA / forwardB in {00, 01, 10}
//       00 = ID/EX (register file value latched in EX)
//       01 = MEM/WB (wbData)              <- 2 stages back
//       10 = EX/MEM (memStageValue_MEM)   <- 1 stage back
//     Priority MEM > WB.  X31 never forwards.
//     forwardB also feeds STUR's store data, so stores write the freshest value.
//
//   (B) ID-stage branch operand Db -- 2-level, because branches resolve in ID:
//     forwardDb in {00, 01, 10}
//       00 = regfile Db_raw            <- distance 3+, covered by negedge write
//       01 = memStageValue_MEM         <- 2 stages back
//       10 = exValue (EX combinational) <- 1 stage back
//     Priority EX > MEM > regfile.
//
//     The EX level is REQUIRED: benchmark 3 has "ADDI X0,X31,#2 / CBZ X0" and
//     benchmark 6 has "ADDI X4,X31,#52 / BR X4" back to back.  With branches
//     resolving in ID the producer is still in EX, so its combinational
//     exValue is the only place the value exists.
module forwarding_unit (
    Rn_EX, Rm_EX, Rm_ID,
    Rd_EX, RegWrite_EX, MemRead_EX,
    Rd_MEM, RegWrite_MEM, Rd_WB, RegWrite_WB,
    forwardA, forwardB, forwardDb
);

    input  logic [4:0] Rn_EX, Rm_EX, Rm_ID;
    input  logic [4:0] Rd_EX, Rd_MEM, Rd_WB;
    input  logic       RegWrite_EX, MemRead_EX, RegWrite_MEM, RegWrite_WB;
    output logic [1:0] forwardA, forwardB, forwardDb;

    always_comb begin

        // ============================================================
        // (A) EX-stage forwarding: MEM has priority over WB
        // ============================================================

        // -------- forwardA (operand A: Rn_EX) --------
        if ( RegWrite_MEM == 1'b1 &&  Rd_MEM != 5'b11111 && Rd_MEM == Rn_EX )
        begin
            forwardA = 2'b10;   // forward from MEM stage
        end
        else if ( RegWrite_WB == 1'b1 && Rd_WB != 5'b11111 && Rd_WB == Rn_EX )
        begin
            forwardA = 2'b01;   // forward from WB stage
        end
        else begin
            forwardA = 2'b00;   // no forwarding
        end


        // -------- forwardB (operand B: Rm_EX) --------
        if ( RegWrite_MEM == 1'b1 &&  Rd_MEM != 5'b11111 && Rd_MEM == Rm_EX )
        begin
            forwardB = 2'b10;   // forward from MEM stage
        end
        else if ( RegWrite_WB == 1'b1 && Rd_WB != 5'b11111 && Rd_WB == Rm_EX )
        begin
            forwardB = 2'b01;   // forward from WB stage
        end
        else begin
            forwardB = 2'b00;   // no forwarding
        end


        // ============================================================
        // (B) ID-stage forwarding for branch operand: EX > MEM > regfile
        // ============================================================
        // -------- forwardDb (branch operand: Rm_ID) --------
        if ( RegWrite_EX == 1'b1 && MemRead_EX  == 1'b0 &&  Rd_EX != 5'b11111 && Rd_EX == Rm_ID )
        begin
            forwardDb = 2'b10;   // forward from EX stage
        end
        else if ( RegWrite_MEM == 1'b1 && Rd_MEM != 5'b11111 && Rd_MEM == Rm_ID )
        begin
            forwardDb = 2'b01;   // forward from MEM stage
        end
        else begin
            forwardDb = 2'b00;   // no forwarding
        end

    end
endmodule

