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
  
  // --- Modports ---
  modport wr_mst (
          // AW
          output awaddr,
          output awprot,
          output awvalid,
          input  awready,
          // W
          output wdata,
          output wstrb,
          output wvalid,
          input  wready,
          // B
          input  bresp,
          input  bvalid,
          output bready
      );

    modport rd_mst (
        // AR
        output araddr,
        output arprot,
        output arvalid,
        input  arready,
        // R
        input  rdata,
        input  rresp,
        input  rvalid,
        output rready
    );

    modport wr_slv (
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

    modport rd_slv (
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
