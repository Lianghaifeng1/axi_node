
`define AXI_MST_AGENT_NUM 2
`define AXI_SLV_AGENT_NUM 2
`define AXI_CROSSBAR_DATA_WIDTH 32
`define AXI_CROSSBAR_ADDR_WIDTH 32

typedef enum bit [1:0] {
  RstAssertSyncDeassertSync,
  RstAssertAsyncDeassertSync,
  RstAssertAsyncDeassertAsync
} rst_scheme_e;

`ifndef SOC_TEST
typedef enum bit [2:0] {SINGLE, INCR, WRAP4, INCR4, WRAP8, INCR8, WRAP16, INCR16} burst_t;
typedef enum bit [2:0] {BYTE, HALFWORD, WORD, WORDx2, WORDx4, WORDx8, WORDx16, WORDx32} size_t;
typedef enum bit {READ, WRITE} write_t;
typedef enum bit[1:0] {IDLE, BUSY, NONSEQ, SEQ} trans_t;
`endif