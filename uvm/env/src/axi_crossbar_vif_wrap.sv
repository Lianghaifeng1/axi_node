class vifs_wrap;
  string hier, name;
  virtual spdif1_dut_intf dut_vif;
  virtual clk_rst_if       hclk_rst_vif;
  virtual pins_if          irq_vif;
  static local vifs_wrap   m_inst;

  function new(string hier, string name = "");
    this.hier = hier;
    this.name = name;
  endfunction

  static function vifs_wrap get();
    if (m_inst == null) begin
      m_inst = new("tb_top", "vifs_wrap");
    end
    return m_inst;
  endfunction

  `DV_VIF_WRAP_GET_VIFS_BEGIN
    `DV_VIF_WRAP_GET_VIF(clk_rst_if, hclk_rst_vif)
    `DV_VIF_WRAP_GET_VIF(spdif1_dut_intf, dut_vif)
  `DV_VIF_WRAP_GET_VIFS_END
endclass