# Project Phoenix - Standardized Simulation Engine

# ------------------------------------------------------------------------------
# 1. Project Configuration
# ------------------------------------------------------------------------------
DUT         ?= phx_bypass
TB          ?= $(DUT)_tb
LIB_DIR     ?= ../../lib
PHX_SRC_DIR ?= $(LIB_DIR)/phoenix/src
RTL_DIR     ?= ../../rtl
TB_DIR      ?= .

BIN         = $(TB).out
VCD         = $(DUT).vcd

# 2. Auto-Discovery Functions
# ------------------------------------------------------------------------------
# Function: process_f_files
# Logic: Look at a list of strings. If a string ends in .f, go inside it. 
# Otherwise, keep the filename as is.
process_f_files = $(foreach f,$1,$(if $(filter %.f,$f),$(call process_f_file,$f),$f))

# Function: process_f_file
# Logic: Read the .f file, add its directory as a prefix to everything inside,
# and then call process_f_files again to see if there are more nested .f files.
process_f_file = $(call process_f_files,$(addprefix $(dir $1),$(shell cat $1)))

# 4. Inputs and Output Names and Values
# ------------------------------------------------------------------------------
# RTL Source Discovery
ifneq ($(wildcard $(RTL_DIR)/$(DUT).f),)
    # Use the recursive file list if it exists
    SRC_LIST += $(call process_f_files, $(RTL_DIR)/$(DUT).f)
else
    # Fallback to the single .sv file
    SRC_LIST += $(RTL_DIR)/$(DUT).sv
endif

# Testbench Source Discovery
ifneq ($(wildcard $(TB_DIR)/$(TB).f),)
    # Use the recursive file list if it exists
    SRC_LIST += $(call process_f_files, $(TB_DIR)/$(TB).f)
else
    # Fallback to the single .sv file
    SRC_LIST += $(TB_DIR)/$(TB).sv
endif

# 4. Execution Rules
# ------------------------------------------------------------------------------
all: compile run

compile:
	iverilog -g2012 $(SRC_LIST) -o $(BIN)

run:
	vvp $(BIN)

waves:
	gtkwave $(VCD) &

clean:
	rm -f $(BIN) $(VCD)

.PHONY: all compile run waves clean

# 5. Help
# ------------------------------------------------------------------------------
help:
	@echo "Phoenix Makefile Commands:"
	@echo "  make         - Compiles and runs the simulation"
	@echo "  make compile - Just compiles the source"
	@echo "  make run     - Executes the compiled binary"
	@echo "  make waves   - Opens GTKWave with $(VCD)"
	@echo "  make clean   - Deletes $(BIN) and $(VCD)"
