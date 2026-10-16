`timescale 1ns/10ps
module zeroExtend  (out, in);
    output logic [63:0] out;
    input  logic [11:0] in;

    genvar i;
    generate
        for (i = 0; i < 12; i++) begin : LSBits
            assign out[i] = in[i];  
        end
        for (i = 12; i < 64; i++) begin : signBits
            assign out[i] = 0;   // Zero extend to all higher bits
        end
    endgenerate
endmodule
