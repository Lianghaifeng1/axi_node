# AXI Node 2x2 UVM Verification Environment

这是一个支持 Cadence AXI VIP/Xcelium 和 Synopsys SVT AXI VIP/VCS 的
2-master、2-slave AXI crossbar block-level UVM 验证环境。通过
`AXI_VIP_SVT` 编译宏选择 VIP 后端，common transaction、reference model
和 scoreboard 在两个后端之间共用。

## 目录

- `rtl/`：来自alexforencich/verilog-axi的crossbar及必要依赖。
- `tb/`：DUT实例、AXI VIP接口连接及filelist。
- `uvm/`：environment、ref model、通用逐字节scoreboard、sequence和test。
- `common_ifs/`：时钟、复位和通用接口。
- `doc/`：ref model、common transaction和scoreboard设计说明。
- `sim/`：Xcelium 与 VCS Makefile。

## 依赖

- Cadence 后端：Xcelium 23.09、Cadence AXI VIP 11.30 或兼容版本。
- Synopsys 后端：VCS 2023.12、SVT AXI VIP O-2018.09 或兼容版本。

商业 EDA 工具及 VIP 源文件不包含在本仓库中。Cadence 安装路径可通过环境变量覆盖：

```bash
export CDS_INST_DIR=/path/to/XCELIUM
export CDN_VIP_ROOT=/path/to/vipcat
export CDN_VIP_LIB_PATH=/path/to/compiled/axi/vip_lib
```

`CDN_VIP_LIB_PATH/64bit`需要包含工程Makefile引用的VIP动态库。

## 编译与运行

Cadence AXI VIP / Xcelium：

```bash
cd sim
make comp_elab
make run TC=axi_crossbar_test_sanity NO_WAVE=1
make run TC=axi_crossbar_test_stress SEED=20260705 NO_WAVE=1
make run TC=axi_crossbar_test_scb_unit VERBOSITY=UVM_MEDIUM NO_WAVE=1
```

Synopsys SVT AXI VIP / VCS：

```bash
cd sim
make -f Makefile.vcs comp_elab
make -f Makefile.vcs run TC=axi_crossbar_test_sanity SEED=1
make -f Makefile.vcs run TC=axi_crossbar_test_stress SEED=1
```

`Makefile.vcs` 自动定义 `AXI_VIP_SVT`。安装位置不同时，可覆盖
`VCS_HOME` 和 `SVT_HOME`。

stress 测试覆盖 FIXED/INCR/WRAP、narrow、非对齐、sparse strobe、
多 master、多 slave 和多 ID outstanding。

## Scoreboard

AXI burst由adapter归一化成逐字节common transaction。每个目标slave对应一个scoreboard，使用双向pending池支持expected/actual任意顺序到达。详细规格见`doc/SCB_SPEC_CN.md`。

## 第三方代码

- `rtl/`来自[alexforencich/verilog-axi](https://github.com/alexforencich/verilog-axi)，MIT许可证见`LICENSE.verilog-axi`。
- `uvm/dv_utils/`包含lowRISC/OpenTitan派生代码，Apache-2.0许可证见`LICENSE.lowRISC`。
