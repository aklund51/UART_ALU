
module uart_alu_runner;

logic clk_i;
logic rst_ni;
logic led_o;

localparam realtime ClockPeriod = 5ms;

initial begin
    clk_i = 0;
    forever begin
        #(ClockPeriod/2);
        clk_i = !clk_i;
    end
end



task automatic reset;
    rst_ni <= 0;
    @(posedge clk_i);
    rst_ni <= 1;
endtask

task automatic task_1;
   //
endtask

task automatic task_2;
    // perform task @(some signal high/low)
endtask

endmodule
