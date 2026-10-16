# project-cpu

A single-cycle 32-bit RISC-V (RV32I) CPU written in SystemVerilog, verified with self-checking testbenches and deployed on a Xilinx Zynq-7000 FPGA.

CPU running on the Real Digital Blackboard lighting up 10 LEDs:

https://github.com/user-attachments/assets/1401f442-7806-424b-8f02-0850f95cc8b2

## Branches

| Branch | What it contains |
|---|---|
| 'single-cycle-edition' | My CPU that works in simulation: 8 modules + a self-checking testbench for each module + system level tests |
| 'fpga-edition' | The same CPU plus memory-mapped I/O (LED peripheral), top-level wrapper, clocking, and constraints for the RealDigital Blackboard |

## Features

- All RV32I instructions except ECALL and EBREAK
- Byte and halfword loads and stores (LB, LBU, LH, LHU, SB, SH)
- Separate instruction and data memories
- Self-checking testbench for every module
- On hardware (FPGA branch): software drives LEDs through memory-mapped I/O

## Architecture

<img width="1123" height="794" alt="datapath" src="https://github.com/user-attachments/assets/1e29cbe7-ab33-4e3a-b416-c49bf8a58246" />

| Module | Purpose |
|---|---|
| `alu.sv` | Arithmetic, logic, shifts, comparisons |
| `control.sv` | Main decoder, ALU decoder, branch logic |
| `regfile.sv` | 32 x 32-bit registers, x0 hardwired to 0 |
| `signext.sv` | Immediate generation for all formats |
| `memory.sv` | Word memory with byte enables, used for instructions and data |
| `byte_enable_decoder.sv` | Converts SB/SH/SW into byte masks and shifted data |
| `reader.sv` | Extracts and sign-extends bytes/halfwords on loads |
| `cpu.sv` | Top-level datapath |

## Running the simulation

- verilator --binary --trace -sv src/cpu.sv tb/test_cpu/test_cpu.sv
- cp tb/test_cpu/test_imemory.hex tb/test_cpu/test_dmemory.hex obj_dir/
- cd obj_dir
- ./Vcpu

## Limitations

No ECALL/EBREAK

Single-Cycle, so clock is limited by longest path

Memory array only has 128 entries but is indexed with 30 bits (my program only touches in range RAM and LED addresses)

## Author 
Samuel Devotta, University of Southampton
