class cpu_wrapper_axi_hub_smoke_test extends axi_crossbar_test_base;
  `uvm_component_utils(cpu_wrapper_axi_hub_smoke_test)

  cpu_wrapper_axi_hub_smoke_vseq m_vseq_h;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
`ifdef AXI_VIP_SVT
    uvm_config_db#(uvm_object_wrapper)::set(this,
      "m_env_h.m_axi_sys_env_h.slave*.sequencer.run_phase",
      "default_sequence", axi_crossbar_svt_slave_mem_response_seq::type_id::get());
`endif
    super.build_phase(phase);
    uvm_config_db#(int)::set(this,
      "m_env_h.m_slv_scb_h[0]", "m_min_trans_num", 1);
    uvm_config_db#(int)::set(this,
      "m_env_h.m_slv_scb_h[1]", "m_min_trans_num", 0);
    m_vseq_h = cpu_wrapper_axi_hub_smoke_vseq::type_id::create("m_vseq_h", this);
  endfunction

  virtual task vseq_run(uvm_phase phase);
    m_vseq_h.start(m_vseqr_h);
  endtask
endclass
