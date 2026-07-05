class axi_crossbar_dut_cfg extends uvm_object;

  `uvm_object_utils_begin(axi_crossbar_dut_cfg)
    // `uvm_field_object(xxx, UVM_ALL_ON)
  `uvm_object_utils_end


  axi_crossbar_regs_model  m_regs_model_h;  // m_regs_model_h
  axi_crossbar_word_access_regs_model  m_word_regs_model_h;  // m_regs_model_h
  uvm_path_e                   m_path;          // operation path for backdoor or frontdoor. default: frontdoor


  extern function new(string name = "axi_crossbar_dut_cfg");

endclass : axi_crossbar_dut_cfg


function axi_crossbar_dut_cfg::new(string name = "axi_crossbar_dut_cfg");
  super.new(name);
endfunction : new