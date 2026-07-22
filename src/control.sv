`timescale 1ns / 1ps

/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off LATCH */

module control(
    // IN
    input logic [6:0] op,
    input logic [2:0] func3,
    input logic [6:0] func7,
    input logic alu_zero,

    // OUT
    output logic [2:0] alu_control,
    output logic [2:0] imm_source,
    output logic mem_write,
    output logic reg_write,
    output logic alu_src,
    output logic [1:0] result_src,
    output logic PCsrc,
    output logic [1:0] second_add_src
);

// MAIN DECODER

logic [1:0] alu_op;
logic branch;
logic jump;

always_comb begin
    case(op)
        // LW
        7'b0000011 : begin
            reg_write = 1'b1;
            imm_source = 3'b000;
            mem_write = 1'b0;
            alu_op = 2'b00;
            alu_src = 1'b1; // imm read
            result_src = 2'b01; // memory read
            branch = 1'b0;
            jump = 1'b0;
        end

        //SW
        7'b0100011 : begin
            reg_write = 1'b0;
            imm_source = 3'b001;
            mem_write = 1'b1;
            alu_op = 2'b00;
            alu_src = 1'b1; //imm read
            branch = 1'b0; 
            jump = 1'b0;
        end

        // R-type
        7'b0110011 : begin
            reg_write = 1'b1;
            mem_write = 1'b0;
            alu_op = 2'b10;
            alu_src = 1'b0; // register read
            result_src = 2'b00; // alu read
            branch = 1'b0;
            jump = 1'b0;
        end

        // B-type
        7'b1100011 : begin
            reg_write = 1'b0;
            imm_source = 3'b010;
            mem_write = 1'b0;
            alu_op = 2'b01;
            alu_src = 1'b0; // register read
            branch = 1'b1;
            jump = 1'b0;
            second_add_src = 2'b00;
        end

        // J-type
        7'b1101111 : begin
            reg_write = 1'b1;
            imm_source = 3'b100;
            mem_write = 1'b0;
            result_src = 2'b10;
            branch = 1'b0;
            jump = 1'b1;
            second_add_src = 2'b00;
        end

        // ALU I-type
        7'b0010011 : begin
            reg_write = 1'b1;
            imm_source = 3'b000;
            alu_op = 2'b10;
            alu_src = 1'b1;
            mem_write = 1'b0;
            result_src = 2'b00;
            branch = 0;
            jump = 0;
        end

        // U-type
        7'b0110111, 7'b0010111: begin
            reg_write = 1'b1;
            imm_source = 3'b011;
            mem_write = 1'b0;
            result_src = 2'b11;
            branch = 0;
            jump = 0;
            case(op[5])
                1'b1 : second_add_src = 2'b01;
                1'b0 : second_add_src = 2'b00;
            endcase
        end

        // Everything else
        default : begin
            reg_write = 1'b0;
            imm_source = 3'b000;
            mem_write = 1'b0;
            alu_op = 2'b00;
            branch = 1'b0;
            jump = 1'b0;
        end
    endcase
end

assign PCsrc = (alu_zero & branch) | jump;

// ALU DECODER

always_comb begin
    case(alu_op)
        // LW, SW
        2'b00 : alu_control = 3'b000;

        // R-type and ALU I-type
        2'b10 : begin 
            case(func3)
                // ADD
                3'b000 : if((func7[5] == 1'b0) | op == 7'b0010011) 
                            alu_control = 3'b000;
                         else 
                            alu_control = 3'b001;
                
                // AND
                3'b111 : alu_control = 3'b010;

                // OR
                3'b110 : alu_control = 3'b011;
                default : alu_control = 3'b111;
            endcase
        end

        // BEQ
        2'b01 : alu_control = 3'b001;

        //Everything else
        default : alu_control = 3'b111;
    endcase
end

endmodule