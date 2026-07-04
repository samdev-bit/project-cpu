`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $display("ASSERTION FAILED in %m: signal (%h) != value (%h)", (signal), (value)); \
        $finish; \
    end

/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

module test_signext;
    logic [24:0] raw_src;
    logic [1:0] imm_source;
    logic [31:0] immediate;

    signext s0 (.*);

logic [11:0] imm;
logic [6:0] imm_11_5;
logic [4:0] imm_4_0;

initial begin

    $dumpfile("test_signext_waveform.vcd");
    $dumpvars(0, test_signext);

    // Manual I-type tests
    #10
    // Initialize
    imm_source = 2'b00;
    raw_src = 25'b0000011110111010101010101;

    // Test basic functionality 
    #10
    `assert(immediate, 32'b00000000000000000000000001111011)
    `assert(int'(immediate), 123)

    // Test negative immediate
    #10
    raw_src = 25'b1111110101101010101010101;

    #10
    `assert(immediate, 32'b11111111111111111111111111010110)
    `assert(int'(immediate), -42)

    // Randomized S-type tests
    #100
    for(int i = 0; i < 100; i++) begin 

        // Test all positive values
        imm = $urandom_range(0,12'b011111111111);
        imm_11_5 = imm[11:5];
        imm_4_0 = imm[4:0];
        raw_src = (imm_11_5 << 18) | (imm_4_0);
        imm_source = 2'b01;

        // Allow time for signals to propogate
        #10
        `assert(int'(immediate), int'(imm))

        // Test all negative values
        imm = $urandom_range(12'b100000000000, 12'b111111111111);
        imm_11_5 = imm[11:5];
        imm_4_0 = imm[4:0];
        raw_src = (imm_11_5 << 18) | (imm_4_0);
        imm_source = 2'b01;

        #10
        `assert(int'(immediate),int'(signed'(imm)))
    end

    $finish;
end

endmodule
