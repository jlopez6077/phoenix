/*
--------------------------------------------------------------------------------
Module      : phx_toggle_leds
Project     : Fpga-based Deterministic Packet Engine
Author      : Juan Lopez
Created     : 2026-07-11
Module Type : Peripherals

Description :
  Toggles LEDs using buttons

--------------------------------------------------------------------------------
*/

module phx_toggle_leds #(
  parameter int WIDTH = 4
)(
  input   logic clk,
  input   logic rst_n,
  input   logic [WIDTH-1:0] switches_n,
  output  logic [WIDTH-1:0] leds_n 
);

  logic [WIDTH-1:0] w_debounced;
  logic w_rst_n;

  phx_delay_line #(
    .LATENCY(2),
    .WIDTH(1)
  ) debounce_inst(
    .clk(clk),
    .rst_n(1'b1),
    .din(rst_n),
    .dout(w_rst_n)
  );

  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin
      phx_debouncer #(
        .DEBOUNCE_CYCLE(500000),
        .TWO_FLOP_SYNCE_DELAY(0)
      ) debounce_inst(
        .clk(clk),
        .rst_n(w_rst_n),
        .bouncy(switches_n[i]),
        .debounced(w_debounced[i])
      );
    end

    genvar j;
    generate
        for(j = 0; j < WIDTH; j=j+1) begin
            toggle_led toggle_inst(
                .clk(clk),
                .rst_n(w_rst_n),
                .button(w_debounced[j]),
                .toggle(leds_n[j])
            );
        end
    endgenerate

endmodule

module toggle_led(
    input logic clk,
    input logic rst_n,
    input logic button,
    output logic toggle
);
  logic r_previous_value = 1'b1;
  logic r_toggle = 1'b1;
    
  always_ff @(posedge clk) begin
    if(!rst_n)
    begin
        r_toggle <= 1'b1;
        r_previous_value <= 1'b1;
    end else 
    begin
        r_previous_value <= button;
        if((r_previous_value == 1'b1) && (button == 1'b0))
            r_toggle <= ~r_toggle;
    end        
  end  
  
  assign toggle = r_toggle;
  
endmodule
