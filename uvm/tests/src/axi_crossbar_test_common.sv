class axi_crossbar_test_common extends uvm_test;

  `uvm_component_utils(axi_crossbar_test_common)

  axi_crossbar_dut_vif        m_dut_vif_h;
  axi_crossbar_cfg             m_cfg_h;
  bit                              sequence_run_done; //when sequence run completed, assert 1
  bit                              check_sequence_en; //if check sequence run done,1->check,0->no check
  string                           fm_case_prefix = "axi_crossbar_fm_test";//the prefix with firmware testcase
  int                              prefix_min = 0;
  int                              prefix_max = 14;

  extern function new(string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task vseq_run(uvm_phase phase);
  extern virtual function void case_set_config(string str,int num);
  //extern virtual task post_shutdown_phase(uvm_phase phase);
  extern function void final_phase(uvm_phase phase);

endclass : axi_crossbar_test_common


function axi_crossbar_test_common::new(string name, uvm_component parent);
  super.new(name, parent);
  sequence_run_done = 0;
  check_sequence_en = 1;
endfunction : new


function void axi_crossbar_test_common::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(axi_crossbar_dut_vif)::get(this, "", "vif",m_dut_vif_h)) begin
    `uvm_fatal(get_full_name(),"can't get dut_if for axi_crossbar_test_common")
  end
endfunction : build_phase


task axi_crossbar_test_common::run_phase(uvm_phase phase);
  uvm_objection objection;
  objection = phase.get_objection();
  objection.set_drain_time(this,1000);
  phase.raise_objection(this);
  repeat(m_cfg_h.m_check_log_start_time) begin
    #1ns;
  end
  `uvm_info(get_full_name(),"[SIMULATION START:] The simulation start to run from run_phase",UVM_NONE)
  @(m_dut_vif_h.sequence_starting);
  vseq_run(phase);
  sequence_run_done = 1;
  phase.drop_objection(this);
endtask : run_phase


function void axi_crossbar_test_common::case_set_config(string str,int num);
endfunction : case_set_config


task axi_crossbar_test_common::vseq_run(uvm_phase phase);
  #1us;
endtask : vseq_run


//task axi_crossbar_test_common::post_shutdown_phase(uvm_phase phase);
//  super.post_shutdown_phase(phase);
//  phase.raise_objection(this);
//  repeat(5) begin
//    @(posedge m_dut_vif_h.clk);
//  end
//  `uvm_info(get_full_name(),$sformatf("configuration stop_value=%0d,timeout_value=%0d",m_cfg_h.m_stop_value,m_cfg_h.m_timeout_value),UVM_LOW)
//  fork : check_simulation_end
//    begin
//      while(m_dut_vif_h.stop_count < m_cfg_h.m_stop_value) begin
//        @(posedge m_dut_vif_h.clk);
//      end
//    end
//    begin
//      while(m_dut_vif_h.timeout_count < m_cfg_h.m_timeout_value) begin
//        @(posedge m_dut_vif_h.clk);
//      end
//      `uvm_fatal(get_full_name(),$sformatf("[31:5m SIMULATION TIMEOUT [0m"))
//    end
//  join_any
//  disable check_simulation_end;
//
//  if((!sequence_run_done) & check_sequence_en) begin
//    `uvm_fatal(get_full_name(),$sformatf("The sequence is running, but there is not any data to be drived to (or sampled from) dut interface over %0d cycles(your configuration:m_stop_value)",m_cfg_h.m_stop_value))
//  end
//  #1us;
//  phase.drop_objection(this);
//endtask : post_shutdown_phase


function void axi_crossbar_test_common::final_phase(uvm_phase phase);
  uvm_report_server svr;  // define uvm report server handle
  super.final_phase(phase);
  svr = uvm_report_server::get_server();
  if(m_dut_vif_h.firmware_data_error) begin
    `uvm_error(get_full_name(),$sformatf("firmware read data is error!"))
  end
  if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) + svr.get_severity_count(UVM_WARNING)) begin
    `uvm_info(get_full_name(), " uvm_check_fail ",UVM_NONE)
  end
  else begin
    `uvm_info(get_full_name(), " uvm_check_pass ", UVM_NONE)
  end
endfunction : final_phase