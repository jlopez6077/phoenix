/*
------------------------------------------------------------------------------
Module      : phx_pipelined_shifter
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-05-19
Module Type : Common

Description :
   
  IN_W  - Input bus width
  OUT_W - Output bus width
  PIPELINED - 1=Pipelined, 0=Combinatorial

Latency : 
  ($clog2(IN_W)+1) / 2
  

  TODO: change name, add Description, review code, test PIPELINED = 0
------------------------------------------------------------------------------
*/

module phx_pipelined_shifter #(
  parameter IN_W = 32,
  parameter OUT_W = 16,
  parameter PIPELINED = 1 
)(
  input logic clk,
  input logic rst_n,
  input logic enable,

  input logic [IN_W-1:0]          shift_in,
  input logic                     shift_in_valid,
  input logic [$clog2(IN_W)-1:0]  shift_amt,

  output logic [OUT_W-1:0]    shift_out,
  output logic                shift_out_valid
);

  localparam int IDX_W = $clog2(IN_W);
  localparam int STAGES = (IDX_W + 1) / 2;

  logic [IN_W-1:0] stage_data [STAGES+1];
  logic [IDX_W-1:0] stage_idx [STAGES+1];
  logic stage_valid[STAGES+1];

  assign stage_data[0] = shift_in;
  assign stage_idx[0] = shift_amt;
  assign stage_valid[0] = shift_in_valid;

  genvar i;
  generate 
    if (PIPELINED == 1) begin : g_pipeline
      for (i = 0; i < STAGES; i++) begin : g_radix4_stages
        // Multiplier for this specific stage 
        localparam int SHIFT_MULT = 1 << (2 * i); 
        localparam int BITS_THIS_STAGE = ((2*i+1) < IDX_W) ? 2 : 1; 
        always_ff @(posedge clk) begin
          if (!rst_n) begin
            stage_data[i+1] <= '0;
            stage_valid[i+1] <= 1'b0;
          end else begin
            if (enable) begin
              stage_idx[i+1] <= stage_idx[i];
              stage_valid[i+1] <= stage_valid[i];
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
            end // if enable
          end // if (!rst_n)
        end // always_ff
      end // g_radix4_stages
      assign shift_out = stage_data[STAGES][OUT_W-1:0];
      assign shift_out_valid = stage_valid[STAGES];
    end else begin : g_combinatorial
      logic [IN_W-1:0] comb_data;
      always_comb begin
        comb_data = shift_in;
        for (int i = 0; i < STAGES; i++) begin
          int shift_mult = 1 << (2 * i);
          int bits_this_stage = ((2*i+1) < IDX_W) ? 2 : 1;
          
          if (bits_this_stage == 2) begin
            case (shift_amt[2*i +: 2])
              2'b01: comb_data >>= (1 * shift_mult);
              2'b10: comb_data >>= (2 * shift_mult);
              2'b11: comb_data >>= (3 * shift_mult);
            endcase
          end else begin
            if (shift_amt[2*i]) comb_data >>= (1 * shift_mult);
          end
        end
      end
      assign shift_out = comb_data[OUT_W-1:0];
      assign shift_out_valid = shift_in_valid; // Passthrough
    end // if PIPELINED
  endgenerate


endmodule
