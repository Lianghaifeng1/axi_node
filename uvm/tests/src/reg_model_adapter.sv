class reg_model_adapter extends uvm_reg_adapter;
  `uvm_object_utils(reg_model_adapter)

  integer data_size;
  function new(string name = "reg_model_adapter");
    super.new(name);
    provides_responses=1; // driver provides separate response items
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    // No register bus type configured - return null
    `uvm_info(get_type_name(), $sformatf("REG_DEBUG :: reg2bus called but no bus type configured"), UVM_MEDIUM)
    return null;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    // No register bus type configured
    `uvm_info(get_type_name(), $sformatf("REG_DEBUG :: bus2reg called but no bus type configured"), UVM_MEDIUM)
    rw.status = UVM_NOT_OK;
  endfunction
endclass