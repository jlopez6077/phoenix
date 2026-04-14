
interface phx_apb_if #(
  parameter DATA_W = 32,
  parameter ADDR_W = 16
)();

  logic [ADDR_W-1:0]  paddr;
  logic               psel;
  logic               penable;
  logic               pwrite;
  logic [DATA_W-1:0]  pwdata;
  logic [DATA_W-1:0]  prdata;
  logic               pready;

  modport mst (
    output paddr,
    output psel,
    output penable,
    output pwrite,
    output pwdata,
    input prdata,
    input pready
  );

  modport slv (
    input paddr,
    input psel,
    input penable,
    input pwrite,
    input pwdata,
    output prdata,
    output pready
  );

endinterface
