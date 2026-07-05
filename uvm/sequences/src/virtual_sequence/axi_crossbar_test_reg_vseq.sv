class axi_crossbar_test_reg_vseq extends axi_crossbar_test_base_vseq;

`uvm_object_utils(axi_crossbar_test_reg_vseq)

extern function new(string name = "axi_crossbar_test_reg_vseq");
extern virtual task body();

endclass: axi_crossbar_test_reg_vseq


function axi_crossbar_test_reg_vseq::new(string name = "axi_crossbar_test_reg_vseq");
  super.new(name);
endfunction: new


task axi_crossbar_test_reg_vseq::body();

  uvm_status_e      stat;
  uvm_reg_data_t    dat;

  uvm_reg_hw_reset_seq     m_rst_seq;
  uvm_reg_bit_bash_seq     m_bit_seq;
  uvm_reg_access_seq       m_access_seq;
  //super.body();

  //========================================================//
  //             reset default value                        //
  //========================================================//
  `uvm_info(get_name(), $sformatf("hw reset sequence is running"), UVM_LOW)
  m_rst_seq = uvm_reg_hw_reset_seq::type_id::create("m_rst_seq");
  m_rst_seq.model = `AXI_CROSSBAR_MODEL;
  m_rst_seq.start(null);
  `uvm_info(get_name(), $sformatf("hw reset sequence is exiting"), UVM_LOW)

  #1us;

  `uvm_info(get_name(), $sformatf("bit bash sequence is running"), UVM_LOW)
  m_bit_seq = uvm_reg_bit_bash_seq::type_id::create("m_bit_seq");
  m_bit_seq.model = `AXI_CROSSBAR_MODEL;
  m_bit_seq.start(null);
  `uvm_info(get_name(), $sformatf("bit bash sequence is exiting"), UVM_LOW)

  #1us;

endtask : body