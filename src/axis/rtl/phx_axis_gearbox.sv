/*
------------------------------------------------------------------------------
Module      : phx_axis_gearbox
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-05-19
Module Type : COMMON

Description :

    Parameters -
      IN_W  : Input Bus Width
      OUT_W : Output Bus Width
------------------------------------------------------------------------------
*/

module phx_axis_gearbox #(
  parameter IN_W = 16,
  parameter OUT_W = 32
)(
  input logic     clk,
  input logic     rst_n, 

  input logic [IN_W-1:0]  s_axis_tdata,
  input logic             s_axis_tvalid,

  output logic [OUT_W-1:0]  m_axis_tdata,
  output logic              m_axis_tvalid
);

  localparam int BUF_W = IN_W + OUT_W;

  // Find the Greatest Common Divisor (GCD)
  function automatic int get_gcd (int a, int b);
    int temp;
    while (b != 0) begin
      temp = b; 
      b = a % b;
      a = temp;
    end
    return a; 
  endfunction

  localparam int GCD_VAL = get_gcd(IN_W, OUT_W);

  localparam int NUM_STATES = OUT_W / GCD_VAL;

  typedef int state_array_t [NUM_STATES];

  function automatic state_array_t calc_fill_levels ();
   state_array_t levels;
   int current = 0;
   for (int i = 0; i < NUM_STATES; i++) begin
    levels[i] = current;
    current = current + IN_W;
    if (current >= OUT_W) current = current - OUT_W;
   end
   return levels;
  endfunction

  localparam state_array_t FILL_LEVEL = calc_fill_levels();

  // Hardware Locic 
  logic [BUF_W-1:0] storage_reg;
  logic [$clog2(NUM_STATES)-1:0] state_idx;

  always_ff @(posedge clk) begin
    if(!rst_n)begin
      state_idx <= '0;
      storage_reg <= '0;
      m_axis_tvalid <= 1'b0;
    end else if (s_axis_tvalid) begin
      logic [BUF_W-1:0] combined_data;
      combined_data = storage_reg | (BUF_W'(s_axis_tdata) << FILL_LEVEL[state_idx]);

      if ((FILL_LEVEL[state_idx] + IN_W) >= OUT_W) begin
        m_axis_tdata <= combined_data[OUT_W-1:0];
        m_axis_tvalid <= 1;
        storage_reg <= combined_data >> OUT_W;
      end else begin
        m_axis_tvalid <= 0;
        storage_reg <= combined_data;
      end

      if (state_idx == NUM_STATES - 1)
        state_idx <= 0;
      else 
        state_idx <= state_idx + 1;

    end else begin // s_axis_tvalid
      m_axis_tvalid <= 0;
    end // !rst_n
  end // always_ff

endmodule
