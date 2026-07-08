`include "axi_crossbar_dut_intf.sv"

package axi_crossbar_env_pkg;

  import uvm_pkg::*;

  // UVM REG pkgs
  import uvmreg_byte_pkg::*;
  import uvmreg_word_pkg::*;
  // Import the DDVAPI AXI SV interface and generic Mem interface
`ifdef AXI_VIP_SVT
  import svt_uvm_pkg::*;
  import svt_axi_uvm_pkg::*;
`else
  import DenaliSvMem::*;
  import DenaliSvCdn_axi::*;
  import cdnAxiUvm::*;
`endif

  typedef virtual axi_crossbar_dut_intf axi_crossbar_dut_vif;
  typedef virtual cpu_wrapper_dummy_if cpu_wrapper_dummy_vif;

  // uvm_macros.svh is included in tb_top_define.sv, no need to include here
  `include "axi_crossbar_env_define.sv"
  `include "axi_crossbar_vip_compat.sv"

  // dut cfg
  `include "axi_crossbar_dut_cfg.sv"
  `include "axi_crossbar_cfg.sv"

  // environment
  `include "axi_crossbar_common_transaction.sv"
  `include "axi_crossbar_common_adapter.sv"
  `include "axi_crossbar_scoreboard.sv"
  `include "axi_crossbar_ref_model.sv"
  `include "axi_crossbar_env.sv"

endpackage : axi_crossbar_env_pkg
