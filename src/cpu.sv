`timescale 1ns / 1ps

/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off WIDTHTRUNC */

module cpu (
    input logic clk,
    input logic rst_n,
    input logic [9:0] sw,

    output logic [9:0] led
);

// CONTROL OUTPUT
wire PCsrc;
wire [1:0] second_add_src;

// SIGNEXT OUTPUT
wire[31:0] immediate;

// REGFILE OUTPUT
wire [31:0] read_data1;

// ALU OUTPUT
wire [31:0] alu_result;
wire alu_zero;
wire alu_lb;

// READER OUTPUT
wire [31:0] masked_wb;
wire valid;

// PROGRAM COUNTER

reg [31:0] pc;
logic [31:0] pc_next;
logic [31:0] PCPlus4;
logic [31:0] pc_plus_second_add;

assign PCPlus4 = pc + 4;

always_comb begin : pcSelect
    if (PCsrc == 1'b1) 
        pc_next = pc_plus_second_add;
    else
        pc_next = PCPlus4;
end

always_comb begin : second_add_select
    case(second_add_src)
        2'b00 : pc_plus_second_add = pc + immediate;
        2'b01 : pc_plus_second_add = immediate;
        2'b10 : pc_plus_second_add = read_data1 + immediate;
        default : pc_plus_second_add = immediate;
    endcase
end

// D FLIP FLOP
always @(posedge clk) begin
    if(rst_n == 0) begin
        pc <= 32'b0;
    end else begin
        pc <= pc_next;
    end
end

// INSTRUCTION MEMORY

// Acts as a ROM
wire [31:0] instruction;

memory #(
    .mem_init("simulation_imemory.hex")
) instruction_memory (
    // Memory inputs
    .clk(clk),
    .address(pc),
    .write_data(32'b0),
    .write_enable(1'b0),
    .byte_enable(4'b0000),
    .rst_n(1'b1),

    // Memory outputs
    .read_data(instruction)
);

// CONTROL

// in
logic [6:0] op;
assign op = instruction[6:0];
logic [2:0] f3;
assign f3 = instruction[14:12];
logic [6:0] f7;
assign f7 = instruction[31:25];
wire alu_src;
wire [1:0] result_src;

// out
wire [3:0] alu_control;
wire [2:0] imm_source;
wire mem_write;
wire reg_write;

control control_unit(
    .op(op),
    .func3(f3),
    .func7(f7),
    .alu_zero(alu_zero),
    .alu_lb(alu_lb),

    .alu_control(alu_control),
    .imm_source(imm_source),
    .mem_write(mem_write),
    .reg_write(reg_write),
    .alu_src(alu_src),
    .result_src(result_src),
    .PCsrc(PCsrc),
    .second_add_src(second_add_src)
);

// REGFILE

// INPUTS
logic [4:0] read_address1;
assign read_address1 = instruction[19:15];
logic [4:0] read_address2;
assign read_address2 = instruction[24:20];
logic [4:0] write_address;
assign write_address = instruction[11:7];
wire [31:0] read_data2;

logic [31:0] write_data;
logic wb_valid;
always_comb begin : wbSelect
    write_data = alu_result;
    wb_valid = 1'b1;

    case (result_src)
        2'b00 : begin 
                    write_data = alu_result;
                    wb_valid = 1'b1;
                end
        2'b01 : begin
                    write_data = masked_wb;
                    wb_valid = valid;
                end
        2'b10 : begin
                    write_data = PCPlus4;
                    wb_valid = 1'b1;
                end 
        2'b11 : begin
                    write_data = pc_plus_second_add;
                    wb_valid = 1'b1;
                end
    endcase
end

regfile regfile(
    // basic signals
    .clk(clk),
    .rst_n(rst_n),

    // Read In
    .read_address1(read_address1),
    .read_address2(read_address2),
    // Read out
    .read_data1(read_data1),
    .read_data2(read_data2),

    // Write In
    .write_enable(reg_write & wb_valid),
    .write_data(write_data),
    .write_address(write_address)
);

// SIGN EXTENDER

logic [24:0] raw_imm;
assign raw_imm = instruction[31:7];

signext sign_extender(
    .raw_src(raw_imm),
    .imm_source(imm_source),
    .immediate(immediate)
);

// ALU

logic [31:0] alu_src2;

always_comb begin : srcBSelect
    if(alu_src == 1)
        alu_src2 = immediate;
    else
        alu_src2 = read_data2;
end

alu alu_inst(
    .alu_control(alu_control),
    .src1(read_data1),
    .src2(alu_src2),
    .alu_result(alu_result),
    .zero(alu_zero),
    .alu_lb(alu_lb)
);

logic led_enable;
logic mem_enable;
logic sw_enable;
logic [1:0] w_sel;

// IO_DECODER
mmio mmio_inst(
    .reg_write(reg_write),
    .mem_write(mem_write),
    .alu_result(alu_result),

    .led_enable(led_enable),
    .mem_enable(mem_enable),
    .sw_enable(sw_enable),
    .w_sel(w_sel)
);

// BYTE_ENABLE_DECODER

wire [3:0] byte_enable;
wire [31:0] mem_led_write_data;

byte_enable_decoder byte_enable_decoder_inst(
    .func3(f3),
    .alu_result(alu_result),
    .read_data2(read_data2),
    .byte_enable(byte_enable),
    .write_data(mem_led_write_data)
);

// PERIPHERALS MODULE

logic [31:0] led_read_data;
logic [31:0] sw_read_data;

peripherals peripherals_inst(
    .clk(clk),
    .rst_n(rst_n),
    .led_enable(led_enable),
    .byte_enable(byte_enable),
    .write_data(mem_led_write_data),
    .sw_in(sw),

    .led_output(led),
    .led_read_data(led_read_data),
    .sw_read_data(sw_read_data)
);

// DATA MEMORY
wire [31:0] mem_read;

memory #(
    .mem_init("test_dmemory.hex")
) data_memory (
    // Inputs
    .clk(clk),
    .address({alu_result[31:2], 2'b00}),
    .write_data(mem_led_write_data),
    .write_enable(mem_enable),
    .byte_enable(byte_enable),
    .rst_n(1'b1),

    // Outputs
    .read_data(mem_read)
);

logic [31:0] read_data;

always_comb begin : write_back_data_select
    case(w_sel)
        2'b11 : read_data = led_read_data;
        2'b10 : read_data = mem_read;
        2'b00 : read_data = sw_read_data;
        default : read_data = mem_read;
    endcase
end

reader reader_inst (
    .mem_read(read_data),
    .func3(f3),
    .byte_enable(byte_enable),

    .wb_data(masked_wb),
    .valid(valid)
);

endmodule