# AXI Crossbar 双 VIP 环境

通过编译宏选择 VIP 后端，common transaction、reference model 和 scoreboard 共用。

## Cadence AXI VIP / Xcelium

```bash
cd sim
make -f Makefile comp_elab
make -f Makefile run TC=axi_crossbar_test_sanity
```

## Synopsys SVT AXI VIP / VCS

```bash
cd sim
make -f Makefile.vcs comp_elab
make -f Makefile.vcs run TC=axi_crossbar_test_sanity SEED=1
```

`Makefile.vcs` 自动定义 `AXI_VIP_SVT`。如安装位置不同，覆盖 `VCS_HOME` 和
`SVT_HOME`。SVT monitor 的 `item_observed_port` 对应 Cadence monitor 的
`EndedCbPort`，两者都在完整 transaction 结束后送入 adapter。
