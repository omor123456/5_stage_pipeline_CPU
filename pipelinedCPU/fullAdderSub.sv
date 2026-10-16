`timescale 1ns/10ps
//can be used for both add/sub
module fullAdderSub (out, cOut, overFlow, a, b, cIn);
    output [63:0] out; 
    output cOut;
	 output overFlow;
    input [63:0] a, b;
    input cIn;
	 logic [63:0] tempB;
    logic [64:0] carries; //most sig is cout of 64

    assign carries[0] = cIn;
	 
//actual add/sub
    genvar i;
    generate
        for (i = 0; i < 64; i++) begin : each64Bits
            xor #0.05 outputXor (tempB[i], b[i], cIn); //for subtraction, b is inverted and cIn is 1 for 2's complement
				
            bit2Adder eachBit (out[i], carries[i+1], a[i], tempB[i], carries[i]);
        end 
    endgenerate
	 
    //assuing OF happens when two carries don't match so equality 
    xor #0.05 checkOF (overFlow, carries[63], carries[64]);
    assign cOut = carries[64];
	 
	 
	 
endmodule



module bit2Adder (out, cOut, a, b, cIn);
    output out, cOut;
    input a, b, cIn;
	 
    logic a1, a2, a3;

    xor #0.05 outxor (out, a, b, cIn);
    and #0.05 andg2 (a1, a, b);
    and #0.05 andg1 (a2, a, cIn);
    and #0.05 andg3 (a3, b, cIn);
    or #0.05 carout (cOut, a1, a2, a3);

endmodule