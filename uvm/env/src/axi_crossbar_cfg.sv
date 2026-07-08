 
class axi_crossbar_cfg extends uvm_object;

  // ------------------------------------------------------------
  // presence flags (per-agent)
  // ------------------------------------------------------------
  

  
  
  bit m_has_axi_mst_agt_en[`AXI_MST_AGENT_NUM ];
  
  bit m_has_axi_slv_agt_en[`AXI_SLV_AGENT_NUM ];
  
  

  // ------------------------------------------------------------
  // basic knobs
  // ------------------------------------------------------------
  integer m_stop_value;
  integer m_timeout_value;
  integer m_check_log_start_time;
  bit [63:0] m_endpoint_base[`AXI_SLV_AGENT_NUM];
  bit [63:0] m_endpoint_end[`AXI_SLV_AGENT_NUM];
  bit [63:0] m_path_base[CPUW_PATH_NUM];
  bit [63:0] m_path_end[CPUW_PATH_NUM];
  int unsigned m_path_slv_idx[CPUW_PATH_NUM];
  int unsigned m_cpu_axi_agt_idx;
  int unsigned m_axi_hub_agt_idx;
  bit m_enable_dummy_ports;

  // ------------------------------------------------------------
  // agent cfg handles
  // ------------------------------------------------------------
  

  
  
`ifdef AXI_VIP_SVT
  rand svt_axi_system_configuration m_axi_sys_cfg_h;
`else
  rand cdnAxiUvmConfig m_axi_mst_agt_cfg_h[`AXI_MST_AGENT_NUM ];
  rand cdnAxiUvmConfig m_axi_slv_agt_cfg_h[`AXI_SLV_AGENT_NUM ];
`endif
  
  

  

  

  // ------------------------------------------------------------
  // ref model enable flag
  // ------------------------------------------------------------
  

  // ------------------------------------------------------------
  // scoreboard enable flags (per-scoreboard)
  // ------------------------------------------------------------
  

  // ------------------------------------------------------------
  // top-level dut cfg
  // ------------------------------------------------------------
  rand axi_crossbar_dut_cfg m_dut_cfg_h; // all sub dut cfg is instantiated under this cfg

  `uvm_object_utils_begin(axi_crossbar_cfg)
    `uvm_field_object(m_dut_cfg_h, UVM_ALL_ON)
  `uvm_object_utils_end

  extern function new(string name = "axi_crossbar_cfg");

endclass : axi_crossbar_cfg

function axi_crossbar_cfg::new(string name = "axi_crossbar_cfg");
  super.new(name);

  m_dut_cfg_h = axi_crossbar_dut_cfg::type_id::create("m_dut_cfg_h");
  m_stop_value = 10000;
  m_timeout_value = 10000;
  m_check_log_start_time = 30;
  m_cpu_axi_agt_idx = 0;
  m_axi_hub_agt_idx = 0;
  m_enable_dummy_ports = 1;
  m_endpoint_base[0] = 64'h0000_0000;
`ifdef CPU_WRAPPER_SKEL
  m_endpoint_end[0]  = 64'hffff_ffff;
`else
  m_endpoint_end[0]  = 64'h0fff_ffff;
`endif
  m_endpoint_base[1] = 64'h1000_0000;
  m_endpoint_end[1]  = 64'h1fff_ffff;
  foreach (m_path_base[path]) begin
    m_path_base[path] = 64'hffff_ffff_ffff_ffff;
    m_path_end[path] = 64'h0;
    m_path_slv_idx[path] = 0;
  end
`ifdef CPU_WRAPPER_SKEL
  m_path_base[CPUW_PATH_CPU_AXI_TO_AXI_HUB] = 64'h0000_0000;
  m_path_end[CPUW_PATH_CPU_AXI_TO_AXI_HUB] = 64'hffff_ffff;
`else
  m_path_base[CPUW_PATH_CPU_AXI_TO_AXI_HUB] = m_endpoint_base[0];
  m_path_end[CPUW_PATH_CPU_AXI_TO_AXI_HUB] = m_endpoint_end[0];
`endif
  m_path_slv_idx[CPUW_PATH_CPU_AXI_TO_AXI_HUB] = m_axi_hub_agt_idx;

`ifdef AXI_VIP_SVT
  m_axi_sys_cfg_h = svt_axi_system_configuration::type_id::create("m_axi_sys_cfg_h");
  m_axi_sys_cfg_h.num_masters = `AXI_MST_AGENT_NUM;
  m_axi_sys_cfg_h.num_slaves = `AXI_SLV_AGENT_NUM;
  m_axi_sys_cfg_h.system_monitor_enable = 1;
  m_axi_sys_cfg_h.create_sub_cfgs(`AXI_MST_AGENT_NUM, `AXI_SLV_AGENT_NUM);
  for (int indx = 0; indx < `AXI_MST_AGENT_NUM; indx++) begin
`ifdef CPU_WRAPPER_SKEL
    m_has_axi_mst_agt_en[indx] = (indx == int'(m_cpu_axi_agt_idx));
`else
    m_has_axi_mst_agt_en[indx] = 1;
`endif
    m_axi_sys_cfg_h.master_cfg[indx].data_width = 32;
    m_axi_sys_cfg_h.master_cfg[indx].axi_interface_type = svt_axi_port_configuration::AXI4;
    m_axi_sys_cfg_h.master_cfg[indx].addr_width = 32;
    m_axi_sys_cfg_h.master_cfg[indx].id_width = 8;
    m_axi_sys_cfg_h.master_cfg[indx].transaction_coverage_enable = 1;
  end
  for (int indx = 0; indx < `AXI_SLV_AGENT_NUM; indx++) begin
