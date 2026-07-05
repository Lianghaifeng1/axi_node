//------------------------------------------------------------------------------
// File       : intr_response_flow.svh
// Description: 通用中断响应程序flow
//              - 支持自由添加中断源
//              - 支持mask机制（mask=1才送给CPU）
//              - 支持中断嵌套（随机打断，小概率）
// Usage      : `include "intr_response_flow.svh" inside base_vseq class
//------------------------------------------------------------------------------//----------------------------------------------------------
// Typedefs
//----------------------------------------------------------
typedef struct {
  string      name;           // 中断源名称
  string      reg_block;      // 寄存器块名称
  string      state_reg;      // 中断状态寄存器名（标志位）
  string      enable_reg;     // 中断使能寄存器名（mask）
  int         state_bit_pos;  // 状态寄存器位位置
  int         enable_bit_pos; // 使能寄存器位位置（默认等于state_bit_pos）
} intr_source_cfg_t;

//----------------------------------------------------------
// Interrupt Source Map (project-specific, register via register_intr_source)
//----------------------------------------------------------
intr_source_cfg_t intr_source_map[string];
string intr_reg_order[$]; // 按注册顺序保存中断源名称

//----------------------------------------------------------
// Global variables for interrupt handling
//----------------------------------------------------------
bit intr_handler_active = 0;  // 当前是否有中断处理在进行
string current_intr_name = ""; // 当前处理的中断名称
int unsigned intr_clr_delay_clks = 1; // 清除后等待的时钟数
time         intr_clr_delay_time = 1ns; // 无时钟时的最小等待
bit          intr_rescan_enable = 0; // 处理完一轮pending后是否重扫
bit          intr_response_stop_requested = 0; // 请求停止后台中断响应线程
bit          intr_response_flow_running = 0; // 后台中断响应线程是否在运行
uvm_event    intr_handled_ev[string]; // 中断处理完成事件
int unsigned intr_handled_cnt[string]; // 中断处理完成计数

//----------------------------------------------------------
// Function: register_intr_source
// Description: 注册一个中断源
//----------------------------------------------------------
function void register_intr_source(
  string name,           // 中断源名称
  string reg_block,      // 寄存器块名称
  string state_reg,      // 中断状态寄存器名
  string enable_reg,     // 中断使能寄存器名（mask）
  int    state_bit_pos,  // 状态位位置
  int    enable_bit_pos = -1 // 使能位位置（默认同state位）
);
  intr_source_cfg_t cfg;

  if (intr_source_map.exists(name)) begin
    `uvm_warning(get_name(), $sformatf("[INTR] Interrupt source %0s already registered, overwriting", name))
  end else begin
    intr_reg_order.push_back(name);
  end

  if (enable_bit_pos < 0)
    enable_bit_pos = state_bit_pos;

  cfg.name           = name;
  cfg.reg_block      = reg_block;
  cfg.state_reg      = state_reg;
  cfg.enable_reg     = enable_reg;
  cfg.state_bit_pos  = state_bit_pos;
  cfg.enable_bit_pos = enable_bit_pos;

  intr_source_map[name] = cfg;
  `uvm_info(get_name(), $sformatf("[INTR] Registered interrupt source: %0s (state bit %0d, enable bit %0d)",
            name, cfg.state_bit_pos, cfg.enable_bit_pos), UVM_LOW)
endfunction

//----------------------------------------------------------
// Task: set_intr_clear_delay
// Description: 设置清除后确认延时
//----------------------------------------------------------
task set_intr_clear_delay(int unsigned clks = 1, time delay = 1ns);
  intr_clr_delay_clks = clks;
  intr_clr_delay_time = delay;
endtask

//----------------------------------------------------------
// Task: set_intr_rescan_enable
// Description: 设置处理中是否重扫pending中断
//----------------------------------------------------------
task set_intr_rescan_enable(bit enable = 1);
  intr_rescan_enable = enable;
endtask

//----------------------------------------------------------
// Function: ensure_intr_handled_event
// Description: 确保中断处理完成事件已创建
//----------------------------------------------------------
function void ensure_intr_handled_event(string intr_name);
  if (!intr_handled_ev.exists(intr_name))
    intr_handled_ev[intr_name] = new($sformatf("intr_handled_%0s", intr_name));
endfunction

//----------------------------------------------------------
// Function: get_intr_handled_cnt
// Description: 获取中断处理完成计数
//----------------------------------------------------------
function int unsigned get_intr_handled_cnt(string intr_name);
  if (!intr_handled_cnt.exists(intr_name))
    return 0;
  return intr_handled_cnt[intr_name];
