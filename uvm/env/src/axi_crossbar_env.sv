class axi_crossbar_env extends uvm_env;
  `uvm_component_utils(axi_crossbar_env)

  cdnAxiUvmAgent m_axi_mst_agt_h[`AXI_MST_AGENT_NUM];
  cdnAxiUvmAgent m_axi_slv_agt_h[`AXI_SLV_AGENT_NUM];
  axi_crossbar_cfg m_cfg_h;//env configuration

  axi_crossbar_regs_model m_regs_model_h;
  axi_crossbar_ref_model m_ref_model_h;
  axi_crossbar_scoreboard #(axi_crossbar_common_transaction)
    m_slv_scb_h[`AXI_SLV_AGENT_NUM];

  extern function new(string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void extract_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);
  extern virtual function void report_phase(uvm_phase phase);
  extern virtual function void final_phase(uvm_phase phase);
endclass: axi_crossbar_env

//****************************************************************
//*********** new function definition          *******************
//****************************************************************
function axi_crossbar_env::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

//****************************************************************
//*********** build_phase definition           *******************
//****************************************************************
function void axi_crossbar_env::build_phase(uvm_phase phase);
  super.build_phase(phase);
  `uvm_info(get_full_name(),"build_phase is entered", UVM_MEDIUM)

  if (!uvm_config_db#(axi_crossbar_cfg)::get(this,"","cfg", m_cfg_h)) begin
    `uvm_fatal(get_full_name(), "Getting axi_crossbar_cfg failed,please check it!")
  end

  m_regs_model_h = m_cfg_h.m_dut_cfg_h.m_regs_model_h;

  m_ref_model_h = axi_crossbar_ref_model::type_id::create("m_ref_model_h", this);
  uvm_config_db#(axi_crossbar_cfg)::set(this, "m_ref_model_h", "cfg", m_cfg_h);
  for (int indx = 0; indx < `AXI_SLV_AGENT_NUM; indx++) begin
    m_slv_scb_h[indx] = axi_crossbar_scoreboard#(
      axi_crossbar_common_transaction
    )::type_id::create($sformatf("m_slv_scb_h[%0d]", indx), this);
    uvm_config_db#(int)::set(this,
      $sformatf("m_slv_scb_h[%0d]", indx), "m_min_trans_num", 1);
  end


for(int indx=0; indx<`AXI_MST_AGENT_NUM; indx++) begin
    if(m_cfg_h.m_has_axi_mst_agt_en[indx] == 1) begin
      m_axi_mst_agt_h[indx] = cdnAxiUvmAgent::type_id::create($sformatf("m_axi_mst_agt_h[%0d]",indx),this);
      uvm_config_object::set(this, $sformatf("m_axi_mst_agt_h[%0d]*",indx), "cfg", m_cfg_h.m_axi_mst_agt_cfg_h[indx]);
    end
  end
for(int indx=0; indx<`AXI_SLV_AGENT_NUM; indx++) begin
    if(m_cfg_h.m_has_axi_slv_agt_en[indx] == 1) begin
      m_axi_slv_agt_h[indx] = cdnAxiUvmAgent::type_id::create($sformatf("m_axi_slv_agt_h[%0d]",indx),this);
      uvm_config_object::set(this, $sformatf("m_axi_slv_agt_h[%0d]*",indx), "cfg", m_cfg_h.m_axi_slv_agt_cfg_h[indx]);
    end
  end
`uvm_info(get_full_name(),"build_phase is exited", UVM_MEDIUM)
endfunction : build_phase

//****************************************************************
//*********** connect_phase definition         *******************
//****************************************************************
function void axi_crossbar_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  `uvm_info(get_full_name(),"connect_phase is entered", UVM_MEDIUM)

  // ============================================================
  // 1. Agent Monitor -> Ref Model (输入)
  // ============================================================
  for (int indx = 0; indx < `AXI_MST_AGENT_NUM; indx++) begin
    if (m_cfg_h.m_has_axi_mst_agt_en[indx]) begin
      void'(m_axi_mst_agt_h[indx].setCallback(DENALI_CDN_AXI_CB_Ended));
      m_axi_mst_agt_h[indx].monitor.EndedCbPort.connect(
        m_ref_model_h.m_mst_fifo[indx].analysis_export);
    end
  end
  for (int indx = 0; indx < `AXI_SLV_AGENT_NUM; indx++) begin
    if (m_cfg_h.m_has_axi_slv_agt_en[indx]) begin
      void'(m_axi_slv_agt_h[indx].setCallback(DENALI_CDN_AXI_CB_Ended));
      m_axi_slv_agt_h[indx].monitor.EndedCbPort.connect(
        m_ref_model_h.m_slv_fifo[indx].analysis_export);
    end
  end

  // ============================================================
  // 2. Ref Model -> Scoreboard (Expected)
  // ============================================================
  for (int indx = 0; indx < `AXI_SLV_AGENT_NUM; indx++)
    m_ref_model_h.m_expected_ap[indx].connect(
      m_slv_scb_h[indx].m_expected_analysis_export);

  // ============================================================
  // 3. DUT Monitor -> Scoreboard (Actual)
  // ============================================================
  for (int indx = 0; indx < `AXI_SLV_AGENT_NUM; indx++)
    m_ref_model_h.m_actual_ap[indx].connect(
      m_slv_scb_h[indx].m_actual_analysis_export);

  `uvm_info(get_full_name(),"connect_phase is exited", UVM_MEDIUM)
endfunction : connect_phase

//****************************************************************
//*********** end_of_elaboration_phase definition***************
//****************************************************************
function void axi_crossbar_env::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  `uvm_info(get_full_name(),"end_of_elaboration_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(),"end_of_elaboration_phase is exited", UVM_MEDIUM)
endfunction : end_of_elaboration_phase

//****************************************************************
//*********** start_of_simulation_phase definition***************
//****************************************************************
function void axi_crossbar_env::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
  `uvm_info(get_full_name(),"start_of_simulation_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(),"start_of_simulation_phase is exited", UVM_MEDIUM)
endfunction : start_of_simulation_phase

//****************************************************************
//*********** run_phase definition             *******************
//****************************************************************
task axi_crossbar_env::run_phase(uvm_phase phase);
  super.run_phase(phase);
  `uvm_info(get_full_name(),"run_phase is entered", UVM_MEDIUM)
  #1ns;

`uvm_info(get_full_name(),"run_phase is exited", UVM_MEDIUM)
endtask : run_phase

//****************************************************************
//*********** extract_phase definition         *******************
//****************************************************************
function void axi_crossbar_env::extract_phase(uvm_phase phase);
  super.extract_phase(phase);
  `uvm_info(get_full_name(),"extract_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(),"extract_phase is exited", UVM_MEDIUM)
endfunction : extract_phase

//****************************************************************
//*********** check_phase definition           *******************
//****************************************************************
function void axi_crossbar_env::check_phase(uvm_phase phase);
  super.check_phase(phase);
  `uvm_info(get_full_name(),"check_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(),"check_phase is exited", UVM_MEDIUM)
endfunction : check_phase

//****************************************************************
//*********** report_phase definition          *******************
//****************************************************************
function void axi_crossbar_env::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_full_name(),"report_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(),"report_phase is exited", UVM_MEDIUM)
endfunction : report_phase

//****************************************************************
//*********** final_phase definition           *******************
//****************************************************************
function void axi_crossbar_env::final_phase(uvm_phase phase);
  super.final_phase(phase);
  `uvm_info(get_full_name(),"final_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(),"final_phase is exited", UVM_MEDIUM)
endfunction : final_phase
