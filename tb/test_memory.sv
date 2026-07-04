`timescale 1ns / 1 ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $display("ASSERTION FAILED in %m: signal (%h) != value (%h)", (signal), (value)); \
        $finish; \
    end

/* verilator lint_off UNUSEDSIGNAL */

module test_memory;

    parameter WORDS = 64;

    logic clk;
    logic [31:0] address;
    logic [31:0] write_data;
    logic write_enable;
    logic rst_n;
    logic [31:0] read_data;

    memory m0 (.*);

initial begin
    $dumpfile("test_memory_waveform.vcd");
    $dumpvars(0, test_memory);
end

    logic [31:0] test_data [3:0] = '{32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'hA5A5A5A5};
    logic [31:0] expected_value;

initial begin
    clk = 0;
    forever begin
        #10ns clk = ~clk;
    end
end

initial begin

    // Initialize
    rst_n = 0;
    write_enable = 0;
    address = 0;
    write_data = 0;

    #10ns rst_n = 1;

    // Check if all values are 0 after reset
    for (int i = 0; i <= WORDS; i++) begin
        address = i*4;
        #1ns `assert(read_data, 32'b0)
    end

    // Check if write works properly
    for (int i = 0; i < 4; i++) begin
        
        write_enable = 1;
        address = i*4;
        write_data = test_data[i];
        @(posedge clk);

        @(negedge clk);
        write_enable = 0;
        #1ns `assert(read_data, test_data[i])
    end

    // Write to multiple addresses and then read back
    for (int i = 0; i<=40; i += 4) begin
        
        address = i;
        write_data = i + 100;
        write_enable = 1;
        @(posedge clk);
       
        @(negedge clk);
        write_enable = 0;
    end

    for (int i = 0; i <= 40; i += 4) begin
        address = i;
        expected_value = i + 100;

        #1ns `assert(read_data, expected_value)
    end

    $finish;
end

endmodule
