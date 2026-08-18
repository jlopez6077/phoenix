/*
--------------------------------------------------------------------------------
Module      : phx_axis_frame_controller
Project     : Fpga-based Deterministic Packet Engine
Author      : Juan Lopez
Created     : 2026-08-13
Module Type : AXI-Stream Component

Description :
  The phx_axis_frame_controller is an AXIS framing module designed to
  manage packet boundaries within a continuous data stream. Its
  function is to generate or synchronize the TLAST (End of Packet) signal
  to a specific size.
  
  Parameters :
  - DATA_W          : Data bus width in bits

  Latency:
  - 1 Clock Cycle (Registered output)

--------------------------------------------------------------------------------
*/

module phx_axis_frame_controller #(
    parameter DATA_W = 32
)(
    input  logic              rst_n,

    // Slave Interface (Input)
    input  logic              axis_clk,
    input  logic [DATA_W-1:0] s_axis_tdata,
    input  logic              s_axis_tvalid,
    input  logic              s_axis_tlast,
    output logic              s_axis_tready,

    // Master Interface (Output)
    output logic [DATA_W-1:0] m_axis_tdata,
    output logic              m_axis_tvalid,
    output logic              m_axis_tlast,
    input  logic              m_axis_tready
);

    logic [31:0] counter;
    logic [31:0] frame_size = 10;
    
    // Pipeline advance condition: advance when downstream is ready OR our output register is empty
    logic pipe_en;
    assign pipe_en = m_axis_tready || !m_axis_tvalid;
    
    // Upstream is ready whenever our output pipeline can accept new data
    assign s_axis_tready = pipe_en;

    // Frame counter logic
    always_ff @(posedge axis_clk) begin
        if (!rst_n) begin
            counter <= '0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            if ((counter == frame_size - 1) || s_axis_tlast) begin
                counter <= '0;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    // Output Register Block (Data, Valid, and Last aligned)
    always_ff @(posedge axis_clk) begin
        if (!rst_n) begin
            m_axis_tdata  <= '0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else if (pipe_en) begin
            m_axis_tvalid <= s_axis_tvalid;
            
            if (s_axis_tvalid) begin
                m_axis_tdata <= s_axis_tdata;
                // Assert tlast on target frame boundary or incoming tlast
                m_axis_tlast <= (counter == frame_size - 1) || s_axis_tlast;
            end else begin
                m_axis_tlast <= 1'b0;
            end
        end
    end

endmodule
