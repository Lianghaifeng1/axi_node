class axi_crossbar_ref_model extends uvm_component;
  `uvm_component_utils(axi_crossbar_ref_model)

  axi_crossbar_cfg m_cfg_h;
`ifdef AXI_VIP_SVT
  axi_crossbar_svt_axi_common_adapter m_axi_adapter;
`else
  axi_crossbar_cdn_axi_common_adapter m_axi_adapter;
`endif
  cpu_wrapper_dummy_common_adapter m_dummy_adapter;
  uvm_tlm_analysis_fifo #(axi_vip_transaction_t) m_mst_fifo[`AXI_MST_AGENT_NUM];
  uvm_tlm_analysis_fifo #(axi_vip_transaction_t) m_slv_fifo[`AXI_SLV_AGENT_NUM];
  uvm_tlm_analysis_fifo #(cpu_wrapper_dummy_transaction) m_rbc_in_fifo;
  uvm_tlm_analysis_fifo #(cpu_wrapper_dummy_transaction) m_mem_in_fifo;
  uvm_tlm_analysis_fifo #(cpu_wrapper_dummy_transaction) m_ram_out_fifo;
  uvm_tlm_analysis_fifo #(cpu_wrapper_dummy_transaction) m_rom_out_fifo;
  uvm_tlm_analysis_fifo #(cpu_wrapper_dummy_transaction) m_public_reg_out_fifo;
  uvm_tlm_analysis_fifo #(cpu_wrapper_dummy_transaction) m_private_reg_out_fifo;
  uvm_tlm_analysis_fifo #(cpu_wrapper_dummy_transaction) m_rbc_out_fifo;
  uvm_analysis_port #(axi_crossbar_common_transaction) m_expected_ap[`AXI_SLV_AGENT_NUM];
  uvm_analysis_port #(axi_crossbar_common_transaction) m_actual_ap[`AXI_SLV_AGENT_NUM];
  uvm_analysis_port #(axi_crossbar_common_transaction) m_expected_wr_ap[CPUW_PATH_NUM];
  uvm_analysis_port #(axi_crossbar_common_transaction) m_actual_wr_ap[CPUW_PATH_NUM];
  uvm_analysis_port #(axi_crossbar_common_transaction) m_expected_rd_ap[CPUW_PATH_NUM];
  uvm_analysis_port #(axi_crossbar_common_transaction) m_actual_rd_ap[CPUW_PATH_NUM];

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
    m_dummy_adapter = cpu_wrapper_dummy_common_adapter::type_id::create("m_dummy_adapter");
    for (int i = 0; i < `AXI_MST_AGENT_NUM; i++)
      m_mst_fifo[i] = new($sformatf("m_mst_fifo[%0d]", i), this);
    for (int i = 0; i < `AXI_SLV_AGENT_NUM; i++) begin
      m_slv_fifo[i] = new($sformatf("m_slv_fifo[%0d]", i), this);
      m_expected_ap[i] = new($sformatf("m_expected_ap[%0d]", i), this);
      m_actual_ap[i] = new($sformatf("m_actual_ap[%0d]", i), this);
    end
    for (int i = 0; i < CPUW_PATH_NUM; i++) begin
      m_expected_wr_ap[i] = new($sformatf("m_expected_wr_ap[%0d]", i), this);
      m_actual_wr_ap[i] = new($sformatf("m_actual_wr_ap[%0d]", i), this);
      m_expected_rd_ap[i] = new($sformatf("m_expected_rd_ap[%0d]", i), this);
      m_actual_rd_ap[i] = new($sformatf("m_actual_rd_ap[%0d]", i), this);
    end
    m_rbc_in_fifo = new("m_rbc_in_fifo", this);
    m_mem_in_fifo = new("m_mem_in_fifo", this);
    m_ram_out_fifo = new("m_ram_out_fifo", this);
    m_rom_out_fifo = new("m_rom_out_fifo", this);
    m_public_reg_out_fifo = new("m_public_reg_out_fifo", this);
    m_private_reg_out_fifo = new("m_private_reg_out_fifo", this);
    m_rbc_out_fifo = new("m_rbc_out_fifo", this);
  endfunction

  function int decode_slave(bit [63:0] address);
