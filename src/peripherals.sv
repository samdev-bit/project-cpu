`timescale 1ns/1ps

module peripherals (
    input logic clk,
    input logic rst_n,
    input logic led_enable,
    input logic [3:0] byte_enable,
    input logic [31:0] write_data,
    input logic [9:0] sw_in,

    output logic [9:0] led_output,
    output logic [31:0] led_read_data,
    output logic [31:0] sw_read_data
);

always @(posedge clk) begin

    if (rst_n == 1'b0) begin
        led_output[9:0] <= 10'b0;
    end
    else if(led_enable) begin
        case(byte_enable[1:0])
            2'b00: ;
            2'b01: led_output[7:0] <= write_data[7:0];
            2'b10: led_output[9:8] <= write_data[9:8];
            2'b11: led_output[9:0] <= write_data[9:0];
        endcase
    end

end

always_comb begin
    led_read_data = {22'b0, led_output[9:0]};
    sw_read_data = {22'b0, sw_in[9:0]};
end

endmodule