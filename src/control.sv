import holy_core_pkg::*;
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
    input logic alu_lb,

    // OUT
    output logic [3:0] alu_control,
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
        OPCODE_I_TYPE_LOAD : begin
            reg_write = 1'b1;
            imm_source = I_TYPE_IMM;
            mem_write = 1'b0;
            alu_op = ALU_OP_LOAD_STORE;
            alu_src = 1'b1; // imm read
            result_src = 2'b01; // memory read
            branch = 1'b0;
            jump = 1'b0;
        end

        //SW
        OPCODE_S_TYPE : begin
            reg_write = 1'b0;
            imm_source = S_TYPE_IMM;
            mem_write = 1'b1;
            alu_op = ALU_OP_LOAD_STORE;
            alu_src = 1'b1; //imm read
            branch = 1'b0; 
            jump = 1'b0;
        end

        // R-type
        OPCODE_R_TYPE : begin
            reg_write = 1'b1;
            mem_write = 1'b0;
            alu_op = ALU_OP_MATH;
            alu_src = 1'b0; // register read
            result_src = 2'b00; // alu read
            branch = 1'b0;
            jump = 1'b0;
        end

        // B-type
        OPCODE_B_TYPE : begin
            reg_write = 1'b0;
            imm_source = B_TYPE_IMM;
            mem_write = 1'b0;
            alu_op = ALU_OP_BRANCHES;
            alu_src = 1'b0; // register read
            branch = 1'b1;
            jump = 1'b0;
            second_add_src = 2'b00;
        end

        // J-type, JALR
        OPCODE_J_TYPE, OPCODE_J_TYPE_JALR : begin
            reg_write = 1'b1;
            mem_write = 1'b0;
            result_src = 2'b10;
            branch = 1'b0;
            jump = 1'b1;
            if(op[3]) begin
                imm_source = J_TYPE_IMM;
                second_add_src = 2'b00;
            end
            else if(~op[3]) begin
                imm_source = I_TYPE_IMM;
                second_add_src = 2'b10;
            end
        end

        // ALU I-type
        OPCODE_I_TYPE_ALU  : begin

            // Make sure f7 is well formatted for SLL, SRL and SRA
            if (func3 == F3_SLL) reg_write = (func7 == F7_SLL_SRL) ? 1'b1 : 1'b0;
            else if (func3 == F3_SRL_SRA) reg_write = ((func7 == F7_SLL_SRL) | (func7 == F7_SRA)) ? 1'b1 : 1'b0;
            else reg_write = 1'b1;

            imm_source = I_TYPE_IMM;
            alu_op = ALU_OP_MATH;
            alu_src = 1'b1;
            mem_write = 1'b0;
            result_src = 2'b00;
            branch = 1'b0;
            jump = 1'b0;
        end

        // U-type
        OPCODE_U_TYPE_LUI, OPCODE_U_TYPE_AUIPC: begin
            reg_write = 1'b1;
            imm_source = U_TYPE_IMM;
            mem_write = 1'b0;
            result_src = 2'b11;
            branch = 1'b0;
            jump = 1'b0;
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

// ALU DECODER

always_comb begin
    case(alu_op)
        // LW, SW
        ALU_OP_LOAD_STORE : alu_control = ALU_ADD;

        // R-type and ALU I-type
        ALU_OP_MATH : begin 
            case(func3)
                // ADD
                F3_ADD_SUB : if((func7[5] == 1'b0) | op == 7'b0010011) 
                            alu_control = ALU_ADD;
                         else 
                            alu_control = ALU_SUB;
                
                // AND
                F3_AND : alu_control = ALU_AND;

                // OR
                F3_OR : alu_control = ALU_OR;

                // SLT
                F3_SLT : alu_control = ALU_SLT;

                // SLTU
                F3_SLTU : alu_control = ALU_SLTU;

                // XOR
                F3_XOR : alu_control = ALU_XOR;

                // SLL
                F3_SLL : alu_control = ALU_SLL;

                // SRL/SRA
                F3_SRL_SRA : alu_control = (func7[5] == 1'b0) ? ALU_SRL : ALU_SRA;

                default : alu_control = 4'b111;
            endcase
        end

        // B-type
        ALU_OP_BRANCHES : begin
            case(func3)

                // BEQ
                F3_BEQ : alu_control = ALU_SUB;

                // BLT
                F3_BLT : alu_control = ALU_SLT;

                // BNE
                F3_BNE : alu_control = ALU_SUB;

                // BGE
                F3_BGE : alu_control = ALU_SLT;

                // BLTU
                F3_BLTU : alu_control = ALU_SLTU;

                // BGEU
                F3_BGEU : alu_control = ALU_SLTU;

                default : alu_control = 4'b0000;
            endcase
        end

        //Everything else
        default : alu_control = 4'b0111;
    endcase
end

// Branch logic decoder

logic assert_branch;

always_comb begin
    case(func3)
        // BEQ
        F3_BEQ : assert_branch = alu_zero & branch;
        // BLT, BLTU
        F3_BLT, F3_BLTU : assert_branch = alu_lb & branch;
        // BNE
        F3_BNE : assert_branch = ~alu_zero & branch;
        // BGE, BGEU
        F3_BGE, F3_BGEU : assert_branch = ~alu_lb & branch;
        default : assert_branch = 1'b0;
    endcase
end

assign PCsrc = assert_branch | jump;

endmodule