`ifdef CPU_WRAPPER_SKEL
    m_has_axi_slv_agt_en[indx] = (indx == int'(m_axi_hub_agt_idx));
`else
    m_has_axi_slv_agt_en[indx] = 1;
`endif
    m_axi_sys_cfg_h.slave_cfg[indx].data_width = 32;
    m_axi_sys_cfg_h.slave_cfg[indx].axi_interface_type = svt_axi_port_configuration::AXI4;
    m_axi_sys_cfg_h.slave_cfg[indx].addr_width = 32;
    m_axi_sys_cfg_h.slave_cfg[indx].id_width = 9;
    m_axi_sys_cfg_h.slave_cfg[indx].transaction_coverage_enable = 1;
    m_axi_sys_cfg_h.slave_cfg[indx].reordering_algorithm = svt_axi_port_configuration::RANDOM;
  end
  for (int indx = 0; indx < `AXI_SLV_AGENT_NUM; indx++) begin
    if (m_has_axi_slv_agt_en[indx])
      m_axi_sys_cfg_h.set_addr_range(indx, m_endpoint_base[indx], m_endpoint_end[indx]);
  end
`else
  for (int indx = 0; indx < `AXI_MST_AGENT_NUM; indx++) begin
      m_axi_mst_agt_cfg_h[indx] =
        cdnAxiUvmConfig::type_id::create(
          $sformatf("m_axi_mst_agt_cfg_h[%0d]", indx)
        );
      m_axi_mst_agt_cfg_h[indx].spec_ver = CDN_AXI_CFG_SPEC_VER_AMBA4;
      m_axi_mst_agt_cfg_h[indx].spec_subtype = CDN_AXI_CFG_SPEC_SUBTYPE_BASE;
      m_axi_mst_agt_cfg_h[indx].spec_interface = CDN_AXI_CFG_SPEC_INTERFACE_FULL;
      m_axi_mst_agt_cfg_h[indx].PortType = CDN_AXI_CFG_MASTER;
      m_axi_mst_agt_cfg_h[indx].reset_signals_sim_start = 1;
      m_axi_mst_agt_cfg_h[indx].verbosity = CDN_AXI_CFG_MESSAGEVERBOSITY_LOW;
      m_axi_mst_agt_cfg_h[indx].no_changes_in_address_channels_limit = 100;
      m_axi_mst_agt_cfg_h[indx].max_write_bursts_behavior =
        CDN_AXI_CFG_MAX_WRITE_BURSTS_BEHAVIOR_CONTINUE_TO_SEND;
      m_axi_mst_agt_cfg_h[indx].write_issuing_capability = 7;
      m_axi_mst_agt_cfg_h[indx].read_issuing_capability = 16;
      m_axi_mst_agt_cfg_h[indx].write_issuing_capability = 16;
      m_axi_mst_agt_cfg_h[indx].addToMemorySegments(
        64'h0000_0000, 64'h0fff_ffff, CDN_AXI_CFG_DOMAIN_NON_SHAREABLE
      );
      m_axi_mst_agt_cfg_h[indx].addToMemorySegments(
        64'h1000_0000, 64'h1fff_ffff, CDN_AXI_CFG_DOMAIN_NON_SHAREABLE
      );
`ifdef CPU_WRAPPER_SKEL
      m_has_axi_mst_agt_en[indx] = (indx == int'(m_cpu_axi_agt_idx));
`else
      m_has_axi_mst_agt_en[indx] = 1;
`endif
  
  end
  for (int indx = 0; indx < `AXI_SLV_AGENT_NUM; indx++) begin
      m_axi_slv_agt_cfg_h[indx] =
        cdnAxiUvmConfig::type_id::create(
          $sformatf("m_axi_slv_agt_cfg_h[%0d]", indx)
        );
      m_axi_slv_agt_cfg_h[indx].spec_ver = CDN_AXI_CFG_SPEC_VER_AMBA4;
      m_axi_slv_agt_cfg_h[indx].spec_subtype = CDN_AXI_CFG_SPEC_SUBTYPE_BASE;
      m_axi_slv_agt_cfg_h[indx].spec_interface = CDN_AXI_CFG_SPEC_INTERFACE_FULL;
      m_axi_slv_agt_cfg_h[indx].PortType = CDN_AXI_CFG_SLAVE;
      m_axi_slv_agt_cfg_h[indx].reset_signals_sim_start = 1;
      m_axi_slv_agt_cfg_h[indx].verbosity = CDN_AXI_CFG_MESSAGEVERBOSITY_LOW;
      m_axi_slv_agt_cfg_h[indx].do_signal_check_only_when_valid = 1;
      m_axi_slv_agt_cfg_h[indx].no_changes_in_address_channels_limit = 100;
      m_axi_slv_agt_cfg_h[indx].write_acceptance_capability = 6;
      m_axi_slv_agt_cfg_h[indx].read_acceptance_capability = 16;
      m_axi_slv_agt_cfg_h[indx].write_acceptance_capability = 16;
      m_axi_slv_agt_cfg_h[indx].read_data_reordering_depth = 16;
      m_axi_slv_agt_cfg_h[indx].disable_memory_update_on_write_burst = 0;
      m_axi_slv_agt_cfg_h[indx].addToMemorySegments(
        m_endpoint_base[indx],
        m_endpoint_end[indx],
        CDN_AXI_CFG_DOMAIN_NON_SHAREABLE
      );
`ifdef CPU_WRAPPER_SKEL
      m_has_axi_slv_agt_en[indx] = (indx == int'(m_axi_hub_agt_idx));
`else
      m_has_axi_slv_agt_en[indx] = 1;
`endif
  
  end
`endif

  
endfunction : new
