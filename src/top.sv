`timescale 1ns / 1ps

module top (
    input  logic       clk,      
    input  logic [0:0] btn,     // used for reset 
    input logic [9:0] sw,

    output logic [9:0] led       
);

    logic clk_cpu;
    logic locked;
    
    clk_wiz_0 cw0 (
        .clk_in1(clk),
        .clk_out1(clk_cpu),
        .locked(locked)
    );

    // Starts in reset
    logic rst_meta = 1'b1;
    logic rst_sync = 1'b1;

    always_ff @(posedge clk_cpu) begin
        rst_meta <= btn[0] | ~locked;      
        rst_sync <= rst_meta;
    end

    logic [9:0] sw_meta = '0;
    logic [9:0] sw_sync = '0;
    always_ff @(posedge clk_cpu) begin
        sw_meta <= sw;          // flop 1: samples the raw switches
        sw_sync <= sw_meta;     // flop 2: clean value, safe to use
    end

    cpu u_cpu (
        .clk   (clk_cpu),
        .rst_n (~rst_sync),
        .sw(sw_sync),      
        .led   (led)
    );

endmodule