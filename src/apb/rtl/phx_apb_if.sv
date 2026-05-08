
interface phx_apb_if #(
  parameter DATA_W = 32,
  parameter ADDR_W = 32
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
  // Registers and Assignments
  //logic [APB_ADDR_W-1:0] m_apb_paddr = '0;
  //logic m_apb_psel = 1'b0;
  //logic m_apb_penable = 1'b0;
  //logic m_apb_pwrite = 1'b0;
  //logic [APB_DATA_W-1:0] m_apb_pwdata = '0;
  //assign m_apb.paddr = m_apb_paddr;
  //assign m_apb.psel = m_apb_psel;
  //assign m_apb.penable = m_apb_penable;
  //assign m_apb.pwrite = m_apb_pwrite
  //assign m_apb.pwdata = m_apb_pwdata

  modport slv (
    input paddr,
    input psel,
    input penable,
    input pwrite,
    input pwdata,
    output prdata,
    output pready
  );

  modport mon (
    input paddr,
    input psel,
    input penable,
    input pwrite,
    input pwdata,
    input prdata,
    input pready
  );

endinterface
