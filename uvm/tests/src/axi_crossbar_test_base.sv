//------------------------------------------------------------------------------
// axi_crossbar test base
//------------------------------------------------------------------------------

class axi_crossbar_test_base extends axi_crossbar_test_common;

  `uvm_component_utils(axi_crossbar_test_base)

  axi_crossbar_env                m_env_h;
  axi_crossbar_test_vseqr          m_vseqr_h;
  reg_model_adapter                   m_adapter_h;
  reg_model_adapter                   m_word_adapter_h;
  axi_crossbar_regs_model                  m_regs_model_h;
  axi_crossbar_word_access_regs_model      m_word_regs_model_h;


  extern function new(string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : axi_crossbar_test_base


function axi_crossbar_test_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


function void axi_crossbar_test_base::build_phase(uvm_phase phase);
  super.build_phase(phase);

  m_cfg_h  = axi_crossbar_cfg::type_id::create("m_cfg_h", this);

  m_env_h  = axi_crossbar_env::type_id::create("m_env_h", this);
  uvm_config_db#(axi_crossbar_cfg)::set(this, "m_env_h", "cfg", m_cfg_h);

  m_vseqr_h = axi_crossbar_test_vseqr::type_id::create("m_vseqr_h", this);
  uvm_config_db#(axi_crossbar_cfg)::set(this, "m_vseqr_h", "cfg", m_cfg_h);

    m_regs_model_h = axi_crossbar_regs_model::type_id::create("m_regs_model_h",this);
    m_regs_model_h.build();
    m_regs_model_h.configure(null,"tb_top");
    m_regs_model_h.lock_model();
    m_regs_model_h.reset();

    m_word_regs_model_h = axi_crossbar_word_access_regs_model::type_id::create("m_word_regs_model_h",this);
    m_word_regs_model_h.build();
    m_word_regs_model_h.configure(null,"tb_top");
    m_word_regs_model_h.lock_model();
    m_word_regs_model_h.reset();

  m_adapter_h      = reg_model_adapter::type_id::create("m_adapter_h");
  m_word_adapter_h = reg_model_adapter::type_id::create("m_word_adapter_h");

  m_cfg_h.m_dut_cfg_h.m_regs_model_h = m_regs_model_h ;
  m_cfg_h.m_dut_cfg_h.m_path         = UVM_FRONTDOOR ;

  m_cfg_h.m_dut_cfg_h.m_word_regs_model_h = m_word_regs_model_h ;
  m_cfg_h.m_dut_cfg_h.m_path         = UVM_FRONTDOOR ;

endfunction : build_phase


function void axi_crossbar_test_base::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  if(uvm_report_enabled(UVM_MEDIUM,UVM_INFO,get_name())) begin
    uvm_top.print_topology();
  end


  for(int indx=0; indx<`AXI_MST_AGENT_NUM; indx++) begin
    if(m_cfg_h.m_has_axi_mst_agt_en[indx] == 1) begin
      if(!$cast(m_vseqr_h.m_axi_mst_seqr_h[indx], m_env_h.m_axi_mst_agt_h[indx].sequencer)) begin
        `uvm_fatal(get_type_name(),
                   $sformatf("$cast(m_vseqr_h.m_axi_mst_seqr_h[indx], m_env_h.m_axi_mst_agt_h[indx].sequencer )) call failed!"));
      end
    end
  end

  for(int indx=0; indx<`AXI_SLV_AGENT_NUM; indx++) begin
    if(m_cfg_h.m_has_axi_slv_agt_en[indx] == 1) begin
      if(!$cast(m_vseqr_h.m_axi_slv_seqr_h[indx], m_env_h.m_axi_slv_agt_h[indx].sequencer)) begin
        `uvm_fatal(get_type_name(),
                   $sformatf("$cast(m_vseqr_h.m_axi_slv_seqr_h[indx], m_env_h.m_axi_slv_agt_h[indx].sequencer )) call failed!"));
      end
    end
  end

  // No dedicated register bus monitor/predictor is instantiated in this AXI crossbar skeleton.
  // Keep RAL models available for future frontdoor/backdoor expansion, but disable predictor hookup.
  m_regs_model_h.default_map.set_auto_predict(0);
  m_word_regs_model_h.default_map.set_auto_predict(0);

  if(!$test$plusargs("NO_TIMEOUT")) uvm_top.set_timeout(400ms,0);

endfunction : connect_phase
