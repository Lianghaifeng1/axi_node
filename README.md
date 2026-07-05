# AXI Node 2x2 UVM Verification Environment

这是一个基于Cadence AXI4 VIP和Xcelium的2-master、2-slave AXI crossbar block-level UVM验证环境。

## 目录

- `rtl/`：来自alexforencich/verilog-axi的crossbar及必要依赖。
- `tb/`：DUT实例、AXI VIP接口连接及filelist。
- `uvm/`：environment、ref model、通用逐字节scoreboard、sequence和test。
- `common_ifs/`：时钟、复位和通用接口。
- `doc/`：ref model、common transaction和scoreboard设计说明。
- `sim/`：Xcelium Makefile。

## 依赖

- Cadence Xcelium 23.09或兼容版本。
- Cadence AXI VIP 11.30或兼容版本。
- 已编译的64-bit Cadence AXI VIP UVM动态库。

商业EDA工具、Cadence VIP源文件及动态库不包含在本仓库中。可通过环境变量覆盖安装路径：

```bash
export CDS_INST_DIR=/path/to/XCELIUM
export CDN_VIP_ROOT=/path/to/vipcat
export CDN_VIP_LIB_PATH=/path/to/compiled/axi/vip_lib
```

`CDN_VIP_LIB_PATH/64bit`需要包含工程Makefile引用的VIP动态库。

## 编译与运行

```bash
cd sim
make comp_elab
make run TC=axi_crossbar_test_sanity NO_WAVE=1
make run TC=axi_crossbar_test_stress SEED=20260705 NO_WAVE=1
make run TC=axi_crossbar_test_scb_unit VERBOSITY=UVM_MEDIUM NO_WAVE=1
```

stress测试覆盖FIXED/INCR/WRAP、narrow、非对齐、sparse strobe、多master、多slave和多ID outstanding。

## Scoreboard

AXI burst由adapter归一化成逐字节common transaction。每个目标slave对应一个scoreboard，使用双向pending池支持expected/actual任意顺序到达。详细规格见`doc/SCB_SPEC_CN.md`。

## 第三方代码

- `rtl/`来自[alexforencich/verilog-axi](https://github.com/alexforencich/verilog-axi)，MIT许可证见`LICENSE.verilog-axi`。
- `uvm/dv_utils/`包含lowRISC/OpenTitan派生代码，Apache-2.0许可证见`LICENSE.lowRISC`。
