#------------------------------------------------------------------------------
# Makefile - UVM Testbench for axi_crossbar
#------------------------------------------------------------------------------

# 获取testbench根目录（sim的上一级目录）
TB_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

export FSDB_SVA_SUCCESS=1

# DUT configuration
DUT_NAME      := axi_crossbar
DUT_TOP       := AXI_CROSSBAR
TEST_CASE     := axi_crossbar_test_sanity

# Directories
SIM_DIR       := ${TB_ROOT}/sim
TB_DIR        := ${TB_ROOT}/tb/src
FL_DIR        := ${TB_ROOT}/tb/fl

# TB include paths
TB_INC += -incdir ${TB_ROOT}/common_ifs
TB_INC += -incdir ${TB_ROOT}/tb/src
TB_INC += -incdir ${TB_ROOT}/uvm/dv_utils
TB_INC += -incdir ${TB_ROOT}/uvm/env/src
TB_INC += -incdir ${TB_ROOT}/uvm/tests/src
TB_INC += -incdir ${TB_ROOT}/uvm/sequences/src
TB_INC += -incdir ${TB_ROOT}/uvm/sequences/src/virtual_sequence
TB_INC += -incdir ${TB_ROOT}/uvm/sequences/src/sequence
TB_INC += -incdir ${TB_ROOT}/uvm/regs_model/src

# TB source files - dv_utils (from OpenTitan)
TB_SRC += ${TB_ROOT}/uvm/dv_utils/dv_test_status_pkg.sv
TB_SRC += ${TB_ROOT}/uvm/dv_utils/dv_utils_pkg.sv

# TB source files - top (common_ifs, regs_model, env_pkg, test_pkg are included via tb_top_define.sv)
TB_SRC += ${TB_ROOT}/tb/src/cpu_wrapper_stub.sv
TB_SRC += ${TB_ROOT}/tb/src/tb_top_define.sv
TB_SRC += ${TB_ROOT}/tb/src/tb_top.sv


# Cadence VIP environment variables (if not set in .bashrc)
CDN_VIP_ROOT := /opt/eda/cadence/vip/vipcat_11.30.068
DENALI := ${CDN_VIP_ROOT}/tools.lnx86/denali_64bit
CDS_INST_DIR := /opt/eda/cadence/XCELUMMAIN2309
CDN_VIP_LIB_PATH := /home/eda/vip/cdn_axi/vip_lib_xmsim64

# Local compiled AXI VIP library directory (generated and verified in this workspace)
VIP_LIB_BASE := ${CDN_VIP_LIB_PATH}


# VIP include paths
VIP_INC += -incdir ${DENALI}/ddvapi/sv/uvm/cdn_axi
VIP_INC += -incdir ${DENALI}/ddvapi/sv
VIP_INC += -incdir ${DENALI}/ddvapi/sv/uvm
VIP_DEF += -define DENALI_SV_NC -define DENALI_UVM



# VIP source files
VIP_SRC += ${DENALI}/ddvapi/sv/denaliMem.sv
VIP_SRC += ${DENALI}/ddvapi/sv/uvm/../denaliCdn_axi.sv
VIP_SRC += ${DENALI}/ddvapi/sv/uvm/cdn_axi/cdnAxiUvmTop.sv
VIP_SRC += ${DENALI}/ddvapi/sv/uvm/../hdl_interfaces/cdn_axi/cb_interfaces/cdnAxi4Interface.sv


# DUT include paths (add paths where DUT source files are located)
# Extract include dir from rtl_path
DUT_INC += -incdir $(dir /home/eda/vip/cdn_axi/verilog-axi/rtl/axi_crossbar.v)


# File lists
DUT_FILE_LIST     := -f ${TB_ROOT}/tb/fl/dut.f
ANA_MODEL_FILE_LIST := -f ${TB_ROOT}/tb/fl/ana_model.f
TB_MODEL_FILE_LIST  := -f ${TB_ROOT}/tb/fl/tb_model.f

#------------------------------------------------------------------------------
# Compile Options
#------------------------------------------------------------------------------
ifdef TC
TEST_CASE = ${TC}
endif

