/*
------------------------------------------------------------------------------
Module      : phx_axis_width_convert
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-05-18
Module Type : Axis

Description :
    Converts AXI-Stream data between differing input and output bus widths while preserving AXIS handshake and packet signaling semantics.
------------------------------------------------------------------------------
*/

module phx_axis_width_convert #(
  parameter IN_BYTES = 3,
  parameter OUT_BYTES = 8
)(  
  input logic clk,
  input logic rst_n,

  // Input 
  input logic [(IN_BYTES*8)-1:0] s_axis_tdata,
  input logic               s_axis_tvalid,
  output logic              s_axis_tready,
  input logic               s_axis_tlast,
  
  // Output
  output logic [(OUT_W*8)-1:0] m_axis_tdata,
  output logic                m_axis_tvalid,
  input logic                 m_axis_tready,
  output logic                m_axis_tlast
);

  // Check parameters
  if (IN_BYTES == 0)
    $fatal(0, "Error: IN_BYTES equals 0");
  if (OUT_BYTES == 0)
    $fatal(0, "Error: OUT_BYTES equals 0");

  // shift_reg
  localparam IN_W = IN_BYTES * 8;   // 32
  localparam OUT_W = OUT_BYTES * 8; // 64
  localparam  SHIFT_R_SIZE = (OUT_W > IN_W) ? OUT_W * 2 : IN_W * 2; 
  logic [SHIFT_R_SIZE-1:0] shift_reg;

  logic [$clog2(SHIFT_R_SIZE)-1:0] cnt_head, cnt_head_minus_one, cnt_tail;

  logic [OUT_W-1:0] tdata;
  logic tvalid;

  assign m_axis_tdata = tdata;
  assign m_axis_tvalid = tvalid;
  
  
  always_ff @(posedge clk) begin : counter_block
    if(!rst_n) begin
      cnt_head <= '0;
    end else begin
      if (cnt_head >= OUT_W) begin
        if (s_axis_tready && s_axis_tvalid) begin
          cnt_head <= cnt_head - OUT_W + IN_W;
        end else begin
          cnt_head <= cnt_head - OUT_W;
        end
      end else if (s_axis_tready && s_axis_tvalid) begin
        cnt_head <= cnt_head + IN_W;
      end
    end
  end

  always_ff @(posedge clk) begin : shift_reg_block
    if (!rst_n) begin
      shift_reg <= '0;
    end else begin 
      if (s_axis_tready && s_axis_tvalid) begin
        shift_reg <= {shift_reg[SHIFT_R_SIZE-IN_BYTES-1:0],s_axis_tdata};
      end
    end
  end

  always_ff @(posedge clk) begin : output_block
    if (!rst_n) begin
     tdata <= '0;
     tvalid <= '0;
    end else begin
      if(cnt_head >= OUT_W)  begin
        tdata <= shift_reg[cnt_head-1:cnt_head-OUT_W];
        tvalid <= 1'b1;
      end else begin
        tvalid <= 1'b0;
      end
    end
  end
endmodule
