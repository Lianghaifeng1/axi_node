class axi_crossbar_ref_model extends uvm_component;
  `uvm_component_utils(axi_crossbar_ref_model)

  axi_crossbar_cfg m_cfg_h;
`ifdef AXI_VIP_SVT
  axi_crossbar_svt_axi_common_adapter m_axi_adapter;
`else
  axi_crossbar_cdn_axi_common_adapter m_axi_adapter;
`endif
  uvm_tlm_analysis_fifo #(axi_vip_transaction_t) m_mst_fifo[`AXI_MST_AGENT_NUM];
  uvm_tlm_analysis_fifo #(axi_vip_transaction_t) m_slv_fifo[`AXI_SLV_AGENT_NUM];
  uvm_analysis_port #(axi_crossbar_common_transaction) m_expected_ap[`AXI_SLV_AGENT_NUM];
  uvm_analysis_port #(axi_crossbar_common_transaction) m_actual_ap[`AXI_SLV_AGENT_NUM];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi_crossbar_cfg)::get(this, "", "cfg", m_cfg_h))
      `uvm_fatal(get_full_name(), "failed to get axi_crossbar_cfg")

`ifdef AXI_VIP_SVT
    m_axi_adapter = axi_crossbar_svt_axi_common_adapter::type_id::create("m_axi_adapter");
`else
    m_axi_adapter = axi_crossbar_cdn_axi_common_adapter::type_id::create("m_axi_adapter");
`endif
    for (int i = 0; i < `AXI_MST_AGENT_NUM; i++)
      m_mst_fifo[i] = new($sformatf("m_mst_fifo[%0d]", i), this);
    for (int i = 0; i < `AXI_SLV_AGENT_NUM; i++) begin
      m_slv_fifo[i] = new($sformatf("m_slv_fifo[%0d]", i), this);
      m_expected_ap[i] = new($sformatf("m_expected_ap[%0d]", i), this);
      m_actual_ap[i] = new($sformatf("m_actual_ap[%0d]", i), this);
    end
  endfunction

  function int decode_slave(bit [63:0] address);
    for (int i = 0; i < `AXI_SLV_AGENT_NUM; i++) begin
      if (address >= m_cfg_h.m_endpoint_base[i] &&
          address <= m_cfg_h.m_endpoint_end[i])
        return i;
    end
    return -1;
  endfunction

  protected function void convert_and_publish(
    axi_vip_transaction_t tr,
    axi_crossbar_common_side_e side,
    int unsigned port_index
  );
    axi_crossbar_common_adapter_context ctx;
    axi_crossbar_common_transaction result[$];
    int dest_port;

`ifdef AXI_VIP_SVT
    dest_port = decode_slave(tr.addr);
`else
    dest_port = decode_slave(tr.StartAddress);
`endif
    if (dest_port < 0 || dest_port >= `AXI_SLV_AGENT_NUM) begin
      `uvm_error(get_name(),
        $sformatf("transaction address does not map to a scoreboard endpoint"))
      return;
    end
    if (side == AXI_COMMON_DOWNSTREAM && dest_port != port_index) begin
      `uvm_error(get_name(),
        $sformatf("routing mismatch: address 0x%016h maps to slave%0d, observed on slave%0d",
`ifdef AXI_VIP_SVT
          tr.addr, dest_port, port_index))
`else
          tr.StartAddress, dest_port, port_index))
`endif
      return;
    end

    ctx = axi_crossbar_common_adapter_context::type_id::create("ctx");
    ctx.side = side;
    ctx.port_index = port_index;
    ctx.source_port = (side == AXI_COMMON_UPSTREAM) ? port_index : 0;
    ctx.dest_port = dest_port;
    ctx.data_width = `AXI_CROSSBAR_DATA_WIDTH;
    ctx.original_id_width = 8;
    ctx.downstream_id_contains_source = (side == AXI_COMMON_DOWNSTREAM);
    m_axi_adapter.convert(tr, ctx, result);

    foreach (result[i]) begin
      if (result[i].source_port >= `AXI_MST_AGENT_NUM) begin
        `uvm_error(get_name(),
          $sformatf("invalid source master %0d decoded from AXI ID 0x%0h",
            result[i].source_port, result[i].transaction_id))
        continue;
      end
      if (side == AXI_COMMON_UPSTREAM)
        m_expected_ap[dest_port].write(result[i]);
      else
        m_actual_ap[dest_port].write(result[i]);
    end
  endfunction

  protected task collect_master(int unsigned index);
    axi_vip_transaction_t tr;
    forever begin
      m_mst_fifo[index].get(tr);
      convert_and_publish(tr, AXI_COMMON_UPSTREAM, index);
    end
  endtask

  protected task collect_slave(int unsigned index);
    axi_vip_transaction_t tr;
    forever begin
      m_slv_fifo[index].get(tr);
      convert_and_publish(tr, AXI_COMMON_DOWNSTREAM, index);
    end
  endtask

  virtual task run_phase(uvm_phase phase);
    for (int i = 0; i < `AXI_MST_AGENT_NUM; i++) begin
      automatic int index = i;
      fork collect_master(index); join_none
    end
    for (int i = 0; i < `AXI_SLV_AGENT_NUM; i++) begin
      automatic int index = i;
      fork collect_slave(index); join_none
    end
    wait fork;
  endtask
endclass
