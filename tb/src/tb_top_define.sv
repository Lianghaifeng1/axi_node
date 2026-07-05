

`define AXI_MST_AGENT_NUM        2


`define AXI_SLV_AGENT_NUM        2


`define AXI_CROSSBAR                              tb_top.u_axi_crossbar

`define AXI_CROSSBAR_MODEL                       m_cfg_h.m_dut_cfg_h.m_regs_model_h
`define AXI_CROSSBAR_MODEL_WORD_ACCESS_MODEL     m_cfg_h.m_dut_cfg_h.m_word_regs_model_h


`include "dv_macros.svh"
// uvm_macros.svh is automatically included by -uvm option in Makefile, no need to include here
`include "common_ifs_pkg.sv"
`include "clk_rst_if.sv"
`include "pins_if.sv"

// vip agent pkg (included via Makefile VIP_SRC, not here)
// VIP packages are compiled separately in Makefile before this file

// DUT package (if specified)
// env pkg
`include "uvmreg_byte_pkg.sv"
`include "uvmreg_word_pkg.sv"

`include "axi_crossbar_env_pkg.sv"
`include "axi_crossbar_test_pkg.sv"