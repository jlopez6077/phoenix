/*
------------------------------------------------------------------------------
Module      : phx_axil_if
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-04-28
Module Type : Axi

Description :
    Axi-lite interface

------------------------------------------------------------------------------
*/

interface phx_axil_if #(
  parameter DATA_W = 32,
  parameter ADDR_W = 32
)();

  // --- Write Address Channel --- AW
  logic [ADDR_W-1:0]  awaddr;
  logic [2:0]         awprot;
  logic               awvalid;
  logic               awready;

  // --- Write Data Channel --- W
  logic [DATA_W-1:0]      wdata;
  logic [(DATA_W/8)-1:0]  wstrb;
  logic                   wvalid;
  logic                   wready;

  // --- Write Response Channel --- B
  logic [1:0] bresp;  // 00-OKAY, 01=EXOKAY, 10=SLVERR, 11=DECERR 
  logic       bvalid;
  logic       bready;
  
  // --- Read Address Channel --- AR
  logic [ADDR_W-1:0]  araddr;
  logic [2:0]         arprot;
  logic               arvalid;
  logic               arready;

  // --- Read Data Channel --- 
  logic [DATA_W-1:0]  rdata;
  logic [1:0]         rresp;
  logic               rvalid;
  logic               rready;
  
 // // --- Modports ---
 // modport wr_mst (
 //         // AW
 //         output awaddr,
 //         output awprot,
 //         output awvalid,
 //         input  awready,
 //         // W
 //         output wdata,
 //         output wstrb,
 //         output wvalid,
 //         input  wready,
 //         // B
 //         input  bresp,
 //         input  bvalid,
 //         output bready
 //     );

 //   modport rd_mst (
 //       // AR
 //       output araddr,
 //       output arprot,
 //       output arvalid,
 //       input  arready,
 //       // R
 //       input  rdata,
 //       input  rresp,
 //       input  rvalid,
 //       output rready
 //   );

    modport wr_slave (
        // AW
        input  awaddr,
        input  awprot,
        input  awvalid,
        output awready,
        // W
        input  wdata,
        input  wstrb,
        input  wvalid,
        output wready,
        // B
        output bresp,
        output bvalid,
        input  bready
    );
    // IO wr_slv block
    //logic s_axil_awready = 1'b0;
    //logic s_axil_wready = 1'b0:
    //logic [1:0] s_axil_bresp = '0;
    //logic s_axil_bvalid = 1'b0;
    //assign s_axil_wr.awready  = s_axil_awready;
    //assign s_axil_wr.wready   = s_axil_wready;
    //assign s_axil_wr.bresp    = s_axil_bresp;
    //assign s_axil_wr.bvalid   = s_axil_bvalid;

    modport rd_slave (
        // AR
        input  araddr,
        input  arprot,
        input  arvalid,
        output arready,
        // R
        output rdata,
        output rresp,
        output rvalid,
        input  rready
    );
    // IO rd_slv block
    //logic s_axil_arready = 1'b0; 
    //logic [1:0] s_axil_rresp = '0;
    //logic [AXIL_DATA_W-1:0] s_axil_rdata = '0;
    //logic s_axil_rvalid     = 1'b0;
    //assign s_axil_rd.arready  = s_axil_arready;
    //assign s_axil_rd.rresp    = s_axil_rresp;
    //assign s_axil_rd.rdata    = s_axil_rdata;
    //assign s_axil_rd.rvalid   = s_axil_rvalid;

    modport wr_mon (
        // AW
        input  awaddr,
        input  awprot,
        input  awvalid,
        input  awready,
        // W
        input  wdata,
        input  wstrb,
        input  wvalid,
        input  wready,
        // B
        input  bresp,
        input  bvalid,
        input  bready
    );

    modport rd_mon (
        // AR
        input  araddr,
        input  arprot,
        input  arvalid,
        input  arready,
        // R
        input  rdata,
        input  rresp,
        input  rvalid,
        input  rready
    );

endinterface
