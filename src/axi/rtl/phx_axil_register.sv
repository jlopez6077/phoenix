/*
------------------------------------------------------------------------------
Module      : phx_axil_register
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-05-06
Module Type : Axi

Description :
    Axi-lite controlled regitsters
Register Map :
    0x0 - register_0      : R/W.
    0x4 - register_1      : R/W.
    0x8 - register_2      : R/W.
    0xc - register_3      : R/W.
------------------------------------------------------------------------------
*/

module phx_axil_register (
  input logic rst_n,

  // AXI4-LITE
  input logic axil_clk,
  phx_axil_if.wr_slave s_axil_wr,
  phx_axil_if.rd_slave s_axil_rd
);
  // Extract Paramters 
  localparam AXIL_DATA_W = s_axil_wr.DATA_W;
  localparam AXIL_ADDR_W = s_axil_wr.ADDR_W;
  // Check Configuration

  // IO wr_slv block
  logic s_axil_awready = 1'b0;
  logic s_axil_wready = 1'b0;
  logic [1:0] s_axil_bresp = '0;
  logic s_axil_bvalid = 1'b0;
  assign s_axil_wr.awready  = s_axil_awready;
  assign s_axil_wr.wready   = s_axil_wready;
  assign s_axil_wr.bresp    = s_axil_bresp;
  assign s_axil_wr.bvalid   = s_axil_bvalid;
  
  // IO rd_slv block
  logic s_axil_arready = 1'b0; 
  logic [1:0] s_axil_rresp = '0;
  logic [AXIL_DATA_W-1:0] s_axil_rdata = '0;
  logic s_axil_rvalid     = 1'b0;
  assign s_axil_rd.arready  = s_axil_arready;
  assign s_axil_rd.rresp    = s_axil_rresp;
  assign s_axil_rd.rdata    = s_axil_rdata;
  assign s_axil_rd.rvalid   = s_axil_rvalid;

  // Registers
  // TODO: Change NUM_REG and register names as needed
  localparam NUM_REG = 4;
  localparam MAX_ADDR = NUM_REG * 4;
  localparam R_MSB = ($clog2(MAX_ADDR)) > 2 ? ($clog2(MAX_ADDR)-1) : 2;
  localparam R_LSB = 2;

  logic [AXIL_DATA_W-1:0] register_0;
  logic [AXIL_DATA_W-1:0] register_1;
  logic [AXIL_DATA_W-1:0] register_2;
  logic [AXIL_DATA_W-1:0] register_3;
  
  // Registers used to track AW, W, & AR
  // if high, channel transfer as occured
  logic aw_done, w_done, ar_done;

  // input holding registers
  logic [AXIL_ADDR_W-1:0] awaddr = '0;
  logic [AXIL_DATA_W-1:0] wdata = '0;
  logic [AXIL_ADDR_W-1:0] araddr = '0;

  // TODO: Add your logic here
  

  // AW Logic ---------------------------------------------------------
  always_ff @(posedge axil_clk) begin : aw_done_block
    // !aw_done mean address write is ready to accept data
    if(!rst_n) begin
        aw_done <= 1'b0; end else begin
      if (s_axil_bvalid & s_axil_wr.bready)         
        aw_done <= 1'b0;
      else if (s_axil_wr.awvalid & s_axil_awready)  
        aw_done <= 1'b1;
    end
  end


  always_ff @(posedge axil_clk) begin : awready_block
    if (!rst_n) begin
      s_axil_awready <= 1'b0;
    end else begin
      s_axil_awready <= 1'b0;
      if(s_axil_wr.awvalid & !aw_done & !s_axil_awready)  
        s_axil_awready <= 1'b1;
    end
  end

  always_ff @(posedge axil_clk) begin : awaddr_block
    if(!rst_n)
      awaddr <= '0;
    else if (s_axil_wr.awvalid & s_axil_awready)
      awaddr <= s_axil_wr.awaddr;
  end

  // W Logic ----------------------------------------------------------
  always_ff @(posedge axil_clk) begin : w_done_block
    // !w_done mean write is ready to accept data
    if (!rst_n) begin
      w_done <= 1'b0;
    end else begin
      if (s_axil_bvalid & s_axil_wr.bready)       
        w_done <= 1'b0;
      else if (s_axil_wr.wvalid & s_axil_wready)  
        w_done <= 1'b1;
    end
  end

  always_ff @(posedge axil_clk) begin : wready_block
    if (!rst_n) begin
      s_axil_wready <= 1'b0;
    end else begin
      s_axil_wready <= 1'b0;
      if (s_axil_wr.wvalid & !w_done & !s_axil_wready)
        s_axil_wready <= 1'b1;
    end
  end

  always_ff @(posedge axil_clk) begin : wdata_block
    if(!rst_n)
      wdata <= '0;
    else if (s_axil_wr.wvalid & s_axil_wready)
      wdata <= s_axil_wr.wdata;
  end

  // B Logic ----------------------------------------------------------
  // TODO: Change bvalid if required
  always_ff @(posedge axil_clk) begin : bvalid_block
    if (!rst_n)begin
      s_axil_bvalid <= 1'b0;
    end else begin
      // if both AW & W have completed tranfser -> bvalid high 
      if (s_axil_wr.bready & s_axil_bvalid)
        s_axil_bvalid <= 1'b0;
      else if (aw_done & w_done)
        s_axil_bvalid <= 1'b1;
    end
  end

  // BRESP Logic ------------------------------------------------------
  always_ff @(posedge axil_clk) begin : bresp_block
    if (!rst_n) begin
      s_axil_bresp <= 2'b00; // Default to OKAY
    end else if (aw_done & w_done & !s_axil_bvalid) begin
      // Decode address to check for valid range
      if (awaddr < MAX_ADDR) begin
        s_axil_bresp <= 2'b00; // OKAY response
      end else begin
        s_axil_bresp <= 2'b11; // DECERR (Decode Error) response
      end
    end
  end

  // Register Write Logic ---------------------------------------------
  // TODO: Change default register values, addresses, and names
  always_ff @(posedge axil_clk) begin
    if (!rst_n) begin
      register_0 <= '0;
      register_1 <= '0;
      register_2 <= '0;
      register_3 <= '0;
    end else if (aw_done & w_done & !s_axil_bvalid) begin
      if (awaddr < MAX_ADDR) begin
        case (awaddr[R_MSB:R_LSB])
          2'b00 : register_0 <= wdata;  // 0x0000
          2'b01 : register_1 <= wdata;  // 0x0100
          2'b10 : register_2 <= wdata; // 0x1000
          2'b11 : register_3 <= wdata; // 0x1100
          default : ;
        endcase
      end
    end
  end

  // AR Logic ---------------------------------------------------------
  always_ff @(posedge axil_clk) begin : ar_done_block
    if (!rst_n) begin
      ar_done <= 1'b0;   
    end else begin
      if (s_axil_rvalid & s_axil_rd.rready)
        ar_done <= 1'b0;
      else if (s_axil_rd.arvalid & s_axil_arready) 
        ar_done <= 1'b1;
    end 
  end

  always_ff @(posedge axil_clk) begin : arready_block
    if(!rst_n) begin
      s_axil_arready <= 1'b0;
    end else begin
      s_axil_arready <= 1'b0;
      if (s_axil_rd.arvalid & !ar_done & !s_axil_arready)
        s_axil_arready <= 1'b1;
    end
  end

  always_ff @(posedge axil_clk) begin : araddr_block
   if(!rst_n)
     araddr <= '0;
   else if (s_axil_rd.arvalid & s_axil_arready)
     araddr <= s_axil_rd.araddr;
  end

  // R Logic ----------------------------------------------------------
  always_ff @(posedge axil_clk) begin : rvalid_block
    if (!rst_n) begin
      s_axil_rvalid <= 1'b0;  
    end else begin
      if (s_axil_rd.rready & s_axil_rvalid)
        s_axil_rvalid <= 1'b0;
      else if (ar_done)
        s_axil_rvalid <= 1'b1;
    end
  end

  // Register Write Logic ---------------------------------------------
  // TODO: Change default register addresses and names
  always_ff @(posedge axil_clk) begin : rdata_block
    if (!rst_n) begin
      s_axil_rdata <= '0;
      s_axil_rresp <= 2'b00; 
    end else begin
      if (ar_done & !s_axil_rvalid) begin
        if (araddr < MAX_ADDR) begin
          s_axil_rresp <= 2'b00; // OKAY
          case(araddr[R_MSB:R_LSB]) 
            2'b00 : s_axil_rdata <= register_0;
            2'b01 : s_axil_rdata <= register_1;
            2'b10 : s_axil_rdata <= register_2;
            2'b11 : s_axil_rdata <= register_3;
            default: s_axil_rdata <= '0;
          endcase
        end else begin
          s_axil_rdata <= '0;
          s_axil_rresp <= 2'b11; // DECERR (Decode Error)
        end
      end 
    end
  end

  // Your Logic -------------------------------------------------------
  // TODO: add custom logic here
  
endmodule
