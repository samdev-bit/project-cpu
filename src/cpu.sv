`timescale 1ns / 1ps

/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off WIDTHTRUNC */

module cpu (
    input logic clk,
    input logic rst_n
);

// PROGRAM COUNTER

reg [31:0] pc;
logic [31:0] pc_next;

always_comb begin : pcSelect
    pc_next = pc + 4;
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
    .mem_init("test_imemory.hex")
) instruction_memory (
    // Memory inputs
    .clk(clk),
    .address(pc),
    .write_data(32'b0),
    .write_enable(1'b0),
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
wire alu_zero;

// out
wire [2:0] alu_control;
wire [1:0] imm_source;
wire mem_write;
wire reg_write;

control control_unit(
    .op(op),
    .func3(f3),
    .func7(f7),
    .alu_zero(alu_zero),

    .alu_control(alu_control),
    .imm_source(imm_source),
    .mem_write(mem_write),
    .reg_write(reg_write)
);

// REGFILE

// INPUTS
logic [4:0] read_address1;
assign read_address1 = instruction[19:15];
logic [4:0] read_address2;
assign read_address2 = instruction[24:20];
logic [4:0] write_address;
assign write_address = instruction[11:7];
wire [31:0] read_data1;
wire [31:0] read_data2;

logic [31:0] write_data;
always_comb begin : wbSelect
    write_data = mem_read;
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
    .write_enable(reg_write),
    .write_data(write_data),
    .write_address(write_address)
);

// SIGN EXTENDER

logic [24:0] raw_imm;
assign raw_imm = instruction[31:7];
wire[31:0] immediate;

signext sign_extender(
    .raw_src(raw_imm),
    .imm_source(imm_source),
    .immediate(immediate)
);

// ALU

wire [31:0] alu_result;
logic [31:0] alu_src2;

always_comb begin : srcBSelect
    alu_src2 = immediate;
end

alu alu_inst(
    .alu_control(alu_control),
    .src1(read_data1),
    .src2(alu_src2),
    .alu_result(alu_result),
    .zero(alu_zero)
);

// DATA MEMORY
wire [31:0] mem_read;

memory #(
    .mem_init("test_dmemory.hex")
) data_memory (
    // Inputs
    .clk(clk),
    .address(alu_result),
    .write_data(read_data2),
    .write_enable(mem_write),
    .rst_n(1'b1),

    // Outputs
    .read_data(mem_read)
);

endmodule