endfunction

//----------------------------------------------------------
// Task: reset_intr_handled_cnt
// Description: 清空指定中断的处理完成计数
//----------------------------------------------------------
task reset_intr_handled_cnt(string intr_name);
  ensure_intr_handled_event(intr_name);
  intr_handled_cnt[intr_name] = 0;
  intr_handled_ev[intr_name].reset();
endtask

//----------------------------------------------------------
// Task: notify_intr_handled
// Description: 通知中断已经被完整处理
//----------------------------------------------------------
task notify_intr_handled(string intr_name);
  ensure_intr_handled_event(intr_name);
  intr_handled_cnt[intr_name] = get_intr_handled_cnt(intr_name) + 1;
  intr_handled_ev[intr_name].trigger();
  `uvm_info(get_name(), $sformatf("[INTR] Notify handled interrupt: %0s (count=%0d)",
            intr_name, intr_handled_cnt[intr_name]), UVM_MEDIUM)
endtask

//----------------------------------------------------------
// Task: wait_intr_handled_cnt
// Description: 等待指定中断处理完成计数达到目标值
//----------------------------------------------------------
task wait_intr_handled_cnt(
  string       intr_name,
  int unsigned target_cnt,
  int          timeout = 5000
);
  bit done = 0;

  ensure_intr_handled_event(intr_name);

  fork : wait_intr_handled_cnt_fork
    begin
      while (get_intr_handled_cnt(intr_name) < target_cnt)
        intr_handled_ev[intr_name].wait_trigger();
      done = 1;
    end
    begin
      #(1us * timeout);
      if (!done)
        `uvm_fatal(get_name(),
                   $sformatf("[INTR] Timeout %0d us waiting handled count of %0s to reach %0d (current=%0d)",
                             timeout, intr_name, target_cnt, get_intr_handled_cnt(intr_name)))
    end
  join_any
  disable wait_intr_handled_cnt_fork;
endtask

//----------------------------------------------------------
// Task: wait_next_intr_handled
// Description: 等待下一次指定中断被完整处理
//----------------------------------------------------------
task wait_next_intr_handled(
  string intr_name,
  int    timeout = 5000
);
  int unsigned base_cnt;

  base_cnt = get_intr_handled_cnt(intr_name);
  wait_intr_handled_cnt(intr_name, base_cnt + 1, timeout);
endtask

//----------------------------------------------------------
// Task: request_interrupt_response_stop
// Description: 请求停止后台中断响应线程
//----------------------------------------------------------
task request_interrupt_response_stop();
  intr_response_stop_requested = 1;
endtask

//----------------------------------------------------------
// Task: clear_interrupt_response_stop
// Description: 清除后台中断响应线程停止请求
//----------------------------------------------------------
task clear_interrupt_response_stop();
  intr_response_stop_requested = 0;
endtask

//----------------------------------------------------------
// Task: get_intr_reg_block
// Description: 获取寄存器块句柄（项目特定，需要根据实际reg_model调整）
//----------------------------------------------------------
task get_intr_reg_block(string reg_block_name, output uvm_reg_block sub_block);
  // === Project-specific: get reg_block (modify based on your reg_model hierarchy) ===
  if(uvm_is_match("*word_access*", reg_block_name))
    sub_block = m_cfg_h.m_dut_cfg_h.m_word_regs_model_h.get_block_by_name(reg_block_name);
  else
    sub_block = m_cfg_h.m_dut_cfg_h.m_regs_model_h.get_block_by_name(reg_block_name);
endtask

//----------------------------------------------------------
// Task: read_intr_state
// Description: 读取中断状态寄存器
//----------------------------------------------------------
task read_intr_state(
  intr_source_cfg_t cfg,
  output uvm_status_e stat,
  output uvm_reg_data_t rdata
);
  uvm_reg        target_reg;
  uvm_reg_block  sub_block;

  get_intr_reg_block(cfg.reg_block, sub_block);
  if (sub_block == null) begin
    `uvm_fatal(get_name(), $sformatf("[INTR] Reg block not found: %0s", cfg.reg_block))
  end

  target_reg = sub_block.get_reg_by_name(cfg.state_reg);
  if (target_reg == null) begin
    `uvm_fatal(get_name(), $sformatf("[INTR] Reg not found: %0s.%0s", cfg.reg_block, cfg.state_reg))
  end

  target_reg.read(stat, rdata);
