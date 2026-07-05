package axi_crossbar_test_pkg;
  import uvm_pkg::*;     // import uvm package
`ifdef AXI_VIP_SVT
  import svt_uvm_pkg::*;
  import svt_axi_uvm_pkg::*;
`else
  import DenaliSvMem::*;
  import DenaliSvCdn_axi::*;
  import cdnAxiUvm::*;
`endif

  import uvmreg_byte_pkg::*;
  import uvmreg_word_pkg::*;
  import axi_crossbar_env_pkg::*;

  // uvm_macros.svh is included in tb_top_define.sv, no need to include here
  `include "axi_crossbar_test_define.sv"
  `include "reg_model_adapter.sv"
  `include "axi_crossbar_test_vseqr.sv"
  `include "axi_crossbar_test_common.sv"
  `include "axi_crossbar_test_base.sv"

  // include sequence and virtual sequence
  `include "axi_crossbar_test_vseq_list.sv"

  //include all uvm testcase
  `include "axi_crossbar_test_sanity.sv"
  `include "axi_crossbar_test_reg.sv"
  `include "axi_crossbar_test_stress.sv"
  `include "axi_crossbar_test_scb_unit.sv"

endpackage
