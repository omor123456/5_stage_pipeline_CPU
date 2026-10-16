`timescale 1ns/10ps

// need 010 for add, 011 for sub, 000 for raw passing B for CBZ
// OP_SUBS ='b11101011000;  add :'b10101011000
// OP_CBZ =  b10110100xxx;       'b10110101xxx so only the 30 bit shows
// control[2] is always 0 due to not doing any and, or, xor
//crlt[1] is 

module ALU_control (cntrl, ALUop, instruction);
    input  logic [1:0]  ALUop;
    input  logic [31:0] instruction;
    output logic [2:0]  cntrl;
    logic op30;

    assign cntrl[2] = 1'b0; // not used
    assign op30 = instruction[30]; // 1 = SUBS, 0 = ADDs

    not #0.05 notPassB (cntrl[1], ALUop[0]);      // 1 for ALUop 00 and 10
    and #0.05 outpute (cntrl[0], ALUop[1], op30);  //only true for sub and ins[30]
endmodule
