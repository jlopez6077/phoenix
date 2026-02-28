`timescale 1ns / 100ps;

module debouncer_tb;
  parameter FREQ = 100_000_000;             // Hz
  parameter PERIOD = 1_000_000_000 / FREQ;  // ns

  parameter int DEBOUNCE_CYCLE = 3;
  parameter int TWO_FLOP_SYNC_DELAY = 0; 

  parameter int TEST_ONE = 3; // Number of times Test One repeats
  parameter int TEST_TWO = 4; // Number of times Test Two repeats

  int cycles = DEBOUNCE_CYCLE; 
  int error_count = 0;

  logic clk,
        rst_n,
        bouncy,
        debounced;
  
  logic bouncy_init;

  debouncer #(
    .DEBOUNCE_CYCLE(DEBOUNCE_CYCLE),
    .TWO_FLOP_SYNC_DELAY(TWO_FLOP_SYNC_DELAY)
  ) uut (.*);

  initial begin
    clk = 1;
    forever #(PERIOD/2) clk = ~clk;
  end

  initial begin
    $dumpfile("debouncer.vcd");
    $dumpvars(0, debouncer_tb);
    $display("\nPeriod: %d ns", PERIOD);
    $display("Paramters:\nDEBOUNCE_CYCLE \t%d\nTWO_FLOP_SYNC_DELAY %d\n", 
              DEBOUNCE_CYCLE, TWO_FLOP_SYNC_DELAY
            );

    rst_n = 0;
    bouncy = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
    $display("\n--- Reset Release at %t ---\n", $time);

    $display("TEST 1: Changing output");
    if (!cycles) cycles = 1;
    fork
      // First thread
      begin : checks_output
        // waits for the pipeline delay 
        repeat (TWO_FLOP_SYNC_DELAY) @(posedge clk); 

        repeat (TEST_ONE) begin
          bouncy_init <= uut.sync_bouncy;
          repeat (cycles) @(posedge clk);
          #0.1; 
          if (debounced != bouncy_init) begin
            $error("Initial input does not equal output. Input: %h, Output: %h", bouncy_init, debounced);
            error_count++;
          end
        end
      end // checks_output

      // Second thread
      begin : changes_input
        repeat (TEST_ONE) begin
          repeat (cycles) @(posedge clk);
          bouncy <= ~bouncy;
        end
      end // changes_input

    join // wait for all threads finish
    if (!error_count)
      $display("TEST 1 PASSES");
    else 
      $display("TEST 1 FAILED: %d errors", error_count);


    $display("\nTEST 2: Filtering input");
    bouncy_init <= debounced;
    error_count <= 0;
    fork
      begin
        repeat (TEST_TWO) begin
          bouncy <= ~bouncy;
          repeat (cycles-1) @(posedge clk);
          #0.1;
          if (debounced != bouncy_init) begin
            $error("Output has changed. Expected Output: %h, Output: %h", bouncy_init, debounced);
            error_count++;
          end
        end
      end
    join // wait for all threads finish
    if (!error_count)
      $display("TEST 2 PASSES\n");
    else 
      $display("TEST 2 FAILED: %d errors\n", error_count);

    repeat (5) @(posedge clk);
    $display("\n--- Simulation Finished ---");
    $finish;
    
  end

  initial
    $monitor("Time %t | bouncy %h | uut.sync_bouncy %h | debounced %h", 
              $time, bouncy, uut.sync_bouncy, debounced);

endmodule
