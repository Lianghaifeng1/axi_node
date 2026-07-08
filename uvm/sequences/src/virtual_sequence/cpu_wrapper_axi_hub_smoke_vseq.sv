class cpu_wrapper_axi_hub_smoke_vseq extends axi_crossbar_test_base_vseq;
  `uvm_object_utils(cpu_wrapper_axi_hub_smoke_vseq)

  function new(string name = "cpu_wrapper_axi_hub_smoke_vseq");
    super.new(name);
  endfunction

  virtual task body();
    axi_crossbar_axi_blocking_write_seq wr_seq;
    axi_crossbar_axi_blocking_read_seq rd_seq;

    if (starting_phase != null)
      starting_phase.raise_objection(this);

    `uvm_info(get_name(), "start CPU_WRAPPER AXI hub smoke sequence", UVM_LOW)

    wr_seq = axi_crossbar_axi_blocking_write_seq::type_id::create("wr_seq");
    wr_seq.address = 64'h0000_0100;
    wr_seq.length = 4;
    wr_seq.size = `AXI_VIP_SIZE_WORD;
    wr_seq.kind = `AXI_VIP_BURST_INCR;
    wr_seq.secure = `AXI_VIP_NONSECURE;
    wr_seq.force_id = 1;
    wr_seq.fixed_id = 8'h01;
    wr_seq.start(m_axi_mst_seqr_h[m_cfg_h.m_cpu_axi_agt_idx]);

    rd_seq = axi_crossbar_axi_blocking_read_seq::type_id::create("rd_seq");
    rd_seq.address = 64'h0000_0100;
    rd_seq.length = 4;
    rd_seq.size = `AXI_VIP_SIZE_WORD;
    rd_seq.kind = `AXI_VIP_BURST_INCR;
    rd_seq.secure = `AXI_VIP_NONSECURE;
    rd_seq.force_id = 1;
    rd_seq.fixed_id = 8'h02;
    rd_seq.start(m_axi_mst_seqr_h[m_cfg_h.m_cpu_axi_agt_idx]);

    `uvm_info(get_name(), "CPU_WRAPPER AXI hub smoke sequence completed", UVM_LOW)

    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask
endclass
