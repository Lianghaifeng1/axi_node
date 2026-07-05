class axi_crossbar_test_stress_vseq extends axi_crossbar_test_base_vseq;
  `uvm_object_utils(axi_crossbar_test_stress_vseq)

  function new(string name = "axi_crossbar_test_stress_vseq");
    super.new(name);
  endfunction

  task run_write(
    int mst_idx,
    bit [63:0] address,
    int unsigned length,
    axi_vip_size_t size,
    axi_vip_burst_t kind,
    bit [63:0] id,
    bit force_strobe = 0,
    bit [31:0] strobe = '1
  );
    axi_crossbar_axi_blocking_write_seq seq;
    seq = axi_crossbar_axi_blocking_write_seq::type_id::create(
      $sformatf("wr_m%0d_a%0h_id%0h", mst_idx, address, id));
    seq.address = address;
    seq.length = length;
    seq.size = size;
    seq.kind = kind;
    seq.secure = `AXI_VIP_NONSECURE;
    seq.force_id = 1;
    seq.fixed_id = id;
    seq.force_strobe = force_strobe;
    seq.fixed_strobe = strobe;
    seq.start(m_axi_mst_seqr_h[mst_idx]);
  endtask

  task run_read(
    int mst_idx,
    bit [63:0] address,
    int unsigned length,
    axi_vip_size_t size,
    axi_vip_burst_t kind,
    bit [63:0] id
  );
    axi_crossbar_axi_blocking_read_seq seq;
    seq = axi_crossbar_axi_blocking_read_seq::type_id::create(
      $sformatf("rd_m%0d_a%0h_id%0h", mst_idx, address, id));
    seq.address = address;
    seq.length = length;
    seq.size = size;
    seq.kind = kind;
    seq.secure = `AXI_VIP_NONSECURE;
    seq.force_id = 1;
    seq.fixed_id = id;
    seq.start(m_axi_mst_seqr_h[mst_idx]);
  endtask

  task run_pair(
    int mst_idx,
    bit [63:0] address,
    int unsigned length,
    axi_vip_size_t size,
    axi_vip_burst_t kind,
    bit [63:0] id,
    bit force_strobe = 0,
    bit [31:0] strobe = '1
  );
    run_write(mst_idx, address, length, size, kind, id, force_strobe, strobe);
    run_read(mst_idx, address, length, size, kind, id);
  endtask

  virtual task body();
    if (starting_phase != null)
      starting_phase.raise_objection(this);

    `uvm_info(get_name(), "starting burst/size/strobe matrix", UVM_LOW)
    run_pair(0, 64'h0000_1000, 1, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_FIXED, 8'h01);
    run_pair(1, 64'h1000_1100, 4, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_FIXED, 8'h02);
    run_pair(0, 64'h0000_1201, 7, `AXI_VIP_SIZE_BYTE, `AXI_VIP_BURST_INCR, 8'h03);
    run_pair(1, 64'h1000_1302, 5, `AXI_VIP_SIZE_HALFWORD, `AXI_VIP_BURST_INCR, 8'h04);
    run_pair(0, 64'h0000_1400, 16, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_INCR, 8'h05);
    run_pair(1, 64'h1000_1504, 2, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_WRAP, 8'h06);
    run_pair(0, 64'h0000_1604, 4, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_WRAP, 8'h07);
    run_pair(1, 64'h1000_1704, 8, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_WRAP, 8'h08);
    run_pair(0, 64'h0000_1804, 16, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_WRAP, 8'h09);
    run_pair(1, 64'h1000_1901, 7, `AXI_VIP_SIZE_BYTE, `AXI_VIP_BURST_INCR, 8'h0a);
    run_pair(0, 64'h0000_1a02, 5, `AXI_VIP_SIZE_HALFWORD, `AXI_VIP_BURST_INCR, 8'h0b);
    run_pair(0, 64'h0000_1b00, 4, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_INCR, 8'h0c, 1, 32'h5);
    run_pair(1, 64'h1000_1c00, 4, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_INCR, 8'h0d, 1, 32'ha);

    `uvm_info(get_name(), "starting concurrent outstanding traffic", UVM_LOW)
    for (int i = 0; i < 12; i++) begin
      automatic int index = i;
      fork
        run_write(index % 2,
                  (index % 3 == 0 ? 64'h1000_4000 : 64'h0000_4000) + index * 64,
                  4, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_INCR, 8'h20 + index);
      join_none
    end
    wait fork;

    for (int i = 0; i < 12; i++) begin
      automatic int index = i;
      fork
        run_read(index % 2,
                 (index % 3 == 0 ? 64'h1000_4000 : 64'h0000_4000) + index * 64,
                 4, `AXI_VIP_SIZE_WORD, `AXI_VIP_BURST_INCR, 8'h40 + index);
      join_none
    end
    wait fork;

    `uvm_info(get_name(), "stress traffic completed", UVM_LOW)
    if (starting_phase != null)
      starting_phase.drop_objection(this);
  endtask
endclass
