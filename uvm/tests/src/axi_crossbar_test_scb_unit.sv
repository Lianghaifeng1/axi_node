class axi_crossbar_test_scb_unit extends uvm_test;
  `uvm_component_utils(axi_crossbar_test_scb_unit)

  axi_crossbar_scoreboard #(axi_crossbar_common_transaction) m_scb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_scb = axi_crossbar_scoreboard#(
      axi_crossbar_common_transaction
    )::type_id::create("m_scb", this);
    uvm_config_db#(int)::set(this, "m_scb", "m_min_trans_num", 3);
  endfunction

  function axi_crossbar_common_transaction make_item(bit [7:0] data);
    axi_crossbar_common_transaction item;
    item = axi_crossbar_common_transaction::type_id::create(
      $sformatf("item_%02h", data));
    item.access = AXI_COMMON_WRITE;
    item.address = 64'h1234;
    item.data = data;
    item.valid_mask = axi_crossbar_common_transaction::CMP_ACCESS |
                      axi_crossbar_common_transaction::CMP_ADDR |
                      axi_crossbar_common_transaction::CMP_DATA;
    return item;
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi_crossbar_common_transaction expected;
    axi_crossbar_common_transaction actual;
    string diff;

    phase.raise_objection(this);
    for (int i = 1; i <= 3; i++) begin
      expected = make_item(i);
      m_scb.m_expected_analysis_export.write(expected);
    end
    for (int i = 3; i >= 1; i--) begin
      actual = make_item(i);
      m_scb.m_actual_analysis_export.write(actual);
    end

    expected = make_item(8'h55);
    actual = make_item(8'haa);
    if (expected.compare_payload(actual, 32'hffff_ffff, diff))
      `uvm_fatal(get_name(), "payload mismatch was not detected")
    if (diff == "")
      `uvm_fatal(get_name(), "payload mismatch did not provide a diagnostic")

    #10ns;
    phase.drop_objection(this);
  endtask
endclass
