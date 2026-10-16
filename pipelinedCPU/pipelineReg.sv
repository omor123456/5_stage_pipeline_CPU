`timescale 1ns/10ps

// pipelineReg -- generic pipeline register with flush + hold.
//
//   Per-bit structure:
//                 hold                  flush
//                  |                      |
//         d ---.   |            afterHold |
//              m2_1 --- afterHold ---.    |
//         q ---'                     m2_1 --- dNext ---[ D_FF ]--- q
//                                    |
//                              1'b0 -'
//

//
//   Only uses mux2_1 (the lab's gate-level single-bit mux) and D_FF.
//-----------------------------------------------------------------------------
module pipelineReg #(parameter WIDTH = 64) (q, d, flush, hold, reset, clk);
    output logic [WIDTH-1:0] q;
    
    input  logic [WIDTH-1:0] d;
    input  logic flush, hold, reset, clk;

    logic [WIDTH-1:0] HoldDone, newInput;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin : eachBit
        
            // hold: select=0 -> d  or select=1 -> q
            mux2_1 muxHold  (.out(HoldDone[i]), .select(hold), .in({q[i], d[i]}));
            
            // flush: select=0 -> afterHold or select=1 -> 0
            mux2_1 muxFlush (.out(newInput[i]), .select(flush), .in({1'b0, HoldDone[i]}));

            D_FF ff (.q(q[i]), .d(newInput[i]), .reset(reset), .clk(clk));
        end
    endgenerate
endmodule