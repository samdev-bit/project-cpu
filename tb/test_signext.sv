`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $error("ASSERTION FAILED in %m: signal (%h) != value (%h) in file %s at line %0d", (signal), (value), (`__FILE__), (`__LINE__)); \
    end

/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

module test_signext;
    logic [24:0] raw_src;
    logic [1:0] imm_source;
    logic [31:0] immediate;

    signext s0 (.*);

// S-type
logic [11:0] imm;
logic [19:0] j_type_imm;
logic [6:0] imm_11_5;
logic [4:0] imm_4_0;

// B-type
logic imm_12;
logic imm_11;
logic [5:0] imm_10_5;
logic [3:0] imm_4_1;


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

    // Randomized B-type tests
    #100
    for(int i = 0; i < 100; i++) begin 

        // Test all positive values
        imm = $urandom_range(0,12'b011111111111);
        imm = imm << 1;
        imm_12 = 1'b0;
        imm_10_5 = imm[10:5];
        imm_4_1 = imm[4:1];
        imm_11 = imm[11];
        raw_src = ({imm_12, imm_10_5} << 18) | ({imm_4_1, imm_11});
        imm_source = 2'b10;

        // Allow time for signals to propogate
        #10
        `assert(int'(immediate), int'({imm_12, imm}))

        #10
        // Test all negative values
        imm = $urandom_range(12'b100000000000, 12'b111111111111);
        imm = imm << 1;
        imm_12 = 1'b1;
        imm_10_5 = imm[11:5];
        imm_4_1 = imm[4:1];
        imm_11 = imm[11];
        raw_src = ({imm_12, imm_10_5} << 18) | ({imm_4_1, imm_11});

        #10
        `assert(int'(immediate),int'(signed'({imm_12, imm})))
    end

    // Randomized J-type tests
    #100 
    for(int i = 0; i < 100; i++) begin 
        // Test all positive values
        j_type_imm = $urandom_range(0,20'b01111111111111111111);
        j_type_imm = j_type_imm << 1; // 159006
        raw_src = ({1'b0, j_type_imm[10:1], j_type_imm[11], j_type_imm[19:12]} << 5);
        imm_source = 2'b11;

        // Allow time for signals to propogate
        #10
        `assert(int'(immediate), int'({1'b0, j_type_imm}))

        // Test all negative values
        j_type_imm = $urandom_range(20'b10000000000000000000, 20'b11111111111111111111);
        j_type_imm = j_type_imm << 1;
        raw_src = ({1'b1, j_type_imm[10:1], j_type_imm[11], j_type_imm[19:12]} << 5);
        imm_source = 2'b11;

        // Allow time for signals to propogate
        #10
        `assert(int'(immediate), int'(signed'({1'b1, j_type_imm})))
    end

    $finish;
end

endmodule
