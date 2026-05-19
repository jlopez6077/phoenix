module phx_axil_register_top (
  input logic clk,
  input logic rst_n,

  // Manually break out the AXI-Lite Write Channel
  input  logic [31:0] s_axil_awaddr,
  input  logic        s_axil_awvalid,
  output logic        s_axil_awready,
  input  logic [31:0] s_axil_wdata,
  input  logic        s_axil_wvalid,
  output logic        s_axil_wready,
  output logic [1:0]  s_axil_bresp,
  output logic        s_axil_bvalid,
  input  logic        s_axil_bready,

  // Manually break out the AXI-Lite Read Channel
  input  logic [31:0] s_axil_araddr,
  input  logic        s_axil_arvalid,
  output logic        s_axil_arready,
  output logic [31:0] s_axil_rdata,
  output logic [1:0]  s_axil_rresp,
  output logic        s_axil_rvalid,
  input  logic        s_axil_rready
);

  // 1. Instantiate the actual Interface
  phx_axil_if #( .DATA_W(32), .ADDR_W(32) ) axil_if();

  // 2. Map the pins to the interface signals
  assign axil_if.awaddr  = s_axil_awaddr;
  assign axil_if.awvalid = s_axil_awvalid;
  assign s_axil_awready  = axil_if.awready;
  assign axil_if.wdata   = s_axil_wdata;
  assign axil_if.wvalid  = s_axil_wvalid;
  assign s_axil_wready   = axil_if.wready;
  assign s_axil_bresp    = axil_if.bresp;
  assign s_axil_bvalid   = axil_if.bvalid;
  assign axil_if.bready  = s_axil_bready;

  assign axil_if.araddr  = s_axil_araddr;
  assign axil_if.arvalid = s_axil_arvalid;
  assign s_axil_arready  = axil_if.arready;
  assign s_axil_rdata    = axil_if.rdata;
  assign s_axil_rresp    = axil_if.rresp;
  assign s_axil_rvalid   = axil_if.rvalid;
  assign axil_if.rready  = s_axil_rready;

  // 3. Instantiate your Register Module
  phx_axil_register u_dut (
    .clk(clk),
    .rst_n(rst_n),
    .s_axil_wr(axil_if.wr_slv),
    .s_axil_rd(axil_if.rd_slv)
  );

endmodule
