`timescale 1ns/10ps

//to call the module: signExtend #(.WIDTH(32)) ext32 ( .out, .in(in32bits)); 
//as we need 9 bits for load/store, cbz/b.lt for 19 and b/bl for 26 bits 

module signExtend #(parameter WIDTH = 9) (out, in);
    output logic [63:0] out;
    input  logic [WIDTH-1:0] in;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin : LSBits
            assign out[i] = in[i];  
        end
        for (i = WIDTH; i < 64; i++) begin : signBits
            assign out[i] = in[WIDTH-1];   // MSB so for i greater or equal to width
        end
    endgenerate
endmodule
