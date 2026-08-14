`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $error("ASSERTION FAILED in %m: signal (%h) != value (%h) in file %s at line %0d", (signal), (value), (`__FILE__), (`__LINE__)); \
    end

module test_reader;
    logic [31:0] mem_read;
    logic [2:0] func3;
    logic [3:0] byte_enable;

    logic [31:0] wb_data;
    logic valid;

    reader r0 (.*);

initial begin
    $dumpfile("test_cpu_waveform.vcd");
    $dumpvars(0, test_cpu);
end

initial begin

    // LW
    func3 = 3'b010;
    byte_enable = 4'b1111;
    #1
    for(int i = 0; i < 100; i++) begin
        mem_read = $urandom();
        #1
        `assert(wb_data, mem_read);
    end

    // LH
    func3 = 3'b001;
    for(int i = 0; i < 100; i++) begin
        byte_enable = 4'b1100;
        #1
        // UNSIGNED
        mem_read = $urandom_range(32'h0000000, 32'h7FFF0000);
        #1
        `assert(wb_data, (mem_read & 32'hFFFF0000) >> 16)
        `assert(valid, 1)

        // SIGNED
        mem_read = $urandom();
        #1
        `assert(signed'(wb_data), signed'(signed'((mem_read & 32'hFFFF0000)) >>> 16))
        `assert(valid, 1)

        byte_enable = 4'b0011;
        #1
        // UNSIGNED
        mem_read = $urandom_range(32'h0000000, 32'h00007FFF);
        #1
        `assert(wb_data, (mem_read & 32'h0000FFFF))
        `assert(valid, 1)

        // SIGNED
        mem_read = $urandom();
        #1
        mem_read = mem_read & 32'h0000FFFF;
        `assert(signed'(wb_data), signed'({{16{mem_read[15]}}, mem_read[15:0]}))
        `assert(valid, 1)

    end

    // LHU
    func3 = 3'b101;
    for(int i = 0; i < 100; i++) begin
        byte_enable = 4'b1100;
        mem_read = $urandom;
        #1
        `assert(wb_data, (mem_read & 32'hFFFF0000) >> 16)
        `assert(valid, 1)

        byte_enable = 4'b0011;
        #1
        `assert(wb_data, (mem_read & 32'h0000FFFF))
        `assert(valid, 1)
    end

    // LB
    func3 = 3'b000;
    for(int i = 0; i < 100; i++) begin
        mem_read = $urandom();

        byte_enable = 4'b1000;
        #1
        `assert(signed'(wb_data), signed'(signed'((mem_read & 32'hFF000000)) >>> 24))
        `assert(valid, 1)

        byte_enable = 4'b0100;
        #1
        `assert(signed'(wb_data), {{24{mem_read[23]}}, mem_read[23:16]})
        `assert(valid, 1)

        byte_enable = 4'b0010;
        #1
        `assert(signed'(wb_data), {{24{mem_read[15]}}, mem_read[15:8]})
        `assert(valid, 1)

        byte_enable = 4'b0001;
        #1
        `assert(signed'(wb_data), {{24{mem_read[7]}}, mem_read[7:0]})
        `assert(valid, 1)
    end

    // LBU
    func3 = 3'b100;
    for(int i = 0; i < 100; i++) begin
        mem_read = $urandom();

        byte_enable = 4'b1000;
        #1
        `assert(wb_data, (mem_read & 32'hFF000000) >> 24)
        `assert(valid, 1)

        byte_enable = 4'b0100;
        #1
        `assert(wb_data, (mem_read & 32'h00FF0000) >> 16)
        `assert(valid, 1)

        byte_enable = 4'b0010;
        #1
        `assert(wb_data, (mem_read & 32'h0000FF00) >> 8)
        `assert(valid, 1)

        byte_enable = 4'b0001;
        #1
        `assert(wb_data, (mem_read & 32'h000000FF))
        `assert(valid, 1)
    end
end

endmodule