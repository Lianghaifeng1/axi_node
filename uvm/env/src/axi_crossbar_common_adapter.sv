typedef enum bit {
  AXI_COMMON_UPSTREAM,
  AXI_COMMON_DOWNSTREAM
} axi_crossbar_common_side_e;

class axi_crossbar_common_adapter_context extends uvm_object;
  axi_crossbar_common_side_e side;
  int unsigned port_index;
  int unsigned source_port;
  int unsigned dest_port;
  int unsigned data_width;
  int unsigned original_id_width;
  bit downstream_id_contains_source;

  `uvm_object_utils(axi_crossbar_common_adapter_context)

  function new(string name = "axi_crossbar_common_adapter_context");
    super.new(name);
    data_width = `AXI_CROSSBAR_DATA_WIDTH;
    original_id_width = 8;
  endfunction
endclass

virtual class axi_crossbar_common_adapter extends uvm_object;
  function new(string name = "axi_crossbar_common_adapter");
    super.new(name);
  endfunction

  pure virtual function void convert(
    uvm_object protocol_tr,
    axi_crossbar_common_adapter_context ctx,
    ref axi_crossbar_common_transaction result[$]
  );
endclass

`ifndef AXI_VIP_SVT
class axi_crossbar_cdn_axi_common_adapter extends axi_crossbar_common_adapter;
  `uvm_object_utils(axi_crossbar_cdn_axi_common_adapter)

  function new(string name = "axi_crossbar_cdn_axi_common_adapter");
    super.new(name);
  endfunction

  function axi_crossbar_common_status_e convert_status(denaliCdn_axiResponseT response);
    case (response)
      DENALI_CDN_AXI_RESPONSE_OKAY:   return AXI_COMMON_STATUS_OKAY;
      DENALI_CDN_AXI_RESPONSE_EXOKAY: return AXI_COMMON_STATUS_EXOKAY;
      DENALI_CDN_AXI_RESPONSE_SLVERR: return AXI_COMMON_STATUS_SLVERR;
      DENALI_CDN_AXI_RESPONSE_DECERR: return AXI_COMMON_STATUS_DECERR;
      default:                        return AXI_COMMON_STATUS_UNKNOWN;
    endcase
  endfunction

  function bit [63:0] get_beat_address(
    denaliCdn_axiTransaction tr,
    int unsigned beat,
    int unsigned bytes_per_beat
  );
    bit [63:0] wrap_bytes;
    bit [63:0] wrap_base;
    case (tr.Kind)
      DENALI_CDN_AXI_BURSTKIND_FIXED:
        return tr.StartAddress;
      DENALI_CDN_AXI_BURSTKIND_WRAP: begin
        wrap_bytes = tr.Length * bytes_per_beat;
        if (wrap_bytes == 0)
          return tr.StartAddress;
        wrap_base = (tr.StartAddress / wrap_bytes) * wrap_bytes;
        return wrap_base + ((tr.StartAddress - wrap_base + beat * bytes_per_beat) % wrap_bytes);
      end
      default:
        return tr.StartAddress + beat * bytes_per_beat;
    endcase
  endfunction

  virtual function void convert(
    uvm_object protocol_tr,
    axi_crossbar_common_adapter_context ctx,
    ref axi_crossbar_common_transaction result[$]
  );
    denaliCdn_axiTransaction tr;
    axi_crossbar_common_transaction common_tr;
    int unsigned bytes_per_beat;
    int unsigned bus_bytes;
    int unsigned data_index;
    int unsigned lane;
    bit [63:0] beat_address;
    bit [63:0] id_mask;
    bit byte_enabled;

    result.delete();
    if (!$cast(tr, protocol_tr)) begin
      `uvm_error(get_type_name(), "protocol transaction is not denaliCdn_axiTransaction")
      return;
    end
    if (tr.Size == DENALI_CDN_AXI_TRANSFERSIZE_UNSET || tr.Length == 0) begin
      `uvm_error(get_type_name(), $sformatf("invalid AXI burst Size=%0d Length=%0d", tr.Size, tr.Length))
      return;
    end

    bytes_per_beat = 1 << (int'(tr.Size) - 1);
    bus_bytes = ctx.data_width / 8;
    id_mask = (64'h1 << ctx.original_id_width) - 1;

    for (int unsigned beat = 0; beat < tr.Length; beat++) begin
      beat_address = get_beat_address(tr, beat, bytes_per_beat);
      for (int unsigned byte_in_beat = 0; byte_in_beat < bytes_per_beat; byte_in_beat++) begin
        data_index = beat * bytes_per_beat + byte_in_beat;
        if (data_index >= tr.Data.size()) begin
          `uvm_error(get_type_name(),
            $sformatf("AXI Data[] too small: index=%0d size=%0d", data_index, tr.Data.size()))
          return;
        end

        lane = (beat_address + byte_in_beat) % bus_bytes;
        byte_enabled = 1;
        if (tr.Direction == DENALI_CDN_AXI_DIRECTION_WRITE) begin
          if (beat >= tr.StrobeArray.size()) begin
            `uvm_error(get_type_name(),
              $sformatf("AXI StrobeArray[] too small: beat=%0d size=%0d", beat, tr.StrobeArray.size()))
            return;
          end
          byte_enabled = tr.StrobeArray[beat][lane];
        end
        if (!byte_enabled)
          continue;

        common_tr = axi_crossbar_common_transaction::type_id::create(
          $sformatf("common_b%0d_byte%0d", beat, byte_in_beat));
        common_tr.access = (tr.Direction == DENALI_CDN_AXI_DIRECTION_WRITE) ?
                           AXI_COMMON_WRITE : AXI_COMMON_READ;
        common_tr.address = beat_address + byte_in_beat;
        common_tr.data = tr.Data[data_index];
        common_tr.source_port = ctx.source_port;
        common_tr.dest_port = ctx.dest_port;
        common_tr.transaction_id = tr.IdTag & id_mask;
        common_tr.beat_index = beat;
        common_tr.byte_index = byte_in_beat;
        common_tr.source_protocol = "CDN_AXI";
        common_tr.valid_mask = axi_crossbar_common_transaction::CMP_ACCESS |
                               axi_crossbar_common_transaction::CMP_ADDR |
                               axi_crossbar_common_transaction::CMP_DATA |
                               axi_crossbar_common_transaction::CMP_STATUS |
                               axi_crossbar_common_transaction::CMP_SOURCE |
                               axi_crossbar_common_transaction::CMP_DEST |
                               axi_crossbar_common_transaction::CMP_ID;

        if (ctx.side == AXI_COMMON_DOWNSTREAM &&
            ctx.downstream_id_contains_source) begin
          common_tr.source_port = tr.IdTag >> ctx.original_id_width;
        end

        if (tr.Direction == DENALI_CDN_AXI_DIRECTION_WRITE) begin
          common_tr.status = convert_status(tr.Resp);
        end else if (beat < tr.TransfersResp.size()) begin
          common_tr.status = convert_status(tr.TransfersResp[beat]);
        end else begin
          common_tr.status = AXI_COMMON_STATUS_UNKNOWN;
          common_tr.valid_mask &= ~axi_crossbar_common_transaction::CMP_STATUS;
        end
        result.push_back(common_tr);
      end
    end
  endfunction
endclass
`else
class axi_crossbar_svt_axi_common_adapter extends axi_crossbar_common_adapter;
  `uvm_object_utils(axi_crossbar_svt_axi_common_adapter)

  function new(string name = "axi_crossbar_svt_axi_common_adapter");
    super.new(name);
  endfunction

  function axi_crossbar_common_status_e convert_status(svt_axi_transaction::resp_type_enum response);
    case (response)
      svt_axi_transaction::OKAY:   return AXI_COMMON_STATUS_OKAY;
      svt_axi_transaction::EXOKAY: return AXI_COMMON_STATUS_EXOKAY;
      svt_axi_transaction::SLVERR: return AXI_COMMON_STATUS_SLVERR;
      svt_axi_transaction::DECERR: return AXI_COMMON_STATUS_DECERR;
      default:                     return AXI_COMMON_STATUS_UNKNOWN;
    endcase
  endfunction

  function bit [63:0] get_beat_address(svt_axi_transaction tr, int unsigned beat,
                                       int unsigned bytes_per_beat);
    bit [63:0] wrap_bytes;
    bit [63:0] wrap_base;
    case (tr.burst_type)
      svt_axi_transaction::FIXED: return tr.addr;
      svt_axi_transaction::WRAP: begin
        wrap_bytes = tr.burst_length * bytes_per_beat;
        wrap_base = (tr.addr / wrap_bytes) * wrap_bytes;
        return wrap_base + ((tr.addr - wrap_base + beat * bytes_per_beat) % wrap_bytes);
      end
      default: return tr.addr + beat * bytes_per_beat;
    endcase
  endfunction

  virtual function void convert(uvm_object protocol_tr,
      axi_crossbar_common_adapter_context ctx,
      ref axi_crossbar_common_transaction result[$]);
    svt_axi_transaction tr;
    axi_crossbar_common_transaction common_tr;
    int unsigned bytes_per_beat;
    int unsigned bus_bytes;
    int unsigned lane;
    bit [63:0] beat_address;
    bit [63:0] id_mask;
    bit byte_enabled;

    result.delete();
    if (!$cast(tr, protocol_tr)) begin
      `uvm_error(get_type_name(), "protocol transaction is not svt_axi_transaction")
      return;
    end
    bytes_per_beat = 1 << int'(tr.burst_size);
    bus_bytes = ctx.data_width / 8;
    id_mask = (64'h1 << ctx.original_id_width) - 1;
    for (int unsigned beat = 0; beat < tr.burst_length; beat++) begin
      if (beat >= tr.data.size()) begin
        `uvm_error(get_type_name(), "SVT AXI data array is shorter than burst_length")
        return;
      end
      beat_address = get_beat_address(tr, beat, bytes_per_beat);
      for (int unsigned byte_in_beat = 0; byte_in_beat < bytes_per_beat; byte_in_beat++) begin
        lane = (beat_address + byte_in_beat) % bus_bytes;
        byte_enabled = (tr.xact_type != svt_axi_transaction::WRITE) ||
                       (beat < tr.wstrb.size() && tr.wstrb[beat][lane]);
        if (!byte_enabled)
          continue;
        common_tr = axi_crossbar_common_transaction::type_id::create(
          $sformatf("common_b%0d_byte%0d", beat, byte_in_beat));
        common_tr.access = (tr.xact_type == svt_axi_transaction::WRITE) ?
                           AXI_COMMON_WRITE : AXI_COMMON_READ;
        common_tr.address = beat_address + byte_in_beat;
        common_tr.data = tr.data[beat][lane*8 +: 8];
        common_tr.source_port = ctx.source_port;
        common_tr.dest_port = ctx.dest_port;
        common_tr.transaction_id = tr.id & id_mask;
        common_tr.beat_index = beat;
        common_tr.byte_index = byte_in_beat;
        common_tr.source_protocol = "SVT_AXI";
        common_tr.valid_mask = axi_crossbar_common_transaction::CMP_ACCESS |
          axi_crossbar_common_transaction::CMP_ADDR | axi_crossbar_common_transaction::CMP_DATA |
          axi_crossbar_common_transaction::CMP_STATUS | axi_crossbar_common_transaction::CMP_SOURCE |
          axi_crossbar_common_transaction::CMP_DEST | axi_crossbar_common_transaction::CMP_ID;
        if (ctx.side == AXI_COMMON_DOWNSTREAM && ctx.downstream_id_contains_source)
          common_tr.source_port = tr.id >> ctx.original_id_width;
        if (tr.xact_type == svt_axi_transaction::WRITE)
          common_tr.status = convert_status(tr.bresp);
        else if (beat < tr.rresp.size())
          common_tr.status = convert_status(tr.rresp[beat]);
        else
          common_tr.valid_mask &= ~axi_crossbar_common_transaction::CMP_STATUS;
        result.push_back(common_tr);
      end
    end
  endfunction
endclass
`endif
