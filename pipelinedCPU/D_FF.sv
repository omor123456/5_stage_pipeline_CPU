
`timescale 1ns/10ps

module D_FF (q, d, reset, clk);
    output reg q;
    input d, reset, clk;
    
    always_ff @(posedge clk)
    begin
        if (reset)
            q <= 0; // On reset, set to 0
        else
            q <= d; // Otherwise out = d
    end
endmodule


module D_FF_en_negedge (q, d, en, reset, clk);
    output q;
    input  d, en, reset, clk;

    logic notEna, a1, a2, tempD;
    not #0.05 (notEna, en);

    and #0.05 (a1, d, en);       
    and #0.05 (a2, q, notEna);  
    or  #0.05 (tempD, a1, a2);   

    D_FF_negedge ff (.q(q), .d(tempD), .reset(reset), .clk(clk));
endmodule

module D_FF_negedge (q, d, reset, clk);
    output reg q;
    input      d, reset, clk;

    always_ff @(negedge clk) 
    begin
        if (reset) 
            q <= 0; // On reset, set to 0
        else
            q <= d; // Otherwise out = d
    end
endmodule