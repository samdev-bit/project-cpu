`timescale 1ns / 1ps

/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off WIDTHTRUNC */

module memory #(
    parameter WORDS = 64,
    parameter mem_init = ""
) (
    input logic clk,
    input logic [31:0] address,
    input logic [31:0] write_data,
    input logic write_enable,
    input logic rst_n,

    output logic [31:0] read_data
);

reg [31:0] mem [0:WORDS-1];

initial begin
    $readmemh(mem_init, mem); // Load memory for simulation
end

always @(posedge clk) begin
    // reset logic
    if (rst_n == 1'b0) begin
        for (int i = 0; i < WORDS; i++) begin
            mem[i] <= 32'b0;
        end
    end
    else if (write_enable) begin
        // Ensure address is aligned, if not ignore the write
        if (address[1:0] == 2'b00) begin
            mem[address[31:2]] <= write_data;
        end 
    end
end

always_comb begin
    read_data = mem[address[31:2]];
end

endmodule
