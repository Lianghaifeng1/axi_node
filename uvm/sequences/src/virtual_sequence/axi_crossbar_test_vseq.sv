class axi_crossbar_test_vseq extends axi_crossbar_test_base_vseq;
  `uvm_object_utils(axi_crossbar_test_vseq)

  extern function new(string name="axi_crossbar_test_vseq");
  extern virtual task body();
  extern virtual task run_master_rw_check(
    int mst_idx,
    longint unsigned base_addr,
    string scenario_name
  );
  extern virtual task run_blocking_write_with_timeout(
    axi_crossbar_axi_blocking_write_seq wr_seq,
    int mst_idx,
    longint unsigned base_addr,
    string scenario_name
  );
  extern virtual task run_blocking_read_with_timeout(
    axi_crossbar_axi_blocking_read_seq rd_seq,
    int mst_idx,
    longint unsigned base_addr,
    string scenario_name
  );
  extern virtual function void check_readback(
    denaliCdn_axiTransaction wr_rsp,
    denaliCdn_axiTransaction rd_rsp,
    string scenario_name
  );

endclass : axi_crossbar_test_vseq

function axi_crossbar_test_vseq::new(string name="axi_crossbar_test_vseq");
  super.new(name);
endfunction : new

task axi_crossbar_test_vseq::body();
  const reg [7:0] same_length = 4;
  const denaliCdn_axiTransferSizeT same_size = DENALI_CDN_AXI_TRANSFERSIZE_WORD;
  const denaliCdn_axiBurstKindT same_kind = DENALI_CDN_AXI_BURSTKIND_INCR;
  const denaliCdn_axiSecureModeT same_secure = DENALI_CDN_AXI_SECUREMODE_NONSECURE;
  axi_crossbar_axi_blocking_write_seq warmup_wr_seq;
  axi_crossbar_axi_blocking_read_seq warmup_rd_seq;

  if(starting_phase != null) begin
    starting_phase.raise_objection(this);
  end
  `uvm_info(get_name(),"start virtual sequence",UVM_LOW)

  warmup_wr_seq = axi_crossbar_axi_blocking_write_seq::type_id::create("warmup_wr_seq");
  warmup_rd_seq = axi_crossbar_axi_blocking_read_seq::type_id::create("warmup_rd_seq");

  `uvm_info(get_name(), "warmup: mst0 writes and reads slave0 window", UVM_LOW)
  warmup_wr_seq.address = 64'h0000_0100;
  warmup_wr_seq.length  = same_length;
  warmup_wr_seq.size    = same_size;
  warmup_wr_seq.kind    = same_kind;
  warmup_wr_seq.secure  = same_secure;
  run_blocking_write_with_timeout(warmup_wr_seq, 0, 64'h0000_0100, "warmup_mst0_to_slv0");

  warmup_rd_seq.address = 64'h0000_0100;
  warmup_rd_seq.length  = same_length;
  warmup_rd_seq.size    = same_size;
  warmup_rd_seq.kind    = same_kind;
  warmup_rd_seq.secure  = same_secure;
  run_blocking_read_with_timeout(warmup_rd_seq, 0, 64'h0000_0100, "warmup_mst0_to_slv0");
  check_readback(warmup_wr_seq.response, warmup_rd_seq.response, "warmup_mst0_to_slv0");

  fork
    run_master_rw_check(0, 64'h1000_0200, "mst0_to_slv1");
    run_master_rw_check(1, 64'h0000_0300, "mst1_to_slv0");
    run_master_rw_check(1, 64'h1000_0400, "mst1_to_slv1");
  join

  `uvm_info(get_name(), "concurrent 2-master traffic finished", UVM_LOW)

  if(starting_phase != null) begin
    starting_phase.drop_objection(this);
  end
endtask : body

