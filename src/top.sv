`timescale 1ns / 1ps

module top (
    input  logic       clk,      // 100 MHz board clock (H16)
    input  logic [0:0] btn,      // btn[0] = reset button (W14)
    output logic [9:0] led       // 10 plain LEDs
);

    // Reset synchronizer: starts IN reset at power-up, so no button press is needed
    logic rst_meta = 1'b1;
    logic rst_sync = 1'b1;

    always_ff @(posedge clk) begin
        rst_meta <= btn[0];      // button is asynchronous, so sample it twice
        rst_sync <= rst_meta;
    end

    cpu u_cpu (
        .clk   (clk),
        .rst_n (~rst_sync),      // cpu is active-low; button is (I believe) active-high
        .led   (led)
    );

endmodule