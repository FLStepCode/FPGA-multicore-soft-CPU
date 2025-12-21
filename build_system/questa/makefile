LIST_RTL := $(CURDIR)/rtl/lists/files_rtl.lst
LIST_HEX := $(CURDIR)/rtl/lists/files_hex.lst

QUESTA_PATH ?= $(CURDIR)/.cache/build_system/questa
TOPLEVEL ?= tb

SIM_PATH ?= $(QUESTA_PATH)/$(SIM_PATH)

VARS_TCL_PATH := $(SIM_PATH)/vars.tcl

run:
	mkdir -p $(SIM_PATH)
	
	@echo set LIST_RTL $(LIST_RTL) > $(VARS_TCL_PATH)
	@echo set LIST_HEX $(LIST_HEX) >> $(VARS_TCL_PATH)
	@echo set TOPLEVEL $(TOPLEVEL) >> $(VARS_TCL_PATH)
	@echo set SIM_PATH $(SIM_PATH) >> $(VARS_TCL_PATH)

	cd $(SIM_PATH)
	vsim -c -do ../questa_script.tcl

wave:
	vsim -view $(SIM_PATH)/vsim.wlf
