`timescale 1ns / 1ps

module delay_line_tb;
  parameter LATENCY = 2;
  parameter WIDTH = 8;

  logic clk;
  logic rst_n;

  logic [WIDTH-1:0] din;
  logic [WIDTH-1:0] dout;

  delay_line #(
    .LATENCY(LATENCY),
    .WIDTH(WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .din(din),
    .dout(dout)
  );

  always begin 
    #5 clk = ~clk;
  end

  initial begin
   //$dumpfile("delay_line.vcd");
   //$dumpvars(0,delay_line_tb);

   clk = 0;
   rst_n = 0;
   din = 0;

   #20;
   rst_n = 1;
  
   din = 8'hde;
   #10;
   din = 8'had;
   #10;
   din = 8'hbe;
   #10;
   din = 8'hef;
   #10;
//   repeat(10) begin
//    @(posedge clk);
//    din = $random;
//   end

   repeat(10) @(posedge clk);

   $finish;
   
  end
endmodule