ifdef CPU_WRAPPER_SKEL
DUT_DEF += -define CPU_WRAPPER_SKEL
DUT_DEF += -define USE_CPU_WRAPPER_STUB
endif

ifdef ID
RUN_DIR = $(addsuffix _${ID},${TEST_CASE})
else
RUN_DIR = ${TEST_CASE}
endif

ifdef SEED
SIMV_OPTIONS += -svseed ${SEED}
else
SIMV_OPTIONS += -svseed random
endif

ifdef COV_EN
COV_COMM_OPTIONS += -covdut ${DUT_TOP} -covfile ${SIM_DIR}/cov_cfg.ccf
COV_SIMV_OPTIONS += -covoverwrite -covfirstbinmatch
endif

# UVM options
SV_UVM_OPTIONS += -uvm

ifdef VERBOSITY
SIMV_OPTIONS += +UVM_VERBOSITY=${VERBOSITY}
else
SIMV_OPTIONS += +UVM_VERBOSITY=UVM_LOW
endif

SIMV_OPTIONS += +uvm_set_severity=*,UVM/RSRC/NOREGEX,UVM_WARNING,UVM_INFO
SIMV_OPTIONS += +UVM_MAX_QUIT_COUNT=10

SIMV_OPTIONS += -nbasync -randwarn +UVM_VERDI_TRACE="UVM_AWARE+RAL+HIER+COMPWAVE" +UVM_TR_RECORD
SIMV_OPTIONS += -licqueue -errormax 10 -warn_multiple_driver

ifdef START_DUMP
SIMV_OPTIONS += +START_TIME=${START_DUMP}
endif

ifdef END_DUMP
SIMV_OPTIONS += +END_TIME=${END_DUMP}
endif

ifdef GUI
SIMV_OPTIONS += -gui
endif

ifndef NO_TIMEOUT
NO_TIMEOUT_OPT := +NO_TIMEOUT
endif

ifdef TIMEOUT
SIMV_OPTIONS += +UVM_TIMEOUT=${TIMEOUT},NO
NO_TIMEOUT_OPT := +NO_TIMEOUT
endif

# Compiler options
COMP_OPTIONS += -sysv_ext .v,.sv,.svp,.vh,.svh -libext .v,.vh -64bit -v200x -sysv -nocsf
COMP_OPTIONS += -access +rw
COMP_OPTIONS += -define UVM_REG_DATA_WIDTH=1024
COMP_OPTIONS += +fsdb+glitch=0
# Default timescale for RTL modules without timescale directive
COMP_OPTIONS += -timescale 1ns/1ps


# VIP shared libraries (reference: cdn_vip_run_ncsim_sv_uvm_64.sh)
# For xrun, use -sv_lib for both libraries (xrun doesn't support -runmode -loadrun like ncsim)
# Note: libcdnvipcuvm.so contains denaliMemGetErrorStringInfo and depends on libsn_uvc.so
# Load VIP libraries for compilation (elaboration phase)
COMP_OPTIONS += -loadpli1 ${CDS_INST_DIR}/tools/methodology/UVM/CDNS-1.1d/sv/lib/64bit/libuvmpli.so:uvm_pli_boot:export
COMP_OPTIONS += -loadvpi ${DENALI}/verilog/libcdnsv.so:cdnsvVIP:export
COMP_OPTIONS += -sv_lib ${DENALI}/verilog/libcdnsv.so

# Load VIP libraries for simulation (runtime phase)
# Note: libcdnvipcuvm.so contains denaliMemGetErrorStringInfo and depends on libsn_uvc.so
# Load order matters: dependency library (libsn_uvc.so) should be loaded first
SIMV_OPTIONS += -sv_lib ${VIP_LIB_BASE}/64bit/libsn_uvc.so
SIMV_OPTIONS += -sv_lib ${VIP_LIB_BASE}/64bit/libcdnvipuvmdpi.so
SIMV_OPTIONS += -sv_lib ${VIP_LIB_BASE}/64bit/libsn_uvc.so 
SIMV_OPTIONS += -sv_lib ${VIP_LIB_BASE}/64bit/libcdnvipcuvm.so

