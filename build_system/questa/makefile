FILES_RTL_PATH := $(CURDIR)/rtl/lists/files_rtl.lst
FILES_HEX_PATH := $(CURDIR)/rtl/lists/files_hex.lst

QUESTA_PATH := $(CURDIR)/build_system/questa
TOPLEVEL ?= tb

SIM_PATH ?= $(TOPLEVEL)
SIM_PATH := $(QUESTA_PATH)/$(SIM_PATH)

VARS_TCL_PATH := $(SIM_PATH)/vars.tcl

run:
	mkdir -p $(SIM_PATH); \
	
	@echo set FILES_RTL_PATH $(FILES_RTL_PATH) > $(VARS_TCL_PATH)
	@echo set FILES_HEX_PATH $(FILES_HEX_PATH) >> $(VARS_TCL_PATH)
	@echo set TOPLEVEL $(TOPLEVEL) >> $(VARS_TCL_PATH)
	@echo set SIM_PATH $(SIM_PATH) >> $(VARS_TCL_PATH)

	cd $(SIM_PATH); \
	vsim -c -do ../questa_script.tcl

clean:
	rm -rf $(SIM_PATH)

wave:
	cd $(SIM_PATH); \
	vsim -view vsim.wlf