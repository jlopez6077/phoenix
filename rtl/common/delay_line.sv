/*
------------------------------------------------------------------------------
Module      : delay_line
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-02-19

Description :
    Pipelined non-blocking delay

------------------------------------------------------------------------------
*/
module delay_line #(
  parameter int LATENCY = 1,
  parameter int WIDTH = 8
)(
  input   logic clk,
  input   logic rst_n,

  input   logic [WIDTH-1:0] din,
  output  logic [WIDTH-1:0] dout
);

  generate
    if(LATENCY == 0) begin : gen_bypass
      assign dout = din;
    end else begin : gen_delay

      logic [WIDTH-1:0] shift_reg [LATENCY];
      // assign dout = shift_reg[LATENCY-1];
      integer i;

      always_ff @(posedge clk) begin
        if(!rst_n) begin
          for (i = 0; i<LATENCY; i++) begin
            shift_reg[i] <= '0; 
          end
        end else begin
          shift_reg[0] <= din;
          dout <= shift_reg[LATENCY-1];
          for (i = 1; i<LATENCY; i++) begin
            shift_reg[i] <= shift_reg[i-1]; 
          end
        end 
      end // always_ff

    end // gen_delay

  endgenerate

endmodule

