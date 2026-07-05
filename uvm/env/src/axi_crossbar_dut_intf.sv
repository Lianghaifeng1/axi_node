`timescale 1ns/10ps

interface axi_crossbar_dut_intf ();

  parameter SETUP_TIME = 0.1ns;
  parameter HOLD_TIME  = 0.1ns;

  logic        clk;
  logic        rst_n;
  logic        sequence_starting;
  logic [31:0] stop_count;
  logic [31:0] timeout_count;
  logic        c_end_flag;
  logic        firmware_case_done;
  logic        firmware_data_error;
  logic        sequence_run_done;

  // ------------------------------------------------------------
  // BFM clocking
  // ------------------------------------------------------------
  clocking bfm_cb @(posedge clk);
    default input #SETUP_TIME output #HOLD_TIME;
    input rst_n;
  endclocking : bfm_cb

  // ------------------------------------------------------------
  // Monitor clocking
  // ------------------------------------------------------------
  clocking mon_cb @(posedge clk);
    default input #SETUP_TIME output #HOLD_TIME;
    input stop_count, timeout_count;
  endclocking : mon_cb

  // ------------------------------------------------------------
  // Modports
  // ------------------------------------------------------------
  modport bfm_mp (clocking bfm_cb);
  modport mon_mp (clocking mon_cb);

endinterface : axi_crossbar_dut_intf