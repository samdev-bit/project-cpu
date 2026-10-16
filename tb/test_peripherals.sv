`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $error("ASSERTION FAILED in %m: signal (%h) != value (%h) in file %s at line %0d", (signal), (value), (`__FILE__), (`__LINE__)); \
    end

module test_peripherals;
    logic clk;
    logic rst_n;
    logic led_enable;
    logic [3:0] byte_enable;
    logic [31:0] write_data;

    logic [9:0] led_output;
    logic [31:0] led_read_data;

    peripherals p0(.*);

initial begin
    $dumpfile("test_peripherals.vcd");
    $dumpvars(0, test_peripherals);
end

initial begin
    clk = 0;
    forever begin
        #10 clk = ~clk;
    end
end

initial begin
    rst_n = 0;
    #1
    `assert(led_output[9:0], 10'b0)

    @(posedge clk)
    rst_n = 1;
    led_enable = 1;
    byte_enable = 4'b1111;
    write_data = 32'h000003FF;
    #1
    `assert(led_output[9:0], 10'h3FF)

    @(posedge clk)
    led_enable = 0;
    write_data = 32'b0;
    #1
    `assert(led_output[9:0], 10'h3FF)

    @(posedge clk)
    led_enable = 1;
    byte_enable = 4'b0001;
    write_data = 32'h000000AA;
    #1
    `assert(led_output[9:0], 10'h3AA)

    @(posedge clk)
    byte_enable = 4'b0010;
    write_data = 32'h00000200;
    #1
    `assert(led_output[9:0], 10'h2AA)

    @(posedge clk)
    byte_enable = 4'b0000;
    write_data = 32'h00000121;
    #1
    `assert(led_output[9:0], 10'h2AA)

    #1
    `assert(led_read_data, {22'b0, 10'h2AA})

    $finish;
end

endmodule