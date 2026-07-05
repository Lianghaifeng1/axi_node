class axi_crossbar_test_base_vseq extends uvm_sequence#(uvm_sequence_item,uvm_sequence_item);

`uvm_object_utils(axi_crossbar_test_base_vseq)
`uvm_declare_p_sequencer(axi_crossbar_test_vseqr)

int value;
int period;
uvm_status_e stat;
uvm_reg_data_t wdata;
uvm_reg_data_t rdata;
axi_crossbar_cfg     m_cfg_h;
axi_crossbar_dut_vif m_dut_vif_h;



//clk rst interface
virtual clk_rst_if aclk_rst_vif;

cdnAxiUvmSequencer m_axi_mst_seqr_h[`AXI_MST_AGENT_NUM];

cdnAxiUvmSequencer m_axi_slv_seqr_h[`AXI_SLV_AGENT_NUM];
extern function new(string name="axi_crossbar_test_base_vseq");
extern virtual task pre_body();
extern virtual task system_config();

`include "./intr_utils.svh"
`include "./intr_response_flow.svh"
`include "./common_task.sv"
endclass : axi_crossbar_test_base_vseq

function axi_crossbar_test_base_vseq::new(string name="axi_crossbar_test_base_vseq");
  super.new(name);
endfunction : new

task axi_crossbar_test_base_vseq::pre_body();
  super.pre_body();
  if (!uvm_config_db#(axi_crossbar_cfg)::get(m_sequencer, "", "cfg", m_cfg_h)) begin
    `uvm_fatal(get_name(),"can't get m_cfg_h")
  end

  if (!uvm_config_db#(axi_crossbar_dut_vif)::get(m_sequencer, "", "vif", m_dut_vif_h)) begin
    `uvm_fatal(get_name(),"can't get dut_if")
  end

  if (!uvm_config_db#(virtual clk_rst_if)::get(m_sequencer, "", "aclk_rst_vif", aclk_rst_vif)) begin
    `uvm_fatal(get_full_name(),"Getting aclk_rst_vif failed,please check it!")
  end
  aclk_rst_vif.apply_reset();

  for(int indx=0;indx<`AXI_MST_AGENT_NUM;indx++) begin
    if(m_cfg_h.m_has_axi_mst_agt_en[indx] == 1) begin
      m_axi_mst_seqr_h[indx] = p_sequencer.m_axi_mst_seqr_h[indx];
    end
  end

  for(int indx=0;indx<`AXI_SLV_AGENT_NUM;indx++) begin
    if(m_cfg_h.m_has_axi_slv_agt_en[indx] == 1) begin
      m_axi_slv_seqr_h[indx] = p_sequencer.m_axi_slv_seqr_h[indx];
    end
  end


  system_config();
  init_intr_map();
  `uvm_info(get_name(),"finished system configuration ",UVM_LOW)
endtask : pre_body

task axi_crossbar_test_base_vseq::system_config();
  uvm_status_e   stat;
  uvm_reg_data_t wdata;
  uvm_reg_data_t rdata;

endtask : system_config