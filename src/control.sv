`timescale 1ns / 1ps

/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */

module control(
    // IN
    input logic [6:0] op,
    input logic [2:0] func3,
    input logic [6:0] func7,
    input logic alu_zero,

    // OUT
    output logic [2:0] alu_control,
    output logic [1:0] imm_source,
    output logic mem_write,
    output logic reg_write,
    output logic alu_src,
    output logic result_src
);

// MAIN DECODER

logic [1:0] alu_op;
always_comb begin
    case(op)
        // LW
        7'b0000011 : begin
            reg_write = 1'b1;
            imm_source = 2'b00;
            mem_write = 1'b0;
            alu_op = 2'b00;
            alu_src = 1'b1; // imm read
            result_src = 1'b1; // memory write
        end

        //SW
        7'b0100011 : begin
            reg_write = 1'b0;
            imm_source = 2'b01;
            mem_write = 1'b1;
            alu_op = 2'b00;
            alu_src = 1'b1; //imm read
        end

        // ADD
        7'b0110011 : begin
            reg_write = 1'b1;
            imm_source = 2'bxx;
            mem_write = 1'b0;
            alu_op = 2'b10;
            alu_src = 1'b0; // register read
            result_src = 1'b0; // alu read
        end

        // Everything else
        default : begin
            reg_write = 1'b0;
            imm_source = 2'b00;
            mem_write = 1'b0;
            alu_op = 2'b00;
        end
    endcase
end

// ALU DECODER

always_comb begin
    case(alu_op)
        // LW, SW
        2'b00 : alu_control = 3'b000;

        // R-type instructions
        2'b10 : begin 
            case(func3)
                3'b000 : if(func7[5] == 1'b0) 
                            alu_control = 3'b000;
                         else 
                            alu_control = 3'b001;
                default : alu_control = 3'b111;
            endcase
        end

        //Everything else
        default : alu_control = 3'b111;
    endcase
end

endmodule
