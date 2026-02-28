`timescale 1ns / 100ps

module delay_line_tb;
  parameter LATENCY = 2;
  parameter WIDTH = 8;
  parameter FREQ = 100_000_000;
  parameter PERIOD = 1_000_000_000 / FREQ;

  logic clk;
  logic rst_n;

  logic [WIDTH-1:0] din;
  logic [WIDTH-1:0] dout;

  logic [WIDTH-1] test_val;

  delay_line #(
    .LATENCY(LATENCY),
    .WIDTH(WIDTH)
  ) uut (.*);

  initial begin
    clk = 1;
    forever #(PERIOD/2) clk = ~clk;
  end

  initial begin
    $dumpfile("delay_line.vcd");
    $dumpvars(0,delay_line_tb);
    $display("Expected Latency between din -> dout = %d clock cycles", LATENCY);
    $display("Period: %d ns\n", PERIOD);

    rst_n = 0;
    din = 0;
    repeat(5) @(posedge clk);
    rst_n = 1;
    $display("--- Reset Release at %t", $time);

    @(posedge clk);

    repeat (5) begin
      test_val = $random();
      din <= test_val;
      $display("Expected dout value: %h", test_val);
      if (LATENCY == 0) @(posedge clk);
      else repeat(LATENCY) @(posedge clk);
      #0.1;
      if (dout == test_val) $display("Success: Expected %h, Actual %h", test_val, dout);
      else                  $error("Failure: Expected %h, Actual %h", test_val, dout);
    end
    
    repeat(5) @(posedge clk);
    $display;
    $finish;
  end

  initial $monitor("Time: %t | din: %h | dout: %h", $time, din, dout);

endmodule
