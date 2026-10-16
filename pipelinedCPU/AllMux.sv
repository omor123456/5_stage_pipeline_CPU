`timescale 1ns/10ps

// mux4_1 and mux2_1 live in mux8_1.sv (shared) so they are not redefined here.

module mux16_1 (out, select, data);
    output out;
    input [3:0] select;
    input [15:0] data;
    logic [3:0] tempSel;

    mux4_1 m1 (tempSel[0], select[1:0], data[3:0]);   //breaks it aparts for the last MSB
    mux4_1 m2 (tempSel[1], select[1:0], data[7:4]);
    mux4_1 m3 (tempSel[2], select[1:0], data[11:8]);
    mux4_1 m4 (tempSel[3], select[1:0], data[15:12]);

    mux4_1 m5 (out, select[3:2], tempSel);  //to get the last output

endmodule




module mux32_1 (out, select, data);
    output out;
    input [4:0] select;
    input [31:0] data;
    logic [1:0] tempData;
    logic notS, and1, and2;

    mux16_1 m1(tempData[0], select[3:0], data[15:0]);
    mux16_1 m2(tempData[1], select[3:0], data[31:16]);
	 
	 //comparing and getting the last output from two tempData bit similar to mux2-1

    not #0.05 n1 (notS, select[4]);
    and #0.05 a1 (and1, tempData[0], notS);   //confused on which one to use first notS or select[4]
    and #0.05 a2 (and2, tempData[1], select[4]);
    or #0.05    o1 (out, and1, and2);
endmodule  




module AllMux (ReadData1, ReadData2, RRegister1, RRegister2, allData);
    output [63:0] ReadData1, ReadData2;
    input [4:0] RRegister1, RRegister2;
    //input [2047:0] allData;
    input [63:0] allData [0:31];  //64*32 registers so would have to have 64bitline of each register

    genvar i, j;
    generate
        for (i = 0; i < 64; i++) begin : each64Bits
            logic [31:0] reg32;  //placeholder
            for(j = 0; j < 32; j++) begin : eachR
                buf #(0.05) b (reg32[j], allData[j][i]); //trying to use this instead of assign for clustering all 32 bits for one mux at each 64 bits
            end
            mux32_1 eachBit1 (ReadData1[i], RRegister1, reg32);
            mux32_1 eachBit2 (ReadData2[i], RRegister2, reg32);
            // mux32_1 eachBit1 (readData1[i], RRegister1, allData[(i*32 + 32) : i*32]);
            // mux32_1 eachBit2 (readData2[i], RRegister2, allData[(i*32 + 32) : i*32]);
        end
    endgenerate

endmodule




//module AllMux_testbench();
//	logic CLOCK_50;
//	logic [63:0] ReadData1, ReadData2;
//   logic [4:0] RRegister1, RRegister2;
//	logic [63:0] allData [0:31];
//
//	
//	
//	AllMux testbench (ReadData1, ReadData2, RRegister1, RRegister2, allData);
//	
////	// Set up a simulated clock.
////	parameter CLOCK_PERIOD=100;
////	
////	initial begin
////		CLOCK_50 <= 0;
////		forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50; // Forever toggle the clock
////	end
////	
//	
//	// Test the design.
//	initial begin
//		
//						repeat(1);
//						
//        // Initialize all 32 registers
//        for (int i = 0; i < 32; i = i + 1)
//            allData[i] = i;
//
//        // Read register 0 and 1
//        RRegister1 = 5'd0;
//        RRegister2 = 5'd1;
//        #10;
//
//     $stop;
//		// End the simulation.
//	end
//endmodule
