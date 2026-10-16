`timescale 1ns/10ps

// Opcode widths 6, 8, 10, or 11 bits The leftover low
// bits of the [31:21] window belong to the immediate field, so they are
// don't-cares. casex treats x in the pattern as a wildcard.
module control_Unit (Reg2Loc, ALUSrc, ImmSel, ALUOp, MemToReg, LinkReg, RegWrite, MemRead, MemWrite, SetFlags, 
                 UncondBr, BrSel, BZero, BLess, opcode);

    input  logic [10:0] opcode;      // instruction[31:21]

    output logic        Reg2Loc;     // 0 = Rd [4:0],  1 = Rm [20:16]
    output logic        ALUSrc;      // 0 = Db,        1 = immediate
    output logic        ImmSel;      // 0 = SE(DAddr9), 1 = ZE(Imm12)
    output logic [1:0]  ALUOp;       // 00 add, 01 passB, 10 decode opcode
    output logic        MemToReg;    // 0 = ALU result, 1 = Dout
    output logic        LinkReg;     // BL: Aw = X30, writeback = PC+4
    output logic        RegWrite;
    output logic        MemRead;
    output logic        MemWrite;
    output logic        SetFlags;    // latch N,V - ADDS and SUBS only
    output logic        UncondBr;    // 0 = CondAddr19, 1 = BrAddr26
    output logic        BrSel;       // BR: next PC comes from Da
    output logic        BZero;       // CBZ  -> condition block
    output logic        BLess;       // B.LT -> condition block

    always_comb begin
        // Defaults first: every signal driven on every path, no latches.
        Reg2Loc  = 1'b0;
        ALUSrc   = 1'b0;
        ImmSel   = 1'b0;
        ALUOp    = 2'b00;
        MemToReg = 1'b0;
        LinkReg  = 1'b0;
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        SetFlags = 1'b0;
        UncondBr = 1'b0;
        BrSel    = 1'b0;
        BZero    = 1'b0;
        BLess    = 1'b0;

        casex (opcode)

        // ---- CB-format: 8-bit opcode, 3 don't-cares ----
        // B.LT is listed first deliberately - see note below.
        11'b01010100xxx: begin                      // B.LT
            BLess    = 1'b1;
        end

        11'b10110100xxx: begin                      // CBZ
            BZero    = 1'b1;
            ALUOp    = 2'b01;                       // pass B -> Zero flag
            // Reg2Loc stays 0 -> Rd, the value being tested
        end

        // ---- I-format: 10-bit opcode, 1 don't-care ----
        11'b1001000100x: begin                      // ADDI
            RegWrite = 1'b1;
            ALUSrc   = 1'b1;
            ImmSel   = 1'b1;                        // zero-extend Imm12
            ALUOp    = 2'b00;
        end

        // ---- R-format: full 11-bit opcode ----
        11'b10101011000: begin                      // ADDS
            RegWrite = 1'b1;
            Reg2Loc  = 1'b1;                        // second source is Rm
            SetFlags = 1'b1;
            ALUOp    = 2'b10;
        end

        11'b11101011000: begin                      // SUBS
            RegWrite = 1'b1;
            Reg2Loc  = 1'b1;
            SetFlags = 1'b1;
            ALUOp    = 2'b10;
        end

        11'b11010110000: begin                      // BR
            BrSel    = 1'b1;
        end

        // ---- D-format: full 11-bit opcode ----
        11'b11111000010: begin                      // LDUR
            RegWrite = 1'b1;
            ALUSrc   = 1'b1;
            MemRead  = 1'b1;
            MemToReg = 1'b1;
            ALUOp    = 2'b00;
        end

        11'b11111000000: begin                      // STUR
            ALUSrc   = 1'b1;
            MemWrite = 1'b1;
            ALUOp    = 2'b00;
            // Reg2Loc stays 0 -> Rd, the value being stored
        end

        // B-format: 6-bit opcode
        11'b000101xxxxx: begin 
            UncondBr = 1'b1;
        end

        11'b100101xxxxx: begin     // BL
            UncondBr = 1'b1;
            LinkReg  = 1'b1;
            RegWrite = 1'b1;
        end

        default: begin
        end
        endcase
    end
endmodule




