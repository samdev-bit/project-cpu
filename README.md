# project-cpu

A single-cycle 32-bit RISC-V (RV32I) CPU written in SystemVerilog, verified with self-checking testbenches and deployed on a Xilinx Zynq-7000 FPGA. Verified in simulation (all RV32I except ECALL/EBREAK) and the fpga_edition branch is verified on a RealDigital Blackboard at 25 MHz.

Demo:

https://github.com/user-attachments/assets/d9808876-3356-4eb3-b630-47ba5e32da68

FPGA edition running on the RealDigital Blackboard. Switches `sw[1:0]` select the blink rate, set by software through memory-mapped I/O

## Branches

| Branch | What it contains |
|---|---|
| `single-cycle-edition` | My CPU that works in simulation: 8 modules + a self-checking testbench for each module + system level tests |
| [`fpga_edition`](../../tree/fpga_edition) | The same CPU plus memory-mapped I/O, top-level wrapper, clocking, and constraints for the RealDigital Blackboard |

## Features

- All RV32I instructions except ECALL and EBREAK
- Byte and halfword loads and stores (LB, LBU, LH, LHU, SB, SH)
- Separate instruction and data memories
- Self-checking testbench for every module
- The FPGA edition adds memory-mapped LED and switch I/O and runs on the RealDigital Blackboard. See [fpga_edition](../../tree/fpga_edition)

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

Requires Verilator version 5.x (I used 5.046)

```bash
cd src/
verilator --binary --trace -sv cpu.sv ../tb/test_cpu/test_cpu.sv
cp ../tb/test_cpu/simulation_imemory.hex ../tb/test_cpu/test_dmemory.hex obj_dir/
cd obj_dir
./Vcpu
```
Successful run will produce this output:

<img width="2854" height="1606" alt="image" src="https://github.com/user-attachments/assets/b1615d5d-9d6d-43ee-b2ee-aa24d368fcf5" />

## Limitations

- No ECALL/EBREAK
- Single-Cycle, so clock is limited by longest path
- Memory array only has 128 entries but is indexed with 30 bits (my program only touches in range RAM/Instruction memory)
- No CSRs, interrupts or exceptions

## Author 

Samuel Devotta, University of Southampton
