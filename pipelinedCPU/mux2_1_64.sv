`timescale 1ns/10ps

// 64-bit 2:1 mux. select = 0 -> in0, select = 1 -> in1.
// Built from the shared single-bit mux2_1 (defined in mux8_1.sv).
module mux2_1_64 (out, select, in0, in1);
    output logic [63:0] out;
    input  logic        select;
    input  logic [63:0] in0, in1;

    genvar i;
    generate
        for (i = 0; i < 64; i++) begin : eachBit
            mux2_1 m (.out(out[i]), .select(select), .in({in1[i], in0[i]}));
        end
    endgenerate
endmodule
