FILES_RTL_PATH := $(CURDIR)/rtl/lists/files_rtl.lst

ICARUS_PATH := $(CURDIR)/build_system/icarus
TOPLEVEL ?= tb

SIM_PATH ?= $(TOPLEVEL)
SIM_PATH := $(ICARUS_PATH)/$(SIM_PATH)

VCD_PATH ?= $(SIM_PATH)/$(TOPLEVEL).vcd

run:
	rm -rf $(SIM_PATH); \
	mkdir $(SIM_PATH); \
	for file in $$(cat $(FILES_RTL_PATH)); do \
		echo ../../../rtl/$$file >> $(SIM_PATH)/files_rtl.lst; \
	done; \
	cd $(SIM_PATH); \
	iverilog -g2012 -o simv -s $(TOPLEVEL) -c files_rtl.lst; \
	vvp simv

wave:
	gtkwave $(VCD_PATH)