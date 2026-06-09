/*
------------------------------------------------------------------------------
Module      : phx_axis_width_converter
Project     : Phoenix Basic Library
Author      : Juan Lopez
Created     : 2026-05-19
Module Type : AXI-Stream Component

Description :
  A high-performance AXI-Stream width converter that handles both 
  up-conversion (narrow to wide) and down-conversion (wide to narrow).
  
  The module uses a GCD-based pre-calculation to determine exactly 
  how many bits are in the internal buffer at any given state. This 
  removes the need for expensive run-time arithmetic (like modulo) 
  and replaces it with a simple state counter and a lookup table of 
  constant shift values.

  Features :
  - Supports any ratio of IN_W to OUT_W.
  - Constant-shift wiring for high-frequency operation.
  - Zero-latency combinational bypass when IN_W == OUT_W.
  - Full AXI-Stream backpressure handling.

  Parameters :
  - IN_W  : Input data bus width in bits.
  - OUT_W : Output data bus width in bits.

  Latency :
  - 1 Clock Cycle (Registered output)
------------------------------------------------------------------------------
*/

module phx_axis_width_converter #(
  parameter IN_W = 32,
  parameter OUT_W = 32
)(
  input logic     clk,
  input logic     rst_n, 

  // Slave Interface (Input)
  input logic [IN_W-1:0]    s_axis_tdata,
  input logic               s_axis_tvalid,
  output logic              s_axis_tready,

  // Master Interface (Output)
  output logic [OUT_W-1:0]  m_axis_tdata,
  output logic              m_axis_tvalid,
  input logic               m_axis_tready
);

  // Buffer width must be large enough to hold at least one input and one output word
  localparam int BUF_W = IN_W + OUT_W;
  localparam int STORAGE_W = BUF_W;
  localparam int COMBO_W = BUF_W;

  // ===================================================================================
  // COMPILE-TIME MATH
  // ===================================================================================
  
  // Standard Euclidean algorithm to find the Greatest Common Divisor
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
  
  // The state machine repeats every (TotalBits / GCD) cycles
  localparam int NUM_STATES = (IN_W > OUT_W) ? (IN_W / GCD_VAL): OUT_W / GCD_VAL;

  typedef int state_array_t [NUM_STATES];

  // This function calculates exactly how many valid bits are in the 'storage_reg' 
  // for every possible step of the conversion process.
  function automatic state_array_t calc_fill_levels ();
    state_array_t levels;
    int current;
    if(IN_W < OUT_W) begin
      // Up-conversion: Buffer grows by IN_W each step until it reaches OUT_W
      current = 0;
      for (int i = 0; i < NUM_STATES; i++) begin
        levels[i] = current;
        current = current + IN_W;
        if (current >= OUT_W) 
          current = current - OUT_W;
      end
    end else begin
      // Down-conversion: Buffer starts full and shrinks by OUT_W each step
      current = IN_W;
      levels[0] = 0;
      for (int i = 1; i < NUM_STATES; i++) begin
        if (current >= OUT_W) 
          current = current - OUT_W;
        else
          current = current + IN_W - OUT_W;
        levels[i] = current;
      end
    end
    return levels;
  endfunction

  // The FILL_LEVEL array is used as a Constant Lookup Table for the shifter hardware
  localparam state_array_t FILL_LEVEL = calc_fill_levels();

  // ===================================================================================
  // HARDWARE LOGIC
  // ===================================================================================
  
  if (IN_W == OUT_W) begin // Passthrough logic
    assign m_axis_tdata = s_axis_tdata;
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;
  end else begin
    
    logic [STORAGE_W-1:0] storage_reg;     // Internal accumulation buffer
    logic [$clog2(NUM_STATES)-1:0] state_idx;
    logic [$clog2(NUM_STATES)-1:0] next_state_idx;
    logic [COMBO_W-1:0] combined_data;   // storage_reg + new input data

    logic out_ready;
    assign out_ready = !m_axis_tvalid || m_axis_tready; // Ready if register is empty OR downstream is consuming

    // Backpressure: Module ready for input if buffer has space or outputting data
    assign s_axis_tready = (IN_W > OUT_W) ? (FILL_LEVEL[state_idx] < OUT_W) && out_ready 
                                          : out_ready;

    // Sequential State Update
    always_ff @(posedge clk) begin : state_block
      if (!rst_n) begin
        state_idx <= '0;
      end else begin
        state_idx <= next_state_idx;
      end
    end

    // Combinational Next State Logic
    always_comb begin : next_state_block
      next_state_idx = state_idx;
      // CASE 1: Slave data arrives and Master is ready to consume
      if(s_axis_tready && s_axis_tvalid) begin 
        next_state_idx = (state_idx == NUM_STATES-1) ? '0 : state_idx + 1'b1;
      // CASE 2: No new data, but buffer has enough data to send (Down-conversion)
      end else if ((FILL_LEVEL[state_idx] >= OUT_W) && m_axis_tready) begin 
        next_state_idx = (state_idx == NUM_STATES-1) ? '0 : state_idx + 1'b1;
      end
    end

    // Main Data Path
    always_ff @(posedge clk) begin 
      if(!rst_n)begin
        storage_reg <= '0;
        m_axis_tvalid <= 1'b0;
        m_axis_tdata <= '0;
      end else begin
        if (m_axis_tready)
          m_axis_tvalid <= 0; 

        // CASE 1: Slave data arrives and Master is ready to consume
        if (s_axis_tready && s_axis_tvalid) begin
          // If the new data completes an output width
          if ((FILL_LEVEL[state_idx] + IN_W) >= OUT_W) begin 
            m_axis_tdata <= combined_data[OUT_W-1:0];
            m_axis_tvalid <= 1'b1;
            storage_reg <= combined_data >> OUT_W; // Store the "overflow" bits
          end else begin
            storage_reg <= combined_data; // Not enough bits for an output
          end
        
        // CASE 2: No new data, but buffer has enough data to send (Down-conversion)
        end else if(FILL_LEVEL[state_idx] >= OUT_W) begin
          if (out_ready) begin
            m_axis_tdata <= combined_data[OUT_W-1:0];
            m_axis_tvalid <= 1'b1;
            storage_reg <= combined_data >> OUT_W;
          end
        end
      end
    end

    // Accumulation logic: New data is shifted to the next "empty" slot in the buffer
    always_comb begin : combined_data_block
      if(s_axis_tready && s_axis_tvalid) 
        combined_data = storage_reg | (COMBO_W'(s_axis_tdata) << FILL_LEVEL[state_idx]);
      else 
        combined_data = storage_reg;
    end

  end

endmodule
