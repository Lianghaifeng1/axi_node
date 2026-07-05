class axi_crossbar_test_stress extends axi_crossbar_test_base;
  `uvm_component_utils(axi_crossbar_test_stress)

  axi_crossbar_test_stress_vseq m_vseq_h;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db#(int)::set(this,
      "m_env_h.m_slv_scb_h[0]", "m_min_trans_num", 610);
    uvm_config_db#(int)::set(this,
      "m_env_h.m_slv_scb_h[1]", "m_min_trans_num", 298);
    m_vseq_h = axi_crossbar_test_stress_vseq::type_id::create("m_vseq_h", this);
  endfunction

  virtual task vseq_run(uvm_phase phase);
    m_vseq_h.start(m_vseqr_h);
  endtask
endclass
