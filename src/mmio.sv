`timescale 1ns/1ps

module mmio (
    input logic mem_write,
    input logic [31:0] alu_result,

    output logic led_enable,
    output logic mem_enable,
    output logic led_sel
);

localparam [31:0] LED_ADDR = 32'h1000_0000;

logic ram_sel;

assign led_sel = (alu_result[31:2] == LED_ADDR[31:2]);
assign ram_sel = (alu_result[31:28] == 4'h0);

assign led_enable = mem_write & led_sel;
assign mem_enable = mem_write & ram_sel;

endmodule