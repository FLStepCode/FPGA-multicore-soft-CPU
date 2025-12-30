FILES_RTL_PATH := $(CURDIR)/rtl/lists/files_rtl.lst

ICARUS_PATH := $(CURDIR)/build_system/icarus
TOPLEVEL ?= tb

SIM_PATH ?= $(TOPLEVEL)
SIM_PATH := $(ICARUS_PATH)/$(SIM_PATH)

VCD_FILE ?= $(TOPLEVEL).vcd
VCD_FILE := $(SIM_PATH)/$(VCD_FILE)

.PHONY: run clear wave

run:
	mkdir -p $(SIM_PATH); \

	for file in $$(cat $(FILES_RTL_PATH)); do \
		echo ../../../rtl/$$file >> $(SIM_PATH)/files_rtl.lst; \
	done; \
	cd $(SIM_PATH); \
	iverilog -g2012 -o simv -s $(TOPLEVEL) -c files_rtl.lst; \
	vvp simv

clean:
	rm -rf $(SIM_PATH)

wave:
	gtkwave $(VCD_FILE)