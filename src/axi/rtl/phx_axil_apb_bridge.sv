/*
------------------------------------------------------------------------------
Module      : phx_axil_apb_bridge
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-04-28
Module Type : Axi

Description :
    Axi-lite to APB bridge used to translate between protocals.

    Parameters -
      REGISTER_OUTPUT: Registers the multiplexer is require with
        * High fanout (WIDTH)
        * Long routing 
        * High utilization

------------------------------------------------------------------------------
*/

module phx_axil_apb_bridge
(
  logic input clk,
  logic input rst_n,

  // Axi4-Lite slave interface
  phx_axil_if.wr_slv s_axil_wr,
  phx_axil_if.rd_slv s_axil_rd,

  // APB master interface
  phx_apb_if.mst m_apb
);

  // Extract Parameters
  localparam AXIL_DATA_W  = s_axil_wr.DATA_W;
  localparam AXIL_ADDR_W  = s_axil_wr.ADDR_W;
  localparam APB_DATA_W   = m_apb.DATA_W;
  localparam APB_ADDR_W   = m_apb.ADDR_W;

  // Check Configuration
  if (AXIL_DATA_W != APB_DATA_W)
    $fatal(0, "Error: Data width mismatch (instance %m)");
  if (AXI_ADDR_W != APB_ADDR_W)
    $fatal(0, "Error: Address width mismatch (instance %m)");
  
 
  logic s_axil_awready    = 1'b0;
  logic s_axil_wready     = 1'b0:
  logic [1:0] s_axil_bresp = '0, s_axil_rresp = '0;
  logic s_axil_bvalid     = 1'b0;
  logic s_axil_arready    = 1'b0; 
  logic [AXIL_DATA_W-1:0] s_axil_rdata = '0;
  logic s_axil_rvalid     = 1'b0;

  logic [APB_ADDR_W-1:0] m_apb_paddr = '0;
  logic m_apb_psel = 1'b0;
  logic m_apb_penable = 1'b0;
  logic m_apb_pwrite = 1'b0;
  logic [APB_DATA_W-1:0] m_apb_pwdata = '0;


  assign s_axil_wr.awready = s_axil_awready;
  assign s_axil_wr.wready = s_axil_wready;
  assign s_axil_wr.bresp = s_axil_bresp;
  assign s_axil_wr.bvalid = s_axil_bvalid;

  assign s_axil_rd.arready = s_axil_arready;
  assign s_axil_rd.rdata = s_axil_rdata;
  assign s_axil_rd.rresp = s_axil_rresp;
  assign s_axil_rd.rvalid = s_axil_rvalid;
  
  assign m_apb.paddr = m_apb_paddr;
  assign m_apb.psel = m_apb_psel;
  assign m_apb.penable = m_apb_penable;
  assign m_apb.pwrite = m_apb_pwrite
  assign m_apb.pwdata = m_apb_pwdata

  typedef enum  logic [1:0] {
    IDLE = 2'b00,
    SETUP = 2'b01,
    ACCESS_WRITE = 2'b10,
    ACCESS_READ = 2'b11
  } state_e;

  state_e state = IDLE, nex_state;

  // State-register - sequential always block
  always_ff @(posedge clk) begin
    if(!rst_n)
      state <= IDLE;
    else 
      state <= nex_state;
  end

  // Next State - combinational always block 
  always_comb begin
    nex_state = state;
    case(state)
      IDLE: begin
        if((s_axil_wr.awvalid && s_axil_wr.wvalid) || (s_axil_rd.arvalid)) 
         nex_state = SETUP;
      end // IDLE
      SETUP: begin    // add the access_write & ready logic here
        if (s_axil_wr.awvalid && s_axil_wr.wvalid) begin 
          nex_state = ACCESS_WRITE;
        end else if (s_axil_rd.arvalid) begin
          nex_state = ACCESS_READ; 
        end
      end // SETUP
      ACCESS_WRITE: begin
        if(m_apb.pready) begin 
          if((s_axil_wr.awvalid && s_axil_wr.wvalid) || (s_axil_rd.arvalid)) 
            nex_state = SETUP;
          else 
            nex_state = IDLE;
        end
      end
      ACCESS_READ: begin
      end
    endcase
  end // always_comb

  // Next-Output APB logic - sequentail always block
  always_ff @(posedge clk) begin
    if (!rst) begin
     m_apb_psel <= 1'b0;
     m_apb_penable <= 1'b0;
   end else begin
     case (nex_state)
      IDLE: begin
        m_apb_psel <= 1'b0;
        m_apb_penable <= 1'b0;
      end 
      SETUP: begin
        m_apb_psel <= 1'b1;
        m_apb_penable <= 1'b0;
        if (s_axil_wr.awvalid && s_axil_wr.wvalid) begin 
          // if Axi4-Lite is write 
          m_apb_paddr <= s_axil_wr.awaddr;
          m_apb_pwdata <= s_axil_wr.wdata;
          m_apb_pwrite <= 1'b1;
        end else 
          // if Axi4-Lite is Read 
          m_apb_paddr <= s_axil_rd.araddr;
          m_apb_pwrite <= 1'b0;
        end
      end
      ACCESS: begin
        m_apb_penable <= 1'b1;
      end
     endcase
   end
  end

  // Next-Output Axi4-Lite logic - sequentail always block
  always_ff @(posedge clk) begin
    if (!rst) begin
      s_axil_awready <= 1'b0;
      s_axil_wready <= 1'b0;
      s_axil_bvaild <= 1'b0;
      s_axil_arready <= 1'b0;
      s_axil_rvalid <= 1'b0;
    end else begin
      s_axil_awready <= 1'b0;
      s_axil_wready <= 1'b0;
      s_axil_arready <= 1'b0;
      case (nex_state)
        IDLE: begin
        end 
        SETUP: begin
          if (s_axil_wr.awvalid && s_axil_wr.wvalid) begin
            s_axil_awready <= 1'b1;
            s_axil_wready <= 1'b1;
          end else if (s_axil_rd.arvalid) begin
            s_axil_arready <= 1'b1;
          end
        end // SETUP
        ACCESS: begin
          if (m_apb.pready) begin   // if APB slave is ready
            if (m_apb_pwrite) begin // if APB is write
              s_axil_bresp <= '0;
              s_axil_bvalid <= 1'b1;
            end else begin          // if APB is read
              s_axil_rdata <= m_apb.prdata;
              s_axil_rvalid <= 1'b1;
              s_axil_rresp <= '0;
            end
          end // if m_apb.pready
        end // ACCESS
      endcase
    end
  end


endmodule