endtask

//----------------------------------------------------------
// Task: read_intr_enable
// Description: 读取中断使能寄存器（mask）
//----------------------------------------------------------
task read_intr_enable(
  intr_source_cfg_t cfg,
  output uvm_status_e stat,
  output uvm_reg_data_t rdata
);
  uvm_reg        target_reg;
  uvm_reg_block  sub_block;

  get_intr_reg_block(cfg.reg_block, sub_block);
  if (sub_block == null) begin
    `uvm_fatal(get_name(), $sformatf("[INTR] Reg block not found: %0s", cfg.reg_block))
  end

  target_reg = sub_block.get_reg_by_name(cfg.enable_reg);
  if (target_reg == null) begin
    `uvm_fatal(get_name(), $sformatf("[INTR] Reg not found: %0s.%0s", cfg.reg_block, cfg.enable_reg))
  end

  target_reg.read(stat, rdata);
endtask

//----------------------------------------------------------
// Task: clear_intr
// Description: 清除中断标志位
//----------------------------------------------------------
task clear_intr(intr_source_cfg_t cfg);
  uvm_status_e   stat;
  uvm_reg_data_t rdata;
  uvm_reg        target_reg;
  uvm_reg_block  sub_block;
  uvm_reg_data_t mask;
  int unsigned   data_w;
  string         lock_key;
  semaphore      clr_sem;

  get_intr_reg_block(cfg.reg_block, sub_block);
  target_reg = sub_block.get_reg_by_name(cfg.state_reg);

  data_w = $bits(uvm_reg_data_t);
  if (cfg.state_bit_pos >= data_w) begin
    `uvm_fatal(get_name(), $sformatf("[INTR] state_bit_pos %0d exceeds uvm_reg_data_t width %0d",
              cfg.state_bit_pos, data_w))
  end
  mask = uvm_reg_data_t'(1) << cfg.state_bit_pos;

  lock_key = target_reg.get_full_name();
  lock_intr_clr_reg(lock_key, clr_sem);

  target_reg.read(stat, rdata);
  if ((rdata & mask) != 0) begin
    target_reg.write(stat, mask);  // W1C: write 1 to clear

    // 验证清除
    if (aclk_rst_vif != null) begin
      if (intr_clr_delay_clks == 0) intr_clr_delay_clks = 1;
      repeat (intr_clr_delay_clks) @(posedge aclk_rst_vif.clk);
    end else begin
      if (intr_clr_delay_time == 0) intr_clr_delay_time = 1ns;
      #intr_clr_delay_time;
    end
    target_reg.read(stat, rdata);
    if ((rdata & mask) != 0) begin
      `uvm_error(get_name(), $sformatf("[INTR] Cannot clear %0s, val=0x%08h", cfg.name, rdata))
    end
  end

  unlock_intr_clr_reg(clr_sem);
endtask

//----------------------------------------------------------
// Task: check_intr_pending
// Description: 检查中断是否pending且未被mask
// Note: Changed from function to task because it calls tasks (read_intr_state, read_intr_enable)
//----------------------------------------------------------
task check_intr_pending(intr_source_cfg_t cfg, output bit is_pending);
  uvm_status_e   stat;
  uvm_reg_data_t state_data;
  uvm_reg_data_t enable_data;
  uvm_reg_data_t state_mask;
  uvm_reg_data_t enable_mask;
  int unsigned   data_w;
  bit            state_bit;
  bit            enable_bit;

  data_w = $bits(uvm_reg_data_t);
  if (cfg.state_bit_pos >= data_w) begin
    `uvm_fatal(get_name(), $sformatf("[INTR] state_bit_pos %0d exceeds uvm_reg_data_t width %0d",
              cfg.state_bit_pos, data_w))
  end
  if (cfg.enable_bit_pos >= data_w) begin
    `uvm_fatal(get_name(), $sformatf("[INTR] enable_bit_pos %0d exceeds uvm_reg_data_t width %0d",
              cfg.enable_bit_pos, data_w))
  end
  state_mask  = uvm_reg_data_t'(1) << cfg.state_bit_pos;
  enable_mask = uvm_reg_data_t'(1) << cfg.enable_bit_pos;

  read_intr_state(cfg, stat, state_data);
  read_intr_enable(cfg, stat, enable_data);

  state_bit  = (state_data & state_mask) != 0;
  enable_bit = (enable_data & enable_mask) != 0;

  // 只有state=1且enable=1（mask=1）的中断才处理
  is_pending = (state_bit && enable_bit);
