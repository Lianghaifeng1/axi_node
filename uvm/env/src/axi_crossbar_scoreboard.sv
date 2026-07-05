class axi_crossbar_scoreboard #(type T = axi_crossbar_common_transaction) extends uvm_scoreboard;
  typedef axi_crossbar_scoreboard #(T) this_type_t;
  `uvm_component_param_utils(this_type_t)

  protected uvm_tlm_analysis_fifo #(T) m_actual_analysis_fifo_h;
  protected uvm_tlm_analysis_fifo #(T) m_expected_analysis_fifo_h;
  uvm_analysis_export #(T) m_actual_analysis_export;
  uvm_analysis_export #(T) m_expected_analysis_export;

  protected T m_actual_pending[string][$];
  protected T m_expected_pending[string][$];

  bit m_scb_check_en;
  bit m_check_fifo_en;
  bit [31:0] m_compare_mask;
  int m_match_num;
  int m_mismatch_num;
  int m_missing_actual_num;
  int m_missing_expected_num;
  int m_min_trans_num;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_actual_analysis_fifo_h = new("m_actual_analysis_fifo_h", this);
    m_expected_analysis_fifo_h = new("m_expected_analysis_fifo_h", this);
    m_actual_analysis_export = new("m_actual_analysis_export", this);
    m_expected_analysis_export = new("m_expected_analysis_export", this);
    m_scb_check_en = 1;
    m_check_fifo_en = 1;
    m_compare_mask = 32'hffff_ffff;
    m_match_num = 0;
    m_mismatch_num = 0;
    m_missing_actual_num = 0;
    m_missing_expected_num = 0;
    m_min_trans_num = 0;
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_actual_analysis_export.connect(m_actual_analysis_fifo_h.analysis_export);
    m_expected_analysis_export.connect(m_expected_analysis_fifo_h.analysis_export);
  endfunction

  virtual task run_phase(uvm_phase phase);
    void'(uvm_config_db#(bit)::get(this, "", "m_scb_check_en", m_scb_check_en));
    void'(uvm_config_db#(bit [31:0])::get(this, "", "m_compare_mask", m_compare_mask));
    fork
      collect_expected();
      collect_actual();
    join
  endtask

  protected task collect_expected();
    T item;
    forever begin
      m_expected_analysis_fifo_h.get(item);
      if (m_scb_check_en)
        match_or_store(item, 1);
    end
  endtask

  protected task collect_actual();
    T item;
    forever begin
      m_actual_analysis_fifo_h.get(item);
      if (m_scb_check_en)
        match_or_store(item, 0);
    end
  endtask

  protected function void match_or_store(T item, bit is_expected);
    string key;
    string diff;
    int match_index;
    key = item.get_match_key(m_compare_mask);
    match_index = -1;

    if (is_expected) begin
      foreach (m_actual_pending[key][idx]) begin
        if (item.compare_payload(m_actual_pending[key][idx], m_compare_mask, diff)) begin
          match_index = idx;
          break;
        end
      end
      if (match_index >= 0) begin
        report_match(item, m_actual_pending[key][match_index], key);
        m_actual_pending[key].delete(match_index);
        if (m_actual_pending[key].size() == 0)
          m_actual_pending.delete(key);
        m_match_num++;
      end else begin
        m_expected_pending[key].push_back(item);
      end
    end else begin
      foreach (m_expected_pending[key][idx]) begin
        if (m_expected_pending[key][idx].compare_payload(item, m_compare_mask, diff)) begin
          match_index = idx;
          break;
        end
      end
      if (match_index >= 0) begin
        report_match(m_expected_pending[key][match_index], item, key);
        m_expected_pending[key].delete(match_index);
        if (m_expected_pending[key].size() == 0)
          m_expected_pending.delete(key);
        m_match_num++;
      end else begin
        m_actual_pending[key].push_back(item);
      end
    end
  endfunction

  protected function void report_match(T expected_item, T actual_item, string key);
    `uvm_info(get_name(),
      $sformatf("MATCH key=%s src=%0d dst=%0d id=0x%0h data=0x%02h",
        key,
        expected_item.source_port,
        expected_item.dest_port,
        expected_item.transaction_id,
        expected_item.data),
      UVM_MEDIUM)
  endfunction

  virtual function void flush_tlm_fifo();
    T item;
    while (m_expected_analysis_fifo_h.try_get(item));
    while (m_actual_analysis_fifo_h.try_get(item));
    m_expected_pending.delete();
    m_actual_pending.delete();
  endfunction

  protected function int pending_count(bit expected_side);
    int count;
    count = 0;
    if (expected_side) begin
      foreach (m_expected_pending[key])
        count += m_expected_pending[key].size();
    end else begin
      foreach (m_actual_pending[key])
        count += m_actual_pending[key].size();
    end
    return count;
  endfunction

  protected function void report_pending_mismatches();
    string diff;
    int pair_count;
    foreach (m_expected_pending[key]) begin
      if (m_actual_pending.exists(key)) begin
        pair_count = (m_expected_pending[key].size() < m_actual_pending[key].size()) ?
                     m_expected_pending[key].size() : m_actual_pending[key].size();
        for (int i = 0; i < pair_count; i++) begin
          void'(m_expected_pending[key][i].compare_payload(
            m_actual_pending[key][i], m_compare_mask, diff));
          `uvm_error(get_name(),
            $sformatf("MISMATCH key=%s: %s\nEXPECTED:\n%s\nACTUAL:\n%s",
              key,
              diff,
              m_expected_pending[key][i].sprint(),
              m_actual_pending[key][i].sprint()))
          m_mismatch_num++;
        end
      end
    end

    m_missing_actual_num = pending_count(1) - m_mismatch_num;
    m_missing_expected_num = pending_count(0) - m_mismatch_num;
    if (m_missing_actual_num < 0) m_missing_actual_num = 0;
    if (m_missing_expected_num < 0) m_missing_expected_num = 0;

    foreach (m_expected_pending[key]) begin
      foreach (m_expected_pending[key][idx])
        `uvm_info(get_name(),
          $sformatf("MISSING ACTUAL key=%s\nEXPECTED:\n%s", key,
                    m_expected_pending[key][idx].sprint()), UVM_NONE)
    end
    foreach (m_actual_pending[key]) begin
      foreach (m_actual_pending[key][idx])
        `uvm_info(get_name(),
          $sformatf("MISSING EXPECTED key=%s\nACTUAL:\n%s", key,
                    m_actual_pending[key][idx].sprint()), UVM_NONE)
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    void'(uvm_config_db#(bit)::get(this, "", "m_check_fifo_en", m_check_fifo_en));
    void'(uvm_config_db#(int)::get(this, "", "m_min_trans_num", m_min_trans_num));
    if (m_check_fifo_en)
      report_pending_mismatches();

    if (m_mismatch_num != 0 || m_missing_actual_num != 0 || m_missing_expected_num != 0) begin
      `uvm_error(get_name(),
        $sformatf("scoreboard failed: match=%0d mismatch=%0d missing_actual=%0d missing_expected=%0d",
          m_match_num, m_mismatch_num, m_missing_actual_num, m_missing_expected_num))
    end else if (m_match_num < m_min_trans_num) begin
      `uvm_error(get_name(),
        $sformatf("scoreboard received %0d matches, minimum is %0d", m_match_num, m_min_trans_num))
    end else begin
      `uvm_info(get_name(),
        $sformatf("scoreboard passed: match=%0d pending=0", m_match_num), UVM_LOW)
    end
  endfunction
endclass
