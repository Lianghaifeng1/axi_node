
`define AXI_MST_AGENT_NUM 2
`define AXI_SLV_AGENT_NUM 2
`define AXI_CROSSBAR_DATA_WIDTH 32
`define AXI_CROSSBAR_ADDR_WIDTH 32

typedef enum int unsigned {
  CPUW_PORT_CPU_AXI = 0,
  CPUW_PORT_AXI_HUB = 1,
  CPUW_PORT_MEM_DUMMY = 2,
  CPUW_PORT_RBC_DUMMY = 3,
  CPUW_PORT_RAM_DUMMY = 4,
  CPUW_PORT_ROM_DUMMY = 5,
  CPUW_PORT_PUBLIC_REG_DUMMY = 6,
  CPUW_PORT_PRIVATE_REG_DUMMY = 7
} cpu_wrapper_port_e;

typedef enum int unsigned {
  CPUW_PATH_CPU_AXI_TO_AXI_HUB = 0,
  CPUW_PATH_CPU_AXI_TO_RAM,
  CPUW_PATH_CPU_AXI_TO_ROM,
  CPUW_PATH_CPU_AXI_TO_PUBLIC_REG,
  CPUW_PATH_CPU_AXI_TO_PRIVATE_REG,
  CPUW_PATH_CPU_AXI_TO_RBC_OUT,
  CPUW_PATH_RBC_TO_PUBLIC_REG,
  CPUW_PATH_RBC_TO_PRIVATE_REG,
  CPUW_PATH_RBC_TO_RBC_OUT,
  CPUW_PATH_MEM_TO_RAM,
  CPUW_PATH_MEM_TO_ROM,
  CPUW_PATH_NUM
} cpu_wrapper_path_e;

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
