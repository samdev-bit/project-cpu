import holy_core_pkg::*;
`timescale 1ns / 1ps

module reader(
    input logic [31:0] mem_read,
    input logic [2:0] func3,
    input logic [3:0] byte_enable,

    output logic [31:0] wb_data,
    output logic valid
);

logic sign_extend;
assign sign_extend = ~func3[2];

logic [31:0] masked_data;
logic [31:0] raw_data;

always_comb begin : mask_apply
    for(int i = 0; i < 4; i++) begin
        if (byte_enable[i]) masked_data[(i*8)+:8] = mem_read[(i*8)+:8];
        else masked_data[(i*8)+:8] = 8'b0;
    end
end

always_comb begin : shift_data
    case(func3)
        F3_WORD : raw_data = masked_data; // LW

        F3_BYTE, F3_BYTE_U : begin // LB, LBU
            case(byte_enable)
                4'b0001 : raw_data = masked_data;
                4'b0010 : raw_data = masked_data >> 8;
                4'b0100 : raw_data = masked_data >> 16;
                4'b1000 : raw_data = masked_data >> 24;
                default : raw_data = masked_data;
            endcase
        end

        F3_HALFWORD, F3_HALFWORD_U : begin // LH, LHU
            case(byte_enable)
                4'b0011 : raw_data = masked_data;
                4'b1100 : raw_data = masked_data >> 16;
                default : raw_data = masked_data;
            endcase
        end

        default : raw_data = masked_data;
    endcase
end

always_comb begin : sign_extender
    case(func3)
        F3_WORD : wb_data = raw_data;
        F3_BYTE, F3_BYTE_U : wb_data = sign_extend ? ({{24{raw_data[7]}}, raw_data[7:0]}) : raw_data;
        F3_HALFWORD, F3_HALFWORD_U : wb_data = sign_extend ? ({{16{raw_data[15]}}, raw_data[15:0]}) : raw_data;
        default : wb_data = raw_data;
    endcase

    valid = |byte_enable;
end

endmodule