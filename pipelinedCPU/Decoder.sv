// 5 to 32 decoder with regwrite eneable or off for the final function
`timescale 1ns/10ps


module Decoder (out, regWrite, writeRegister);
    output [31:0] out;
    input [4:0] writeRegister;
    input regWrite;
    logic not_sigBit;
    logic [1:0] tempSelector;
     
    
    not #0.05 n1(not_sigBit, writeRegister[4]); //assuming 4 is the most significant bit
    and #0.05 and1(tempSelector[0], not_sigBit, regWrite);
    and #0.05 and2(tempSelector[1], writeRegister[4], regWrite); //acting as 1_2 decoder

    Decoder4_16 d1 (out[15:0], writeRegister[3:0], tempSelector[0]);
    Decoder4_16 d2 (out[31:16], writeRegister[3:0], tempSelector[1]);  //assumeing the first bit is ON 
endmodule





module Decoder2_4 (out, n, enable);
    output [3:0] out;
    input [1:0] n;
    input enable;
    logic notN0, notN1;

    //NAND (out[0], n[0], n[1]); // shows 0001
    not #0.05 n1(notN0, n[0]);
    not #0.05 n2(notN1, n[1]);

    and #0.05 and1(out[0], notN0, notN1, enable); //0001
    and #0.05 and2(out[1], n[0], notN1, enable);  //0010
    and #0.05 and3(out[2], notN0, n[1], enable);   //0100
    and #0.05 and4(out[3], n[0], n[1], enable);    //1000
    
endmodule

module Decoder4_16 (out, n, enable);
    output [15:0] out;
    input [3:0] n;
    input enable;
    logic [3:0] tempSelector;

    Decoder2_4 d0 (tempSelector[3:0], n[3:2], enable);  // use the two bits to break the input and output toallocate the other bits to make it upto 16 bits

    Decoder2_4 d1 (out[3:0], n[1:0], tempSelector[0]); 
    Decoder2_4 d2 (out[7:4], n[1:0], tempSelector[1]);
    Decoder2_4 d3 (out[11:8], n[1:0], tempSelector[2]);
    Decoder2_4 d4 (out[15:12], n[1:0], tempSelector[3]);

endmodule



