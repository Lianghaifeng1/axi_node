`ifdef USE_CPU_WRAPPER_STUB
module cpu_wrapper_stub #(
  parameter int S_COUNT = 2,
  parameter int M_COUNT = 2,
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 32,
  parameter int STRB_WIDTH = DATA_WIDTH/8,
  parameter int S_ID_WIDTH = 8,
  parameter int M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
  parameter AWUSER_ENABLE = 0,
  parameter int AWUSER_WIDTH = 1,
  parameter WUSER_ENABLE = 0,
  parameter int WUSER_WIDTH = 1,
  parameter BUSER_ENABLE = 0,
  parameter int BUSER_WIDTH = 1,
  parameter ARUSER_ENABLE = 0,
  parameter int ARUSER_WIDTH = 1,
  parameter RUSER_ENABLE = 0,
  parameter int RUSER_WIDTH = 1,
  parameter S_THREADS = 0,
  parameter S_ACCEPT = 0,
  parameter M_REGIONS = 1,
  parameter M_BASE_ADDR = 0,
  parameter M_ADDR_WIDTH = 0,
  parameter M_CONNECT_READ = 0,
  parameter M_CONNECT_WRITE = 0,
  parameter M_ISSUE = 0,
  parameter M_SECURE = 0,
  parameter S_AW_REG_TYPE = 0,
  parameter S_W_REG_TYPE = 0,
  parameter S_B_REG_TYPE = 0,
  parameter S_AR_REG_TYPE = 0,
  parameter S_R_REG_TYPE = 0,
  parameter M_AW_REG_TYPE = 0,
  parameter M_W_REG_TYPE = 0,
  parameter M_B_REG_TYPE = 0,
  parameter M_AR_REG_TYPE = 0,
  parameter M_R_REG_TYPE = 0
) (
  input  wire                            clk,
  input  wire                            rst,
  input  wire [S_COUNT*S_ID_WIDTH-1:0]   s_axi_awid,
  input  wire [S_COUNT*ADDR_WIDTH-1:0]   s_axi_awaddr,
  input  wire [S_COUNT*8-1:0]            s_axi_awlen,
  input  wire [S_COUNT*3-1:0]            s_axi_awsize,
  input  wire [S_COUNT*2-1:0]            s_axi_awburst,
  input  wire [S_COUNT-1:0]              s_axi_awlock,
  input  wire [S_COUNT*4-1:0]            s_axi_awcache,
  input  wire [S_COUNT*3-1:0]            s_axi_awprot,
  input  wire [S_COUNT*4-1:0]            s_axi_awqos,
  input  wire [S_COUNT*AWUSER_WIDTH-1:0] s_axi_awuser,
  input  wire [S_COUNT-1:0]              s_axi_awvalid,
  output wire [S_COUNT-1:0]              s_axi_awready,
  input  wire [S_COUNT*DATA_WIDTH-1:0]   s_axi_wdata,
  input  wire [S_COUNT*STRB_WIDTH-1:0]   s_axi_wstrb,
  input  wire [S_COUNT-1:0]              s_axi_wlast,
  input  wire [S_COUNT*WUSER_WIDTH-1:0]  s_axi_wuser,
  input  wire [S_COUNT-1:0]              s_axi_wvalid,
  output wire [S_COUNT-1:0]              s_axi_wready,
  output wire [S_COUNT*S_ID_WIDTH-1:0]   s_axi_bid,
  output wire [S_COUNT*2-1:0]            s_axi_bresp,
  output wire [S_COUNT*BUSER_WIDTH-1:0]  s_axi_buser,
  output wire [S_COUNT-1:0]              s_axi_bvalid,
  input  wire [S_COUNT-1:0]              s_axi_bready,
  input  wire [S_COUNT*S_ID_WIDTH-1:0]   s_axi_arid,
  input  wire [S_COUNT*ADDR_WIDTH-1:0]   s_axi_araddr,
  input  wire [S_COUNT*8-1:0]            s_axi_arlen,
  input  wire [S_COUNT*3-1:0]            s_axi_arsize,
  input  wire [S_COUNT*2-1:0]            s_axi_arburst,
  input  wire [S_COUNT-1:0]              s_axi_arlock,
  input  wire [S_COUNT*4-1:0]            s_axi_arcache,
  input  wire [S_COUNT*3-1:0]            s_axi_arprot,
  input  wire [S_COUNT*4-1:0]            s_axi_arqos,
  input  wire [S_COUNT*ARUSER_WIDTH-1:0] s_axi_aruser,
  input  wire [S_COUNT-1:0]              s_axi_arvalid,
  output wire [S_COUNT-1:0]              s_axi_arready,
  output wire [S_COUNT*S_ID_WIDTH-1:0]   s_axi_rid,
  output wire [S_COUNT*DATA_WIDTH-1:0]   s_axi_rdata,
  output wire [S_COUNT*2-1:0]            s_axi_rresp,
  output wire [S_COUNT-1:0]              s_axi_rlast,
  output wire [S_COUNT*RUSER_WIDTH-1:0]  s_axi_ruser,
  output wire [S_COUNT-1:0]              s_axi_rvalid,
  input  wire [S_COUNT-1:0]              s_axi_rready,
  output wire [M_COUNT*M_ID_WIDTH-1:0]   m_axi_awid,
  output wire [M_COUNT*ADDR_WIDTH-1:0]   m_axi_awaddr,
  output wire [M_COUNT*8-1:0]            m_axi_awlen,
  output wire [M_COUNT*3-1:0]            m_axi_awsize,
  output wire [M_COUNT*2-1:0]            m_axi_awburst,
  output wire [M_COUNT-1:0]              m_axi_awlock,
  output wire [M_COUNT*4-1:0]            m_axi_awcache,
  output wire [M_COUNT*3-1:0]            m_axi_awprot,
  output wire [M_COUNT*4-1:0]            m_axi_awqos,
  output wire [M_COUNT*4-1:0]            m_axi_awregion,
  output wire [M_COUNT*AWUSER_WIDTH-1:0] m_axi_awuser,
  output wire [M_COUNT-1:0]              m_axi_awvalid,
  input  wire [M_COUNT-1:0]              m_axi_awready,
  output wire [M_COUNT*DATA_WIDTH-1:0]   m_axi_wdata,
  output wire [M_COUNT*STRB_WIDTH-1:0]   m_axi_wstrb,
  output wire [M_COUNT-1:0]              m_axi_wlast,
  output wire [M_COUNT*WUSER_WIDTH-1:0]  m_axi_wuser,
  output wire [M_COUNT-1:0]              m_axi_wvalid,
  input  wire [M_COUNT-1:0]              m_axi_wready,
  input  wire [M_COUNT*M_ID_WIDTH-1:0]   m_axi_bid,
  input  wire [M_COUNT*2-1:0]            m_axi_bresp,
  input  wire [M_COUNT*BUSER_WIDTH-1:0]  m_axi_buser,
  input  wire [M_COUNT-1:0]              m_axi_bvalid,
  output wire [M_COUNT-1:0]              m_axi_bready,
  output wire [M_COUNT*ADDR_WIDTH-1:0]   m_axi_araddr,
  output wire [M_COUNT*8-1:0]            m_axi_arlen,
  output wire [M_COUNT*3-1:0]            m_axi_arsize,
  output wire [M_COUNT*2-1:0]            m_axi_arburst,
  output wire [M_COUNT-1:0]              m_axi_arlock,
  output wire [M_COUNT*4-1:0]            m_axi_arcache,
  output wire [M_COUNT*3-1:0]            m_axi_arprot,
  output wire [M_COUNT*4-1:0]            m_axi_arqos,
  output wire [M_COUNT*4-1:0]            m_axi_arregion,
  output wire [M_COUNT*ARUSER_WIDTH-1:0] m_axi_aruser,
  output wire [M_COUNT*M_ID_WIDTH-1:0]   m_axi_arid,
  output wire [M_COUNT-1:0]              m_axi_arvalid,
  input  wire [M_COUNT-1:0]              m_axi_arready,
  input  wire [M_COUNT*M_ID_WIDTH-1:0]   m_axi_rid,
  input  wire [M_COUNT*DATA_WIDTH-1:0]   m_axi_rdata,
  input  wire [M_COUNT*2-1:0]            m_axi_rresp,
  input  wire [M_COUNT-1:0]              m_axi_rlast,
  input  wire [M_COUNT*RUSER_WIDTH-1:0]  m_axi_ruser,
  input  wire [M_COUNT-1:0]              m_axi_rvalid,
  output wire [M_COUNT-1:0]              m_axi_rready
);

  localparam int SRC_ID_PAD = M_ID_WIDTH - S_ID_WIDTH;

  assign m_axi_awid[M_ID_WIDTH-1:0] = {{SRC_ID_PAD{1'b0}}, s_axi_awid[S_ID_WIDTH-1:0]};
  assign m_axi_awaddr[ADDR_WIDTH-1:0] = s_axi_awaddr[ADDR_WIDTH-1:0];
  assign m_axi_awlen[7:0] = s_axi_awlen[7:0];
  assign m_axi_awsize[2:0] = s_axi_awsize[2:0];
  assign m_axi_awburst[1:0] = s_axi_awburst[1:0];
  assign m_axi_awlock[0] = s_axi_awlock[0];
  assign m_axi_awcache[3:0] = s_axi_awcache[3:0];
  assign m_axi_awprot[2:0] = s_axi_awprot[2:0];
  assign m_axi_awqos[3:0] = s_axi_awqos[3:0];
  assign m_axi_awregion[3:0] = 4'h0;
  assign m_axi_awuser[AWUSER_WIDTH-1:0] = s_axi_awuser[AWUSER_WIDTH-1:0];
  assign m_axi_awvalid[0] = s_axi_awvalid[0];
  assign s_axi_awready[0] = m_axi_awready[0];

  assign m_axi_wdata[DATA_WIDTH-1:0] = s_axi_wdata[DATA_WIDTH-1:0];
  assign m_axi_wstrb[STRB_WIDTH-1:0] = s_axi_wstrb[STRB_WIDTH-1:0];
  assign m_axi_wlast[0] = s_axi_wlast[0];
  assign m_axi_wuser[WUSER_WIDTH-1:0] = s_axi_wuser[WUSER_WIDTH-1:0];
  assign m_axi_wvalid[0] = s_axi_wvalid[0];
  assign s_axi_wready[0] = m_axi_wready[0];

  assign s_axi_bid[S_ID_WIDTH-1:0] = m_axi_bid[S_ID_WIDTH-1:0];
  assign s_axi_bresp[1:0] = m_axi_bresp[1:0];
  assign s_axi_buser[BUSER_WIDTH-1:0] = m_axi_buser[BUSER_WIDTH-1:0];
  assign s_axi_bvalid[0] = m_axi_bvalid[0];
  assign m_axi_bready[0] = s_axi_bready[0];

  assign m_axi_arid[M_ID_WIDTH-1:0] = {{SRC_ID_PAD{1'b0}}, s_axi_arid[S_ID_WIDTH-1:0]};
  assign m_axi_araddr[ADDR_WIDTH-1:0] = s_axi_araddr[ADDR_WIDTH-1:0];
  assign m_axi_arlen[7:0] = s_axi_arlen[7:0];
  assign m_axi_arsize[2:0] = s_axi_arsize[2:0];
  assign m_axi_arburst[1:0] = s_axi_arburst[1:0];
  assign m_axi_arlock[0] = s_axi_arlock[0];
  assign m_axi_arcache[3:0] = s_axi_arcache[3:0];
  assign m_axi_arprot[2:0] = s_axi_arprot[2:0];
  assign m_axi_arqos[3:0] = s_axi_arqos[3:0];
  assign m_axi_arregion[3:0] = 4'h0;
  assign m_axi_aruser[ARUSER_WIDTH-1:0] = s_axi_aruser[ARUSER_WIDTH-1:0];
  assign m_axi_arvalid[0] = s_axi_arvalid[0];
  assign s_axi_arready[0] = m_axi_arready[0];

  assign s_axi_rid[S_ID_WIDTH-1:0] = m_axi_rid[S_ID_WIDTH-1:0];
  assign s_axi_rdata[DATA_WIDTH-1:0] = m_axi_rdata[DATA_WIDTH-1:0];
  assign s_axi_rresp[1:0] = m_axi_rresp[1:0];
  assign s_axi_rlast[0] = m_axi_rlast[0];
  assign s_axi_ruser[RUSER_WIDTH-1:0] = m_axi_ruser[RUSER_WIDTH-1:0];
  assign s_axi_rvalid[0] = m_axi_rvalid[0];
  assign m_axi_rready[0] = s_axi_rready[0];

  generate
    if (S_COUNT > 1) begin : gen_tie_s
      assign s_axi_awready[S_COUNT-1:1] = '1;
      assign s_axi_wready[S_COUNT-1:1] = '1;
      assign s_axi_bid[S_COUNT*S_ID_WIDTH-1:S_ID_WIDTH] = '0;
      assign s_axi_bresp[S_COUNT*2-1:2] = '0;
      assign s_axi_buser[S_COUNT*BUSER_WIDTH-1:BUSER_WIDTH] = '0;
      assign s_axi_bvalid[S_COUNT-1:1] = '0;
      assign s_axi_arready[S_COUNT-1:1] = '1;
      assign s_axi_rid[S_COUNT*S_ID_WIDTH-1:S_ID_WIDTH] = '0;
      assign s_axi_rdata[S_COUNT*DATA_WIDTH-1:DATA_WIDTH] = '0;
      assign s_axi_rresp[S_COUNT*2-1:2] = '0;
      assign s_axi_rlast[S_COUNT-1:1] = '0;
      assign s_axi_ruser[S_COUNT*RUSER_WIDTH-1:RUSER_WIDTH] = '0;
      assign s_axi_rvalid[S_COUNT-1:1] = '0;
    end
    if (M_COUNT > 1) begin : gen_tie_m
      assign m_axi_awid[M_COUNT*M_ID_WIDTH-1:M_ID_WIDTH] = '0;
      assign m_axi_awaddr[M_COUNT*ADDR_WIDTH-1:ADDR_WIDTH] = '0;
      assign m_axi_awlen[M_COUNT*8-1:8] = '0;
      assign m_axi_awsize[M_COUNT*3-1:3] = '0;
      assign m_axi_awburst[M_COUNT*2-1:2] = '0;
      assign m_axi_awlock[M_COUNT-1:1] = '0;
      assign m_axi_awcache[M_COUNT*4-1:4] = '0;
      assign m_axi_awprot[M_COUNT*3-1:3] = '0;
      assign m_axi_awqos[M_COUNT*4-1:4] = '0;
      assign m_axi_awregion[M_COUNT*4-1:4] = '0;
      assign m_axi_awuser[M_COUNT*AWUSER_WIDTH-1:AWUSER_WIDTH] = '0;
      assign m_axi_awvalid[M_COUNT-1:1] = '0;
      assign m_axi_wdata[M_COUNT*DATA_WIDTH-1:DATA_WIDTH] = '0;
      assign m_axi_wstrb[M_COUNT*STRB_WIDTH-1:STRB_WIDTH] = '0;
      assign m_axi_wlast[M_COUNT-1:1] = '0;
      assign m_axi_wuser[M_COUNT*WUSER_WIDTH-1:WUSER_WIDTH] = '0;
      assign m_axi_wvalid[M_COUNT-1:1] = '0;
      assign m_axi_bready[M_COUNT-1:1] = '1;
      assign m_axi_arid[M_COUNT*M_ID_WIDTH-1:M_ID_WIDTH] = '0;
      assign m_axi_araddr[M_COUNT*ADDR_WIDTH-1:ADDR_WIDTH] = '0;
      assign m_axi_arlen[M_COUNT*8-1:8] = '0;
      assign m_axi_arsize[M_COUNT*3-1:3] = '0;
      assign m_axi_arburst[M_COUNT*2-1:2] = '0;
      assign m_axi_arlock[M_COUNT-1:1] = '0;
      assign m_axi_arcache[M_COUNT*4-1:4] = '0;
      assign m_axi_arprot[M_COUNT*3-1:3] = '0;
      assign m_axi_arqos[M_COUNT*4-1:4] = '0;
      assign m_axi_arregion[M_COUNT*4-1:4] = '0;
      assign m_axi_aruser[M_COUNT*ARUSER_WIDTH-1:ARUSER_WIDTH] = '0;
      assign m_axi_arvalid[M_COUNT-1:1] = '0;
      assign m_axi_rready[M_COUNT-1:1] = '1;
    end
  endgenerate

endmodule
`endif
