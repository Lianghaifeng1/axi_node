//------------------------------------------------------------------------------
// axi_crossbar test virtual sequencer
//------------------------------------------------------------------------------

class axi_crossbar_test_vseqr extends uvm_sequencer#(uvm_sequence_item, uvm_sequence_item);

  `uvm_component_utils(axi_crossbar_test_vseqr)

  axi_crossbar_cfg m_cfg_h;

  //-------------------------------------------------------------------------
  // VIP sequencers (from Testbench.cdn_vip)
  //-------------------------------------------------------------------------
`ifdef AXI_VIP_SVT
  svt_axi_master_sequencer m_axi_mst_seqr_h[`AXI_MST_AGENT_NUM];
  svt_axi_slave_sequencer m_axi_slv_seqr_h[`AXI_SLV_AGENT_NUM];
`else
  cdnAxiUvmSequencer m_axi_mst_seqr_h[`AXI_MST_AGENT_NUM];
  cdnAxiUvmSequencer m_axi_slv_seqr_h[`AXI_SLV_AGENT_NUM];
`endif
  //-------------------------------------------------------------------------
  // Project agents' sequencers (from Testbench.Agents)
  //-------------------------------------------------------------------------
  // Extern method declarations
  extern function               new(string name, uvm_component parent);
  extern virtual function void  build_phase(uvm_phase phase);
  extern virtual function void  connect_phase(uvm_phase phase);
  extern virtual function void  end_of_elaboration_phase(uvm_phase phase);
  extern virtual function void  start_of_simulation_phase(uvm_phase phase);
  extern virtual task           run_phase(uvm_phase phase);
  extern virtual function void  extract_phase(uvm_phase phase);
  extern virtual function void  check_phase(uvm_phase phase);
  extern virtual function void  report_phase(uvm_phase phase);
  extern virtual function void  final_phase(uvm_phase phase);

endclass : axi_crossbar_test_vseqr


//------------------------------------------------------------------------------
// new
//------------------------------------------------------------------------------
function axi_crossbar_test_vseqr::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


//------------------------------------------------------------------------------
// build_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_vseqr::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(axi_crossbar_cfg)::get(this, "", "cfg", m_cfg_h)) begin
    `uvm_fatal(get_full_name(), "can't get m_cfg_h")
  end
endfunction : build_phase


//------------------------------------------------------------------------------
// connect_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_vseqr::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  `uvm_info(get_full_name(), "connect_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(), "connect_phase is exited",  UVM_MEDIUM)
endfunction : connect_phase


//------------------------------------------------------------------------------
// end_of_elaboration_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_vseqr::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  `uvm_info(get_full_name(), "end_of_elaboration_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(), "end_of_elaboration_phase is exited",  UVM_MEDIUM)
endfunction : end_of_elaboration_phase


//------------------------------------------------------------------------------
// start_of_simulation_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_vseqr::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
  `uvm_info(get_full_name(), "start_of_simulation_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(), "start_of_simulation_phase is exited",  UVM_MEDIUM)
endfunction : start_of_simulation_phase


//------------------------------------------------------------------------------
// run_phase
//------------------------------------------------------------------------------
task axi_crossbar_test_vseqr::run_phase(uvm_phase phase);
  super.run_phase(phase);
  `uvm_info(get_full_name(), "run_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(), "run_phase is exited",  UVM_MEDIUM)
endtask : run_phase


//------------------------------------------------------------------------------
// extract_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_vseqr::extract_phase(uvm_phase phase);
  super.extract_phase(phase);
  `uvm_info(get_full_name(), "extract_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(), "extract_phase is exited",  UVM_MEDIUM)
endfunction : extract_phase


//------------------------------------------------------------------------------
// check_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_vseqr::check_phase(uvm_phase phase);
  super.check_phase(phase);
  `uvm_info(get_full_name(), "check_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(), "check_phase is exited",  UVM_MEDIUM)
endfunction : check_phase


//------------------------------------------------------------------------------
// report_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_vseqr::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_full_name(), "report_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(), "report_phase is exited",  UVM_MEDIUM)
endfunction : report_phase


//------------------------------------------------------------------------------
// final_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_vseqr::final_phase(uvm_phase phase);
  super.final_phase(phase);
  `uvm_info(get_full_name(), "final_phase is entered", UVM_MEDIUM)

  `uvm_info(get_full_name(), "final_phase is exited",  UVM_MEDIUM)
endfunction : final_phase
