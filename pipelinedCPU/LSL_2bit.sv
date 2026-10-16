module LSL_2bit (out, in);
    output [63:0] out;
    input  [63:0] in;

    genvar i;
    generate
        for (i = 0; i < 62; i = i + 1) begin : all_bits
            assign out[i+2] = in[i];
        end
    endgenerate

    assign out[0] = 0;
    assign out[1] = 0;
endmodule

