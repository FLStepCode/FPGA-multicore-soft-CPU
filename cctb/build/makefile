SHELL := /bin/bash

TOPLEVEL_LANG ?= verilog

TOPLEVEL ?= axi_unwrap

MODULE ?= tb_axi

SIM ?= questa
SIM_ARGS := -suppress 12110 -autofindloop
SIM_BUILD ?= $(MODULE)

WAVES ?= 1

.PHONY: run clean_run clean_all_runs clean_all clean_venv

run: cctb/build/venv/bin/activate
	source cctb/build/venv/bin/activate; \
	mkdir -p cctb/$(SIM_BUILD); \
	cd cctb/$(SIM_BUILD); \
	python3 ../build/move_files.py; \
	export VERILOG_SOURCES=$$(cat files_rtl.lst); \
	export COCOTB_MAKEFILES=$$(cocotb-config --makefiles); \
	make -f $${COCOTB_MAKEFILES}/Makefile.sim TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
	TOPLEVEL=$(TOPLEVEL) MODULE=$(MODULE) SIM=$(SIM) SIM_BUILD=$(SIM_BUILD) \
	SIM_ARGS="$(SIM_ARGS)" WAVES=$(WAVES) \
	VERILOG_SOURCES="$${VERILOG_SOURCES}"; \
	rm -rf $(MODULE).py

wave:
	cd cctb/$(SIM_BUILD); \
	vsim -view vsim.wlf

cctb/build/venv/bin/activate: cctb/build/user_requirements.txt cctb/build/requirements.txt
	python3 -m venv cctb/build/venv; \
	source cctb/build/venv/bin/activate; \
	pip install -r cctb/build/requirements.txt; \
	pip install -r cctb/build/user_requirements.txt; \

clean_run:
	cd cctb; \
	rm -rf $(SIM_BUILD)

clean_all_runs:
	cd cctb; \
	for dir in ./*; do \
		if [[ "$$dir" != "./build" ]]; then \
			rm -rf $$dir; \
		fi \
	done

clean_venv:
	cd cctb/build; \
	rm -rf venv

clean_all: clean_all_runs clean_venv


# include cocotb's make rules to take care of the simulator setup
# include $(shell cocotb-config --makefiles)/Makefile.sim