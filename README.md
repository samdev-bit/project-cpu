# project-cpu (fpga_edition)

A single-cycle RV32I CPU in SystemVerilog, extended with memory-mapped I/O and running at 25 MHz on the RealDigital Blackboard (Zynq-7000 XC7Z007S).

All modules, including the new MMIO and peripheral modules, pass self-checking testbenches. LED writes, switch input and the switch-controlled blink rate are verified on hardware. LED read-back is verified in simulation only.

## Demos

| fixed blink, switch-to-LED loop, reset restarting the program | Switch-controlled delay demo |
|---|---|
| https://github.com/user-attachments/assets/1548b4cf-4b66-4f95-8433-e3351aa90bea | https://github.com/user-attachments/assets/911c5825-81b6-4557-9a39-33fd46442494 |

Demo 1: “Fixed blink, switch-to-LED loop, and BTN0 restarting the program.”

Demo 2: “`sw[1:0]` sets the blink rate (0.125 s to 1 s) through memory-mapped I/O.”

## Differences from single-cycle-edition

- `mmio.sv` module : used to decode addresses, has its own testbench
- `peripherals.sv` : LED register and switch read path, has its own testbench
- `top.sv` : top level wrapper (includes clock wizard and two flop synchronizers for switches and reset)
  
## Hardware and tools

- Board: RealDigital Blackboard (Zynq-7000 XC7Z007S). Only the PL fabric is used, the ARM cores are not.
- Vivado v2025.1 (64-bit)
- Clock: 100 MHz board oscillator (pin H16).

## Architecture additions
<img width="841" height="893" alt="fpga_edition_diagram" src="https://github.com/user-attachments/assets/816ad145-d499-460b-ba29-2dc274aa53d1" />

BE_decoder output goes to both RAM and Peripherals so sb and sh can also work on the I/O (switches and LEDs).

## Memory map

| Address | Device | Access |
|---|---|---|
| 0x0000_0000 | Data Memory (128 words) | Read/Write |
| 0x1000_0000 | LED register (10 bits) | Read/Write |
| 0x1000_0004 | Switches (10 bits synchronized) | Read |

Unmapped stores are ignored

## Clocking and reset

- 100 MHz in, Clocking Wizard to 25 MHz, locked holds the CPU in reset until the clock is stable.
- Two-flop synchronizers for the reset button and the switches to avoid metastability from asynchronous inputs.
- Power-on reset: synchronizer flops initialise to 1 so CPU boots in reset.

## Timing and resources

- WNS +12.433 ns, WHS +0.122 ns at 25 MHz
- WNS -10.1 ns at 100 MHz (single cycle was too slow for clock speed).
- 3215 LUTs and 4843 FFs

(All stats based on build done with demo2_imemory.hex and post implementation)

## How to set-up clocking wizard

1. Open IP Catalog (Flow Navigator, under Project Manager).
2. Search for Clocking Wizard and double-click it.
3. Set the component name to clk_wiz_0 (it must match the instance in top.sv).
4. Clocking Options tab: primary input frequency 100 MHz.
5. Output Clocks tab: enable clk_out1 and set it to 25 MHz.
6. Untick reset and power_down, and keep locked.
7. Click OK, then Generate.

## Build steps

1. Create a Vivado project for the Blackboard part.
2. Add the sources, XDC and Clocking Wizard IP.
3. Put the chosen hex file in your src folder (where all your modules are) where $readmemh finds it (also remember to change the name of the file read by instruction memory in the `cpu.sv` module to the file you picked).
4. Synthesise, implement, generate bitstream.
5. Program via Hardware Manager.
6. Press BTN0 to restart the program.

After changing a hex file, Reset Runs on synthesis, or the old program gets programmed.

## Simulation 

Run the same way as in [`single-cycle-edition`](../../tree/single-cycle-edition)

## Limitations

- No ECALL/EBREAK, CSRs, interrupts.
- Single-cycle, limited to 50 MHz by the critical path.
- `memory.sv` indexes with address[31:2], so out-of-range accesses return x in simulation but alias on hardware. Demo programs stay in range.
- Hardware demos only use LEDs and switches (no buttons beyond reset, no UART).
- Switches are sampled once per phase in demo 2, so changes take effect after the current phase.


## Key Takeaways moving from simulation to hardware
- A single-cycle design’s longest path limits the clock on hardware (100 MHz failed, 25 MHz passed).
- Declare signals before they are used. Verilator accepted `cpu.sv` with signals used ahead of their declarations, but Vivado required them at the top of the file
- Asynchronous inputs need two-flop synchronizers. Simulation changes inputs cleanly on clock edges, but on hardware they can change at any moment and cause metastability.
- Inferred latches (from missing defaults in always_comb) pass simulation but are flagged by synthesis. Always assign defaults.

## Author

Samuel Devotta, University of Southampton
