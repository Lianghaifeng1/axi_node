//------------------------------------------------------------------------------
// axi_crossbar test sanity
//------------------------------------------------------------------------------

class axi_crossbar_test_sanity extends axi_crossbar_test_base;

  `uvm_component_utils(axi_crossbar_test_sanity)

  axi_crossbar_test_vseq m_vseq_h;

  // Extern methods
  extern function               new(string name, uvm_component parent);
  extern virtual function void  build_phase(uvm_phase phase);
  extern virtual function void  connect_phase(uvm_phase phase);
  extern virtual task           vseq_run(uvm_phase phase);

endclass : axi_crossbar_test_sanity


//------------------------------------------------------------------------------
// new
//------------------------------------------------------------------------------
function axi_crossbar_test_sanity::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new


//------------------------------------------------------------------------------
// build_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_sanity::build_phase(uvm_phase phase);
`ifdef AXI_VIP_SVT
  uvm_config_db#(uvm_object_wrapper)::set(this,
    "m_env_h.m_axi_sys_env_h.slave*.sequencer.run_phase",
    "default_sequence", axi_crossbar_svt_slave_mem_response_seq::type_id::get());
`endif
  super.build_phase(phase);
  m_vseq_h = axi_crossbar_test_vseq::type_id::create("m_vseq_h", this);
endfunction : build_phase


//------------------------------------------------------------------------------
// connect_phase
//------------------------------------------------------------------------------
function void axi_crossbar_test_sanity::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase


//------------------------------------------------------------------------------
// vseq_run
//------------------------------------------------------------------------------
task axi_crossbar_test_sanity::vseq_run(uvm_phase phase);
  m_vseq_h.start(m_vseqr_h);
  `uvm_info(get_full_name(), "send item finished ...", UVM_LOW)
endtask : vseq_run
