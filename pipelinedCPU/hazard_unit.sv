// hazard_unit 
//
// (1) Load-use stall: LDUR in EX +  instructions that uses the result of the last instruction in ID reading the loaded register
//     Response: hold PC, hold IF/ID, bubble ID/EX ctrl
// (2) Branch flush : squash the delay slot after any taken branch for credit
module hazard_unit #(parameter ENABLE_FLUSH = 0) (MemRead_EX, Rd_EX, Rn_ID, Rm_ID, redirect_ID, stall, flush_IFID, bubble_IDEX);

    input  logic       MemRead_EX;
    input  logic [4:0] Rd_EX, Rn_ID, Rm_ID;
    input  logic       redirect_ID;

    output logic       stall, flush_IFID, bubble_IDEX;

    assign stall = MemRead_EX && (Rd_EX != 5'b11111) && ((Rd_EX == Rn_ID) || (Rd_EX == Rm_ID));

    assign bubble_IDEX = stall;

    // A stall means the branch in ID has NOT committed its redirect yet (PC is
    // held), so flushing IF/ID here would destroy the delay-slot instruction we
    // are about to need.  flush beats hold inside pipelineReg, so gate it here
    assign flush_IFID  = (ENABLE_FLUSH != 0) && redirect_ID && !stall;


endmodule