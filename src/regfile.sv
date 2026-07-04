`timescale 1ns / 1ps

module regfile (
    // basic signals
    input logic clk,
    input logic rst_n,

    // Reads
    input logic [4:0] read_address1,
    input logic [4:0] read_address2,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2,

    // Writes 
    input logic write_enable,
    input logic [31:0] write_data,
    input logic [4:0] write_address
);

// 32 32bit registers
reg [31:0] registers [0:31];

//Write logic
always @(posedge clk) begin
    // reset
    if (rst_n == 1'b0) begin
        for (int i = 0; i<32; i++) begin
            registers[i] <= 32'b0;
        end
    end
    // Write, except to 0th register
    else if (write_enable == 1'b1 && write_address != 0) begin
        registers[write_address] <= write_data;
    end
end

// Read logic
always_comb begin : readLogic 
    read_data1 = registers[read_address1];
    read_data2 = registers[read_address2];
end

endmodule
