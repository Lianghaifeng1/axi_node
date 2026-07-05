// ============================================================
// Instance: u_axi_crossbar (axi_crossbar)
// ============================================================

// Parameters
// Match the generated VIP environment: 2 upstream masters + 2 downstream slaves.
localparam S_COUNT                        = 2;
localparam M_COUNT                        = 2;
localparam DATA_WIDTH                     = 32;
localparam ADDR_WIDTH                     = 32;
localparam STRB_WIDTH                     = (DATA_WIDTH/8);
localparam S_ID_WIDTH                     = 8;
localparam M_ID_WIDTH                     = S_ID_WIDTH+$clog2(S_COUNT);
localparam AWUSER_ENABLE                  = 0;
localparam AWUSER_WIDTH                   = 1;
localparam WUSER_ENABLE                   = 0;
localparam WUSER_WIDTH                    = 1;
localparam BUSER_ENABLE                   = 0;
localparam BUSER_WIDTH                    = 1;
localparam ARUSER_ENABLE                  = 0;
localparam ARUSER_WIDTH                   = 1;
localparam RUSER_ENABLE                   = 0;
localparam RUSER_WIDTH                    = 1;
localparam S_THREADS                      = {S_COUNT{32'd2}};
localparam S_ACCEPT                       = {S_COUNT{32'd16}};
localparam M_REGIONS                      = 1;
// Two downstream slave windows:
//   m_axi[0] : 0x0000_0000 - 0x0fff_ffff
//   m_axi[1] : 0x1000_0000 - 0x1fff_ffff
localparam M_BASE_ADDR                    = {
                                             32'h1000_0000,
                                             32'h0000_0000
                                            };
localparam M_ADDR_WIDTH                   = {
                                             32'd28,
                                             32'd28
                                            };
localparam M_CONNECT_READ                 = {M_COUNT{{S_COUNT{1'b1}}}};
localparam M_CONNECT_WRITE                = {M_COUNT{{S_COUNT{1'b1}}}};
localparam M_ISSUE                        = {M_COUNT{32'd4}};
localparam M_SECURE                       = {M_COUNT{1'b0}};
localparam S_AW_REG_TYPE                  = {S_COUNT{2'd0}};
localparam S_W_REG_TYPE                   = {S_COUNT{2'd0}};
localparam S_B_REG_TYPE                   = {S_COUNT{2'd1}};
localparam S_AR_REG_TYPE                  = {S_COUNT{2'd0}};
localparam S_R_REG_TYPE                   = {S_COUNT{2'd2}};
localparam M_AW_REG_TYPE                  = {M_COUNT{2'd1}};
localparam M_W_REG_TYPE                   = {M_COUNT{2'd2}};
localparam M_B_REG_TYPE                   = {M_COUNT{2'd0}};
localparam M_AR_REG_TYPE                  = {M_COUNT{2'd1}};
localparam M_R_REG_TYPE                   = {M_COUNT{2'd0}};

// Wires and Registers
wire                            clk;
wire                            rst;
wire [S_COUNT*S_ID_WIDTH-1:0]   s_axi_awid;
wire [S_COUNT*ADDR_WIDTH-1:0]   s_axi_awaddr;
wire [S_COUNT*8-1:0]            s_axi_awlen;
wire [S_COUNT*3-1:0]            s_axi_awsize;
wire [S_COUNT*2-1:0]            s_axi_awburst;
wire [S_COUNT-1:0]              s_axi_awlock;
wire [S_COUNT*4-1:0]            s_axi_awcache;
wire [S_COUNT*3-1:0]            s_axi_awprot;
wire [S_COUNT*4-1:0]            s_axi_awqos;
wire [S_COUNT*AWUSER_WIDTH-1:0] s_axi_awuser;
wire [S_COUNT-1:0]              s_axi_awvalid;
wire [S_COUNT-1:0]              s_axi_awready;
wire [S_COUNT*DATA_WIDTH-1:0]   s_axi_wdata;
wire [S_COUNT*STRB_WIDTH-1:0]   s_axi_wstrb;
wire [S_COUNT-1:0]              s_axi_wlast;
wire [S_COUNT*WUSER_WIDTH-1:0]  s_axi_wuser;
wire [S_COUNT-1:0]              s_axi_wvalid;
wire [S_COUNT-1:0]              s_axi_wready;
wire [S_COUNT*S_ID_WIDTH-1:0]   s_axi_bid;
wire [S_COUNT*2-1:0]            s_axi_bresp;
wire [S_COUNT*BUSER_WIDTH-1:0]  s_axi_buser;
wire [S_COUNT-1:0]              s_axi_bvalid;
wire [S_COUNT-1:0]              s_axi_bready;
wire [S_COUNT*S_ID_WIDTH-1:0]   s_axi_arid;
wire [S_COUNT*ADDR_WIDTH-1:0]   s_axi_araddr;
wire [S_COUNT*8-1:0]            s_axi_arlen;
wire [S_COUNT*3-1:0]            s_axi_arsize;
wire [S_COUNT*2-1:0]            s_axi_arburst;
wire [S_COUNT-1:0]              s_axi_arlock;
wire [S_COUNT*4-1:0]            s_axi_arcache;
wire [S_COUNT*3-1:0]            s_axi_arprot;
wire [S_COUNT*4-1:0]            s_axi_arqos;
wire [S_COUNT*ARUSER_WIDTH-1:0] s_axi_aruser;
wire [S_COUNT-1:0]              s_axi_arvalid;
wire [S_COUNT-1:0]              s_axi_arready;
wire [S_COUNT*S_ID_WIDTH-1:0]   s_axi_rid;
wire [S_COUNT*DATA_WIDTH-1:0]   s_axi_rdata;
wire [S_COUNT*2-1:0]            s_axi_rresp;
wire [S_COUNT-1:0]              s_axi_rlast;
wire [S_COUNT*RUSER_WIDTH-1:0]  s_axi_ruser;
wire [S_COUNT-1:0]              s_axi_rvalid;
wire [S_COUNT-1:0]              s_axi_rready;
wire [M_COUNT*M_ID_WIDTH-1:0]   m_axi_awid;
wire [M_COUNT*ADDR_WIDTH-1:0]   m_axi_awaddr;
wire [M_COUNT*8-1:0]            m_axi_awlen;
wire [M_COUNT*3-1:0]            m_axi_awsize;
wire [M_COUNT*2-1:0]            m_axi_awburst;
wire [M_COUNT-1:0]              m_axi_awlock;
wire [M_COUNT*4-1:0]            m_axi_awcache;
wire [M_COUNT*3-1:0]            m_axi_awprot;
wire [M_COUNT*4-1:0]            m_axi_awqos;
wire [M_COUNT*4-1:0]            m_axi_awregion;
wire [M_COUNT*AWUSER_WIDTH-1:0] m_axi_awuser;
wire [M_COUNT-1:0]              m_axi_awvalid;
wire [M_COUNT-1:0]              m_axi_awready;
wire [M_COUNT*DATA_WIDTH-1:0]   m_axi_wdata;
wire [M_COUNT*STRB_WIDTH-1:0]   m_axi_wstrb;
wire [M_COUNT-1:0]              m_axi_wlast;
wire [M_COUNT*WUSER_WIDTH-1:0]  m_axi_wuser;
wire [M_COUNT-1:0]              m_axi_wvalid;
wire [M_COUNT-1:0]              m_axi_wready;
wire [M_COUNT*M_ID_WIDTH-1:0]   m_axi_bid;
wire [M_COUNT*2-1:0]            m_axi_bresp;
wire [M_COUNT*BUSER_WIDTH-1:0]  m_axi_buser;
wire [M_COUNT-1:0]              m_axi_bvalid;
wire [M_COUNT-1:0]              m_axi_bready;
wire [M_COUNT*M_ID_WIDTH-1:0]   m_axi_arid;
wire [M_COUNT*ADDR_WIDTH-1:0]   m_axi_araddr;
wire [M_COUNT*8-1:0]            m_axi_arlen;
wire [M_COUNT*3-1:0]            m_axi_arsize;
wire [M_COUNT*2-1:0]            m_axi_arburst;
wire [M_COUNT-1:0]              m_axi_arlock;
wire [M_COUNT*4-1:0]            m_axi_arcache;
wire [M_COUNT*3-1:0]            m_axi_arprot;
wire [M_COUNT*4-1:0]            m_axi_arqos;
wire [M_COUNT*4-1:0]            m_axi_arregion;
wire [M_COUNT*ARUSER_WIDTH-1:0] m_axi_aruser;
wire [M_COUNT-1:0]              m_axi_arvalid;
wire [M_COUNT-1:0]              m_axi_arready;
wire [M_COUNT*M_ID_WIDTH-1:0]   m_axi_rid;
wire [M_COUNT*DATA_WIDTH-1:0]   m_axi_rdata;
wire [M_COUNT*2-1:0]            m_axi_rresp;
wire [M_COUNT-1:0]              m_axi_rlast;
wire [M_COUNT*RUSER_WIDTH-1:0]  m_axi_ruser;
wire [M_COUNT-1:0]              m_axi_rvalid;
wire [M_COUNT-1:0]              m_axi_rready;

axi_crossbar #(
  .S_COUNT                       (S_COUNT),
  .M_COUNT                       (M_COUNT),
  .DATA_WIDTH                    (DATA_WIDTH),
  .ADDR_WIDTH                    (ADDR_WIDTH),
  .STRB_WIDTH                    (STRB_WIDTH),
  .S_ID_WIDTH                    (S_ID_WIDTH),
  .M_ID_WIDTH                    (M_ID_WIDTH),
  .AWUSER_ENABLE                 (AWUSER_ENABLE),
  .AWUSER_WIDTH                  (AWUSER_WIDTH),
  .WUSER_ENABLE                  (WUSER_ENABLE),
  .WUSER_WIDTH                   (WUSER_WIDTH),
  .BUSER_ENABLE                  (BUSER_ENABLE),
  .BUSER_WIDTH                   (BUSER_WIDTH),
  .ARUSER_ENABLE                 (ARUSER_ENABLE),
  .ARUSER_WIDTH                  (ARUSER_WIDTH),
  .RUSER_ENABLE                  (RUSER_ENABLE),
  .RUSER_WIDTH                   (RUSER_WIDTH),
  .S_THREADS                     (S_THREADS),
  .S_ACCEPT                      (S_ACCEPT),
  .M_REGIONS                     (M_REGIONS),
  .M_BASE_ADDR                   (M_BASE_ADDR),
  .M_ADDR_WIDTH                  (M_ADDR_WIDTH),
  .M_CONNECT_READ                (M_CONNECT_READ),
  .M_CONNECT_WRITE               (M_CONNECT_WRITE),
  .M_ISSUE                       (M_ISSUE),
  .M_SECURE                      (M_SECURE),
  .S_AW_REG_TYPE                 (S_AW_REG_TYPE),
  .S_W_REG_TYPE                  (S_W_REG_TYPE),
  .S_B_REG_TYPE                  (S_B_REG_TYPE),
  .S_AR_REG_TYPE                 (S_AR_REG_TYPE),
  .S_R_REG_TYPE                  (S_R_REG_TYPE),
  .M_AW_REG_TYPE                 (M_AW_REG_TYPE),
  .M_W_REG_TYPE                  (M_W_REG_TYPE),
  .M_B_REG_TYPE                  (M_B_REG_TYPE),
  .M_AR_REG_TYPE                 (M_AR_REG_TYPE),
  .M_R_REG_TYPE                  (M_R_REG_TYPE)
) u_axi_crossbar (
  .clk                           (clk),
  .rst                           (rst),
  .s_axi_awid                    (s_axi_awid),
  .s_axi_awaddr                  (s_axi_awaddr),
  .s_axi_awlen                   (s_axi_awlen),
  .s_axi_awsize                  (s_axi_awsize),
  .s_axi_awburst                 (s_axi_awburst),
  .s_axi_awlock                  (s_axi_awlock),
  .s_axi_awcache                 (s_axi_awcache),
  .s_axi_awprot                  (s_axi_awprot),
  .s_axi_awqos                   (s_axi_awqos),
  .s_axi_awuser                  (s_axi_awuser),
  .s_axi_awvalid                 (s_axi_awvalid),
  .s_axi_awready                 (s_axi_awready),
  .s_axi_wdata                   (s_axi_wdata),
  .s_axi_wstrb                   (s_axi_wstrb),
  .s_axi_wlast                   (s_axi_wlast),
  .s_axi_wuser                   (s_axi_wuser),
  .s_axi_wvalid                  (s_axi_wvalid),
  .s_axi_wready                  (s_axi_wready),
  .s_axi_bid                     (s_axi_bid),
  .s_axi_bresp                   (s_axi_bresp),
  .s_axi_buser                   (s_axi_buser),
  .s_axi_bvalid                  (s_axi_bvalid),
  .s_axi_bready                  (s_axi_bready),
  .s_axi_arid                    (s_axi_arid),
  .s_axi_araddr                  (s_axi_araddr),
  .s_axi_arlen                   (s_axi_arlen),
  .s_axi_arsize                  (s_axi_arsize),
  .s_axi_arburst                 (s_axi_arburst),
  .s_axi_arlock                  (s_axi_arlock),
  .s_axi_arcache                 (s_axi_arcache),
  .s_axi_arprot                  (s_axi_arprot),
  .s_axi_arqos                   (s_axi_arqos),
  .s_axi_aruser                  (s_axi_aruser),
  .s_axi_arvalid                 (s_axi_arvalid),
  .s_axi_arready                 (s_axi_arready),
  .s_axi_rid                     (s_axi_rid),
  .s_axi_rdata                   (s_axi_rdata),
  .s_axi_rresp                   (s_axi_rresp),
  .s_axi_rlast                   (s_axi_rlast),
  .s_axi_ruser                   (s_axi_ruser),
  .s_axi_rvalid                  (s_axi_rvalid),
  .s_axi_rready                  (s_axi_rready),
  .m_axi_awid                    (m_axi_awid),
  .m_axi_awaddr                  (m_axi_awaddr),
  .m_axi_awlen                   (m_axi_awlen),
  .m_axi_awsize                  (m_axi_awsize),
  .m_axi_awburst                 (m_axi_awburst),
  .m_axi_awlock                  (m_axi_awlock),
  .m_axi_awcache                 (m_axi_awcache),
  .m_axi_awprot                  (m_axi_awprot),
  .m_axi_awqos                   (m_axi_awqos),
  .m_axi_awregion                (m_axi_awregion),
  .m_axi_awuser                  (m_axi_awuser),
  .m_axi_awvalid                 (m_axi_awvalid),
  .m_axi_awready                 (m_axi_awready),
  .m_axi_wdata                   (m_axi_wdata),
  .m_axi_wstrb                   (m_axi_wstrb),
  .m_axi_wlast                   (m_axi_wlast),
  .m_axi_wuser                   (m_axi_wuser),
  .m_axi_wvalid                  (m_axi_wvalid),
  .m_axi_wready                  (m_axi_wready),
  .m_axi_bid                     (m_axi_bid),
  .m_axi_bresp                   (m_axi_bresp),
  .m_axi_buser                   (m_axi_buser),
  .m_axi_bvalid                  (m_axi_bvalid),
  .m_axi_bready                  (m_axi_bready),
  .m_axi_arid                    (m_axi_arid),
  .m_axi_araddr                  (m_axi_araddr),
  .m_axi_arlen                   (m_axi_arlen),
  .m_axi_arsize                  (m_axi_arsize),
  .m_axi_arburst                 (m_axi_arburst),
  .m_axi_arlock                  (m_axi_arlock),
  .m_axi_arcache                 (m_axi_arcache),
  .m_axi_arprot                  (m_axi_arprot),
  .m_axi_arqos                   (m_axi_arqos),
  .m_axi_arregion                (m_axi_arregion),
  .m_axi_aruser                  (m_axi_aruser),
  .m_axi_arvalid                 (m_axi_arvalid),
  .m_axi_arready                 (m_axi_arready),
  .m_axi_rid                     (m_axi_rid),
  .m_axi_rdata                   (m_axi_rdata),
  .m_axi_rresp                   (m_axi_rresp),
  .m_axi_rlast                   (m_axi_rlast),
  .m_axi_ruser                   (m_axi_ruser),
  .m_axi_rvalid                  (m_axi_rvalid),
  .m_axi_rready                  (m_axi_rready)
);
