`timescale 1ns / 100ps

module phx_bypass_tb;
  localparam int WIDTH = 8;
  localparam int DINA_DELAY = 5;      // Data input a delay
  localparam int DINB_DELAY = 2;      // Data input b delay
  localparam int REGISTER_OUTPUT = 1; // low = false

  parameter FREQ = 100_000_000;
  parameter PERIOD = 1_000_000_000 / FREQ;

  logic clk;
  logic rst_n;
  logic sw;
  logic [WIDTH-1:0] dina;
  logic [WIDTH-1:0] dinb;
  logic [WIDTH-1:0] dout;

  phx_bypass #(
    .WIDTH(WIDTH),
    .DINA_DELAY(DINA_DELAY),
    .DINB_DELAY(DINB_DELAY),
    .REGISTER_OUTPUT(REGISTER_OUTPUT)
  ) uut (.*);

  initial begin
    clk = 1;
    forever #(PERIOD/2) clk = ~clk;
  end

  initial begin
    $dumpfile("phx_bypass.vcd");
    $dumpvars(0,phx_bypass_tb);
    $display("Period: %d ns\n", PERIOD);
    
    rst_n <= 0;
    sw <= 0;
    dina <= '0;
    dinb <= '0;

    // Reset
    repeat (2) @(posedge clk);
    rst_n <= 1;
    $display("---Reset Released at %t---\n", $time);
    repeat (2) @(posedge clk);

    // Testing dina, sw = 0
    @(posedge clk);
    dina <= 8'hA1; 
    $display("Time %t: Setting dina=%h. Expected at dout in %0d cycles.", $time, dina, DINA_DELAY + REGISTER_OUTPUT);

    repeat(DINA_DELAY + REGISTER_OUTPUT) @(posedge clk);
    #1;
    if (dout == 8'ha1)  $display("SUCCESS: dina reached dout\n");
    else                $error("FAILURE: Expected A1, Actual %h\n", dout);
 
    // Testing dinb, sw = 1
    @(posedge clk);
    sw <= 1;
    dinb <= 8'hB2;
    $display("Time %t: Setting dinb=%h. Expected at dout in %0d cycles.", $time, dinb, DINB_DELAY + REGISTER_OUTPUT);
    repeat(DINB_DELAY + REGISTER_OUTPUT) @(posedge clk);
    #1;
    if (dout == 8'hB2) $display("SUCCESS: dinb reached dout correctly.\n");
    else                $error("FAILURE: Expected B2, Actual %h\n", dout);
    @(posedge clk);
  
    // Final test 
    repeat (5) begin 
      sw <= ~sw;
      dina <= $random;
      dinb <= $random;
      #1;
      if (!(DINA_DELAY || DINB_DELAY) & !REGISTER_OUTPUT) @(posedge clk); // if there is no delay
      else if (sw) repeat (DINB_DELAY + REGISTER_OUTPUT)  @(posedge clk); // if dout = dinb
      else    repeat (DINA_DELAY + REGISTER_OUTPUT)       @(posedge clk); // if dout = dina
    end

    repeat (5) @(posedge clk);
    $display("--- Simulation Finished ---");
    $finish;

  end

  initial begin
    $monitor("Time: %t | sw: %b | dina: %h | dinb: %h | dout: %h", 
             $time, sw, dina, dinb, dout);
  end 
endmodule
