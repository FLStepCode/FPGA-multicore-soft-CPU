# AXI-NoC-with-PMUs-and-cosim
An open-source and free to use performance measuring framework of AXI-based interconnects using cosimulation principles. Contains a 4x4 mesh NoC, which connects with masters and slaves using AXI, RAM banks (AXI RAM) connected as slaves, programmable AXI-loaders (AXI LD) connected as masters and readable AXI perfoemance metric units (AXI PMU) cutting between AXI LD and interconnect.
All AXI LD and AXI PMU instances are controlled/read by UART overlord, which reads commands from a PC using UART and controls units accordingly.

![noc](https://github.com/FLStepCode/FPGA-multicore-soft-CPU/blob/main/doc/cosim.png?raw=true)

### Key features
* A 4x4 mesh NoC which uses an XY algorithm and cut-through routing, and has AXI-stream interfaces as connections;
* NoC routers connect to local nodes using an AXI-to-AXIS bridge, which turns a AXI stream interface into a full fledged AXI;
* Uses cosimulation principles to accelerate modelling and performance measurement (FPGA modelling is around 250,000x faster than conventional simulation in my case);
* Uses Questa/cocotb+Questa for simulation;
* Supports Quartus for FPGA synthesis;
* Offers a build system that can be used with a single `make` call with a possibility of more fine tuning;
* Runs on wsl using Ubuntu 22.04, probably runs on most Linux distributions as long as necessary software is installed.

## Repository contents
<pre>
Directiry                      Description

build_system                   Contains a build system allowing icarus/Questa simulation and Quartus compilation using `make`
├ icarus                       Icarus build system (doesn't work for a whole design since it uses a lot of unsupported SystemVerilog syntax)
├ quartus                      Questa build system (main simulation engine for this project)
└ questa                       Quartus build system (for generating FPGA programming files)
cctb                           Cocotb build system (only supports Questa for the purposes of this project)
├ build                        Contains everything for cocotb to work
│   ├ user_requirements.txt    List of other python modules to be installed (conventional requirements.txt style)
│   └ *everything else*        Things that make cocotb work in this project
└ *sim_run*                    Contains a particular simulation run associated with a .py module used for it
data                           Filler directiry for drawing performance graphs depending on the load
doc                            Documentation
python                         Cosimulation scripts (PC side)
├ perpetual_read.py            Perpetually reads UART input and outputs incoming data to the terminal
└ uart_write.py                Write UART data and is used to issue commands to the design on the FPGA
rtl
├ *everything else*            Synthesizable RTL and additional stuff (firmwares and hexes for soft cores, etc.)
├ lists                        Perpetually reads UART input and outputs incoming data to the terminal
│   ├ files_hex.lst            List of all hex files (paths relative to ./rtl/ directory)
│   ├ files_rtl.lst            List of all SystemVerilog files (paths relative to ./rtl/ directory)
│   └ modules_cctb.lst         List of all cocotb testbench python files (paths relative to ./rtl/ directory)
└ tb                           Pure HDL testbenches for Questa and python testbenches with HDL wrappers for cocotb
.gitignore                     .gitignore
README.md                      README.md
</pre>

## Necessary software
* OS - Linux, Windows (for use in WSL2, verified distro - Ubuntu 22.04);
* Intel® Quartus® Prime Lite (verified version - 17.1, [installation guide](https://cdrdv2-public.intel.com/666293/quartus_install-683472-666293.pdf));
* Questa*-FPGAs Standard Edition (verified version - 24.1);


## Credits
Special thanks to [Elgrush](https://github.com/Elgrush) for immense contributions to this project, starting from
helping me improve our NoC design and continuing with improving our project infrastructure, which started as a
humble build system by me and is now growing into a full fledged CI/CD for easy testing of our designs. This
repository is a moment frozen in time, to see our actuall current work refer to the
https://github.com/apoj-inc/AXI-NoC-with-built-in-PMUs
