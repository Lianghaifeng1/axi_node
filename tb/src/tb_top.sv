module tb_top;
  //import uvm package
  import uvm_pkg::*;
  import dv_utils_pkg::*;
  // Import the DDVAPI AHB SV interface and the generic Mem interface
  import axi_crossbar_env_pkg::*;
  import axi_crossbar_test_pkg::*;
`ifdef AXI_VIP_SVT
  import svt_uvm_pkg::*;
  import svt_axi_uvm_pkg::*;
`endif

  //signals definition
  wire       sys_clk;
  wire       sys_rstn;
  reg        pon_rst;
  bit [31:0] stop_count;
  bit [31:0] timeout_count;
  reg        firmware_case_done;

  bit        sequence_starting;

  initial begin
    pon_rst            = 1'b0;
    sequence_starting  = 1'b0;
    #100ns;
    pon_rst           = 1'b1;
    sequence_starting = 1'b1;
  end

  axi_crossbar_dut_intf dut_intf();

`ifndef ONLY_COMP_TB
  //instantiate DUT
  `include "dut_inst.sv"
  assign clk = sys_clk;
  assign rst = ~sys_rstn;
`endif

  reg error_flag;
  reg c_end_flag;
  assign dut_intf.clk                = sys_clk;
  assign dut_intf.rst_n              = sys_rstn;
  assign dut_intf.sequence_starting  = sequence_starting;
  assign dut_intf.stop_count         = stop_count;
  assign dut_intf.timeout_count      = timeout_count;
  assign dut_intf.firmware_case_done = firmware_case_done;
  assign dut_intf.firmware_data_error= error_flag;
  assign dut_intf.c_end_flag         = c_end_flag;

  wire tran_valid = 1'b1;
  reg  bus_tran_d1;
  reg  bus_tran_d2;

  wire bus_tran_chg = (bus_tran_d1 != bus_tran_d2);
  reg  bus_tran_chg_d1;
  wire bus_valid    = bus_tran_chg | bus_tran_chg_d1;

  always @(posedge sys_clk or negedge sys_rstn) begin
    if (sys_rstn != 1'b1) begin
      bus_tran_d1     <= 1'b0;
      bus_tran_d2     <= 1'b0;
      bus_tran_chg_d1 <= 1'b0;
    end else begin
      bus_tran_d1     <= tran_valid;
      bus_tran_d2     <= bus_tran_d1;
      bus_tran_chg_d1 <= bus_tran_chg;
    end
  end

  wire clear_dmac_en;
  assign clear_dmac_en = (bus_valid === 1'b1) || 1'b0;
  wire clear_en;
  assign clear_en = clear_dmac_en;

  always @(posedge sys_clk or negedge sys_rstn) begin
    if (!sys_rstn) begin
      stop_count <= 32'd0;
    end else if (clear_en === 1'b1) begin
      stop_count <= 32'd0;
    end else if (clear_en == 1'b0) begin
      stop_count <= stop_count + 1;
    end
  end

  always @(posedge sys_clk or negedge sys_rstn) begin
    if (!sys_rstn) begin
      timeout_count <= 32'd0;
    end else if (clear_en === 1'b1) begin
      timeout_count <= timeout_count + 1;
    end else begin
      timeout_count <= 32'd0;
    end
  end

  integer start_dump = 0;
  integer end_dump   = 0;
  `ifdef FSDB
  initial begin
    if ($test$plusargs("WAVE_DUMP_EN")) begin
      if ($value$plusargs("START_TIME=%d", start_dump)) begin
        repeat (start_dump) begin
          #1us;
        end
      end

      $fsdbDumpfile("axi_crossbar.fsdb");
      $fsdbDumpvars(0, tb_top);
      $fsdbDumpSVA(0, tb_top);
      $fsdbDumpMDA(0, tb_top);
      $fsdbDumpon;

      if ($value$plusargs("END_TIME=%d", end_dump)) begin
        repeat ((end_dump - start_dump)) begin
          #1us;
        end
        $fsdbDumpoff;
      end
    end
  end
  `endif

  clk_rst_if aclk_rst_if(
    .clk  (sys_clk),
    .rst_n(sys_rstn)
  );


`ifndef AXI_VIP_SVT
generate
    for (genvar i = 0; i < `AXI_MST_AGENT_NUM; i++) begin : axi_mst_if
      cdnAxi4ActiveMasterInterface #(
        .ID_WIDTH(S_ID_WIDTH),
        .READ_ID_WIDTH(S_ID_WIDTH),
        .WRITE_ID_WIDTH(S_ID_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .READ_DATA_WIDTH(DATA_WIDTH),
        .WRITE_DATA_WIDTH(DATA_WIDTH),
        .USER_WIDTH(WUSER_WIDTH),
        .ADDR_USER_WIDTH(AWUSER_WIDTH),
        .RESP_USER_WIDTH(BUSER_WIDTH)
      ) cdnAxi4ActiveMasterInterface (
        .aclk(sys_clk),
        .aresetn(sys_rstn),
        .awvalid(s_axi_awvalid[i]),
        .awaddr(s_axi_awaddr[i*ADDR_WIDTH +: ADDR_WIDTH]),
        .awlen(s_axi_awlen[i*8 +: 8]),
        .awsize(s_axi_awsize[i*3 +: 3]),
        .awburst(s_axi_awburst[i*2 +: 2]),
        .awlock(s_axi_awlock[i]),
        .awcache(s_axi_awcache[i*4 +: 4]),
        .awprot(s_axi_awprot[i*3 +: 3]),
        .awregion(),
        .awqos(s_axi_awqos[i*4 +: 4]),
        .awid(s_axi_awid[i*S_ID_WIDTH +: S_ID_WIDTH]),
        .awready(s_axi_awready[i]),
        .awuser(s_axi_awuser[i*AWUSER_WIDTH +: AWUSER_WIDTH]),
        .wvalid(s_axi_wvalid[i]),
        .wlast(s_axi_wlast[i]),
        .wdata(s_axi_wdata[i*DATA_WIDTH +: DATA_WIDTH]),
        .wstrb(s_axi_wstrb[i*STRB_WIDTH +: STRB_WIDTH]),
        .wready(s_axi_wready[i]),
        .wuser(s_axi_wuser[i*WUSER_WIDTH +: WUSER_WIDTH]),
        .bvalid(s_axi_bvalid[i]),
        .bresp(s_axi_bresp[i*2 +: 2]),
        .bid(s_axi_bid[i*S_ID_WIDTH +: S_ID_WIDTH]),
        .bready(s_axi_bready[i]),
        .buser(s_axi_buser[i*BUSER_WIDTH +: BUSER_WIDTH]),
        .arvalid(s_axi_arvalid[i]),
        .araddr(s_axi_araddr[i*ADDR_WIDTH +: ADDR_WIDTH]),
        .arlen(s_axi_arlen[i*8 +: 8]),
        .arsize(s_axi_arsize[i*3 +: 3]),
        .arburst(s_axi_arburst[i*2 +: 2]),
        .arlock(s_axi_arlock[i]),
        .arcache(s_axi_arcache[i*4 +: 4]),
        .arprot(s_axi_arprot[i*3 +: 3]),
        .arregion(),
        .arqos(s_axi_arqos[i*4 +: 4]),
        .arid(s_axi_arid[i*S_ID_WIDTH +: S_ID_WIDTH]),
        .arready(s_axi_arready[i]),
        .aruser(s_axi_aruser[i*ARUSER_WIDTH +: ARUSER_WIDTH]),
        .rvalid(s_axi_rvalid[i]),
        .rlast(s_axi_rlast[i]),
        .rdata(s_axi_rdata[i*DATA_WIDTH +: DATA_WIDTH]),
        .rresp(s_axi_rresp[i*2 +: 2]),
        .rid(s_axi_rid[i*S_ID_WIDTH +: S_ID_WIDTH]),
        .rready(s_axi_rready[i]),
        .ruser(s_axi_ruser[i*RUSER_WIDTH +: RUSER_WIDTH])
      );
      initial begin
        uvm_config_string::set(null,
          $sformatf("uvm_test_top.m_env_h.m_axi_mst_agt_h[%0d]", i),
          "hdlPath",
          $sformatf("tb_top.axi_mst_if[%0d].cdnAxi4ActiveMasterInterface", i)
        );
      end
    end
endgenerate
generate
    for (genvar i = 0; i < `AXI_SLV_AGENT_NUM; i++) begin : axi_slv_if
      cdnAxi4ActiveSlaveInterface #(
        .ID_WIDTH(M_ID_WIDTH),
        .READ_ID_WIDTH(M_ID_WIDTH),
        .WRITE_ID_WIDTH(M_ID_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .READ_DATA_WIDTH(DATA_WIDTH),
        .WRITE_DATA_WIDTH(DATA_WIDTH),
        .USER_WIDTH(WUSER_WIDTH),
        .ADDR_USER_WIDTH(AWUSER_WIDTH),
        .RESP_USER_WIDTH(BUSER_WIDTH)
      ) cdnAxi4ActiveSlaveInterface (
        .aclk(sys_clk),
        .aresetn(sys_rstn),
        .awvalid(m_axi_awvalid[i]),
        .awaddr(m_axi_awaddr[i*ADDR_WIDTH +: ADDR_WIDTH]),
        .awlen(m_axi_awlen[i*8 +: 8]),
        .awsize(m_axi_awsize[i*3 +: 3]),
        .awburst(m_axi_awburst[i*2 +: 2]),
        .awlock(m_axi_awlock[i]),
        .awcache(m_axi_awcache[i*4 +: 4]),
        .awprot(m_axi_awprot[i*3 +: 3]),
        .awregion(m_axi_awregion[i*4 +: 4]),
        .awqos(m_axi_awqos[i*4 +: 4]),
        .awid(m_axi_awid[i*M_ID_WIDTH +: M_ID_WIDTH]),
        .awready(m_axi_awready[i]),
        .awuser(m_axi_awuser[i*AWUSER_WIDTH +: AWUSER_WIDTH]),
        .wvalid(m_axi_wvalid[i]),
        .wlast(m_axi_wlast[i]),
        .wdata(m_axi_wdata[i*DATA_WIDTH +: DATA_WIDTH]),
        .wstrb(m_axi_wstrb[i*STRB_WIDTH +: STRB_WIDTH]),
        .wready(m_axi_wready[i]),
        .wuser(m_axi_wuser[i*WUSER_WIDTH +: WUSER_WIDTH]),
        .bvalid(m_axi_bvalid[i]),
        .bresp(m_axi_bresp[i*2 +: 2]),
        .bid(m_axi_bid[i*M_ID_WIDTH +: M_ID_WIDTH]),
        .bready(m_axi_bready[i]),
        .buser(m_axi_buser[i*BUSER_WIDTH +: BUSER_WIDTH]),
        .arvalid(m_axi_arvalid[i]),
        .araddr(m_axi_araddr[i*ADDR_WIDTH +: ADDR_WIDTH]),
        .arlen(m_axi_arlen[i*8 +: 8]),
        .arsize(m_axi_arsize[i*3 +: 3]),
        .arburst(m_axi_arburst[i*2 +: 2]),
        .arlock(m_axi_arlock[i]),
        .arcache(m_axi_arcache[i*4 +: 4]),
        .arprot(m_axi_arprot[i*3 +: 3]),
        .arregion(m_axi_arregion[i*4 +: 4]),
        .arqos(m_axi_arqos[i*4 +: 4]),
        .arid(m_axi_arid[i*M_ID_WIDTH +: M_ID_WIDTH]),
        .arready(m_axi_arready[i]),
        .aruser(m_axi_aruser[i*ARUSER_WIDTH +: ARUSER_WIDTH]),
        .rvalid(m_axi_rvalid[i]),
        .rlast(m_axi_rlast[i]),
        .rdata(m_axi_rdata[i*DATA_WIDTH +: DATA_WIDTH]),
        .rresp(m_axi_rresp[i*2 +: 2]),
        .rid(m_axi_rid[i*M_ID_WIDTH +: M_ID_WIDTH]),
        .rready(m_axi_rready[i]),
        .ruser(m_axi_ruser[i*RUSER_WIDTH +: RUSER_WIDTH])
      );
      initial begin
        uvm_config_string::set(null,
          $sformatf("uvm_test_top.m_env_h.m_axi_slv_agt_h[%0d]", i),
          "hdlPath",
          $sformatf("tb_top.axi_slv_if[%0d].cdnAxi4ActiveSlaveInterface", i)
        );
      end
    end
