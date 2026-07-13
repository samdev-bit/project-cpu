`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $display("ASSERTION FAILED in %m: signal (%h) != value (%h)", (signal), (value)); \
        $finish; \
    end

/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

module test_cpu;
    logic clk;
    logic rst_n;

    cpu c0 (.*);

initial begin
    $dumpfile("test_cpu_waveform.vcd");
    $dumpvars(0, test_cpu);
end

initial begin
    clk = 0;
    forever begin
        #10 clk = ~clk;
    end
end


initial begin 

    logic [31:0] imem [31:0];
    logic [31:0] expected_instruction;
    logic [31:0] test_address;
    $readmemh("test_imemory.hex", imem);

    // Reset check
    rst_n = 1;

    #10
    rst_n = 0;
    #10
    test_address = (int'(32'hC)) / 4;
    `assert(c0.pc, 8'b00000000)
    `assert(c0.data_memory.mem[test_address], 32'hF2F2F2F2) // Checking if initial value at byte 12 is correct for the SW check
    rst_n = 1;

    // Read check
    for (int i = 0; i < 5; i++) begin
        @(posedge clk);
        expected_instruction = imem[i];
        `assert(c0.instruction, expected_instruction)
    end

    #20

    // LW logic check
    `assert(c0.regfile.registers[18], 32'HDEADBEEF)

    // SW logic check
    `assert(c0.data_memory.mem[test_address], 32'hDEADBEEF)

    // ADD logic check
    `assert(c0.regfile.registers[19], 32'h00000AAA)
    `assert(c0.regfile.registers[20], 32'hDEADC999)

    // AND logic check
    `assert(c0.regfile.registers[21], 32'hDEAD8889)

    $dumpflush;
    $finish;
end

endmodule
