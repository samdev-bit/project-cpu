`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $error("ASSERTION FAILED in %m: signal (%h) != value (%h) in file %s at line %0d", (signal), (value), (`__FILE__), (`__LINE__)); \
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
    for (int i = 0; i < 8; i++) begin
        @(posedge clk);
        expected_instruction = imem[i];
        `assert(c0.instruction, expected_instruction)
    end

    #10

    // LW logic check
    `assert(c0.regfile.registers[18], 32'HDEADBEEF)

    // SW logic check
    `assert(c0.data_memory.mem[test_address], 32'hDEADBEEF)

    // ADD logic check
    `assert(c0.regfile.registers[19], 32'h00000AAA)
    `assert(c0.regfile.registers[20], 32'hDEADC999)

    // AND logic check
    `assert(c0.regfile.registers[21], 32'hDEAD8889)

    // OR logic check
    `assert(c0.regfile.registers[5], 32'h125F552D)
    `assert(c0.regfile.registers[6], 32'h7F4FD46A)
    `assert(c0.regfile.registers[7], 32'h7F5FD56F)

    // BEQ logic check
    @(posedge clk);
    `assert(c0.instruction, 32'h00730663)

    @(posedge clk);
    `assert(c0.instruction, 32'h00802B03) // previous branch should not be taken
    #10
    `assert(c0.regfile.registers[22], 32'hDEADBEEF)

    @(posedge clk);
    `assert(c0.instruction, 32'h01690863)

    @(posedge clk);
    `assert(c0.instruction, 32'h00002B03)
    #10
    `assert(c0.regfile.registers[22], 32'hAEAEAEAE)

    @(posedge clk);
    `assert(c0.instruction, 32'hFF6B0CE3)

    @(posedge clk);
    `assert(c0.instruction, 32'h00000663)

    @(posedge clk);
    `assert(c0.instruction, 32'h00000013)

    // JAL logic check
    #40
    `assert(c0.instruction, 32'hFFDFF0EF)

    #20
    `assert(c0.instruction, 32'h00C000EF)

    #20
    `assert(c0.instruction, 32'h00C02383)
    #10
    `assert(c0.regfile.registers[7], 32'hDEADBEEF)


    // ADDI tests
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[26], 32'hDEADC09A)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[25], 32'h7F4FD38B)

    $dumpflush;
    $finish;
end

endmodule
