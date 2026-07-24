`timescale 1ns / 1ps

module alu (
    // IN
    input logic [3:0] alu_control,
    input logic [31:0] src1,
    input logic [31:0] src2,
    // OUT
    output logic [31:0] alu_result,
    output logic zero
);

always_comb begin
    case (alu_control)
        // ADD
        4'b0000 : alu_result = src1 + src2;

        // AND
        4'b0010 : alu_result = src1 & src2;

        //OR
        4'b0011 : alu_result = src1 | src2;

        // SUB
        4'b0001 : alu_result = src1 + (~src2 + 1'b1);

        // SLT
        4'b0101 : alu_result = {31'b0, signed'(src1) < signed'(src2)};

        // SLTU
        4'b0111 : alu_result = {31'b0, unsigned'(src1) < unsigned'(src2)};

        // XOR
        4'b1000 : alu_result = src1 ^ src2;

        // SLL
        4'b1001 : alu_result = src1 << src2;

        // UNIMPLEMENTED STUFF
        default: alu_result = 32'b0;
    endcase
end

assign zero = (alu_result == 32'b0);

endmodule
