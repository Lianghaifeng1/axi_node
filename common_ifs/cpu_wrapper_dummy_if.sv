interface cpu_wrapper_dummy_if #(
  parameter int ADDR_WIDTH = 64,
  parameter int DATA_WIDTH = 1024,
  parameter int RESP_WIDTH = 2
) (
  input logic clk,
  input logic rst_n
);
  localparam int STRB_WIDTH = DATA_WIDTH / 8;

  logic                  valid;
  logic                  ready;
  logic                  write;
  logic [ADDR_WIDTH-1:0] addr;
  logic [DATA_WIDTH-1:0] wdata;
  logic [STRB_WIDTH-1:0] wstrb;
  logic [DATA_WIDTH-1:0] rdata;
  logic [RESP_WIDTH-1:0] resp;

  task automatic drive_idle();
    valid = 1'b0;
    write = 1'b0;
    addr  = '0;
    wdata = '0;
    wstrb = '0;
  endtask

  task automatic slave_idle();
    ready = 1'b1;
    rdata = '0;
    resp  = '0;
  endtask

  task automatic init_dummy();
    drive_idle();
    slave_idle();
  endtask

  task automatic drive_request(
    input bit                  is_write,
    input logic [ADDR_WIDTH-1:0] req_addr,
    input logic [DATA_WIDTH-1:0] req_data = '0,
    input logic [STRB_WIDTH-1:0] req_strb = '1
  );
    @(posedge clk);
    valid <= 1'b1;
    write <= is_write;
    addr  <= req_addr;
    wdata <= req_data;
    wstrb <= req_strb;
    do begin
      @(posedge clk);
    end while (!ready);
    valid <= 1'b0;
  endtask

  task automatic wait_request(
    output bit                  is_write,
    output logic [ADDR_WIDTH-1:0] req_addr,
    output logic [DATA_WIDTH-1:0] req_data,
    output logic [STRB_WIDTH-1:0] req_strb
  );
    do begin
      @(posedge clk);
    end while (!(valid && ready));
    is_write = write;
    req_addr = addr;
    req_data = wdata;
    req_strb = wstrb;
  endtask

  modport master (
    input  clk, rst_n, ready, rdata, resp,
    output valid, write, addr, wdata, wstrb
  );

  modport slave (
    input  clk, rst_n, valid, write, addr, wdata, wstrb,
    output ready, rdata, resp
  );

  modport monitor (
    input clk, rst_n, valid, ready, write, addr, wdata, wstrb, rdata, resp
  );
endinterface
