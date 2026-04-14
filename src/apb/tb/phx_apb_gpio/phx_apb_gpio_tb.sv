`timescale 1ns/100ps
import phx_apb_tb_pkg::*;

module phx_apb_gpio_tb;
  // Paramters
  parameter FREQ = 100_000_000;
  parameter PERIOD = 1_000_000_000 / FREQ;

  localparam ADDR_W = 16;
  localparam DATA_W = 32;

  // Pins``
  logic clk;
  logic rst_n;
  phx_apb_if #(.DATA_W(DATA_W), .ADDR_W(ADDR_W)) m_apb();
  logic [DATA_W-1:0] gpio_pins;

  // DUT
  phx_apb_gpio #(
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .s_abp(m_apb),
    .gpio_pins(gpio_pins)
  );

  initial begin
    clk = 1;
    forever #(PERIOD/2) clk = ~clk;
  end


  initial begin
    $dumpfile("phx_apb_gpio.vcd");
    $dumpvars(0,phx_apb_gpio_tb);
    $display("Period: %d ns\n", PERIOD);
    
    rst_n <= 0;

    // Reset
    repeat (2) @(posedge clk);
    rst_n <= 1;
    $display("---Reset Released at %t---\n", $time);
    repeat (2) @(posedge clk);

    apb_write(clk,rst_n, m_apb, 16'h00, 32'hffff);
    apb_write(clk,rst_n, m_apb, 16'h00, 32'hdead);


    repeat (5) @(posedge clk);
    $display("--- Simulation Finished ---");
    $finish;
  end

  //initial begin
  //  $monitor("Time: %t | sw: %b | dina: %h | dinb: %h | dout: %h", 
  //           $time, sw, dina, dinb, dout);
  //end 

endmodule