task axi_crossbar_test_vseq::run_master_rw_check(
  int mst_idx,
  longint unsigned base_addr,
  string scenario_name
);
  axi_crossbar_axi_blocking_write_seq wr_seq;
  axi_crossbar_axi_blocking_read_seq rd_seq;
  const reg [7:0] same_length = 4;
  const denaliCdn_axiTransferSizeT same_size = DENALI_CDN_AXI_TRANSFERSIZE_WORD;
  const denaliCdn_axiBurstKindT same_kind = DENALI_CDN_AXI_BURSTKIND_INCR;
  const denaliCdn_axiSecureModeT same_secure = DENALI_CDN_AXI_SECUREMODE_NONSECURE;

  wr_seq = axi_crossbar_axi_blocking_write_seq::type_id::create(
    $sformatf("%s_wr_seq", scenario_name)
  );
  rd_seq = axi_crossbar_axi_blocking_read_seq::type_id::create(
    $sformatf("%s_rd_seq", scenario_name)
  );

  `uvm_info(get_name(),
    $sformatf("%s: master%0d access addr 0x%08h", scenario_name, mst_idx, base_addr),
    UVM_LOW)

  wr_seq.address = base_addr;
  wr_seq.length  = same_length;
  wr_seq.size    = same_size;
  wr_seq.kind    = same_kind;
  wr_seq.secure  = same_secure;
  run_blocking_write_with_timeout(wr_seq, mst_idx, base_addr, scenario_name);

  rd_seq.address = base_addr;
  rd_seq.length  = same_length;
  rd_seq.size    = same_size;
  rd_seq.kind    = same_kind;
  rd_seq.secure  = same_secure;
  run_blocking_read_with_timeout(rd_seq, mst_idx, base_addr, scenario_name);

  check_readback(wr_seq.response, rd_seq.response, scenario_name);
endtask

task axi_crossbar_test_vseq::run_blocking_write_with_timeout(
  axi_crossbar_axi_blocking_write_seq wr_seq,
  int mst_idx,
  longint unsigned base_addr,
  string scenario_name
);
  bit write_done;

  write_done = 0;
  fork
    begin
      wr_seq.start(m_axi_mst_seqr_h[mst_idx]);
      write_done = 1;
    end
    begin
      #20us;
      if (!write_done) begin
        `uvm_fatal(get_name(),
          $sformatf("%s write timeout on master%0d addr 0x%08h",
            scenario_name, mst_idx, base_addr))
      end
    end
  join_any
  disable fork;
endtask

task axi_crossbar_test_vseq::run_blocking_read_with_timeout(
  axi_crossbar_axi_blocking_read_seq rd_seq,
  int mst_idx,
  longint unsigned base_addr,
  string scenario_name
);
  bit read_done;

  read_done = 0;
  fork
    begin
      rd_seq.start(m_axi_mst_seqr_h[mst_idx]);
      read_done = 1;
    end
    begin
      #20us;
      if (!read_done) begin
        `uvm_fatal(get_name(),
          $sformatf("%s read timeout on master%0d addr 0x%08h",
            scenario_name, mst_idx, base_addr))
      end
    end
  join_any
  disable fork;
endtask

function void axi_crossbar_test_vseq::check_readback(
  denaliCdn_axiTransaction wr_rsp,
  denaliCdn_axiTransaction rd_rsp,
  string scenario_name
);
  if (wr_rsp.Data.size() != rd_rsp.Data.size()) begin
    `uvm_fatal(get_name(),
      $sformatf("%s data size mismatch: wr=%0d rd=%0d",
        scenario_name, wr_rsp.Data.size(), rd_rsp.Data.size()))
  end

  for (int i = 0; i < rd_rsp.Data.size(); i++) begin
    if (rd_rsp.Data[i] != wr_rsp.Data[i]) begin
      `uvm_fatal(get_name(),
        $sformatf("%s readback mismatch at byte %0d addr 0x%08h: wr=0x%02x rd=0x%02x",
          scenario_name,
          i,
          rd_rsp.StartAddress + i,
          wr_rsp.Data[i],
          rd_rsp.Data[i]))
    end
  end

  `uvm_info(get_name(),
    $sformatf("%s readback matched %0d bytes", scenario_name, rd_rsp.Data.size()),
    UVM_LOW)
endfunction
