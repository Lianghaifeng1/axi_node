`ifdef AXI_VIP_SVT
  typedef svt_axi_transaction axi_vip_transaction_t;
  typedef svt_axi_transaction::burst_size_enum axi_vip_size_t;
  typedef svt_axi_transaction::burst_type_enum axi_vip_burst_t;
  typedef bit axi_vip_secure_t;
  `define AXI_VIP_SIZE_BYTE svt_axi_transaction::BURST_SIZE_8BIT
  `define AXI_VIP_SIZE_HALFWORD svt_axi_transaction::BURST_SIZE_16BIT
  `define AXI_VIP_SIZE_WORD svt_axi_transaction::BURST_SIZE_32BIT
  `define AXI_VIP_BURST_FIXED svt_axi_transaction::FIXED
  `define AXI_VIP_BURST_INCR svt_axi_transaction::INCR
  `define AXI_VIP_BURST_WRAP svt_axi_transaction::WRAP
  `define AXI_VIP_NONSECURE 1'b1
`else
  typedef denaliCdn_axiTransaction axi_vip_transaction_t;
  typedef denaliCdn_axiTransferSizeT axi_vip_size_t;
  typedef denaliCdn_axiBurstKindT axi_vip_burst_t;
  typedef denaliCdn_axiSecureModeT axi_vip_secure_t;
  `define AXI_VIP_SIZE_BYTE DENALI_CDN_AXI_TRANSFERSIZE_BYTE
  `define AXI_VIP_SIZE_HALFWORD DENALI_CDN_AXI_TRANSFERSIZE_HALFWORD
  `define AXI_VIP_SIZE_WORD DENALI_CDN_AXI_TRANSFERSIZE_WORD
  `define AXI_VIP_BURST_FIXED DENALI_CDN_AXI_BURSTKIND_FIXED
  `define AXI_VIP_BURST_INCR DENALI_CDN_AXI_BURSTKIND_INCR
  `define AXI_VIP_BURST_WRAP DENALI_CDN_AXI_BURSTKIND_WRAP
  `define AXI_VIP_NONSECURE DENALI_CDN_AXI_SECUREMODE_NONSECURE
`endif
