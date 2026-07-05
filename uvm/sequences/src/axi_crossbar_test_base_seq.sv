class axi_crossbar_test_base_seq extends uvm_sequence#(uvm_sequence_item);

`uvm_object_utils(axi_crossbar_test_base_seq)

axi_crossbar_cfg     m_cfg_h;
axi_crossbar_dut_vif m_dut_vif_h;

function new(string name = "axi_crossbar_test_base_seq");
  super.new(name);
endfunction : new

virtual function void set_config(axi_crossbar_cfg cfg, axi_crossbar_dut_vif vif);
  this.m_cfg_h     = cfg;
  this.m_dut_vif_h = vif;
endfunction : set_config

endclass : axi_crossbar_test_base_seq