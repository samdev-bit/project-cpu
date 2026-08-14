import holy_core_pkg::*;
`timescale 1ns / 1ps

module byte_enable_decoder (
    input logic [2:0] func3,
    input logic [31:0] alu_result,
    input logic [31:0] read_data2,

    output logic [3:0] byte_enable,
    output logic [31:0] write_data
);

logic [1:0] offset;
assign offset = alu_result[1:0];

always_comb begin
    case(func3)
        F3_BYTE, F3_BYTE_U : begin // SB, LB, LBU
            case(offset)
                2'b00 : begin 
                    byte_enable = 4'b0001;
                    write_data = read_data2 & 32'h000000FF;
                end
                2'b01 : begin
                    byte_enable = 4'b0010;
                    write_data = read_data2 & 32'h0000FF00;
                end
                2'b10 : begin
                    byte_enable = 4'b0100;
                    write_data = read_data2 & 32'h00FF0000;
                end
                2'b11 : begin
                    byte_enable = 4'b1000;
                    write_data = read_data2 & 32'hFF000000;
                end
            endcase
        end
        F3_HALFWORD, F3_HALFWORD_U : begin // SH, LH, LHU
            case(offset)
                2'b00 : begin 
                    byte_enable = 4'b0011;
                    write_data = read_data2 & 32'h0000FFFF;
                end
                2'b10 : begin 
                    byte_enable = 4'b1100;
                    write_data = read_data2 & 32'hFFFF0000;
                end
                default: byte_enable = 4'b0000;
            endcase
        end
        F3_WORD : begin // SW
            byte_enable = (offset == 2'b00) ? 4'b1111 : 4'b0000;
            write_data = read_data2;
        end
        default : begin
            byte_enable = 4'b0000;
            write_data = read_data2;
        end
    endcase
end

endmodule