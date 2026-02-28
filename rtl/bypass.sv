/*
------------------------------------------------------------------------------
Module      : bypass
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-02-22
Module Type : COMMON

Description :
    bypass is a multiplexer that allows dina or dinb to equal dout

    Parameters -
      REGISTER_OUTPUT: Registers the multiplexer is require with
        * High fanout (WIDTH)
        * Long routing 
        * High utilization

------------------------------------------------------------------------------
*/


module bypass #(
  parameter int WIDTH = 8,
  parameter int DINA_DELAY = 0,   // Data input a delay
  parameter int DINB_DELAY = 0,   // Data input b delay
  parameter int REGISTER_OUTPUT = 0  // low = false
)(
  input   logic clk,
  input   logic rst_n,

  input   logic             sw,   // switch input, low: dina = dout, high: dinb = dout
  input   logic [WIDTH-1:0] dina,
  input   logic [WIDTH-1:0] dinb,
  output  logic [WIDTH-1:0] dout
);

  logic [WIDTH-1:0] w_dina, w_dinb;

  delay_line #(
    .LATENCY(DINA_DELAY),
    .WIDTH(WIDTH)
  ) dina_delay_inst (
    .clk(clk),
    .rst_n(rst_n),
    .din(dina),
    .dout(w_dina)
  );

  delay_line #(
    .LATENCY(DINB_DELAY),
    .WIDTH(WIDTH)
  ) dinb_delay_inst (
    .clk(clk),
    .rst_n(rst_n),
    .din(dinb),
    .dout(w_dinb)
  );

  logic [WIDTH-1:0] mux_out;
  assign mux_out = (sw) ? w_dinb : w_dina;

  if (REGISTER_OUTPUT) begin : gen_reg_out
    always_ff @(posedge clk) begin 
      if (!rst_n) dout <= '0;
      else        dout <= mux_out;
    end
  end else begin : gen_comb_out
    assign dout = mux_out;
  end

endmodule

