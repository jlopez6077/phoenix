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
  input logic clk,
  input logic rst_n,

  phx_axil_if.wr_slv s_axil_wr,
  phx_axil_if.rd_slv s_axil_rd
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
  localparam MAX_ADDR = (NUM_REG > 1) ? (NUM_REG * 4) : 8;
  localparam R_MSB = $clog2(MAX_ADDR)-1;
  localparam R_LSB = 2;
  logic [AXIL_DATA_W-1:0] register_0;
  logic [AXIL_DATA_W-1:0] register_1;
  logic [AXIL_DATA_W-1:0] register_2;
  logic [AXIL_DATA_W-1:0] register_3;
  
  // Registers used to track AW, W, & AR
  // if high, channel is ready for transfer
  // else waiting for B or R to complete
  logic aw_enable = 1'b1, w_enable = 1'b1, ar_enable = 1'b1;

  // input holding registers
  logic [AXIL_ADDR_W-1:0] awaddr = '0;
  logic [AXIL_DATA_W-1:0] wdata = '0;
  logic [AXIL_ADDR_W-1:0] araddr = '0;

  // AW Logic ---------------------------------------------------------
  always_ff @(posedge clk) begin : awready_block
    if (!rst_n) begin
      s_axil_awready <= 1'b0;
      aw_enable <= 1'b1;
    end else begin
      if(s_axil_wr.awvalid && !s_axil_awready && aw_enable) begin
        s_axil_awready <= 1'b1;
        aw_enable <= 1'b0;
      end else begin
        s_axil_awready <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk) begin : awaddr_block
    if(!rst_n)
      awaddr <= '0;
    else if (s_axil_wr.awvalid && !s_axil_awready && aw_enable)
      awaddr <= s_axil_wr.awaddr;
  end

  // W Logic ----------------------------------------------------------
  always_ff @(posedge clk) begin : wready_block
    if (!rst_n) begin
      s_axil_wready <= 1'b0;
      w_enable <= 1'b1;
    end else begin
      if(s_axil_wr.wvalid && !s_axil_wready && w_enable) begin
        s_axil_wready <= 1'b1;
        w_enable <= 1'b0;
      end else begin
        s_axil_wready <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk) begin : wdata_block
    if(!rst_n)
      wdata <= '0;
    else if (s_axil_wr.wvalid && !s_axil_wready && w_enable)
      wdata <= s_axil_wr.wdata;
  end

  // B Logic ----------------------------------------------------------
  // TODO: Change bvalid if required
  always_ff @(posedge clk) begin : bvalid_block
    if (!rst_n)begin
      s_axil_bvalid <= 1'b0;
    end else begin
      // if both AW & W have completed tranfser -> bvalid high 
      if (!(aw_enable || w_enable)) begin 
        if (s_axil_bvalid && s_axil_wr.bready) begin
          s_axil_bvalid <= 1'b0;
          w_enable <= 1'b1;
          aw_enable <= 1'b1;
        end else begin
          s_axil_bvalid <= 1'b1;
        end
      end else begin
        s_axil_bvalid <= 1'b0;
      end
    end
  end
  // TODO: Implement bresp logic here

  // Register Write Logic ---------------------------------------------
  // TODO: Change default register values, addresses, and names
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      register_0 <= '0;
      register_1 <= '0;
      register_2 <= '0;
      register_3 <= '0;
    end else if (!(aw_enable || w_enable)) begin
      case (awaddr[R_MSB:R_LSB])
        2'b00 : register_0 <= wdata;  // 0x0000
        2'b01 : register_1 <= wdata;  // 0x0100
        2'b10  : register_2 <= wdata; // 0x1000
        2'b11  : register_3 <= wdata; // 0x1100
        default: s_axil_bresp <= 2'b11;
      endcase
    end
  end

  // AR Logic ---------------------------------------------------------
  always_ff @(posedge clk) begin : arready_block
    if(!rst_n) begin
      s_axil_arready <= 1'b0;
      ar_enable <= 1'b1;
    end else begin
      if (s_axil_rd.arvalid && !s_axil_arready && ar_enable) begin
        s_axil_arready <= 1'b1;
        ar_enable <= 1'b0;
      end else 
        s_axil_arready <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin : araddr_block
   if(!rst_n)
     araddr <= '0;
   else if (s_axil_rd.arvalid && !s_axil_arready && ar_enable)
     araddr <= s_axil_rd.araddr;
  end

  // R Logic ----------------------------------------------------------
  // TODO: Change rvalid if required
  always_ff @(posedge clk) begin : rvalid_block
    if (!rst_n) begin
      s_axil_rvalid <= 1'b0;  
    end else begin
      if (!ar_enable) begin
        if (s_axil_rvalid && s_axil_rd.rready) begin
          s_axil_rvalid <= 1'b0;  
          ar_enable <= 1'b1;
        end else begin
          s_axil_rvalid <= 1'b1;  
        end
      end else begin
        s_axil_rvalid <= 1'b0;
      end
    end
  end
  
  // TODO: Change default register addresses and names
  always_ff @(posedge clk) begin : rdata_block
    if (!rst_n) begin
      s_axil_rdata <= '0;
    end else begin
      if (!ar_enable) begin
        case(araddr[R_MSB:R_LSB]) 
          2'b00 : s_axil_rdata <= register_0;
          2'b01 : s_axil_rdata <= register_1;
          2'b10 : s_axil_rdata <= register_2;
          2'b11 : s_axil_rdata <= register_3;
          default: s_axil_rresp <= 2'b11;
        endcase
      end 
    end
  end

  // Your Logic -------------------------------------------------------
  // TODO: add custom logic here
  
endmodule
