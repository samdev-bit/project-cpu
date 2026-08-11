`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $error("ASSERTION FAILED in %m: signal (%h) != value (%h) in file %s at line %0d", (signal), (value), (`__FILE__), (`__LINE__)); \
    end

module test_byte_enable_decoder;
    logic [2:0] func3;
    logic [31:0] read_data2;
    logic [31:0] alu_result;

    logic [3:0] byte_enable;
    logic [31:0] write_data;

    byte_enable_decoder b0 (.*);

initial begin
    $dumpfile("test_byte_enable_decoder.vcd");
    $dumpvars(0, test_byte_enable_decoder);
end

initial begin
    logic [31:0] word;

    // SW
    word = 32'h123ABC00;
    func3 = 3'b010;

    for(int i = 0; i < 100; i++) begin
        read_data2 = $urandom();
        for(int j = 0; j < 4; j++) begin
            alu_result = word | j;
            #1
            `assert(write_data, (read_data2 & 32'hFFFFFFFF))
            if(b0.offset == 2'b00) begin `assert(byte_enable, 4'b1111) end
            else begin `assert(byte_enable, 4'b0000) end
        end
    end

    // SB
    #10

    func3 = 3'b000;

    for(int i = 0; i < 100; i++) begin
        read_data2 = $urandom();
        for(int j = 0; j < 4; j++) begin
            alu_result = word | j;
            #1
            if(b0.offset == 2'b00) begin
                `assert(byte_enable, 4'b0001)
                `assert(write_data, (read_data2 & 32'h000000FF))
            end
            else if(b0.offset == 2'b01) begin
                `assert(byte_enable, 4'b0010)
                `assert(write_data, (read_data2 & 32'h0000FF00))
            end
            else if(b0.offset == 2'b10) begin
                `assert(byte_enable, 4'b0100)
                `assert(write_data, (read_data2 & 32'h00FF0000))
            end
            else if(b0.offset == 2'b11) begin
                `assert(byte_enable, 4'b1000)
                `assert(write_data, (read_data2 & 32'hFF000000))
            end
        end
    end

    // SH
    #10

    func3 = 3'b001;

    for(int i = 0; i < 100; i++) begin
        read_data2 = $urandom();
        for(int j = 0; j < 4; j++) begin
            alu_result = word | j;
            #1
            if(b0.offset == 2'b00) begin
                `assert(byte_enable, 4'b0011)
                `assert(write_data, (read_data2 & 32'h0000FFFF))
            end
            else if(b0.offset == 2'b10) begin
                `assert(byte_enable, 4'b1100)
                `assert(write_data, (read_data2 & 32'hFFFF0000))
            end
            else begin `assert(byte_enable, 4'b0000) end
        end
    end
end

endmodule