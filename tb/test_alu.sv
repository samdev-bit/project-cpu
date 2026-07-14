`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $error("ASSERTION FAILED in %m: signal (%h) != value (%h) in file %s at line %0d", (signal), (value), (`__FILE__), (`__LINE__)); \
    end

module test_alu;
    logic [2:0] alu_control;
    logic [31:0] src1;
    logic [31:0] src2;
    logic [31:0] alu_result;
    logic zero;

    alu a0 (.*);

initial begin
    $dumpfile("test_alu_waveform.vcd");
    $dumpvars(0, test_alu);
end

logic [31:0] expected;

initial begin

    // Test function works when control is 000
    for (int i = 0; i<1000; i++) begin
        src1 = $urandom();
        src2 = $urandom();

        // TEST FOR 000
        alu_control = 3'b000;
        #1
        expected = (src1 + src2);
        #1
        `assert(alu_result, expected)

        // TEST FOR 010
        alu_control = 3'b010;
        #1
        expected = (src1 & src2);
        #1
        `assert(alu_result, expected)

        // TEST FOR 011
        alu_control = 3'b011;
        #1
        expected = (src1 | src2);
        #1
        `assert(alu_result, expected)

        // TEST FOR 001
        alu_control = 3'b001;
        #1
        expected = (src1 - src2);
        #1
        `assert(alu_result, expected)
    end

    // Make sure zero flag works
    #1
    alu_control = 3'b001;
    src1 = 123;
    src2 = 123;
    #1
    `assert(zero, 1)
    `assert(alu_result, 0)

    // Make sure only 000 does something
    #1
    alu_control = 3'b111;
    src1 = $urandom();
    src2 = $urandom();
    #1
    `assert(alu_result, 0)

    $finish;
end

endmodule
