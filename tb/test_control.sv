`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $display("ASSERTION FAILED in %m: signal (%h) != value (%h)", (signal), (value)); \
        $finish; \
    end

/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */

module test_control;
    logic [6:0] op;
    logic [2:0] func3;
    logic [6:0] func7;
    logic alu_zero;

    logic [2:0] alu_control;
    logic [1:0] imm_source;
    logic mem_write;
    logic reg_write;

    control c0 (.*);

/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */

initial begin
    $dumpfile("test_control_waveform.vcd");
    $dumpvars(0, test_control);
end

initial begin

    // TEST FOR LW
    op = 7'b0000011;

    #10
    `assert(alu_control, 000)
    `assert(imm_source, 00)
    `assert(mem_write, 0)
    `assert(reg_write, 1)

    // TEST FOR SW
    #10
    op = 7'b0100011;

    #10
    `assert(alu_control, 000)
    `assert(imm_source, 01)
    `assert(mem_write, 1)
    `assert(reg_write, 0)

    $finish;

end

endmodule
