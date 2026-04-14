/*
--------------------------------------------------------------------------------
Module      : apb_gpio
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-03-31
Module Type : COMMON

Description :
  A simple, 32-bit APB-based GPIO peripheral. Each pin can be individually 
  configured as an input or an output.

Register Map:
  0x00 - DATA_OUT : R/W. Sets the value to be driven on output pins.
  0x04 - DATA_DIR : R/W. Sets the direction of each pin (1=Output, 0=Input)
  0x08 - DATA_IN  : R/O. Reads the current physical stat of the pins.

--------------------------------------------------------------------------------
*/


module apb_gpio #(
  parameter ADDR_W = 16,
  parameter DATA_W= 32
)(
  input   logic                   clk,
  input   logic                   rst_n,

  // APB Slave Interface
  phx_apb_if.slv s_apb,

  // GPIO Port
  inout wire [DATA_WIDTH-1:0]  gpio_pins
);
  
  // Internal Register
  logic [DATA_WIDTH-1:0] data_out_reg;  // Holds the output value
  logic [DATA_WIDTH-1:0] data_dir_reg;  // Holds the direction for each pin

  // APB Logic 
  
  // Decode reevant address bits
  // Assumption: address is word-aligend
  logic addr_sel_data_out, addr_sel_data_dir, addr_sel_data_in;

  assign addr_sel_data_out  = (s_apb.paddr[3:2] == 2'b00); // Address 0x00
  assign addr_sel_data_dir  = (s_apb.paddr[3:2] == 2'b01); // Address 0x04
  assign addr_sel_data_in   = (s_apb.paddr[3:2] == 2'b10); // Address 0x08

  // APB Write Logic
  always_ff @(posedge clk) begin
    if (!rst_n) 
    begin
      data_out_reg <= '0;
      data_dir_reg <= '0;
    end else 
    begin
      if (s_apb.psel && s_apb.penable && s_apb.pwrite) begin
        if (addr_sel_data_out)
          data_out_reg <= s_apb.pwdata;
        if (addr_sel_data_dir)
          data_dir_reg <= s_apb.pwdata;
      end
    end
  end
   
  // APB Read Logic 
  always_comb begin
    s_apb.prdata = '0;
    case (1'b1)
      addr_sel_data_out:  s_apb.prdata = data_out_reg;
      addr_sel_data_dir:  s_apb.prdata = data_dir_reg;
      addr_sel_data_in:   s_apb.prdata = gpio_pins;
    endcase
  end

  // Ready Signal 
  assign s_apb.pready = 1'b1;

  // GPIO Tri-State Logic
  generate 
    for (genvar i=0; i<DATA_WIDTH; i++) begin : tri_state_buffer
      assign gpio_pins[i] = data_dir_reg[i] ? data_out_reg[i] : 1'bz;
    end
  endgenerate

endmodule

