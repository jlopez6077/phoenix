/*
------------------------------------------------------------------------------
Module      : phx_pipelined_shifter
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-05-19
Module Type : Common

Description :
   
  IN_W  - Input bus width.
  OUT_W - Output bus width.

Latency : 
  ($clog2(IN_W)+1) / 2
------------------------------------------------------------------------------
*/

module phx_pipelined_shifter #(
  parameter IN_W = 32,
  parameter OUT_W = 16
)(
  input logic clk,
  input logic rst_n,

  input logic [IN_W-1:0]          shift_in,
  input logic [$clog2(IN_W)-1:0]  shift_amt,

  output logic [OUT_W-1:0]    shift_out
);

  localparam int IDX_W = $clog2(IN_W);
  localparam int STAGES = (IDX_W + 1) / 2;

  logic [IN_W-1:0] stage_data [STAGES+1];
  logic [IDX_W-1:0] stage_idx [STAGES+1];

  assign stage_data[0] = shift_in;
  assign stage_idx[0] = shift_amt;

  genvar i;
  generate 
    for (i = 0; i < STAGES; i++) begin : g_radix4_stages
      // i = 0
      // Multiplier for this specific stage 
      localparam int SHIFT_MULT = 1 << (2 * i); // 1

      localparam int BITS_THIS_STAGE = ((2*i+1) < IDX_W) ? 2 : 1; // 2

      always_ff @(posedge clk) begin
       stage_idx[i+1] <= stage_idx[i];

       if (BITS_THIS_STAGE == 2) begin
         case (stage_idx[i][2*i +: 2]) // 0-1, 2-3, 4-5
           2'b00: stage_data[i+1] <= stage_data[i];
           2'b01: stage_data[i+1] <= stage_data[i] >> (1 * SHIFT_MULT);
           2'b10: stage_data[i+1] <= stage_data[i] >> (2 * SHIFT_MULT);
           2'b11: stage_data[i+1] <= stage_data[i] >> (3 * SHIFT_MULT);
         endcase
       end else begin
         case (stage_idx[i][2*i])
           1'b0: stage_data[i+1] <= stage_data[i];
           1'b1: stage_data[i+1] <= stage_data[i] >> (1 * SHIFT_MULT);
         endcase
       end
      end
    end
  endgenerate
  assign shift_out = stage_data[STAGES][OUT_W-1:0];
endmodule
