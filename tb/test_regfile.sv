`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $display("ASSERTION FAILED in %m: signal (%h) != value (%h)", (signal), (value)); \
        $finish; \
    end

module test_regfile;

    logic clk;
    logic rst_n;
    
    logic [4:0] read_address1;
    logic [4:0] read_address2;
    logic [31:0] read_data1;
    logic [31:0] read_data2;

    logic write_enable;
    logic [31:0] write_data;
    logic [4:0] write_address;

    regfile r0 (.*);

initial begin
    $dumpfile("test_regfile_waveform.vcd");
    $dumpvars(0, test_regfile);
end

initial begin
    clk = 0;
    forever begin
        #10 clk = ~clk;
    end
end

logic [31:0] theoretical_regs [0:31];

initial begin

    // Initialize
    rst_n = 0;
    write_enable = 0;
    read_address1 = 0;
    read_address2 = 0;
    write_address = 0;
    write_data = 0;

    #10 rst_n = 1;

    // Setting up a theoretical register to compare against
    for (int i = 0; i < 32; i++) begin
        theoretical_regs[i] = 32'b0;
    end

    // Thousand random writes and reads
    for (int i = 0; i < 1000; i++) begin

        read_address1 = 5'($urandom_range(31,1));
        read_address2 = 5'($urandom_range(31,1));
        write_address = 5'($urandom_range(31,1));
        write_data = $urandom();

        @(posedge clk);

        #1 
        `assert(read_data1, theoretical_regs[read_address1])
        `assert(read_data2, theoretical_regs[read_address2])

        @(posedge clk);
        write_enable = 1;

        @(negedge clk);
        write_enable = 0;
        theoretical_regs[write_address] = write_data;
    end

    // Making sure we can't write to the 0th register
    #1
    write_address = 0;
    write_enable = 1;
    write_data = 32'hAEAEAEAE;
    @(posedge clk);

    @(negedge clk);
    write_enable = 0;
    theoretical_regs[write_address] = 0;

    @(posedge clk);
    #1
    read_address1 = 0;
    #1
    $display("%s", (read_data1));
    `assert (read_data1, 0)

    $finish;
end

endmodule
