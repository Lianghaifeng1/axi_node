class axi_crossbar_axi_transaction extends denaliCdn_axiTransaction;

  `uvm_object_utils(axi_crossbar_axi_transaction)

  cdnAxiUvmConfig cfg;

  function new(string name = "axi_crossbar_axi_transaction");
    super.new(name);
  endfunction

  function void pre_randomize();
    cdnAxiUvmSequencer seqr;

    super.pre_randomize();

    if (!$cast(seqr, get_sequencer())) begin
      `uvm_fatal(get_type_name(), "failed to cast sequencer")
    end

    if (!$cast(cfg, seqr.pAgent.cfg)) begin
      `uvm_fatal(get_type_name(), "failed to cast agent cfg")
    end

    this.SpecVer =
      (cfg.spec_ver == CDN_AXI_CFG_SPEC_VER_AMBA4) ?
      DENALI_CDN_AXI_SPECVERSION_AMBA4 :
      DENALI_CDN_AXI_SPECVERSION_AMBA3;
    this.SpecSubtype =
      (cfg.spec_subtype == CDN_AXI_CFG_SPEC_SUBTYPE_ACE) ?
      DENALI_CDN_AXI_SPECSUBTYPE_ACE :
      DENALI_CDN_AXI_SPECSUBTYPE_BASE;
    this.SpecInterface =
      (cfg.spec_interface == CDN_AXI_CFG_SPEC_INTERFACE_FULL) ?
      DENALI_CDN_AXI_SPECINTERFACE_FULL :
      DENALI_CDN_AXI_SPECINTERFACE_LITE;

    if (cfg.pins.rdata.size >= 1024 || cfg.pins.wdata.size >= 1024) begin
      this.BurstMaxSize = DENALI_CDN_AXI_TRANSFERSIZE_K_BITS;
    end else if (cfg.pins.rdata.size >= 512 || cfg.pins.wdata.size >= 512) begin
      this.BurstMaxSize = DENALI_CDN_AXI_TRANSFERSIZE_SIXTEEN_WORDS;
    end else if (cfg.pins.rdata.size >= 256 || cfg.pins.wdata.size >= 256) begin
      this.BurstMaxSize = DENALI_CDN_AXI_TRANSFERSIZE_EIGHT_WORDS;
    end else if (cfg.pins.rdata.size >= 128 || cfg.pins.wdata.size >= 128) begin
      this.BurstMaxSize = DENALI_CDN_AXI_TRANSFERSIZE_FOUR_WORDS;
    end else if (cfg.pins.rdata.size >= 64 || cfg.pins.wdata.size >= 64) begin
      this.BurstMaxSize = DENALI_CDN_AXI_TRANSFERSIZE_TWO_WORDS;
    end else if (cfg.pins.rdata.size >= 32 || cfg.pins.wdata.size >= 32) begin
      this.BurstMaxSize = DENALI_CDN_AXI_TRANSFERSIZE_WORD;
    end else if (cfg.pins.rdata.size >= 16 || cfg.pins.wdata.size >= 16) begin
      this.BurstMaxSize = DENALI_CDN_AXI_TRANSFERSIZE_HALFWORD;
    end else begin
      this.BurstMaxSize = DENALI_CDN_AXI_TRANSFERSIZE_BYTE;
    end

    this.SpecVer.rand_mode(0);
    this.SpecSubtype.rand_mode(0);
    this.SpecInterface.rand_mode(0);
    this.BurstMaxSize.rand_mode(0);
  endfunction

endclass

class axi_crossbar_axi_blocking_read_seq extends cdnAxiUvmSequence;

  rand axi_crossbar_axi_transaction trans;
  rand reg [63:0] address;
  rand reg [7:0] length;
  rand denaliCdn_axiTransferSizeT size;
  rand denaliCdn_axiBurstKindT kind;
  rand denaliCdn_axiSecureModeT secure;

  denaliCdn_axiTransaction response;
  uvm_sequence_item item;
  bit force_id;
  bit [63:0] fixed_id;

  constraint read_seq_c {
    length > 0;
    size != DENALI_CDN_AXI_TRANSFERSIZE_UNSET;
    kind inside {
      DENALI_CDN_AXI_BURSTKIND_FIXED,
      DENALI_CDN_AXI_BURSTKIND_INCR,
      DENALI_CDN_AXI_BURSTKIND_WRAP
    };
    kind == DENALI_CDN_AXI_BURSTKIND_WRAP -> length inside {2, 4, 8, 16};
    kind == DENALI_CDN_AXI_BURSTKIND_FIXED -> length < 16;
    secure != DENALI_CDN_AXI_SECUREMODE_UNSET;
  }

  `uvm_object_utils_begin(axi_crossbar_axi_blocking_read_seq)
    `uvm_field_object(response, UVM_ALL_ON)
  `uvm_object_utils_end

  `uvm_declare_p_sequencer(cdnAxiUvmSequencer)

  function new(string name = "axi_crossbar_axi_blocking_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_create(trans)
    start_item(trans);
    if (!trans.randomize() with {
      trans.Direction == DENALI_CDN_AXI_DIRECTION_READ;
      trans.StartAddress == address;
      trans.Length == length;
      trans.Size == size;
      trans.Kind == kind;
      trans.Secure == secure;
    }) begin
      `uvm_fatal(get_type_name(), "failed to randomize read transaction")
    end
    if (force_id)
      trans.IdTag = fixed_id;
    finish_item(trans);

    get_response(item, trans.get_transaction_id());
    if (!$cast(response, item)) begin
      `uvm_fatal(get_type_name(), "failed to cast read response")
    end
  endtask

endclass

class axi_crossbar_axi_blocking_write_seq extends cdnAxiUvmSequence;

  rand axi_crossbar_axi_transaction trans;
  rand reg [63:0] address;
  rand reg [7:0] length;
  rand denaliCdn_axiTransferSizeT size;
  rand denaliCdn_axiBurstKindT kind;
  rand denaliCdn_axiSecureModeT secure;

  denaliCdn_axiTransaction response;
  uvm_sequence_item item;
  bit force_id;
  bit [63:0] fixed_id;
  bit force_strobe;
  bit [31:0] fixed_strobe;

  constraint write_seq_c {
    length > 0;
    size != DENALI_CDN_AXI_TRANSFERSIZE_UNSET;
    kind inside {
      DENALI_CDN_AXI_BURSTKIND_FIXED,
      DENALI_CDN_AXI_BURSTKIND_INCR,
      DENALI_CDN_AXI_BURSTKIND_WRAP
    };
    kind == DENALI_CDN_AXI_BURSTKIND_WRAP -> length inside {2, 4, 8, 16};
    kind == DENALI_CDN_AXI_BURSTKIND_FIXED -> length < 16;
    secure != DENALI_CDN_AXI_SECUREMODE_UNSET;
  }

  `uvm_object_utils_begin(axi_crossbar_axi_blocking_write_seq)
    `uvm_field_object(response, UVM_ALL_ON)
  `uvm_object_utils_end

  `uvm_declare_p_sequencer(cdnAxiUvmSequencer)

  function new(string name = "axi_crossbar_axi_blocking_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_create(trans)
    start_item(trans);
    if (!trans.randomize() with {
      trans.Direction == DENALI_CDN_AXI_DIRECTION_WRITE;
      trans.StartAddress == address;
      trans.Length == length;
      trans.Size == size;
      trans.Kind == kind;
      trans.Secure == secure;
    }) begin
      `uvm_fatal(get_type_name(), "failed to randomize write transaction")
    end
    if (force_id)
      trans.IdTag = fixed_id;
    if (force_strobe) begin
      trans.StrobeArray = new[length];
      foreach (trans.StrobeArray[i])
        trans.StrobeArray[i] = fixed_strobe;
    end
    finish_item(trans);

    get_response(item, trans.get_transaction_id());
    if (!$cast(response, item)) begin
      `uvm_fatal(get_type_name(), "failed to cast write response")
    end
  endtask

endclass
