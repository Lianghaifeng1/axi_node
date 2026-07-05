//------------------------------------------------------------------------------
// File       : intr_utils.svh
// Description: Interrupt wait/clear utilities
// Usage      : `include "intr_utils.svh" inside base_vseq class
//------------------------------------------------------------------------------

//----------------------------------------------------------
// Typedefs
//----------------------------------------------------------
typedef struct {
  string reg_block;
  string reg_name;
  int    hi_bit;
  int    lo_bit;
} intr_info_t;

typedef enum bit [1:0] {
  WAIT_INTR,
  CLR_INTR,
  WAIT_CLR_INTR
} intr_act_e;

//----------------------------------------------------------
// Interrupt Map (project-specific, modify for each project)
//----------------------------------------------------------
intr_info_t intr_map[string];
static semaphore intr_clr_sem_by_reg[string];
static semaphore intr_clr_sem_guard = new(1);

function void init_intr_map();
  // === Project-specific: register all interrupts here ===
  // intr_map["intr_name"] = '{reg_block: "block_name", reg_name: "REG_NAME", hi_bit: x, lo_bit: x};
endfunction

//----------------------------------------------------------
// Task: lock_intr_clr_reg
//----------------------------------------------------------
task automatic lock_intr_clr_reg(
  string           lock_key,
  output semaphore sem
);
  intr_clr_sem_guard.get(1);
  if ((!intr_clr_sem_by_reg.exists(lock_key)) || intr_clr_sem_by_reg[lock_key] == null)
    intr_clr_sem_by_reg[lock_key] = new(1);
  sem = intr_clr_sem_by_reg[lock_key];
  intr_clr_sem_guard.put(1);

  sem.get(1);
endtask

task automatic unlock_intr_clr_reg(semaphore sem);
  if (sem != null)
    sem.put(1);
endtask

//----------------------------------------------------------
// Task: wait_clr_intr
//----------------------------------------------------------
task wait_clr_intr(
  string     intr_id,
  int        timeout  = 5000,
  intr_act_e intr_act = WAIT_CLR_INTR,
  bit        chk_clr  = 1
);
  uvm_status_e   stat;
  uvm_reg_data_t rdata;
  uvm_reg        target_reg;
  uvm_reg_block  sub_block;
  intr_info_t    info;
  bit [31:0]     mask;
  bit            wait_done = 0;
  string         lock_key;
  semaphore      clr_sem;

  `uvm_info(get_name(), $sformatf("[INTR] Begin %0s: %0s", intr_act.name(), intr_id), UVM_LOW)

  if (!intr_map.exists(intr_id)) begin
    `uvm_error(get_name(), $sformatf("[INTR] Unknown intr_id: %0s", intr_id))
    return;
  end

  info = intr_map[intr_id];
  mask = ((1 << (info.hi_bit - info.lo_bit + 1)) - 1) << info.lo_bit;

  `uvm_info(get_name(), $sformatf("[INTR] %0s.%0s[%0d:%0d] mask=0x%08h",
            info.reg_block, info.reg_name, info.hi_bit, info.lo_bit, mask), UVM_MEDIUM)

  // === Project-specific: get reg_block (modify based on your reg_model hierarchy) ===
  if(uvm_is_match("*word_access*", info.reg_block))
    sub_block = m_cfg_h.m_dut_cfg_h.m_word_regs_model_h.get_block_by_name(info.reg_block);
  else
    sub_block = m_cfg_h.m_dut_cfg_h.m_regs_model_h.get_block_by_name(info.reg_block);

  target_reg = sub_block.get_reg_by_name(info.reg_name);
  if (target_reg == null) begin
    `uvm_fatal(get_name(), $sformatf("[INTR] Reg not found: %0s.%0s", info.reg_block, info.reg_name))
  end

  // WAIT
  if (intr_act != CLR_INTR) begin
    fork : intr_wait_fork
      begin
        do begin
          target_reg.read(stat, rdata);
          // === Project-specific: wait for clock (modify based on your clock interface) ===
          if ((rdata & mask) != mask) #1ns;
        end while ((rdata & mask) != mask);
        wait_done = 1;
      end

      begin
        #(1us * timeout);
        if (!wait_done)
          `uvm_fatal(get_name(), $sformatf("[INTR] Timeout %0d us waiting for %0s!", timeout, intr_id))
      end
    join_any
    disable intr_wait_fork;
  end

  // CLEAR
  if (intr_act != WAIT_INTR) begin
    lock_key = target_reg.get_full_name();
    lock_intr_clr_reg(lock_key, clr_sem);

    // Re-read after taking the lock so another thread that already cleared this
    // register does not trigger a redundant write and UVM warning.
    target_reg.read(stat, rdata);
    if ((rdata & mask) != 0) begin
      target_reg.write(stat, mask);
      if (chk_clr) begin
        target_reg.read(stat, rdata);
        if ((rdata & mask) != 0)
          `uvm_error(get_name(), $sformatf("[INTR] Cannot clear %0s, val=0x%08h", intr_id, rdata))
      end
    end

    unlock_intr_clr_reg(clr_sem);
  end

  `uvm_info(get_name(), $sformatf("[INTR] End %0s: %0s", intr_act.name(), intr_id), UVM_LOW)
endtask
