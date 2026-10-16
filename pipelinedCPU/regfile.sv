`timescale 1ns/10ps  //0.05 for 50 ps


module regfile (ReadData1, ReadData2, WriteData, ReadRegister1, ReadRegister2, WriteRegister, RegWrite, reset, clk);
    output [63:0] ReadData1, ReadData2;
    input [63:0] WriteData;
    input [4:0] ReadRegister1, ReadRegister2, WriteRegister;
    input RegWrite, reset, clk;

    logic [63:0] registers [0:31];  // 32of 64 bit registers
    logic [31:0] allRegistersDecoded; //for write enables the 64 d flipflops

    Decoder decodeAll (allRegistersDecoded, RegWrite, WriteRegister);

    genvar i, j;
    generate
        for (i = 0; i < 31; i++) begin : eachR
            for (j = 0; j < 64; j++) begin : bitwise 
                D_FF_en_negedge dataEntry (registers[i][j], WriteData[j], allRegistersDecoded[i], reset, clk);
            end
        end

        for (j = 0; j < 64; j++) begin : Reg31   //assiging all bits of 31 register to zero
            buf #0.05 (registers[31][j], 1'b0);
        end
    endgenerate

    AllMux outputs (ReadData1, ReadData2, ReadRegister1, ReadRegister2, registers);

endmodule


//lowkneeded cuz having it reset all the values just from the D_ff isn't good but looks pretty similar to mux2-1 concept
module D_FF_en (q, d, en, reset, clk);
    output q;
    input  d, en, reset, clk;
    logic  notEna, a1, a2, tempD;
    not #0.05 (notEna, en);

	 
    and #0.05 (a1, d, en);
    and #0.05 (a2, q, notEna);
    or  #0.05 (tempD, a1, a2);
    
    D_FF ff (q, tempD, reset, clk); 
endmodule
