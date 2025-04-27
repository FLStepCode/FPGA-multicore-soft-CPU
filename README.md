# FPGA-multicore-soft-CPU
A SystemVerilog description of a 9-core soft processor with shared cache using schoolRISCV cores connected to a
3x3 mesh NoC.

# NoC architecture
THe platform that this CPU is planned to be built on is a 3x3 mesh NoC, where each of the routers are switching
packets between each other. Details can be seen in ./doc/NoC.pdf (coming soon).

# Branches

## main
This is the main branch of this project, which will contain an HDL description a 9-core soft CPU with a shared RAM.
Shared RAM will consist of chunks "assigned" to each of the cores and connected to its own memory controller.
These controllers are the point of contact of each RAM chunk to the NoC connection subsystem. Details can be
seen in ./doc/CPU.pdf (coming soon).

## network-with-generators
This is a secondary branch of this project, which contains an HDL description of the NoC connection subsystem
itself at ./mesh_3x3 and the "core substitute" at ./generators. A complete description contains a single 3x3 mesh
with 3 "core substitutes", one for each router on the main diagonal. Core substitute consists of 2 modules
for generating pseudo-random 32-bit data packet and splitting it up into transferrable data flits and
1 module for receiving data flits and assembling back them into valid 32-bit packets.

Along with the SystemVerilog code there are tcl-scripts for simulation in ModelSim 
(./modelsim/modelsim_script.tcl) and compilation in Quartus Prime Lite 17.1 for a DE10-Lite board
(./board/de10lite/quartus_project.tcl). These scripts have been tested for Quartus Prime Lite 17.1 and for a
ModelSim version, that comes bundled with it, and there is no guarantee that they will work for any other
configuration.

As long as you have ...\intelFPGA_lite\17.1\quartus\bin64 and ...\intelFPGA_lite\17.1\modelsim_ase\win32aloem in
PATH, the usage for the scripts should be:
```
vsim -do .\modelsim_script.tcl          # Launches a ModelSim GUI with relevant signals in the wave window
```
```
quartus_sh -t .\quartus_project.tcl     # compiles a quartus project fully in CLI
```

The testbench used for the simulation is located at ./tb/tb.sv.

After Quartus finished compiling the project, you should be able to program DE10-Lite. Read
./doc/NoC_with_generators.pdf to learn how to monitor this design on your board using switches and seven segment
displays (coming soon).

# Credits
Special thanks to Grushevskiy Nikita Ivanovich for taking a huge part in developing different router componoetnts
and different topologies of the NoC connection subsystem. *github handle*

Special thanks to Nigmatullin Nikolay Rafaelevich for developing componentry that is being used for
"core substitutes". *github handle*
