# FPGA-multicore-soft-CPU
An open-source and free to use NoC description using SystemVerilog. Includes a 4x4 mesh NoC, an array of modified schoolRISCV cores connected to each of the routers and a shared memory, which is distributed across all of the routers in equally. The NoC provides a connection between each of the cores and the memory.

![noc](https://github.com/user-attachments/assets/aa34831d-684f-4f62-a5ef-b4c694798db7)

### Key features
* A router equipped with input buffers, arbiter and a routing algorithm with all of the connections being full duplex;
* Packet adapters that can mitigate a length mismatch between full data packets and transferrable data packets;
* Modified schoolRISC core that can work with data memory thus modelling CPU's behaviour to test the NoC;
* A controller that connects CPU to the NoC through converters;
* Written in SystemVerilog;
* ModelSim simulation capabilities out of the box;
* Everything ready to be programmed on a DE10-Standard board;
* Full documentation.

## Repository contents

### main
| Directiry | Description |
| --------- | ----------- |
| doc | |
| └ UserManual.pdf | user manual for this project |
| boards | HDL files and scripts for programming FPGA boards |
| ├ *board\_name* | a directory containing files for generating a Quartus project for a specific board |
| ├ toplevel.sv | a common toplevel module to be used in board-specific modules for hardware-on-loop |
| └ toplevel\_onboard.sv | a common toplevel module to be used in board-specific modules for self-contained |
| cores | HDL files for schoolRISCV soft core and supporting modules |
| ├ converters | HDL files for converters between memory controller (MC) packets and NoC packets |
| <p>├ packet\_collector.sv</p> | converter from NoC to MC |
| <p>└ splitter.sv</p> | converter from MC to NoC |
| └ src | HDL files for the schoolRISCV soft core |
| <p>├ cpu\_with\_ram.sv</p> | module that connects CPU and RAM to the MC |
| <p>├ ram.sv</p> | a two-port RAM |
| <p>├ sm\_register.v</p> | a DFF for an instruction counter |
| <p>├ sm\_rom.v</p> | preloaded instructions |
| <p>├ sr\_cpu.v</p> | a CPU module with a counter, decoder, register file, ALU, AGU and a control unit |
| <p>├ sr\_cpu.vh</p> | `define macros for RISCV opcodes and ALU/AGU oper codes |
| <p>├ sr\_mem\_ctrl.sv</p> | a memory controller (MC) connecting CPU to RAM through the NoC |
| <p>└ sr\_mem\_ctrl.svh</p> | `define macros for MC instructions |
| cpu | HDL files for the 16-core CPU on a NoC |
| ├ noc\_with\_cores.sv | connects 16 CPU cores to the mesh 4x4 NoC |
| └ uart.sv | hooks up the 16-core CPU to the UART to monitor RAM data at a given address |
| mesh\_4x4 | HDL files for the 4x4 mesh NoC |
| ├ inc | `define macros for NoC configuration |
| <p>├ noc.svh</p> | macros for general NoC parameters |
| <p>├ noc\_XY.svh</p> | macros for topology-specific (mesh) parameters |
| <p>├ queue.svh</p> | macros for queue parameters |
| <p>└ router.svh</p> | macros for router parameters |
| ├ noc | |
| <p>└ noc.sv</p> | module that connects 16 routers into a NoC |
| └ src | HDL files for router components |
| <p>├ algorithm.sv</p> | an XY algorithm for packet switching |
| <p>├ arbiter.sv</p> | a module that chooses a packet to be switched |
| <p>├ queue.sv</p> | FIFOs for collecting incoming packets |
| <p>└ router.sv</p> | a module that creates a router from its components |
| modelsim | |
| ├ ram\_image\_0..5.hex | RAM images that contain a picture |
| ├ instr\_node\_0..15.hex | RAM images that contain RISCV codes for each core|
| ├ modelsim\_run.bat | a batch file that launches ModelSim using modelsim\_script.tcl script |
| └ modelsim\_script.tcl | a script, according to which the simulation is ran |
| tb | HDL files for testbenches |
| └ tb.sv | a testbench files that tests the CPU, dumping RAM contents at the end |

### network-with-generators
// coming soon

## Necessary software
* Quartus Prime Lite (only verified version - 17.1)
* Modelsim - Intel FPGA Starter Edition 10.5b (came bundled with Quartus)

Make sure that the folder containing Quartus executables and ModelSim executable are in PATH 

### Simulation quick start guide
Run ```modelsim_run.bat``` from the ```modelsim``` repository to launch ModelSim and run the simulation. The process generates multiple new files: ```latency_log_*.csv``` and ```output_image_chunk_*.hex```, that contain ```lw``` and ```sw``` latencies in clock cycles for each of the cores and the RAM contents of each of the RAM chunks, that contain the resulting image, respectively. For more details refer to the ```UserManual.pdf```.

### Programming quick start guide
Run the following cmd command from the ```boards/DE10-Standard``` directory:
```
quartus_sh -t quartus_onboard.tcl
```
This creates a Quartus project, that can be then opened so you can program the board from there using Device Programmer. For more details refer to the ```UserManual.pdf```.

## Credits
Special thanks to Grushevskiy Nikita Ivanovich for taking a huge part in developing different router componoetnts
and different topologies of the NoC connection subsystem. *github handle*

Special thanks to Nigmatullin Nikolay Rafaelevich for developing componentry that is being used for
"core substitutes". *github handle*
