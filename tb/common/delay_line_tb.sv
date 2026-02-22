module tb_delay_line;

    parameter WIDTH = 8;
    parameter LATENCY = 3;

    logic clk;
    logic rst_n;
    logic [WIDTH-1:0] din;
    logic [WIDTH-1:0] dout;

    // Instantiate DUT
    delay_line #(
        .WIDTH(WIDTH),
        .LATENCY(LATENCY)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .dout(dout)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        din = 0;

        #20;
        rst_n = 1;

        repeat (10) begin
            @(posedge clk);
            din = $random;
        end

        #100;
        $finish;
    end

endmodule

