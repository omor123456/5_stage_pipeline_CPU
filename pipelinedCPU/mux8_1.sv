`timescale 1ns/10ps

//one bit
module mux8_1 (out, select, data);
    output out;
    input [2:0] select;
    input [7:0] data;
    logic [1:0] tempD;

    mux4_1 m1(tempD[0], select[1:0], data[3:0]);
    mux4_1 m2(tempD[1], select[1:0], data[7:4]);

    mux2_1 lastMux(out, select[2], tempD);

endmodule



module mux2_1 (out, select, in);
    output out;
    input select;
    input [1:0] in;
    logic notS, and1, and2;
    not #0.05 n1 (notS, select);

    and #0.05 a1 (and1, in[0], notS);
    and #0.05 a2 (and2, in[1], select);
    or  #0.05 lasout1 (out, and1, and2);

endmodule


//4_1 mux from lab 1
module mux4_1 (out, select, data);
    output out;
    input [1:0] select;
    input [3:0] data;

    logic and1, and2, and3, and4, notS1, notS2;
    logic or1, or2;

    not #0.05 n1 (notS1, select[0]);
    not #0.05 n2 (notS2, select[1]);

    and #0.05 m1 (and1, data[0], notS1, notS2);
    and #0.05 m2 (and2, data[1], select[0], notS2);
    and #0.05 m3 (and3, data[2], notS1, select[1]);
    and #0.05 m4 (and4, data[3], select[0], select[1]);
    or #0.05 orgate1 (or1, and1, and2);
    or #0.05 orgate2 (or2, and3, and4);

    or #0.05 o3 (out, or1, or2);
endmodule