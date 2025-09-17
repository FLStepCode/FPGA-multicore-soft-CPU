SIM ?= questa
SIM_ARGS := -suppress 12110
TOPLEVEL_LANG ?= verilog

TOPLEVEL ?= axi_unwrap
MODULE ?= tb_axi
WAVES ?= 1

COCOTB_MAKEFILES := $(shell cocotb-config --makefiles)

run:
	mkdir -p sim_build
	python3 move_files.py
	make -f $(COCOTB_MAKEFILES)/Makefile.sim TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
	TOPLEVEL=$(TOPLEVEL) MODULE=$(MODULE) SIM=$(SIM) \
	SIM_ARGS="$(SIM_ARGS)" WAVES=$(WAVES) \
	VERILOG_SOURCES="$(cat sim_build/files_rtl.lst)"

# include cocotb's make rules to take care of the simulator setup
# include $(shell cocotb-config --makefiles)/Makefile.sim