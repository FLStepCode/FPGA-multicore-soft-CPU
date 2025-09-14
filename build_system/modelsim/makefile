FILES_RTL_PATH := $(CURDIR)/rtl/lists/files_rtl.lst
FILES_HEX_PATH := $(CURDIR)/rtl/lists/files_hex.lst
VARS_TCL_PATH := $(CURDIR)/build_system/modelsim/vars.tcl
MODELSIM_PATH := $(CURDIR)/build_system/modelsim
TOPLEVEL ?= tb
SIM_PATH ?= $(TOPLEVEL)

SIM_PATH := $(MODELSIM_PATH)/$(SIM_PATH)
WLF_PATH := $(SIM_PATH)/vsim.wlf

run:
	@echo set FILES_RTL_PATH $(FILES_RTL_PATH) > $(VARS_TCL_PATH)
	@echo set FILES_HEX_PATH $(FILES_HEX_PATH) >> $(VARS_TCL_PATH)
	@echo set TOPLEVEL $(TOPLEVEL) >> $(VARS_TCL_PATH)
	@echo set SIM_PATH $(SIM_PATH) >> $(VARS_TCL_PATH)

	cd $(MODELSIM_PATH) && \
	vsim -c -do modelsim_script.tcl

wave:
	vsim -view $(WLF_PATH)