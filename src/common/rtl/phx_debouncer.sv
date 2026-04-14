/*
--------------------------------------------------------------------------------
Module      : phx_debouncer
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-02-25
Module Type : COMMON
Description :
    Debouncer filters out oscillation inputs. Output debounced changes only when 
    input bouncy remains its current state for DEBOUNCE_CYCLE clock cycles, 
    Removing mechanical noise (bouncing) from switches, buttons, or sensors.
--------------------------------------------------------------------------------
*/


module phx_debouncer #(
  parameter int DEBOUNCE_CYCLE = 20,
  parameter int TWO_FLOP_SYNC_DELAY = 0
)(
  input   logic clk,
  input   logic rst_n,

  input   logic bouncy,
  output  logic debounced
);

  logic sync_bouncy;

  // Stage 1: 2-Flop Synchronizer
  // Bringing asynchronous 'bouncy' into 'clk' domain
  phx_delay_line #(
    .LATENCY(TWO_FLOP_SYNC_DELAY),
    .WIDTH(1)
  ) sync_inst(
    .rst_n(rst_n),
    .clk(clk),
    .din(bouncy),
    .dout(sync_bouncy)
  );
 
  generate 
    if (DEBOUNCE_CYCLE > 0) begin : debounce_stage

      logic [$clog2(DEBOUNCE_CYCLE)-1:0] cnt = 0;
      logic bouncy_state = 0;
      assign debounced = bouncy_state;

      // Stage 2: implementing counter to filter input
      always_ff @(posedge clk) begin 
        if(!rst_n) begin
          cnt <= '0;
          bouncy_state <= 0;
        end else begin
          if(bouncy_state != sync_bouncy & cnt < DEBOUNCE_CYCLE - 1) begin
            cnt <= cnt + 1;
          end else if (cnt == DEBOUNCE_CYCLE - 1) begin 
            bouncy_state <= sync_bouncy;
            cnt <= '0;
          end else 
            cnt <= '0;
        end
      end // always_ff

    end else begin : gen_bypass
      assign debounced = sync_bouncy;
    end
  endgenerate


endmodule
