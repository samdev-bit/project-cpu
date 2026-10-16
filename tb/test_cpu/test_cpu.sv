`timescale 1ns / 1ps

`define assert(signal, value) \
    if ((signal) !== (value)) begin \
        $error("ASSERTION FAILED in %m: signal (%h) != value (%h) in file %s at line %0d", (signal), (value), (`__FILE__), (`__LINE__)); \
    end

/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

module test_cpu;
    logic clk;
    logic rst_n;
    logic [9:0] sw;

    logic [9:0] led;

    cpu c0 (.*);

initial begin
    $dumpfile("test_cpu_waveform.vcd");
    $dumpvars(0, test_cpu);
end

initial begin
    clk = 0;
    forever begin
        #10 clk = ~clk;
    end
end


initial begin 

    logic [31:0] imem [127:0];
    logic [31:0] expected_instruction;
    logic [31:0] test_address;
    $readmemh("test_imemory.hex", imem);

    // Reset check
    rst_n = 1;

    #10
    rst_n = 0;
    #10
    test_address = (int'(32'hC)) / 4;
    `assert(c0.pc, 8'b00000000)
    `assert(c0.data_memory.mem[test_address], 32'hF2F2F2F2) // Checking if initial value at byte 12 is correct for the SW check
    rst_n = 1;

    // Read check
    for (int i = 0; i < 8; i++) begin
        @(posedge clk);
        expected_instruction = imem[i];
        `assert(c0.instruction, expected_instruction)
    end

    #10

    // LW logic check
    `assert(c0.regfile.registers[18], 32'HDEADBEEF)

    // SW logic check
    `assert(c0.data_memory.mem[test_address], 32'hDEADBEEF)

    // ADD logic check
    `assert(c0.regfile.registers[19], 32'h00000AAA)
    `assert(c0.regfile.registers[20], 32'hDEADC999)

    // AND logic check
    `assert(c0.regfile.registers[21], 32'hDEAD8889)

    // OR logic check
    `assert(c0.regfile.registers[5], 32'h125F552D)
    `assert(c0.regfile.registers[6], 32'h7F4FD46A)
    `assert(c0.regfile.registers[7], 32'h7F5FD56F)

    // BEQ logic check
    @(posedge clk);
    `assert(c0.instruction, 32'h00730663)

    @(posedge clk);
    `assert(c0.instruction, 32'h00802B03) // previous branch should not be taken
    #10
    `assert(c0.regfile.registers[22], 32'hDEADBEEF)

    @(posedge clk);
    `assert(c0.instruction, 32'h01690863)

    @(posedge clk);
    `assert(c0.instruction, 32'h00002B03)
    #10
    `assert(c0.regfile.registers[22], 32'hAEAEAEAE)

    @(posedge clk);
    `assert(c0.instruction, 32'hFF6B0CE3)

    @(posedge clk);
    `assert(c0.instruction, 32'h00000663)

    @(posedge clk);
    `assert(c0.instruction, 32'h00000013)

    // JAL logic check
    #40
    `assert(c0.instruction, 32'hFFDFF0EF)

    #20
    `assert(c0.instruction, 32'h00C000EF)

    #20
    `assert(c0.instruction, 32'h00C02383)
    #10
    `assert(c0.regfile.registers[7], 32'hDEADBEEF)


    // ADDI tests
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[26], 32'hDEADC09A)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[25], 32'h7F4FD38B)

    // AUIPC test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[5], 32'h1F1FA064)

    // LUI test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[5], 32'h2F2FA000)

    // SLTI test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[23], 32'h00000000)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[23], 32'h00000001)

    // SLTIU test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[22], 32'h00000001)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[22], 32'h00000000)

    // XORI test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[18], 32'h21524445)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[19], 32'h21524445)

    // ORI test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[20], 32'h2152456F)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[20], 32'hFFFFFD6F)

    // ANDI test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[15], 32'h00000005)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[15], 32'h21524005)

    // SLLI test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[8], 32'hFFF5BC00)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[8], 32'hFFF5BC00)

    // SRLI test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[20], 32'h003FFD6F)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[20], 32'h003FFD6F)

    // SRAI test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[8], 32'hFFF7AB62)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[8], 32'h00000FFF)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[8], 32'h00000FFF)

    // SUB test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[18], 32'hBD5B4444)

    // SLL test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[7], 32'h00000008)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[18], 32'h5B444400)

    // SLT test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[17], 32'h00000001)

    // SLTU test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[17], 32'h00000001)

    // XOR test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[17], 32'h7A160045)

    // SRL test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[8], 32'h00215244)

    // SRA test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[8], 32'h00215244)

    // BLT test
    @(posedge clk)
    
    @(posedge clk)
    `assert(c0.instruction, 32'h01144463)
    #1

    @(posedge clk)
    `assert(c0.instruction, 32'h00000013)
    #1
    `assert(c0.regfile.registers[8], 32'h00215244)

    // BNE test
    @(posedge clk)
    
    @(posedge clk)
    `assert(c0.instruction, 32'h01141463)
    #1

    @(posedge clk)
    `assert(c0.instruction, 32'h00000013)
    #1
    `assert(c0.regfile.registers[8], 32'h00215244)

    // BGE test
    @(posedge clk)
    
    @(posedge clk)
    `assert(c0.instruction, 32'h0088D463)
    #1

    @(posedge clk)
    `assert(c0.instruction, 32'h00000013)
    #1
    `assert(c0.regfile.registers[8], 32'h00215244)

    // BLTU test
    @(posedge clk)

    @(posedge clk)
    `assert(c0.instruction, 32'h01146463)
    #1

    @(posedge clk)
    `assert(c0.instruction, 32'h00000013)
    #1
    `assert(c0.regfile.registers[8], 32'h00215244)

    // BGEU test
    @(posedge clk)

    @(posedge clk)
    `assert(c0.instruction, 32'h0088F463)
    #1

    @(posedge clk)
    `assert(c0.instruction, 32'h00000013)
    #1
    `assert(c0.regfile.registers[8], 32'h00215244)

    // JALR test
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[7], 32'h00000120)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[7], 32'h00000134)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[1], 32'h0000012C)

    @(posedge clk)
    `assert(c0.instruction, 32'h00000013)

    @(posedge clk)
    #1
    `assert(c0.data_memory.mem[0], 32'hAEAEAEAE)

    @(posedge clk)
    #1
    `assert(c0.data_memory.mem[1], 32'h00210000)

    @(posedge clk)
    #1
    `assert(c0.data_memory.mem[0], 32'hAEAEAEAE)

    @(posedge clk)
    #1
    `assert(c0.data_memory.mem[0], 32'hAEAEAEAE)

    @(posedge clk)
    #1
    `assert(c0.data_memory.mem[1], 32'h5B440000)
    c0.regfile.registers[7] = 32'h00000000;
    c0.regfile.registers[18] = 32'h00000000;
    c0.regfile.registers[20] = 32'h00000000;
    c0.regfile.registers[21] = 32'h00000000;

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[7], 32'h00000010)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[18], 32'h00000000)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[18], 32'hFFFFFFDE)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[19], 32'h000000BE)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[20], 32'h00000000)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[20], 32'hFFFFDEAD)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[21], 32'h00000000)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[21], 32'h0000DEAD)
    
    @(posedge clk)
    #1
    `assert(c0.regfile.registers[1], 32'h10000000)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[2], 32'h00000001)

    @(posedge clk)
    #1
    `assert(led, 10'b0000000001)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[1], 32'h10000000)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[2], 32'h00000001)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[4], 32'h00000006)

    for (int i = 0; i < 6; i++) begin
        // sw x2, 0(x1)
        @(posedge clk); 
        #1;
        `assert(led, (i % 2 == 0) ? 10'b1 : 10'b0)

        // addi x3, x0, 5
        @(posedge clk); 
        #1;
        `assert(c0.regfile.registers[3], 32'd5)

        for (int k = 1; k <= 5; k++) begin
            // addi x3, x3, -1
            @(posedge clk); 
            #1;
            `assert(c0.regfile.registers[3], 5 - k)

            // bne x3, x0, -4
            @(posedge clk); 
            #1;
            `assert(c0.pc, (k < 5) ? 32'h188 : 32'h190)
        end

        // xori x2, x2
        @(posedge clk); 
        #1;
        `assert(c0.regfile.registers[2], (i % 2 == 0) ? 32'd0 : 32'd1)

        // addi x4, x4
        @(posedge clk); 
        #1;
        `assert(c0.regfile.registers[4], 5 - i)

        // bne x4, x0
        @(posedge clk); 
        #1;
        `assert(c0.pc, (i < 5) ? 32'h180 : 32'h19C)
    end

    sw = 10'b0101010101;

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[1], 32'h10000000)

    @(posedge clk)
    #1
    `assert(c0.regfile.registers[2], 32'h00000155)

    @(posedge clk)
    #1
    `assert(led, 10'b0101010101)


    $dumpflush;
    $finish;
end

endmodule