endtask

//----------------------------------------------------------
// Task: find_pending_intr_sources
// Description: 查找所有pending且未被mask的中断源
//----------------------------------------------------------
task find_pending_intr_sources(output string pending_intr_list[$]);
  bit is_pending;
  pending_intr_list.delete();

  foreach (intr_reg_order[i]) begin
    string intr_name;
    intr_name = intr_reg_order[i];
    if (intr_source_map.exists(intr_name)) begin
      check_intr_pending(intr_source_map[intr_name], is_pending);
      if (is_pending) begin
        pending_intr_list.push_back(intr_name);
      end
    end
  end
endtask

//----------------------------------------------------------
// Function: select_intr_from_pending
// Description: 保留接口，当前返回第一个pending
//----------------------------------------------------------
function void select_intr_from_pending(ref string pending_intr_list[$], output string selected_intr);
  if (pending_intr_list.size() == 0) begin
    selected_intr = "";
    return;
  end

  if (pending_intr_list.size() == 1) begin
    selected_intr = pending_intr_list[0];
    return;
  end

  selected_intr = pending_intr_list[0];
endfunction

//----------------------------------------------------------
// Task: call_intr_handler
// Description: 调用对应的中断处理函数
//             用户需要在base_vseq中实现handle_interrupt_by_name task
//----------------------------------------------------------
task call_intr_handler(string intr_name);
  `uvm_info(get_name(), $sformatf("[INTR] Calling handler for: %0s", intr_name), UVM_MEDIUM)

  // 调用用户实现的统一接口
  // 用户需要在base_vseq中override handle_interrupt_by_name task
  handle_interrupt_by_name(intr_name);
endtask

//----------------------------------------------------------
// Task: handle_interrupt_by_name (用户必须在base_vseq中override)
// Description: 根据中断名称调用对应的处理函数
//             这是一个virtual task，用户必须在base_vseq中实现
//----------------------------------------------------------
virtual task handle_interrupt_by_name(string intr_name);
  // 用户必须在base_vseq中override此task
  // 示例实现：
  //   case (intr_name)
  //     "tx_done": handle_tx_done_interrupt();
  //     "rx_ready": handle_rx_ready_interrupt();
  //     default: `uvm_error(get_name(), $sformatf("Unknown interrupt: %0s", intr_name))
  //   endcase
  `uvm_fatal(get_name(), $sformatf("[INTR] handle_interrupt_by_name not implemented! Please override in base_vseq for interrupt: %0s", intr_name))
endtask

//----------------------------------------------------------
// Task: wait_for_int_o
// Description: 等待int_o信号assert
//             用户需要在base_vseq中override此task以访问实际的中断信号
//----------------------------------------------------------
virtual task wait_for_int_o();
  // === Project-specific: wait for int_o signal ===
  // 用户需要在base_vseq中override此task
  // 示例实现：
  //   @(posedge m_dut_vif_h.int_o) 或
  //   wait(m_dut_vif_h.int_o == 1) 或
  //   @(posedge intr_vif.pins)
  //
  // 默认实现：轮询检查pending中断（作为fallback）
  bit found = 0;
  string pending_list[$];

  while (!found) begin
    @(posedge aclk_rst_vif.clk);
    find_pending_intr_sources(pending_list);
    if (pending_list.size() > 0) begin
      found = 1;
    end
  end
endtask

//----------------------------------------------------------
// Task: check_int_o_asserted
// Description: 检查int_o信号是否assert（非阻塞）
//             用户需要在base_vseq中override此task以访问实际的中断信号
// Note: Changed from function to task because it calls find_pending_intr_sources task
//----------------------------------------------------------
virtual task check_int_o_asserted(output bit is_asserted);
  // === Project-specific: check int_o signal ===
  // 用户需要在base_vseq中override此task
  // 示例实现：
  //   is_asserted = (m_dut_vif_h.int_o == 1); 或
  //   is_asserted = (intr_vif.pins != 0);
  //   return;
  //
  // 默认实现：检查是否有pending中断（作为fallback）
  string pending_list[$];
  find_pending_intr_sources(pending_list);
  is_asserted = (pending_list.size() > 0);
endtask

//----------------------------------------------------------
// Task: handle_single_interrupt
// Description: 处理单个中断
//              在IP环境只有一个int_o，不会真正被其他中断源打断。
//              为了模拟SoC里“更高优先级中断打断当前中断”的效果，
//              这里用**随机暂停一段时间**来模拟 CPU 被外部打断。
//----------------------------------------------------------
task handle_single_interrupt(
  string intr_name,
  real   nest_prob
);
  bit            do_pause;
  int            pause_clks;

  // 更新全局状态（用于debug和状态跟踪）
  intr_handler_active = 1;
  current_intr_name = intr_name;

  `uvm_info(get_name(), $sformatf("[INTR] >>> Entering interrupt handler: %0s", intr_name), UVM_LOW)

  // 决定是否"被外部打断"：小概率插入一段随机暂停时间
  // nest_prob 表示被打断的概率（0.0 ~ 1.0）
  do_pause = ($urandom_range(0, 1000) < integer'(nest_prob * 1000.0));
  if (do_pause) begin
    // 随机暂停若干个时钟周期来模拟CPU去处理更高优先级中断
    // 可以根据需要调整最小/最大暂停周期
    pause_clks = $urandom_range(5, 50);
    `uvm_info(get_name(),
              $sformatf("[INTR] *** Simulate external higher-priority interrupt: pause %0d clks before handling %0s",
                        pause_clks, intr_name),
              UVM_MEDIUM)
    repeat (pause_clks) @(posedge aclk_rst_vif.clk);
  end

  // 真正处理当前IP的中断
  call_intr_handler(intr_name);

  // 清除中断标志位
  if (intr_source_map.exists(intr_name)) begin
    clear_intr(intr_source_map[intr_name]);
  end

  notify_intr_handled(intr_name);

  // 清除全局状态
  intr_handler_active = 0;
  current_intr_name = "";

  `uvm_info(get_name(), $sformatf("[INTR] <<< Exiting interrupt handler: %0s", intr_name), UVM_LOW)
endtask

//----------------------------------------------------------
// Task: process_interrupt_response
// Description: 核心中断响应处理流程
//----------------------------------------------------------
task process_interrupt_response(
  int    timeout = 10000,   // 超时时间（us）
  real   nest_prob = 0.1    // 中断嵌套概率（默认10%）
);
  string pending_intr_list[$];
  string selected_intr;
  bit    op_done = 0;

  clear_interrupt_response_stop();
  intr_response_flow_running = 1;
  `uvm_info(get_name(), $sformatf("[INTR] Starting interrupt response flow (nest_prob=%.1f%%)", nest_prob*100), UVM_LOW)

  while (!intr_response_stop_requested) begin
    op_done = 0;
    fork : intr_wait_fork
      begin
        // 等待int_o信号assert
        wait_for_int_o();
        if (!intr_response_stop_requested)
          op_done = 1;
      end
      begin
        #(1us * timeout);
        if (!op_done && !intr_response_stop_requested)
          `uvm_fatal(get_name(), $sformatf("[INTR] Timeout %0d us waiting for int_o!", timeout))
      end
      begin
        wait (intr_response_stop_requested == 1);
      end
    join_any
    disable intr_wait_fork;

    if (intr_response_stop_requested)
      break;

    // 查找所有pending且未被mask的中断源
    find_pending_intr_sources(pending_intr_list);

    if (pending_intr_list.size() > 0) begin
      do begin
        `uvm_info(get_name(), $sformatf("[INTR] Detected pending interrupts: %0d",
                  pending_intr_list.size()), UVM_LOW)

        foreach (pending_intr_list[i]) begin
          selected_intr = pending_intr_list[i];
          `uvm_info(get_name(), $sformatf("[INTR] Handling interrupt: %0s (%0d/%0d)",
                    selected_intr, i+1, pending_intr_list.size()), UVM_LOW)
          handle_single_interrupt(selected_intr, nest_prob);
        end

        if (intr_rescan_enable)
          find_pending_intr_sources(pending_intr_list);
      end while (intr_rescan_enable && (pending_intr_list.size() > 0));
    end else begin
      `uvm_info(get_name(), "[INTR] int_o asserted but no valid interrupt found (all masked?)", UVM_MEDIUM)
    end

    // 等待一个时钟周期，避免零延迟循环
    if (aclk_rst_vif != null)
      @(posedge aclk_rst_vif.clk);
    else
      #1ns;
  end

  intr_response_flow_running = 0;
  `uvm_info(get_name(), "[INTR] Interrupt response flow stopped", UVM_LOW)
endtask