`timescale 1ns/10ps

module mux2_1_5bits (out, select, in0, in1);
    output logic [4:0] out;
    input  logic       select;
    input  logic [4:0] in0, in1;

    genvar i;
    generate
        for (i = 0; i < 5; i++) begin : eachBit
            mux2_1 m (.out(out[i]), .select(select), .in({in1[i], in0[i]}));
        end
    endgenerate
endmodule