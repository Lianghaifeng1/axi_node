class axi_crossbar_test_reg extends axi_crossbar_test_base;

  `uvm_component_utils(axi_crossbar_test_reg)

  axi_crossbar_test_reg_vseq  m_vseq_h;

  extern function new(string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task vseq_run(uvm_phase phase);

endclass: axi_crossbar_test_reg

function axi_crossbar_test_reg::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction: new

function void axi_crossbar_test_reg::build_phase(uvm_phase phase);
  super.build_phase(phase);
  m_vseq_h = axi_crossbar_test_reg_vseq::type_id::create("m_vseq_h", this);

  //exclude reg of bit bash test
  //uvm_resource_db#(bit)::set({"REG::",`axi_crossbar_MODEL.get_full_name(),".axi_crossbar_INT0"}, "NO_REG_BIT_BASH_TEST", 1, this);

  //exclude reg of access test
  //uvm_resource_db#(bit)::set({"REG::",`axi_crossbar_MODEL.get_full_name(),".axi_crossbar_CNT0_L"}, "NO_REG_ACCESS_TEST", 1, this);
endfunction: build_phase

function void axi_crossbar_test_reg::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction: connect_phase

task axi_crossbar_test_reg::vseq_run(uvm_phase phase);
  m_vseq_h.start(m_vseqr_h);
  `uvm_info(get_full_name(),"reg_vseq is started ...", UVM_LOW)
endtask: vseq_run