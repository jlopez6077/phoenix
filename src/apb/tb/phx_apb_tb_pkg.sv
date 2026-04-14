
package phx_apb_tb_pkg;

  task automatic apb_write (
    input logic clk,
    input logic rst_n,
    virtual phx_apb_if m_apb,
    input logic [15:0] addr,
    input logic [31:0] data
  );
    // --- T0: Setup Phase --- 
    m_apb.paddr   <= addr;
    m_apb.psel    <= 1'b1;
    m_apb.penable <= 1'b0;
    m_apb.pwrite  <= 1'b1;
    m_apb.pwdata  <= data;
    @(posedge clk);

    // --- T1: Access Phase --- 
    m_apb.penable <= 1'b1;
    @(posedge clk);

    wait(m_apb.pready);
    
    // --- T2: Idle ---
    m_apb.psel    <= 1'b0;
    m_apb.penable  <= 1'b0;
    @(posedge clk);
  endtask

endpackage
