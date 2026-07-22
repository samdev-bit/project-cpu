`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $error("ASSERTION FAILED in %m: signal (%h) != value (%h) in file %s at line %0d", (signal), (value), (`__FILE__), (`__LINE__)); \
    end

/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off WIDTHEXPAND */

module test_control;
    logic [6:0] op;
    logic [2:0] func3;
    logic [6:0] func7;
    logic alu_zero;

    logic [2:0] alu_control;
    logic [2:0] imm_source;
    logic mem_write;
    logic reg_write;
    logic alu_src;
    logic [1:0] result_src;
    logic PCsrc;
    logic [1:0] second_add_src;

    control c0 (.*);

initial begin
    $dumpfile("test_control_waveform.vcd");
    $dumpvars(0, test_control);
end

initial begin

    // TEST FOR DEFAULT
    op = 7'b0000000;

    #10
    `assert(reg_write, 0)
    `assert(mem_write, 0)
    `assert(imm_source, 3'b000)
    `assert(alu_control, 000)
    `assert(PCsrc, 0)


    // TEST FOR LW
    op = 7'b0000011;

    #10
    `assert(alu_control, 000)
    `assert(imm_source, 3'b000)
    `assert(mem_write, 0)
    `assert(reg_write, 1)
    `assert(alu_src, 1)
    `assert(result_src, 2'b01)
    `assert(PCsrc, 0)

    // TEST FOR SW
    #10
    op = 7'b0100011;

    #10
    `assert(alu_control, 000)
    `assert(imm_source, 3'b001)
    `assert(mem_write, 1)
    `assert(reg_write, 0)
    `assert(alu_src, 1)
    `assert(PCsrc, 0)

    // TEST FOR ADD
    #10
    op = 7'b0110011;
    func3 = 3'b000;

    #10
    `assert(alu_control, 000)
    `assert(reg_write, 1)
    `assert(mem_write, 0)
    `assert(alu_src, 0)
    `assert(result_src, 2'b00)
    `assert(PCsrc, 0)


    // TEST FOR AND
    #10
    op = 7'b0110011;
    func3 =  3'b111;

    #10
    `assert(alu_control, 3'b010)
    `assert(reg_write, 1)
    `assert(mem_write, 0)
    `assert(alu_src, 0)
    `assert(result_src, 2'b00)
    `assert(PCsrc, 0)

    // TEST FOR OR
    #10
    op = 7'b0110011;
    func3 =  3'b110;

    #10
    `assert(alu_control, 3'b011)
    `assert(reg_write, 1)
    `assert(mem_write, 0)
    `assert(alu_src, 0)
    `assert(result_src, 2'b00)
    `assert(PCsrc, 0)

    // TEST FOR BEQ
    #10
    op = 7'b1100011;
    alu_zero = 1'b0;

    // Test when branch should not be taken
    #10
    `assert(alu_control, 3'b001)
    `assert(imm_source, 3'b010)
    `assert(mem_write, 0)
    `assert(reg_write, 0)
    `assert(alu_src, 0)
    `assert(PCsrc, 0)

    // Test when branch should be taken#
    #5
    alu_zero = 1'b1;
    #5
    `assert(PCsrc, 1)

    // TEST FOR JAL
    #10
    op = 7'b1101111;
    alu_zero = 1'b0;
    
    #10
    `assert(reg_write, 1'b1)
    `assert(imm_source, 3'b100)
    `assert(mem_write, 1'b0)
    `assert(result_src, 2'b10)
    `assert(PCsrc, 1'b1)

    // TEST FOR ADDI
    #10
    op = 7'b0010011;
    func3 = 3'b000;
    func7 = 7'b0100000;

    #10
    `assert(reg_write, 1'b1)
    `assert(imm_source, 3'b000)
    `assert(mem_write, 1'b0)
    `assert(alu_control, 1'b000)
    `assert(PCsrc, 1'b0)

    // TEST FOR LUI
    #10
    op = 7'b0110111;

    #10
    `assert(reg_write, 1'b1)
    `assert(imm_source, 3'b011)
    `assert(mem_write, 1'b0)
    `assert(result_src, 2'b11)
    `assert(PCsrc, 1'b0)
    `assert(second_add_src, 2'b01)

    // TEST FOR AUIPC
    #10
    op = 7'b0010111;

    #10
    `assert(reg_write, 1'b1)
    `assert(imm_source, 3'b011)
    `assert(mem_write, 1'b0)
    `assert(result_src, 2'b11)
    `assert(PCsrc, 1'b0)
    `assert(second_add_src, 2'b00)

    $finish;

end

endmodule
