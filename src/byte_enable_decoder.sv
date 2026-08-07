`timescale 1ns / 1ps

module byte_enable_decoder (
    input logic [2:0] func3,
    input logic [31:0] alu_result,
    input logic [31:0] read_data2,

    output logic [3:0] byte_enable
);

assign byte_enable = 4'b1111;

endmodule