`ifdef CPU_WRAPPER_SKEL
    cpu_wrapper_path_e path;
    path = decode_path(address, CPUW_PORT_CPU_AXI);
    return int'(m_cfg_h.m_path_slv_idx[path]);
`else
    for (int i = 0; i < `AXI_SLV_AGENT_NUM; i++) begin
      if (address >= m_cfg_h.m_endpoint_base[i] &&
          address <= m_cfg_h.m_endpoint_end[i])
        return i;
    end
    return -1;
`endif
  endfunction

  function bit path_source_matches(cpu_wrapper_path_e path, cpu_wrapper_port_e source_port);
    case (source_port)
      CPUW_PORT_CPU_AXI:
        return (path == CPUW_PATH_CPU_AXI_TO_AXI_HUB ||
                path == CPUW_PATH_CPU_AXI_TO_RAM ||
                path == CPUW_PATH_CPU_AXI_TO_ROM ||
                path == CPUW_PATH_CPU_AXI_TO_PUBLIC_REG ||
                path == CPUW_PATH_CPU_AXI_TO_PRIVATE_REG ||
                path == CPUW_PATH_CPU_AXI_TO_RBC_OUT);
      CPUW_PORT_RBC_DUMMY:
        return (path == CPUW_PATH_RBC_TO_PUBLIC_REG ||
                path == CPUW_PATH_RBC_TO_PRIVATE_REG ||
                path == CPUW_PATH_RBC_TO_RBC_OUT);
      CPUW_PORT_MEM_DUMMY:
        return (path == CPUW_PATH_MEM_TO_RAM ||
                path == CPUW_PATH_MEM_TO_ROM);
      default:
        return 0;
    endcase
  endfunction

  function cpu_wrapper_path_e decode_path(
    bit [63:0] address,
    cpu_wrapper_port_e source_port = CPUW_PORT_CPU_AXI
  );
    for (int i = 0; i < CPUW_PATH_NUM; i++) begin
      if (path_source_matches(cpu_wrapper_path_e'(i), source_port) &&
          address >= m_cfg_h.m_path_base[i] &&
          address <= m_cfg_h.m_path_end[i]) begin
        return cpu_wrapper_path_e'(i);
      end
    end
    if (source_port == CPUW_PORT_RBC_DUMMY)
      return CPUW_PATH_RBC_TO_RBC_OUT;
    if (source_port == CPUW_PORT_MEM_DUMMY)
      return CPUW_PATH_MEM_TO_RAM;
    return CPUW_PATH_CPU_AXI_TO_AXI_HUB;
  endfunction

  function cpu_wrapper_port_e get_path_dest_cpuw_port(cpu_wrapper_path_e path);
    case (path)
      CPUW_PATH_CPU_AXI_TO_AXI_HUB:      return CPUW_PORT_AXI_HUB;
      CPUW_PATH_CPU_AXI_TO_RAM,
      CPUW_PATH_MEM_TO_RAM:              return CPUW_PORT_RAM_DUMMY;
      CPUW_PATH_CPU_AXI_TO_ROM,
      CPUW_PATH_MEM_TO_ROM:              return CPUW_PORT_ROM_DUMMY;
      CPUW_PATH_CPU_AXI_TO_PUBLIC_REG,
      CPUW_PATH_RBC_TO_PUBLIC_REG:       return CPUW_PORT_PUBLIC_REG_DUMMY;
      CPUW_PATH_CPU_AXI_TO_PRIVATE_REG,
      CPUW_PATH_RBC_TO_PRIVATE_REG:      return CPUW_PORT_PRIVATE_REG_DUMMY;
      CPUW_PATH_CPU_AXI_TO_RBC_OUT,
      CPUW_PATH_RBC_TO_RBC_OUT:          return CPUW_PORT_RBC_DUMMY;
      default:                           return CPUW_PORT_AXI_HUB;
    endcase
  endfunction

  protected function void publish_common(
    axi_crossbar_common_transaction item,
    axi_crossbar_common_side_e side,
    cpu_wrapper_path_e path,
    int unsigned legacy_dest_port
  );
`ifdef CPU_WRAPPER_SKEL
    if (item.access == AXI_COMMON_WRITE) begin
      if (side == AXI_COMMON_UPSTREAM)
        m_expected_wr_ap[path].write(item);
      else
        m_actual_wr_ap[path].write(item);
    end else begin
      if (side == AXI_COMMON_UPSTREAM)
        m_expected_rd_ap[path].write(item);
      else
        m_actual_rd_ap[path].write(item);
    end
`else
    if (side == AXI_COMMON_UPSTREAM)
      m_expected_ap[legacy_dest_port].write(item);
    else
      m_actual_ap[legacy_dest_port].write(item);
`endif
  endfunction

  protected function void convert_and_publish_common(
    uvm_object protocol_tr,
    axi_crossbar_common_adapter adapter,
    axi_crossbar_common_adapter_context ctx
  );
    axi_crossbar_common_transaction result[$];
    adapter.convert(protocol_tr, ctx, result);
    foreach (result[i])
      publish_common(result[i], ctx.side, ctx.path, ctx.dest_port);
  endfunction

  protected function axi_crossbar_common_adapter_context build_axi_context(
    axi_vip_transaction_t tr,
    axi_crossbar_common_side_e side,
    int unsigned port_index,
    output int dest_port,
    output cpu_wrapper_path_e path
  );
    axi_crossbar_common_adapter_context ctx;
    bit [63:0] tr_addr;

`ifdef AXI_VIP_SVT
    tr_addr = tr.addr;
`else
    tr_addr = tr.StartAddress;
`endif
    dest_port = decode_slave(tr_addr);
    path = decode_path(tr_addr, CPUW_PORT_CPU_AXI);

    ctx = axi_crossbar_common_adapter_context::type_id::create("axi_ctx");
    ctx.side = side;
    ctx.port_index = port_index;
    ctx.source_port = (side == AXI_COMMON_UPSTREAM) ? port_index : 0;
    ctx.dest_port = dest_port;
    ctx.path = path;
    ctx.source_cpuw_port = CPUW_PORT_CPU_AXI;
    ctx.dest_cpuw_port = get_path_dest_cpuw_port(path);
    ctx.data_width = `AXI_CROSSBAR_DATA_WIDTH;
    ctx.original_id_width = 8;
    ctx.downstream_id_contains_source = (side == AXI_COMMON_DOWNSTREAM);
    ctx.adapter_name = "AXI";
    return ctx;
  endfunction

  protected function axi_crossbar_common_adapter_context build_dummy_context(
    cpu_wrapper_dummy_transaction tr,
    axi_crossbar_common_side_e side,
    cpu_wrapper_port_e source_port,
    cpu_wrapper_port_e dest_port,
    cpu_wrapper_path_e path,
    string adapter_name
  );
    axi_crossbar_common_adapter_context ctx;
    ctx = axi_crossbar_common_adapter_context::type_id::create("dummy_ctx");
    ctx.side = side;
    ctx.port_index = 0;
    ctx.source_port = int'(source_port);
    ctx.dest_port = int'(dest_port);
    ctx.path = path;
    ctx.source_cpuw_port = source_port;
    ctx.dest_cpuw_port = dest_port;
    ctx.data_width = 1024;
    ctx.original_id_width = 0;
    ctx.downstream_id_contains_source = 0;
    ctx.adapter_name = adapter_name;
    return ctx;
  endfunction

  protected function void convert_and_publish(
    axi_vip_transaction_t tr,
    axi_crossbar_common_side_e side,
    int unsigned port_index
  );
    axi_crossbar_common_adapter_context ctx;
    int dest_port;
    cpu_wrapper_path_e path;
    bit [63:0] tr_addr;

`ifdef AXI_VIP_SVT
    tr_addr = tr.addr;
`else
    tr_addr = tr.StartAddress;
`endif
    dest_port = decode_slave(tr_addr);
    path = decode_path(tr_addr, CPUW_PORT_CPU_AXI);
    if (dest_port < 0 || dest_port >= `AXI_SLV_AGENT_NUM) begin
      `uvm_error(get_name(),
        $sformatf("transaction address does not map to a scoreboard endpoint"))
      return;
    end
    if (side == AXI_COMMON_DOWNSTREAM && dest_port != port_index) begin
      `uvm_error(get_name(),
        $sformatf("routing mismatch: address 0x%016h maps to slave%0d, observed on slave%0d",
          tr_addr, dest_port, port_index))
      return;
    end

    ctx = build_axi_context(tr, side, port_index, dest_port, path);
    convert_and_publish_common(tr, m_axi_adapter, ctx);
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

  protected function bit dummy_check_enabled(cpu_wrapper_dummy_transaction tr);
    return !m_cfg_h.m_enable_dummy_ports && tr.valid;
  endfunction

  protected function void report_dummy_drop(
    string handler_name,
    cpu_wrapper_dummy_transaction tr,
    axi_crossbar_common_adapter_context ctx
  );
    if (dummy_check_enabled(tr)) begin
      `uvm_error(get_name(),
        $sformatf("%s observed active dummy transaction while dummy ports are disabled:\n%s",
          handler_name, tr.sprint()))
    end else begin
      `uvm_info(get_name(),
        $sformatf("%s placeholder protocol=%s side=%0d path=%0d src=%0d dst=%0d addr=0x%016h access=%0d valid=%0b ready=%0b",
          handler_name, tr.protocol, ctx.side, ctx.path, ctx.source_cpuw_port,
          ctx.dest_cpuw_port, tr.address, tr.access, tr.valid, tr.ready),
        UVM_HIGH)
    end
  endfunction

  protected function void handle_dummy_placeholder(
    string handler_name,
    cpu_wrapper_dummy_transaction tr,
    axi_crossbar_common_side_e side,
    cpu_wrapper_port_e source_port,
    cpu_wrapper_port_e dest_port,
    cpu_wrapper_path_e path
  );
    axi_crossbar_common_adapter_context ctx;
    ctx = build_dummy_context(tr, side, source_port, dest_port, path, tr.protocol);
    report_dummy_drop(handler_name, tr, ctx);
  endfunction

  protected function void publish_dummy_expected(
    cpu_wrapper_dummy_transaction tr,
    cpu_wrapper_path_e path
  );
    axi_crossbar_common_adapter_context ctx;
    cpu_wrapper_port_e dest_port;
    dest_port = get_path_dest_cpuw_port(path);
    ctx = build_dummy_context(tr, AXI_COMMON_UPSTREAM, CPUW_PORT_MEM_DUMMY,
                              dest_port, path, tr.protocol);
    convert_and_publish_common(tr, m_dummy_adapter, ctx);
  endfunction

  protected function void publish_dummy_actual(
    cpu_wrapper_dummy_transaction tr,
    cpu_wrapper_path_e path
  );
    axi_crossbar_common_adapter_context ctx;
    cpu_wrapper_port_e dest_port;
    dest_port = get_path_dest_cpuw_port(path);
    ctx = build_dummy_context(tr, AXI_COMMON_DOWNSTREAM, CPUW_PORT_MEM_DUMMY,
                              dest_port, path, tr.protocol);
    convert_and_publish_common(tr, m_dummy_adapter, ctx);
  endfunction

  virtual function void handle_cpu_axi_to_axi_hub(axi_vip_transaction_t tr = null);
    `uvm_info(get_name(), "CPU AXI to AXI hub route is handled by AXI monitor FIFOs", UVM_HIGH)
  endfunction

  virtual function void handle_rbc_in(cpu_wrapper_dummy_transaction tr);
    cpu_wrapper_path_e path;
    tr.port = CPUW_DUMMY_RBC_IN;
    if (tr.protocol == "")
      tr.protocol = "RBC_IN_DUMMY";
    path = decode_path(tr.address, CPUW_PORT_RBC_DUMMY);
    handle_dummy_placeholder("handle_rbc_in", tr, AXI_COMMON_UPSTREAM,
                             CPUW_PORT_RBC_DUMMY, get_path_dest_cpuw_port(path), path);
  endfunction

  virtual function void handle_mem_in(cpu_wrapper_dummy_transaction tr);
    cpu_wrapper_path_e path;
    tr.port = CPUW_DUMMY_MEM_IN;
    if (tr.protocol == "")
      tr.protocol = "MEM_IN_DUMMY";
    path = decode_path(tr.address, CPUW_PORT_MEM_DUMMY);
    handle_dummy_placeholder("handle_mem_in", tr, AXI_COMMON_UPSTREAM,
                             CPUW_PORT_MEM_DUMMY, get_path_dest_cpuw_port(path), path);
  endfunction

  virtual function void handle_ram_out(cpu_wrapper_dummy_transaction tr);
    cpu_wrapper_path_e path;
    tr.port = CPUW_DUMMY_RAM_OUT;
    if (tr.protocol == "")
      tr.protocol = "RAM_OUT_DUMMY";
    path = decode_path(tr.address, CPUW_PORT_CPU_AXI);
    handle_dummy_placeholder("handle_ram_out", tr, AXI_COMMON_DOWNSTREAM,
                             CPUW_PORT_CPU_AXI, CPUW_PORT_RAM_DUMMY, path);
  endfunction

  virtual function void handle_rom_out(cpu_wrapper_dummy_transaction tr);
    cpu_wrapper_path_e path;
    tr.port = CPUW_DUMMY_ROM_OUT;
    if (tr.protocol == "")
      tr.protocol = "ROM_OUT_DUMMY";
    path = decode_path(tr.address, CPUW_PORT_CPU_AXI);
    handle_dummy_placeholder("handle_rom_out", tr, AXI_COMMON_DOWNSTREAM,
                             CPUW_PORT_CPU_AXI, CPUW_PORT_ROM_DUMMY, path);
  endfunction

  virtual function void handle_public_reg_out(cpu_wrapper_dummy_transaction tr);
    cpu_wrapper_path_e path;
    tr.port = CPUW_DUMMY_PUBLIC_REG_OUT;
    if (tr.protocol == "")
      tr.protocol = "PUBLIC_REG_OUT_DUMMY";
    path = decode_path(tr.address, CPUW_PORT_RBC_DUMMY);
    handle_dummy_placeholder("handle_public_reg_out", tr, AXI_COMMON_DOWNSTREAM,
                             CPUW_PORT_RBC_DUMMY, CPUW_PORT_PUBLIC_REG_DUMMY, path);
  endfunction

  virtual function void handle_private_reg_out(cpu_wrapper_dummy_transaction tr);
    cpu_wrapper_path_e path;
    tr.port = CPUW_DUMMY_PRIVATE_REG_OUT;
    if (tr.protocol == "")
      tr.protocol = "PRIVATE_REG_OUT_DUMMY";
    path = decode_path(tr.address, CPUW_PORT_RBC_DUMMY);
    handle_dummy_placeholder("handle_private_reg_out", tr, AXI_COMMON_DOWNSTREAM,
                             CPUW_PORT_RBC_DUMMY, CPUW_PORT_PRIVATE_REG_DUMMY, path);
  endfunction

  virtual function void handle_rbc_out(cpu_wrapper_dummy_transaction tr);
    cpu_wrapper_path_e path;
    tr.port = CPUW_DUMMY_RBC_OUT;
    if (tr.protocol == "")
      tr.protocol = "RBC_OUT_DUMMY";
    path = decode_path(tr.address, CPUW_PORT_RBC_DUMMY);
    handle_dummy_placeholder("handle_rbc_out", tr, AXI_COMMON_DOWNSTREAM,
                             CPUW_PORT_RBC_DUMMY, CPUW_PORT_RBC_DUMMY, path);
  endfunction

  protected task collect_rbc_in();
    cpu_wrapper_dummy_transaction tr;
    forever begin
      m_rbc_in_fifo.get(tr);
      handle_rbc_in(tr);
    end
  endtask

  protected task collect_mem_in();
    cpu_wrapper_dummy_transaction tr;
    forever begin
      m_mem_in_fifo.get(tr);
      handle_mem_in(tr);
    end
  endtask

  protected task collect_ram_out();
    cpu_wrapper_dummy_transaction tr;
    forever begin
      m_ram_out_fifo.get(tr);
      handle_ram_out(tr);
    end
  endtask

  protected task collect_rom_out();
    cpu_wrapper_dummy_transaction tr;
    forever begin
      m_rom_out_fifo.get(tr);
      handle_rom_out(tr);
    end
  endtask

  protected task collect_public_reg_out();
    cpu_wrapper_dummy_transaction tr;
    forever begin
      m_public_reg_out_fifo.get(tr);
      handle_public_reg_out(tr);
    end
  endtask

  protected task collect_private_reg_out();
    cpu_wrapper_dummy_transaction tr;
    forever begin
      m_private_reg_out_fifo.get(tr);
      handle_private_reg_out(tr);
    end
  endtask

  protected task collect_rbc_out();
    cpu_wrapper_dummy_transaction tr;
    forever begin
      m_rbc_out_fifo.get(tr);
      handle_rbc_out(tr);
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
    fork
      collect_rbc_in();
      collect_mem_in();
      collect_ram_out();
      collect_rom_out();
      collect_public_reg_out();
      collect_private_reg_out();
      collect_rbc_out();
    join_none
    wait fork;
  endtask
endclass
