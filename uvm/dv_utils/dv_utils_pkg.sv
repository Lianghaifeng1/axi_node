// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package dv_utils_pkg;
  // dep packages
  import uvm_pkg::*;

  // macro includes
  `include "dv_macros.svh"
  // uvm_macros.svh is included in tb_top_define.sv, no need to include here
  // `ifdef UVM
  //   `include "uvm_macros.svh"
  // `endif

  // common parameters used across all benches
  parameter int NUM_MAX_INTERRUPTS = 32;
  typedef logic [NUM_MAX_INTERRUPTS-1:0] interrupt_t;

  parameter int NUM_MAX_ALERTS = 32;
  typedef logic [NUM_MAX_ALERTS-1:0] alert_t;

  // types & variables
  typedef bit [31:0] uint;
  typedef bit [7:0]  uint8;
  typedef bit [15:0] uint16;
  typedef bit [31:0] uint32;
  typedef bit [63:0] uint64;

  // TODO: The above typedefs violate the name rule, which is fixed below. Cleanup the codebase to
  // use the typedefs below and remove the ones above.
  typedef bit [7:0]  uint8_t;
  typedef bit [15:0] uint16_t;
  typedef bit [31:0] uint32_t;
  typedef bit [63:0] uint64_t;


  // return the smaller value of 2 inputs
  function automatic int min2(int a, int b);
      return (a < b) ? a : b;
  endfunction

  // return the bigger value of 2 inputs
  function automatic int max2(int a, int b);
    return (a > b) ? a : b;
  endfunction

  // return the biggest value within the given queue of integers.
  function automatic int max(const ref int int_q[$]);
    `DV_CHECK_GT_FATAL(int_q.size(), 0, "max function cannot accept an empty queue of integers!",
                       $sformatf("%m"))
    // Assign the first value from the queue in case of negative integers.
    max = int_q[0];
    foreach (int_q[i]) max = max2(max, int_q[i]);
    return max;
  endfunction

  // get absolute value of the input. Usage: absolute(val) or absolute(a - b)
  function automatic uint absolute(int val);
    return val >= 0 ? val : -val;
  endfunction

  // endian swaps a 32-bit data word
  function automatic logic [31:0] endian_swap(logic [31:0] data);
    return {<<8{data}};
  endfunction

  // endian swaps bytes at a word granularity, while preserving overall word ordering.
  //
  // e.g. if `arr[] = '{'h0, 'h1, 'h2, 'h3, 'h4, 'h5, 'h6, 'h7}`, this function will produce:
  //      `'{'h3, 'h2, 'h1, 'h0, 'h7, 'h6, 'h5, 'h4}`
  function automatic void endian_swap_byte_arr(ref bit [7:0] arr[]);
    arr = {<< byte {arr}};
    arr = {<< 32 {arr}};
  endfunction

`ifdef UVM
  // Simple function to set max errors before quitting sim
  function automatic void set_max_quit_count(int n);
    uvm_report_server report_server = uvm_report_server::get_server();
    report_server.set_max_quit_count(n);
  endfunction

  // return if uvm_fatal occurred
  function automatic bit has_uvm_fatal_occurred();
    uvm_report_server report_server = uvm_report_server::get_server();
    return report_server.get_severity_count(UVM_FATAL) > 0;
  endfunction

  // get masked data based on provided byte mask; if csr reg handle is provided (optional) then
  // masked bytes from csr's mirrored value are returned, else masked bytes are 0's
  function automatic bit [bus_params_pkg::BUS_DW-1:0]
      get_masked_data(bit [bus_params_pkg::BUS_DW-1:0] data,
                      bit [bus_params_pkg::BUS_DBW-1:0] mask,
                      uvm_reg csr = null);
    bit [bus_params_pkg::BUS_DW-1:0] csr_data;
    csr_data = (csr != null) ? csr.get_mirrored_value() : '0;
    get_masked_data = data;
    foreach (mask[i]) begin
      if (~mask[i]) get_masked_data[i * 8 +: 8] = csr_data[i * 8 +: 8];
    end
  endfunction

  // create a sequence by name and return the handle of uvm_sequence
  function automatic uvm_sequence create_seq_by_name(string seq_name);
    uvm_object      obj;
    uvm_factory     factory;
    uvm_sequence    seq;

    factory = uvm_factory::get();
    obj = factory.create_object_by_name(seq_name, "", seq_name);
    if (obj == null) begin
      // print factory overrides to help debug
      factory.print(1);
      `uvm_fatal($sformatf("%m"), $sformatf("could not create %0s seq", seq_name))
    end
    if (!$cast(seq, obj)) begin
      `uvm_fatal($sformatf("%m"), $sformatf("cast failed - %0s is not a uvm_sequence", seq_name))
    end
    return seq;
  endfunction
`endif

  // Returns the hierarchical path to the interface / module N levels up.
  //
  // Meant to be invoked inside a module or interface.
  // hier:        String input of the interface / module, typically $sformatf("%m").
  // n_levels_up: Integer number of levels up the hierarchy to omit.
  //              Example: if (hier = tb.dut.foo.bar, n_levels_up = 2), then return tb.dut
  function automatic string get_parent_hier(string hier, int n_levels_up = 1);
    int idx;
    int level;
    if (n_levels_up <= 0) return hier;
    for (idx = hier.len() - 1; idx >= 0; idx--) begin
      if (hier[idx] == ".") level++;
      if (level == n_levels_up) break;
    end
    return (hier.substr(0, idx - 1));
  endfunction


endpackage