# Set LD_LIBRARY_PATH for runtime
VIP_LIB_PATH := ${VIP_LIB_BASE}/64bit:${DENALI}/verilog
 

ifdef UDBG
COMP_OPTIONS += -uvmlinedebug -classlinedebug
endif

ifdef LDBG
COMP_OPTIONS += -linedebug
endif

ifdef CDN_VIP
COMP_OPTIONS += -cdn_vip_svlib -cdn_viplib -cds_vip_noauto
endif

# File options
RTL_FILE_OPTIONS  := ${DUT_DEF} ${DUT_INC} ${DUT_SRC} ${DUT_FILE_LIST} ${ANA_MODEL_FILE_LIST}
TB_FILE_OPTIONS   := ${VIP_INC} ${VIP_DEF} ${TB_INC} ${VIP_SRC} ${TB_SRC} ${TB_MODEL_FILE_LIST}
FILE_OPTIONS      := ${RTL_FILE_OPTIONS} ${TB_FILE_OPTIONS}

#------------------------------------------------------------------------------
# Run directory management
#------------------------------------------------------------------------------
ifeq (${RUN_DIR},$(wildcard ${RUN_DIR}))
MK_DIR := rm -rf ${RUN_DIR}/*
else
MK_DIR := mkdir -p ${RUN_DIR}
endif

mk_dir:
	${MK_DIR}
	@echo "Created run directory: ${RUN_DIR}"

#------------------------------------------------------------------------------
# Compilation targets
#------------------------------------------------------------------------------
.PHONY: tb_elab rtl_elab comp_elab comp_pp clean help

# Compile testbench only (no DUT)
tb_elab: clean
	xrun -c ${COMP_OPTIONS} -define ONLY_COMP_TB \
		${TB_FILE_OPTIONS} ${SV_UVM_OPTIONS} ${COV_COMM_OPTIONS} \
		-disable_sem2009 -top tb_top -l xrun_tb_comp.log

# Compile DUT only
rtl_elab:
	xrun -c ${COMP_OPTIONS} ${RTL_FILE_OPTIONS} ${COV_COMM_OPTIONS} -top ${DUT_TOP} -l xrun_rtl_comp.log

# Compile everything (normal mode)

# First compile VIP packages, then compile testbench
comp_elab: clean
	@echo "Compiling VIP packages first..."
	xrun -c ${COMP_OPTIONS} ${VIP_INC} ${VIP_DEF} ${VIP_SRC} ${SV_UVM_OPTIONS} ${COV_COMM_OPTIONS} \
		-disable_sem2009 -l xrun_vip_comp.log
	@echo "Compiling testbench..."
	xrun -elaborate ${COMP_OPTIONS} ${FILE_OPTIONS} ${SV_UVM_OPTIONS} ${COV_COMM_OPTIONS} \
		-top tb_top -l xrun_comp.log


#------------------------------------------------------------------------------
# Verisium Debug Modes (from Verisium UG)
#------------------------------------------------------------------------------
# Mode 1: verisium_pp (Post-Processing)
#   - Run simulation first, record data to IDA database
#   - Open Verisium offline after simulation to analyze
#   - Includes: -source_debug, -lwdgen, -persistent_sources_debug, +sdiHdlDisable
#
# Mode 2: verisium_interactive (Interactive Debug)
#   - Launch simulator + Verisium GUI together
#   - Set breakpoints, single-step, inspect variables in real-time
#   - Includes: -source_debug, -lwdgen, -classlinedebug, -enable_tpe, -gui -verisium
#------------------------------------------------------------------------------

# Post-Processing debug options
PP_DEBUG_OPTIONS := -debug_opts verisium_pp

# Interactive debug options
INTERACTIVE_DEBUG_OPTIONS := -debug_opts verisium_interactive

#------------------------------------------------------------------------------
# Post-Processing Mode (comp_pp / run_pp)
#------------------------------------------------------------------------------
# Compile with post-processing debug support
# Usage: make comp_pp
comp_pp: clean
	@echo "=============================================="
	@echo " Compiling with Verisium Post-Processing Mode"
	@echo " (-debug_opts verisium_pp)"
	@echo "=============================================="

	@echo "Compiling VIP packages first..."
	xrun -c ${COMP_OPTIONS} ${VIP_INC} ${VIP_DEF} ${VIP_SRC} ${SV_UVM_OPTIONS} ${COV_COMM_OPTIONS} \
		-disable_sem2009 -l xrun_vip_comp.log
	@echo "Compiling testbench..."
	xrun -elaborate ${COMP_OPTIONS} ${PP_DEBUG_OPTIONS} \
		${FILE_OPTIONS} ${SV_UVM_OPTIONS} ${COV_COMM_OPTIONS} \
		-top tb_top -l xrun_comp_pp.log

	@echo ""
	@echo "Done. Use 'make run_pp TC=xxx' to run simulation."
	@echo "After simulation, use 'make vsm TC=xxx' to analyze."

#------------------------------------------------------------------------------
# Interactive Debug Mode (comp_dbg / run_dbg)
#------------------------------------------------------------------------------
# Compile with interactive debug support
# Usage: make comp_dbg
comp_dbg: clean
	@echo "=============================================="
	@echo " Compiling with Verisium Interactive Mode"
	@echo " (-debug_opts verisium_interactive)"
	@echo "=============================================="

	@echo "Compiling VIP packages first..."
	xrun -c ${COMP_OPTIONS} ${VIP_INC} ${VIP_DEF} ${VIP_SRC} ${SV_UVM_OPTIONS} ${COV_COMM_OPTIONS} \
		-disable_sem2009 -l xrun_vip_comp.log
	@echo "Compiling testbench..."
	xrun -elaborate ${COMP_OPTIONS} ${INTERACTIVE_DEBUG_OPTIONS} \
		${FILE_OPTIONS} ${SV_UVM_OPTIONS} ${COV_COMM_OPTIONS} \
		-top tb_top -l xrun_comp_dbg.log

	@echo ""
	@echo "Done. Use 'make run_dbg TC=xxx' to start interactive debug."

#------------------------------------------------------------------------------
# Simulation targets
#------------------------------------------------------------------------------
.PHONY: run sim sim_and_check

# IDA waveform output directory
IDA_DIR := ${SIM_DIR}/ida

# Waveform dump control (default: enabled with IDA format)
# Usage: make run TC=xxx [NO_WAVE=1] [WAVE_FORMAT=ida|shm|vcd]
ifndef NO_WAVE
WAVE_FORMAT ?= ida
WAVE_TCL_CMD = -input ${SIM_DIR}/dump_wave.tcl
export TEST_NAME := ${TEST_CASE}
export WAVE_FORMAT
export IDA_DIR
else
WAVE_TCL_CMD =
endif

run: mk_dir
	cd ${RUN_DIR} && ln -sf ../xcelium.d . 2>/dev/null || true

	cd ${RUN_DIR} && LD_LIBRARY_PATH=${VIP_LIB_PATH}:${LD_LIBRARY_PATH} xrun -R +UVM_TESTNAME=${TEST_CASE} ${NO_TIMEOUT_OPT} \
		${SIMV_OPTIONS} ${COV_SIMV_OPTIONS} ${WAVE_TCL_CMD} -l run.log


sim: comp_elab run

sim_and_check: sim
	@grep -c "UVM_FATAL\|UVM_ERROR" ${RUN_DIR}/run.log && exit 1 || echo "Test PASSED"

#------------------------------------------------------------------------------
# Post-Processing Debug Run (run_pp)
#------------------------------------------------------------------------------
# Run with debug recording for post-processing analysis
# Usage: make run_pp TC=xxx [DEBUG_LEVEL=wave|full]
#   DEBUG_LEVEL=wave : Record waveforms only (default, smaller database)
#   DEBUG_LEVEL=full : Record waveforms + SV flow + log (larger database, more debug info)
DEBUG_LEVEL ?= wave
export DEBUG_LEVEL

run_pp: mk_dir
	cd ${RUN_DIR} && ln -sf ../xcelium.d . 2>/dev/null || true
	@echo "=============================================="
	@echo " Running with Post-Processing Debug"
	@echo " Test:        ${TEST_CASE}"
	@echo " Debug Level: ${DEBUG_LEVEL}"
	@echo " IDA Output:  ${IDA_DIR}/${TEST_CASE}.ida"
	@echo "=============================================="

	cd ${RUN_DIR} && LD_LIBRARY_PATH=${VIP_LIB_PATH}:${LD_LIBRARY_PATH} xrun -R +UVM_TESTNAME=${TEST_CASE} ${NO_TIMEOUT_OPT} \
		${SIMV_OPTIONS} ${COV_SIMV_OPTIONS} \
		-input ${SIM_DIR}/dump_wave.tcl -l run.log

	@echo ""
	@echo "=============================================="
	@echo " Post-Processing Debug Complete"
	@echo " To analyze: make vsm TC=${TEST_CASE}"
	@echo "=============================================="

# Full post-processing debug flow: compile + run
sim_pp: comp_pp run_pp

#------------------------------------------------------------------------------
# Interactive Debug Run (run_dbg)
#------------------------------------------------------------------------------
# Run with Verisium interactive debugger
# Usage: make run_dbg TC=xxx
# This launches the simulator with Verisium GUI for real-time debugging
run_dbg: mk_dir
	cd ${RUN_DIR} && ln -sf ../xcelium.d . 2>/dev/null || true
	@echo "=============================================="
	@echo " Starting Interactive Debug Session"
	@echo " Test: ${TEST_CASE}"
	@echo "=============================================="
	@echo " Verisium GUI will open for interactive debugging."
	@echo " You can set breakpoints, single-step, and inspect variables."
	@echo "=============================================="

	cd ${RUN_DIR} && LD_LIBRARY_PATH=${VIP_LIB_PATH}:${LD_LIBRARY_PATH} xrun -R +UVM_TESTNAME=${TEST_CASE} ${NO_TIMEOUT_OPT} \
		${SIMV_OPTIONS} ${COV_SIMV_OPTIONS} \
		-gui -verisium -l run.log


# Full interactive debug flow: compile + run
sim_dbg: comp_dbg run_dbg

#------------------------------------------------------------------------------
# All-in-one targets
#------------------------------------------------------------------------------
.PHONY: all

all: comp_elab run

#------------------------------------------------------------------------------
# Verdi
#------------------------------------------------------------------------------
.PHONY: verdi verdi_clean

verdi:
	verdi -2012 -ntb_opts uvm-1.2 -sv +v2k -ssz -sv_pragma \
		-timescale=1ns/100ps -top tb_top ${TB_FILE_OPTIONS} &

verdi_clean:
	@rm -rf verdiLog vericomLog vhdlcomLog novas.* verdi_work.lib++

#------------------------------------------------------------------------------
# Verisium Debug (IDA waveform viewer)
#------------------------------------------------------------------------------
.PHONY: vsm vsm_list

# Open Verisium Debug with IDA waveform
# Usage: make vsm TC=testcase
vsm:
ifndef TC
	@echo "ERROR: Please specify testcase with TC=xxx"
	@echo "Usage: make vsm TC=testcase_name"
	@echo ""
	@echo "Available IDA waveforms:"
	@ls -1d ${IDA_DIR}/*.ida 2>/dev/null | xargs -I{} basename {} .ida || echo "  (none found in ${IDA_DIR})"
	@exit 1
else
	@if [ -d "${IDA_DIR}/${TC}.ida" ]; then \
		echo "Opening Verisium Debug: ${IDA_DIR}/${TC}.ida"; \
		verisium -db ${IDA_DIR}/${TC}.ida & \
	else \
		echo "ERROR: IDA waveform not found: ${IDA_DIR}/${TC}.ida"; \
		echo ""; \
		echo "Available IDA waveforms:"; \
		ls -1d ${IDA_DIR}/*.ida 2>/dev/null | xargs -I{} basename {} .ida || echo "  (none found)"; \
		exit 1; \
	fi
endif

# List available IDA waveforms
vsm_list:
	@echo "Available IDA waveforms in ${IDA_DIR}:"
	@ls -1d ${IDA_DIR}/*.ida 2>/dev/null | xargs -I{} basename {} .ida || echo "  (none found)"

#------------------------------------------------------------------------------
# Clean
#------------------------------------------------------------------------------
clean:
	@rm -rf INCA_libs *.log *.history xrune xruns href.txt xcelium.d vhdl_lib *.sdf.gz.X sdf_annotation_log

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------
help:
	@echo ""
	@echo "TB_ROOT: ${TB_ROOT}"
	@echo "DUT:     ${DUT_NAME}"
	@echo "IDA_DIR: ${IDA_DIR}"
	@echo ""
	@echo "================ Compilation Commands ================"
	@echo "  make tb_elab     : Compile testbench only (define ONLY_COMP_TB)"
	@echo "  make rtl_elab    : Compile DUT only"
	@echo "  make comp_elab   : Compile DUT + testbench (normal mode)"
	@echo "  make comp_pp     : Compile with verisium_pp (post-processing)"
	@echo "  make comp_dbg    : Compile with verisium_interactive (debug)"
	@echo ""
	@echo "================ Simulation Commands ================"
	@echo "  make run TC=xxx  : Run simulation with testcase"
	@echo "  make sim TC=xxx  : Compile + run simulation"
	@echo "  make all TC=xxx  : Same as 'make sim'"
	@echo ""
	@echo "================ Post-Processing Debug (verisium_pp) ================"
	@echo "  make run_pp TC=xxx               : Run and record to IDA database"
	@echo "  make run_pp TC=xxx DEBUG_LEVEL=full : Record wave + flow + log"
	@echo "  make sim_pp TC=xxx               : Compile PP + run"
	@echo ""
	@echo "================ Interactive Debug (verisium_interactive) ================"
	@echo "  make run_dbg TC=xxx              : Run with Verisium GUI debugger"
	@echo "  make sim_dbg TC=xxx              : Compile DBG + run"
	@echo ""
	@echo "================ Waveform Commands ================"
	@echo "  make vsm TC=xxx  : Open Verisium Debug with IDA waveform"
	@echo "  make vsm_list    : List available IDA waveforms"
	@echo "  make verdi       : Open Verdi"
	@echo ""
	@echo "================ Options ================"
	@echo "  TC=xxx           : Testcase name (default: ${TEST_CASE})"
	@echo "  SEED=xxx         : Random seed"
	@echo "  COV_EN=1         : Enable coverage"
	@echo "  GUI=1            : Run with GUI"
	@echo "  NO_WAVE=1        : Disable waveform dump (default: enabled)"
	@echo "  WAVE_FORMAT=xxx  : Wave format: ida (default), shm, vcd"
	@echo "  DEBUG_LEVEL=xxx  : PP debug level: wave (default), full"
	@echo "  VERBOSITY=xxx    : UVM verbosity (UVM_LOW/MEDIUM/HIGH/DEBUG)"
	@echo ""
	@echo "================ Clean ================"
	@echo "  make clean       : Clean simulation files"
	@echo "  make verdi_clean : Clean Verdi files"
	@echo ""
	@echo "================ Debug Workflows ================"
	@echo "  [Post-Processing] 仿真后离线分析:"
	@echo "    1. make comp_pp              # 编译 (verisium_pp)"
	@echo "    2. make run_pp TC=xxx        # 运行仿真，记录IDA"
	@echo "    3. make vsm TC=xxx           # 打开Verisium分析"
	@echo ""
	@echo "  [Interactive] 实时交互调试:"
	@echo "    1. make comp_dbg             # 编译 (verisium_interactive)"
	@echo "    2. make run_dbg TC=xxx       # 启动Verisium GUI调试"
	@echo ""
