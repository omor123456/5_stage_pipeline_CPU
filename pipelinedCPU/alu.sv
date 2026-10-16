`timescale 1ns/10ps


module alu (A, B, cntrl, result, negative, zero, overflow, carry_out);
    input [63:0] A, B;
    input [2:0] cntrl;
    output [63:0] result;
    output negative, zero, overflow, carry_out;
    logic [63:0] sum, and_out, or_out, xor_out, not_out;
    logic  cIn, cntrl_addsub, overFlow_addsub, notC2, addNeed;
    logic [15:0] zero16;
    logic [3:0] zero4;
    logic [63:0] tempoutput [0:7];
    // 110:XOR [6]  100:AND [4]  101:OR [5] 010:ADD [2]  011:SUB [3]
    assign tempoutput[0] = B; //so result is alwasy B for 000 [0], 111 [7]

    genvar x, y, z;
    generate
        for (x = 0; x < 64; x++) begin : eachBit
            xor #0.05 xor1 (tempoutput[6][x], A[x], B[x]);
            and #0.05 and1 (tempoutput[4][x], A[x], B[x]);
            or  #0.05 or1  (tempoutput[5][x], A[x], B[x]);
        end
    endgenerate

    assign cIn = cntrl[0];  //would select the add or sub

    fullAdderSub addsub (tempoutput[2], cntrl_addsub, overFlow_addsub, A, B, cIn);
    assign tempoutput[3] = tempoutput[2];  //opecode would do the same operation


    // addNeed = cntrl[1] AND NOT cntrl[2] -> true only for 010 (ADD) and 011 (SUB).
    not #0.05 not2 (notC2, cntrl[2]);
    and #0.05 addSubOn (addNeed, cntrl[1], notC2);

    // ---------------------------------------------------------------------
    // FIX #1: carry_out is the RAW carry out of the 64-bit adder, gated so
    // that logic ops report 0.  It must NOT be inverted for subtract.
    // A - B is implemented as A + ~B + 1, and the carry out of that sum is
    // already the ARM C flag (C=1 means "no borrow").  The old
    //     xor (carry_out, final_carry, cntrl[0])
    // flipped C on every SUBS, and it also drove carry_out to 1 for
    // cntrl = 001/011/101/111 when addNeed was 0.
    // ---------------------------------------------------------------------
    and #0.05 gco (carry_out, cntrl_addsub, addNeed);

    and #0.05 finaloverFlow (overflow, overFlow_addsub, addNeed);


    //assinging the output from the mux
    generate
        for (y = 0; y < 64; y++) begin : eachB
            logic [7:0] ALUoptions;
            for (z = 0; z < 8; z++) begin : eachALUpath
                assign ALUoptions[z] = tempoutput[z][y];
            end
            mux8_1 out (result[y], cntrl[2:0], ALUoptions);
        end
    endgenerate



    //zero case:
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : checking4_16bits
            nor #0.05 zer (zero16[i], result[i*4], result[i*4+1], result[i*4+2], result[i*4+3]);
        end
    endgenerate

    and #0.05 z17 (zero4[0], zero16[0], zero16[1], zero16[2], zero16[3]);
    and #0.05 z18 (zero4[1], zero16[4], zero16[5], zero16[6], zero16[7]);
    and #0.05 z19 (zero4[2], zero16[8], zero16[9], zero16[10], zero16[11]);
    and #0.05 z20 (zero4[3], zero16[12], zero16[13], zero16[14], zero16[15]);
    and #0.05 z21 (zero, zero4[0], zero4[1], zero4[2], zero4[3]);  //zero case

    assign negative = result[63]; //negative case

endmodule