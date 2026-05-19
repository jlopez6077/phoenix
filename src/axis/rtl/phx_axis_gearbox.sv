/*
------------------------------------------------------------------------------
Module      : phx_axis_gearbox
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-05-19
Module Type : COMMON

Description :

    Parameters -
      REGISTER_OUTPUT: Registers the multiplexer is require with
        * High fanout (WIDTH)
        * Long routing 
        * High utilization
      TWO_FF_SYNC: Adds a two flip-flop synchonizer to sw
        * If sw is a CDC input

------------------------------------------------------------------------------
*/

module phx_axis_gearbox #(
  parameter IN_W = 256,
  parameter OUT_W = 512
)(
  input logic     clk,
  input logic     rst_n, 

  input logic [IN_W-1:0]  s_axis_tdata,
  input logic             s_axis_tvalid,

  output logic [OUT_W-1:0]  m_axis_tdata,
  output logic              m_axis_tvalid
);
 localparam int ACC_W = IN_W + OUT_W; 

 logic [ACC_W-1:0] accumulator;
 logic [$clog2(ACC_W):0] fill_level;

  always_ff @(posedge clk) begin
    if(!rst_n)begin
      fill_level <= '0;
      accumulator <= '0;
      m_axis_tvalid <= 0;
    end else begin
      m_axis_tvalid <= 0;
      if (s_axis_tvalid) begin
        accumulator[(fill_level + IN_W)-1 -: IN_W] <= s_axis_tdata;
        if ((fill_level + IN_W) >= OUT_W) begin
          m_axis_tdata <= {s_axis_tdata, accumulator}[OUT_W-1:0];
          m_axis_tvalid <= 1'b1;

          fill_level <= (fill_level + IN_W) - OUT_W;

          accumulator <= {s_axis_tdata, accumulator} >> OUT_W;
        end else begin
          fill_level <= fill_level + IN_W;
        end
      end // if s_axis_tvalid
    end // if !rst_n
  end // always_ff
