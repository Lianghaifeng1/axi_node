# 通用 Scoreboard 规格说明

## 1. 目标

`axi_crossbar_scoreboard`用于比较参考模型产生的expected逐字节访问与DUT输出侧监测到的actual逐字节访问。

Scoreboard与AXI、MEM、REG、APB、AHB等具体协议解耦，只接收`axi_crossbar_common_transaction`。协议transaction必须先由对应adapter转换为统一的逐字节访问。

当前环境按照目标端点数量例化scoreboard：

```text
m_slv_scb_h[0]：检查发往slave0的访问
m_slv_scb_h[1]：检查发往slave1的访问
```

## 2. 输入接口

每个scoreboard提供两个analysis export：

```systemverilog
uvm_analysis_export #(T) m_expected_analysis_export;
uvm_analysis_export #(T) m_actual_analysis_export;
```

- `m_expected_analysis_export`：接收ref model根据上游transaction生成的预期访问。
- `m_actual_analysis_export`：接收ref model根据下游monitor transaction生成的实际访问。

两个export分别连接内部`uvm_tlm_analysis_fifo`。expected和actual由独立线程持续读取，任意一侧都可以先到达。

## 3. 比较单位

Scoreboard的最小比较单位为一个有效byte，不是一个AXI burst或beat。

每个common transaction包含：

| 字段 | 含义 | 默认AXI场景是否比较 |
|---|---|---|
| `access` | READ或WRITE | 是 |
| `address` | byte地址 | 是 |
| `data` | 8-bit数据 | 是 |
| `status` | OKAY、EXOKAY、SLVERR、DECERR | 是 |
| `source_port` | 来源master编号 | 是 |
| `dest_port` | 目标slave编号 | 是 |
| `transaction_id` | 原始AXI ID | 是 |
| `beat_index` | 原burst内beat编号 | 否，仅调试 |
| `byte_index` | beat内byte编号 | 否，仅调试 |
| `source_protocol` | 来源协议名称 | 否，仅调试 |

写访问只为strobe/byte-enable有效的byte生成common transaction。读访问为每个请求byte生成common transaction。

## 4. 匹配键

基础匹配键由以下字段组成：

```text
access + byte address
```

示例：

```text
1:0000000010000100
```

其中`1`表示WRITE，后续为64-bit byte地址。

ID、source port和data不直接放入基础键。这样可以兼容AXI2MEM或AXI2REG转换后ID被删除、burst被拆分或数据宽度变化的场景。

基础键相同后，再使用`compare_payload()`比较完整有效字段。

## 5. 字段有效性

最终参与比较的字段由以下掩码共同决定：

```text
scoreboard.compare_mask
& expected.valid_mask
& actual.valid_mask
```

当前AXI到AXI场景的两侧均提供完整字段，因此比较方向、地址、数据、响应、source、destination和原始ID。

未来MEM/REG adapter没有ID或response时，不设置对应`valid_mask`，scoreboard自动忽略该字段，无需修改比较核心。

## 6. Pending数据结构

Scoreboard维护两组关联队列：

```systemverilog
T m_expected_pending[string][$];
T m_actual_pending[string][$];
```

string为基础匹配键，每个键下允许保存多个transaction，用于支持：

- expected先到或actual先到。
- 不同AXI ID乱序完成。
- 多master并发访问同一slave。
- 同一地址的重复访问。
- bridge拆分、合并和不同monitor callback执行顺序。

## 7. 实时处理流程

### 7.1 Expected到达

1. 调用`get_match_key()`生成基础键。
2. 遍历相同键的actual pending队列。
3. 调用`compare_payload()`查找完整匹配项。
4. 找到后删除actual项，`m_match_num++`。
5. 找不到则将expected保存到expected pending队列。

### 7.2 Actual到达

处理流程与expected完全对称：搜索expected pending队列，匹配成功后删除expected项，否则缓存actual。

### 7.3 为什么不实时报告Mismatch

actual到达但暂时找不到expected，可能只是合法乱序，不能立即认定为错误。因此：

- 成功匹配可以实时确认。
- 找不到匹配项只进入pending，不立即报错。
- payload mismatch和transaction缺失在`report_phase`统一判定。

如果需要准实时检查，可后续增加pending超时机制，但超时报错门限必须大于系统允许的最大合法延迟。

## 8. 仿真结束判定

`report_phase()`执行以下检查：

1. 相同键的expected和actual都存在，但payload不同：报告`MISMATCH`。
2. 只有expected存在：报告`MISSING ACTUAL`。
3. 只有actual存在：报告`MISSING EXPECTED`。
4. 检查match数量是否达到`m_min_trans_num`。
5. 汇总match、mismatch、missing actual和missing expected数量。

通过条件：

```text
mismatch == 0
missing_actual == 0
missing_expected == 0
match >= m_min_trans_num
所有pending队列为空
```

压力测试当前要求：

```text
slave0 match >= 610
slave1 match >= 298
```

最低匹配数用于防止expected和actual同时漏采时，因两侧pending都为空而误判通过。

## 9. 日志规格

### 9.1 匹配成功

每个byte匹配成功时产生一条`UVM_MEDIUM`摘要：

```text
MATCH key=1:0000000000001234 src=0 dst=0 id=0x12 data=0x5a
```

默认`UVM_LOW`运行时不显示逐byte成功信息，只显示最终汇总。调试时使用：

```bash
make run TC=<test> VERBOSITY=UVM_MEDIUM NO_WAVE=1
```

### 9.2 Payload不匹配

在`report_phase`使用`UVM_ERROR`打印：

```text
MISMATCH key=<key>: <第一个差异字段>
EXPECTED:
<expected完整transaction>
ACTUAL:
<actual完整transaction>
```

### 9.3 单边缺失

```text
MISSING ACTUAL key=<key>
EXPECTED:
<expected完整transaction>
```

或：

```text
MISSING EXPECTED key=<key>
ACTUAL:
<actual完整transaction>
```

## 10. 配置项

| 配置项 | 默认值 | 说明 |
|---|---:|---|
| `m_scb_check_en` | 1 | 总比较开关 |
| `m_check_fifo_en` | 1 | 仿真结束时检查pending |
| `m_compare_mask` | `32'hffff_ffff` | scoreboard允许比较的字段 |
| `m_min_trans_num` | 0 | 最低成功匹配数量 |

`flush_tlm_fifo()`会清空expected/actual FIFO和全部pending队列，可用于reset恢复。

## 11. 已验证场景

- FIXED、INCR、WRAP burst。
- BYTE、HALFWORD、WORD传输。
- burst长度1、2、4、5、7、8、16。
- narrow和非对齐访问。
- sparse strobe `0x5`和`0xa`。
- 两个master、两个slave。
- 多ID outstanding。
- 多master竞争同一slave。
- expected和actual反序到达。
- payload mismatch识别。

## 12. 能力边界

- Scoreboard比较访问结果，不检查AXI五通道周期时序；协议规则由Cadence AXI VIP checker负责。
- 不建立memory state，不能独立判断slave返回的数据本身是否符合memory内容。
- 不预测寄存器side effect，如clear-on-read或write-one-to-clear。
- 如果两笔访问的方向、地址、数据和所有有效字段完全相同，交换两笔访问的因果关系无法被识别。
- 下游协议删除ID后，只能验证访问集合，不能证明访问来自具体master。
- 当前没有pending超时，因此最终mismatch和missing在仿真结束时确认。
- 未映射地址在crossbar内部直接返回DECERR时，需要独立error endpoint scoreboard。
