# AXI-NoC-with-PMUs-and-cosim
An open-source and free to use performance measuring framework of AXI-based interconnects using cosimulation principles. Contains a 4x4 mesh NoC, which connects with masters and slaves using AXI, RAM banks (AXI RAM) connected as slaves, programmable AXI-loaders (AXI LD) connected as masters and readable AXI perfoemance metric units (AXI PMU) cutting between AXI LD and interconnect.
All AXI LD and AXI PMU instances are controlled/read by UART overlord, which reads commands from a PC using UART and controls units accordingly.

![noc](./doc/cosim.png)

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

## Using the build system

/* coming soon */

## HDL design insights

### NoC
The performance measuring system is tailored for usage in AXI interconnects. A 4x4 mesh NoC with cut-through
routing is used as an example of such interconnect. The NoC itself works using an AXI-stream protocol for
continuous data streaming between routers, but each of the routers is connected to a bidirectional AXI to
AXI-stream bridge, so IP cores can connect to the network using a full-fledged AXI interface.

![noc](./doc/noc.png)

### AXI LD
Each of the slave ports of the NoC is connected to an AXI-LD instance, which receives commands, collects them
in a FIFO and upon receiving a start signal through a special port AXI-LD begins to create AXI transactions.
Depending on the value on a `req depth` port the unit initiates N AXI transactions before waiting for B-responses.
AXI-LD allows setting AxID and AxLEN of the transaction and whether it is a read/write transactions.

![noc](./doc/axi_ld.png)

### AXI PMU
AXI PMU consists of a single AXI port in monitor mode (all of the signals are inputs). AXI signals are monitored
by an event decoder, which looks for certain combinations of signals, and depending on them increments certain
counters (shoutout to [ZipCPU](https://zipcpu.com/blog/2021/08/14/axiperf.html)). Each of the counters is assigned
to a certain event such as awvalid-stall, b-handshake, bvalid-stall and others (non-programmable). Also this module
has an `address` input and a `value` output, which allows reading values of different counters depending on the
chosen `address`. All of the AXI PMU instances are connected between AXI LD - NoC connections.

![noc](./doc/axi_pmu.png)

### UART overlord
The UART overlord is connected straight to the `tx` and `rx` UART signals. This module has receiver and transmitter
FSMs embedded in it, which converts bitstreams into 8-bit words and transmits/receives those words by a handshake
mechanism. Certain words are interpreted as commands, which allows for programming AXI LD instances or reading
counter values from AXI PMU instances.
![noc](./doc/uart_overlord.png)

## Credits
Special thanks to [Elgrush](https://github.com/Elgrush) for immense contributions to this project, starting from
helping me improve our NoC design and continuing with improving our project infrastructure, which started as a
humble build system by me and is now growing into a full fledged CI/CD for easy testing of our designs. This
repository is a moment frozen in time, to see our actuall current work refer to the
https://github.com/apoj-inc/AXI-NoC-with-built-in-PMUs
