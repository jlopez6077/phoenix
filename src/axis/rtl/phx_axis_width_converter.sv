/*
------------------------------------------------------------------------------
Module      : phx_axis_width_converter
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-05-19
Module Type : COMMON

Description :
  This module aggregates smaller input 
  words into a larger output word using a constant-shift accumulation 
  architecture.

  Features :
  - Automatically calculates state transitions based on the Greatest 
    Common Divisor (GCD) of the bus widths.
  - Optimized for high-frequency timing via constant-shift wiring.

  Parameters -
  - IN_W      : Input Bus Width
  - OUT_W     : Output Bus Width
  - Pipelined : 1 = true, Addition register for meeting timing

  Latency :
  - 1 (pipelined accumulation) + PIPELINED (registered shifting) clock cycles
------------------------------------------------------------------------------
*/

module phx_axis_width_converter #(
  parameter IN_W = 16,
  parameter OUT_W = 8
)(
  input logic     clk,
  input logic     rst_n, 

  input logic [IN_W-1:0]  s_axis_tdata,
  input logic             s_axis_tvalid,
  output logic            s_axis_tready,

  output logic [OUT_W-1:0]  m_axis_tdata,
  output logic              m_axis_tvalid,
  input logic               m_axis_tready
);

  localparam int BUF_W = IN_W + OUT_W;

  // ===================================================================================
  // COMPILE-TIME MATH
  // ===================================================================================
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
  localparam int NUM_STATES = (IN_W > OUT_W) ? (IN_W / GCD_VAL): OUT_W / GCD_VAL;

  // Pre-caluculate the fill_level for each state
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
  
  // ===================================================================================
  // HARDWARE LOGIC
  // ===================================================================================
  if (IN_W == OUT_W) begin
    assign m_axis_tdata = s_axis_tdata;
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;
  end else begin
    
    logic [BUF_W-1:0] storage_reg;
    logic [$clog2(NUM_STATES)-1:0] state_idx;
    logic [$clog2(NUM_STATES)-1:0] next_state_idx;
    logic [BUF_W-1:0] combined_data;

    // Output is ready if it's empty OR downstream is consuming it right now
    logic out_ready;
    assign out_ready = !m_axis_tvalid || m_axis_tready;
    assign s_axis_tready = (IN_W > OUT_W) ? (FILL_LEVEL[state_idx] < OUT_W) && out_ready 
                                          : out_ready;

    always_ff @(posedge clk) begin : state_block
      if (!rst_n) begin
        state_idx <= '0;
      end else begin
        state_idx <= next_state_idx;
      end
    end

    always_comb begin : next_state_block
      next_state_idx = state_idx;
      if(s_axis_tready && s_axis_tvalid) begin
        next_state_idx = (state_idx == NUM_STATES-1) ? '0 : state_idx + 1'b1;
      end else if ((FILL_LEVEL[state_idx] >= OUT_W) && m_axis_tready) begin
        next_state_idx = (state_idx == NUM_STATES-1) ? '0 : state_idx + 1'b1;
      end
    end // next_state_block

    always_ff @(posedge clk) begin 
      if(!rst_n)begin
        storage_reg <= '0;
        m_axis_tvalid <= 1'b0;
        m_axis_tdata <= '0;
      end else begin
        if (m_axis_tready)    // If downstream accepted the data
          m_axis_tvalid <= 0; // clear valid unless new data replaces it

        if (s_axis_tready && s_axis_tvalid) begin
          if ((FILL_LEVEL[state_idx] + IN_W) >= OUT_W) begin 
            m_axis_tdata <= combined_data[OUT_W-1:0];
            m_axis_tvalid <= 1'b1;
            storage_reg <= combined_data >> OUT_W;
          end else begin
            storage_reg <= combined_data;
          end
        end else if(FILL_LEVEL[state_idx] >= OUT_W) begin
          if (out_ready) begin
            m_axis_tdata <= combined_data[OUT_W-1:0];
            m_axis_tvalid <= 1'b1;
            storage_reg <= combined_data >> OUT_W;
          end
        end
      end
    end // always_ff

    always_comb begin : combined_data_block
      if(s_axis_tready && s_axis_tvalid) 
        combined_data = storage_reg | (BUF_W'(s_axis_tdata) << FILL_LEVEL[state_idx]);
      else 
        combined_data = storage_reg;
    end // combined_data_block

  end // if IN_W == OUT_W

endmodule
