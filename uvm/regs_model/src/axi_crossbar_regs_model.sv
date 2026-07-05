// uvm_macros.svh is included in tb_top_define.sv, no need to include here
import uvm_pkg::*;

class axi_crossbar_regs_model extends uvm_reg_block;

  `uvm_object_utils(axi_crossbar_regs_model)

  function new(input string name = "axi_crossbar_regs_model");
    super.new(name, UVM_NO_COVERAGE);
  endfunction : new

  virtual function void build();
    default_map = create_map("default_map", 0, 1, UVM_LITTLE_ENDIAN, 1);
  endfunction : build

endclass