endgenerate
`else
  svt_axi_if axi_if();
  assign axi_if.common_aclk = sys_clk;
  generate
    for (genvar i = 0; i < `AXI_MST_AGENT_NUM; i++) begin : svt_mst_if
      assign axi_if.master_if[i].aresetn = sys_rstn;
      assign s_axi_awvalid[i] = axi_if.master_if[i].awvalid;
      assign s_axi_awaddr[i*ADDR_WIDTH +: ADDR_WIDTH] = axi_if.master_if[i].awaddr;
      assign s_axi_awlen[i*8 +: 8] = axi_if.master_if[i].awlen;
      assign s_axi_awsize[i*3 +: 3] = axi_if.master_if[i].awsize;
      assign s_axi_awburst[i*2 +: 2] = axi_if.master_if[i].awburst;
      assign s_axi_awlock[i] = axi_if.master_if[i].awlock;
      assign s_axi_awcache[i*4 +: 4] = axi_if.master_if[i].awcache;
      assign s_axi_awprot[i*3 +: 3] = axi_if.master_if[i].awprot;
      assign s_axi_awqos[i*4 +: 4] = axi_if.master_if[i].awqos;
      assign s_axi_awid[i*S_ID_WIDTH +: S_ID_WIDTH] = axi_if.master_if[i].awid;
      assign s_axi_awuser[i*AWUSER_WIDTH +: AWUSER_WIDTH] = axi_if.master_if[i].awuser;
      assign axi_if.master_if[i].awready = s_axi_awready[i];
      assign s_axi_wvalid[i] = axi_if.master_if[i].wvalid;
      assign s_axi_wlast[i] = axi_if.master_if[i].wlast;
      assign s_axi_wdata[i*DATA_WIDTH +: DATA_WIDTH] = axi_if.master_if[i].wdata;
      assign s_axi_wstrb[i*STRB_WIDTH +: STRB_WIDTH] = axi_if.master_if[i].wstrb;
      assign s_axi_wuser[i*WUSER_WIDTH +: WUSER_WIDTH] = axi_if.master_if[i].wuser;
      assign axi_if.master_if[i].wready = s_axi_wready[i];
      assign axi_if.master_if[i].bvalid = s_axi_bvalid[i];
      assign axi_if.master_if[i].bresp = s_axi_bresp[i*2 +: 2];
      assign axi_if.master_if[i].bid = s_axi_bid[i*S_ID_WIDTH +: S_ID_WIDTH];
      assign axi_if.master_if[i].buser = s_axi_buser[i*BUSER_WIDTH +: BUSER_WIDTH];
      assign s_axi_bready[i] = axi_if.master_if[i].bready;
      assign s_axi_arvalid[i] = axi_if.master_if[i].arvalid;
      assign s_axi_araddr[i*ADDR_WIDTH +: ADDR_WIDTH] = axi_if.master_if[i].araddr;
      assign s_axi_arlen[i*8 +: 8] = axi_if.master_if[i].arlen;
      assign s_axi_arsize[i*3 +: 3] = axi_if.master_if[i].arsize;
      assign s_axi_arburst[i*2 +: 2] = axi_if.master_if[i].arburst;
      assign s_axi_arlock[i] = axi_if.master_if[i].arlock;
      assign s_axi_arcache[i*4 +: 4] = axi_if.master_if[i].arcache;
      assign s_axi_arprot[i*3 +: 3] = axi_if.master_if[i].arprot;
      assign s_axi_arqos[i*4 +: 4] = axi_if.master_if[i].arqos;
      assign s_axi_arid[i*S_ID_WIDTH +: S_ID_WIDTH] = axi_if.master_if[i].arid;
      assign s_axi_aruser[i*ARUSER_WIDTH +: ARUSER_WIDTH] = axi_if.master_if[i].aruser;
      assign axi_if.master_if[i].arready = s_axi_arready[i];
      assign axi_if.master_if[i].rvalid = s_axi_rvalid[i];
      assign axi_if.master_if[i].rlast = s_axi_rlast[i];
      assign axi_if.master_if[i].rdata = s_axi_rdata[i*DATA_WIDTH +: DATA_WIDTH];
      assign axi_if.master_if[i].rresp = s_axi_rresp[i*2 +: 2];
      assign axi_if.master_if[i].rid = s_axi_rid[i*S_ID_WIDTH +: S_ID_WIDTH];
      assign axi_if.master_if[i].ruser = s_axi_ruser[i*RUSER_WIDTH +: RUSER_WIDTH];
      assign s_axi_rready[i] = axi_if.master_if[i].rready;
    end
    for (genvar i = 0; i < `AXI_SLV_AGENT_NUM; i++) begin : svt_slv_if
      assign axi_if.slave_if[i].aresetn = sys_rstn;
      assign axi_if.slave_if[i].awvalid = m_axi_awvalid[i];
      assign axi_if.slave_if[i].awaddr = m_axi_awaddr[i*ADDR_WIDTH +: ADDR_WIDTH];
      assign axi_if.slave_if[i].awlen = m_axi_awlen[i*8 +: 8];
      assign axi_if.slave_if[i].awsize = m_axi_awsize[i*3 +: 3];
      assign axi_if.slave_if[i].awburst = m_axi_awburst[i*2 +: 2];
      assign axi_if.slave_if[i].awlock = m_axi_awlock[i];
      assign axi_if.slave_if[i].awcache = m_axi_awcache[i*4 +: 4];
      assign axi_if.slave_if[i].awprot = m_axi_awprot[i*3 +: 3];
      assign axi_if.slave_if[i].awqos = m_axi_awqos[i*4 +: 4];
      assign axi_if.slave_if[i].awregion = m_axi_awregion[i*4 +: 4];
      assign axi_if.slave_if[i].awid = m_axi_awid[i*M_ID_WIDTH +: M_ID_WIDTH];
      assign axi_if.slave_if[i].awuser = m_axi_awuser[i*AWUSER_WIDTH +: AWUSER_WIDTH];
      assign m_axi_awready[i] = axi_if.slave_if[i].awready;
      assign axi_if.slave_if[i].wvalid = m_axi_wvalid[i];
      assign axi_if.slave_if[i].wlast = m_axi_wlast[i];
      assign axi_if.slave_if[i].wdata = m_axi_wdata[i*DATA_WIDTH +: DATA_WIDTH];
      assign axi_if.slave_if[i].wstrb = m_axi_wstrb[i*STRB_WIDTH +: STRB_WIDTH];
      assign axi_if.slave_if[i].wuser = m_axi_wuser[i*WUSER_WIDTH +: WUSER_WIDTH];
      assign m_axi_wready[i] = axi_if.slave_if[i].wready;
      assign m_axi_bvalid[i] = axi_if.slave_if[i].bvalid;
      assign m_axi_bresp[i*2 +: 2] = axi_if.slave_if[i].bresp;
      assign m_axi_bid[i*M_ID_WIDTH +: M_ID_WIDTH] = axi_if.slave_if[i].bid;
      assign m_axi_buser[i*BUSER_WIDTH +: BUSER_WIDTH] = axi_if.slave_if[i].buser;
      assign axi_if.slave_if[i].bready = m_axi_bready[i];
      assign axi_if.slave_if[i].arvalid = m_axi_arvalid[i];
      assign axi_if.slave_if[i].araddr = m_axi_araddr[i*ADDR_WIDTH +: ADDR_WIDTH];
      assign axi_if.slave_if[i].arlen = m_axi_arlen[i*8 +: 8];
      assign axi_if.slave_if[i].arsize = m_axi_arsize[i*3 +: 3];
      assign axi_if.slave_if[i].arburst = m_axi_arburst[i*2 +: 2];
      assign axi_if.slave_if[i].arlock = m_axi_arlock[i];
      assign axi_if.slave_if[i].arcache = m_axi_arcache[i*4 +: 4];
      assign axi_if.slave_if[i].arprot = m_axi_arprot[i*3 +: 3];
      assign axi_if.slave_if[i].arqos = m_axi_arqos[i*4 +: 4];
      assign axi_if.slave_if[i].arregion = m_axi_arregion[i*4 +: 4];
      assign axi_if.slave_if[i].arid = m_axi_arid[i*M_ID_WIDTH +: M_ID_WIDTH];
      assign axi_if.slave_if[i].aruser = m_axi_aruser[i*ARUSER_WIDTH +: ARUSER_WIDTH];
      assign m_axi_arready[i] = axi_if.slave_if[i].arready;
      assign m_axi_rvalid[i] = axi_if.slave_if[i].rvalid;
      assign m_axi_rlast[i] = axi_if.slave_if[i].rlast;
      assign m_axi_rdata[i*DATA_WIDTH +: DATA_WIDTH] = axi_if.slave_if[i].rdata;
      assign m_axi_rresp[i*2 +: 2] = axi_if.slave_if[i].rresp;
      assign m_axi_rid[i*M_ID_WIDTH +: M_ID_WIDTH] = axi_if.slave_if[i].rid;
      assign m_axi_ruser[i*RUSER_WIDTH +: RUSER_WIDTH] = axi_if.slave_if[i].ruser;
      assign axi_if.slave_if[i].rready = m_axi_rready[i];
    end
  endgenerate
`endif
initial begin
    $timeformat(-9, 3, "ns", 10);
aclk_rst_if.set_active(
      .drive_clk_val  (1),
      .drive_rst_n_val(1)
    );
uvm_config_db#(axi_crossbar_dut_vif)::set(null, "uvm_test_top", "vif", dut_intf);
`ifdef AXI_VIP_SVT
uvm_config_db#(svt_axi_vif)::set(null,
  "uvm_test_top.m_env_h.m_axi_sys_env_h", "vif", axi_if);
`endif

uvm_config_db#(axi_crossbar_dut_vif)::set(null, "uvm_test_top.m_vseqr_h", "vif", dut_intf);

uvm_config_db#(virtual interface clk_rst_if)::set(
      null,
      "uvm_test_top.m_vseqr_h",
      "aclk_rst_vif",
      aclk_rst_if
    );
run_test();  // run_test
  end

  reg error_flag_l;
  initial begin
    error_flag_l = 1'b0;
    error_flag   = 1'b0;
    c_end_flag   = 1'b0;
  end

endmodule
