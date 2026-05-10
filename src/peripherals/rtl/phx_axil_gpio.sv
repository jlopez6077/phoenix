/*
--------------------------------------------------------------------------------
Module      : phx_axil_gpio
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-05-09
Module Type : Peripheral

Description :
  A simple, 32-bit AXIL-based GPIO peripheral. Each pin can be individually 
  configured as an input or an output.

Register Map:
  0x00 - DATA_OUT : R/W. Sets the value to be driven on output pins.
  0x04 - DATA_DIR : R/W. Sets the direction of each pin (1=Output, 0=Input)
  0x08 - DATA_IN  : R. Reads the current physical stat of the pins.

--------------------------------------------------------------------------------
*/


module phx_axil_gpio 
(
  input   logic                   clk,
  input   logic                   rst_n,

  // AXIL Slave Interface
  phx_axil_if.wr_slv s_axil_wr,
  phx_axil_if.rd_slv s_axil_rd,

  // GPIO Port
  inout wire [31:0]  gpio_pins
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
  localparam R_MSB = 3;
  localparam R_LSB = 2;
  logic [AXIL_DATA_W-1:0] data_out_reg;  // Holds the output value
  logic [AXIL_DATA_W-1:0] data_dir_reg;  // Holds the direction for each pin

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
  // Implement bresp logic here

  // Register Write Logic ---------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      data_out_reg <= '0;
      data_dir_reg <= '0;
    end else if (!(aw_enable || w_enable)) begin
      case (awaddr[R_MSB:R_LSB])
        2'b00 : data_out_reg <= wdata;  // 0x0000
        2'b01 : data_dir_reg <= wdata;  // 0x0100
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

  always_ff @(posedge clk) begin : rdata_block
    if (!rst_n) begin
      s_axil_rdata <= '0;
    end else begin
      if (!ar_enable) begin
        case(araddr[R_MSB:R_LSB]) 
          2'b00 : s_axil_rdata <= data_out_reg;
          2'b01 : s_axil_rdata <= data_dir_reg;
          2'b10 : s_axil_rdata <= gpio_pins;
          default: s_axil_rresp <= 2'b11;
        endcase
      end 
    end
  end

  // Your Logic -------------------------------------------------------
  // GPIO Tri-State Logic
  generate 
    for (genvar i=0; i<AXIL_DATA_W; i++) begin : tri_state_buffer
      assign gpio_pins[i] = data_dir_reg[i] ? data_out_reg[i] : 1'bz;
    end
  endgenerate

endmodule

