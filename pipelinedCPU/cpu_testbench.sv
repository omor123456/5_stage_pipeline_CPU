`timescale 1ns/10ps

module cpu_testbench ();
    logic clk, reset;

    // REQUIRED build: delay slot after every branch executes (TB3 -> X2 = 4).
    cpu dut (.clk(clk), .reset(reset));

    // EXTRA CREDIT build: comment out the line above, uncomment this one.
    // Flushes IF/ID on a taken branch, so the delay slot is squashed
    // (TB3 -> X2 = 0).  TB2/TB5/TB6 have NOOPs in every delay slot, so they
    // still pass with this enabled; only TB3 and TB7's X2 counter changes.
    // cpu #(.ENABLE_FLUSH(1)) dut (.clk(clk), .reset(reset));

    parameter CLOCK_PERIOD = 10000;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD/2) clk <= ~clk;
    end

    initial begin
        // start every benchmark from a known 0 state.
        reset <= 1;
        @(posedge clk);
        @(posedge clk);
        reset <= 0;

        repeat (2000) @(posedge clk);
        $stop;
    end
endmodule