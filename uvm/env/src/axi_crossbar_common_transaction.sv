typedef enum bit {
  AXI_COMMON_READ,
  AXI_COMMON_WRITE
} axi_crossbar_common_access_e;

typedef enum bit [2:0] {
  AXI_COMMON_STATUS_UNKNOWN,
  AXI_COMMON_STATUS_OKAY,
  AXI_COMMON_STATUS_EXOKAY,
  AXI_COMMON_STATUS_SLVERR,
  AXI_COMMON_STATUS_DECERR
} axi_crossbar_common_status_e;

class axi_crossbar_common_transaction extends uvm_sequence_item;
  localparam bit [31:0] CMP_ACCESS = 32'h0000_0001;
  localparam bit [31:0] CMP_ADDR   = 32'h0000_0002;
  localparam bit [31:0] CMP_DATA   = 32'h0000_0004;
  localparam bit [31:0] CMP_STATUS = 32'h0000_0008;
  localparam bit [31:0] CMP_SOURCE = 32'h0000_0010;
  localparam bit [31:0] CMP_DEST   = 32'h0000_0020;
  localparam bit [31:0] CMP_ID     = 32'h0000_0040;

  axi_crossbar_common_access_e access;
  bit [63:0] address;
  bit [7:0] data;
  axi_crossbar_common_status_e status;
  int unsigned source_port;
  int unsigned dest_port;
  bit [63:0] transaction_id;
  int unsigned beat_index;
  int unsigned byte_index;
  bit [31:0] valid_mask;
  string source_protocol;

  `uvm_object_utils_begin(axi_crossbar_common_transaction)
    `uvm_field_enum(axi_crossbar_common_access_e, access, UVM_ALL_ON)
    `uvm_field_int(address, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_enum(axi_crossbar_common_status_e, status, UVM_ALL_ON)
    `uvm_field_int(source_port, UVM_ALL_ON)
    `uvm_field_int(dest_port, UVM_ALL_ON)
    `uvm_field_int(transaction_id, UVM_ALL_ON)
    `uvm_field_int(beat_index, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(byte_index, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_int(valid_mask, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_field_string(source_protocol, UVM_ALL_ON | UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name = "axi_crossbar_common_transaction");
    super.new(name);
    status = AXI_COMMON_STATUS_UNKNOWN;
  endfunction

  function string get_match_key(bit [31:0] compare_mask);
    // Address and operation are the only fields guaranteed to survive
    // AXI-to-memory/register bridges.
    return $sformatf("%0d:%016h", access, address);
  endfunction

  function bit compare_payload(
    axi_crossbar_common_transaction rhs,
    bit [31:0] compare_mask,
    output string diff
  );
    bit [31:0] active_mask;
    diff = "";
    active_mask = compare_mask & valid_mask & rhs.valid_mask;

    if ((active_mask & CMP_ACCESS) && access != rhs.access)
      diff = $sformatf("access exp=%0d act=%0d", access, rhs.access);
    else if ((active_mask & CMP_ADDR) && address != rhs.address)
      diff = $sformatf("address exp=0x%016h act=0x%016h", address, rhs.address);
    else if ((active_mask & CMP_DATA) && data != rhs.data)
      diff = $sformatf("data exp=0x%02h act=0x%02h", data, rhs.data);
    else if ((active_mask & CMP_STATUS) && status != rhs.status)
      diff = $sformatf("status exp=%0d act=%0d", status, rhs.status);
    else if ((active_mask & CMP_SOURCE) && source_port != rhs.source_port)
      diff = $sformatf("source_port exp=%0d act=%0d", source_port, rhs.source_port);
    else if ((active_mask & CMP_DEST) && dest_port != rhs.dest_port)
      diff = $sformatf("dest_port exp=%0d act=%0d", dest_port, rhs.dest_port);
    else if ((active_mask & CMP_ID) && transaction_id != rhs.transaction_id)
      diff = $sformatf("transaction_id exp=0x%0h act=0x%0h", transaction_id, rhs.transaction_id);

    return diff == "";
  endfunction
endclass

typedef enum int unsigned {
  CPUW_DUMMY_RBC_IN,
  CPUW_DUMMY_MEM_IN,
  CPUW_DUMMY_RAM_OUT,
  CPUW_DUMMY_ROM_OUT,
  CPUW_DUMMY_PUBLIC_REG_OUT,
  CPUW_DUMMY_PRIVATE_REG_OUT,
  CPUW_DUMMY_RBC_OUT
} cpu_wrapper_dummy_port_e;

class cpu_wrapper_dummy_transaction extends uvm_sequence_item;
  cpu_wrapper_dummy_port_e port;
  axi_crossbar_common_access_e access;
  bit [63:0] address;
  bit [1023:0] data;
  bit [127:0] byte_en;
  axi_crossbar_common_status_e status;
  bit valid;
  bit ready;
  string protocol;

  `uvm_object_utils_begin(cpu_wrapper_dummy_transaction)
    `uvm_field_enum(cpu_wrapper_dummy_port_e, port, UVM_ALL_ON)
    `uvm_field_enum(axi_crossbar_common_access_e, access, UVM_ALL_ON)
    `uvm_field_int(address, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(byte_en, UVM_ALL_ON)
    `uvm_field_enum(axi_crossbar_common_status_e, status, UVM_ALL_ON)
    `uvm_field_int(valid, UVM_ALL_ON)
    `uvm_field_int(ready, UVM_ALL_ON)
    `uvm_field_string(protocol, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "cpu_wrapper_dummy_transaction");
    super.new(name);
    status = AXI_COMMON_STATUS_UNKNOWN;
    valid = 0;
    ready = 0;
    protocol = "DUMMY";
  endfunction

  function axi_crossbar_common_transaction to_common(
    string item_name,
    int unsigned source_port,
    int unsigned dest_port
  );
    axi_crossbar_common_transaction common_tr;
    common_tr = axi_crossbar_common_transaction::type_id::create(item_name);
    common_tr.access = access;
    common_tr.address = address;
    common_tr.data = data[7:0];
    common_tr.status = status;
    common_tr.source_port = source_port;
    common_tr.dest_port = dest_port;
    common_tr.transaction_id = 0;
    common_tr.beat_index = 0;
    common_tr.byte_index = 0;
    common_tr.source_protocol = protocol;
    common_tr.valid_mask = axi_crossbar_common_transaction::CMP_ACCESS |
                           axi_crossbar_common_transaction::CMP_ADDR |
                           axi_crossbar_common_transaction::CMP_DATA |
                           axi_crossbar_common_transaction::CMP_STATUS |
                           axi_crossbar_common_transaction::CMP_SOURCE |
                           axi_crossbar_common_transaction::CMP_DEST;
    return common_tr;
  endfunction
endclass
