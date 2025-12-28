# AXI-NoC-with-PMUs-and-cosim
An open-source and free to use performance measuring framework of AXI-based interconnects using cosimulation principles. Contains a 4x4 mesh NoC, which connects with masters and slaves using AXI, RAM banks (AXI RAM) connected as slaves, programmable AXI-loaders (AXI LD) connected as masters and readable AXI perfoemance metric units (AXI PMU) cutting between AXI LD and interconnect.
All AXI LD and AXI PMU instances are controlled/read by UART overlord, which reads commands from a PC using UART and controls units accordingly.

![noc](https://github.com/FLStepCode/FPGA-multicore-soft-CPU/blob/main/doc/cosim.png?raw=true)

### Key features
* A 4x4 mesh NoC which uses an XY algorithm, which have AXI-stream interfaces as connections;
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
