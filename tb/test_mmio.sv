`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $error("ASSERTION FAILED in %m: signal (%h) != value (%h) in file %s at line %0d", (signal), (value), (`__FILE__), (`__LINE__)); \
    end

module test_mmio;
    logic mem_write;
    logic [31:0] alu_result;

    logic led_enable;
    logic mem_enable;
    logic [1:0] w_sel;

    mmio m0 (.*);

initial begin
    $dumpfile("test_mmio.vcd");
    $dumpvars(0, test_mmio);
end

initial begin
    alu_result = 32'h00000000;
    mem_write = 1'b1;
    #1
    `assert(mem_enable, 1'b1)
    `assert(led_enable, 1'b0)
    `assert(w_sel, 2'b10)

    #1
    alu_result = 32'h00000004;
    #1
    `assert(mem_enable, 1'b1)
    `assert(led_enable, 1'b0)
    `assert(w_sel, 2'b10)

    #1
    alu_result = 32'h10000000;
    #1
    `assert(mem_enable, 1'b0)
    `assert(led_enable, 1'b1)
    `assert(w_sel, 2'b11)

    #1
    alu_result = 32'h10000002;
    #1
    `assert(mem_enable, 1'b0)
    `assert(led_enable, 1'b1)
    `assert(w_sel, 2'b11)

    #1
    alu_result = 32'h10000000;
    mem_write = 1'b0;
    #1
    `assert(mem_enable, 1'b0)
    `assert(led_enable, 1'b0)
    `assert(w_sel, 2'b11)

    #1
    alu_result = 32'h20000000;
    mem_write = 1'b1;
    #1
    `assert(mem_enable, 1'b0)
    `assert(led_enable, 1'b0)
    `assert(w_sel, 2'b10)

    #1
    alu_result = 32'h10000004;
    mem_write = 1'b0;
    #1
    `assert(mem_enable, 1'b0)
    `assert(led_enable, 1'b0)
    `assert(w_sel, 2'b00)

    #1
    alu_result = 32'h10000006;
    mem_write = 1'b0;
    #1
    `assert(mem_enable, 1'b0)
    `assert(led_enable, 1'b0)
    `assert(w_sel, 2'b00)

    #1
    alu_result = 32'h10000006;
    mem_write = 1'b0;
    #1
    `assert(mem_enable, 1'b0)
    `assert(led_enable, 1'b0)
    `assert(w_sel, 2'b00)

    #1
    alu_result = 32'h10000008;
    mem_write = 1'b0;
    #1
    `assert(mem_enable, 1'b0)
    `assert(led_enable, 1'b0)
    `assert(w_sel, 2'b10)
end

endmodule