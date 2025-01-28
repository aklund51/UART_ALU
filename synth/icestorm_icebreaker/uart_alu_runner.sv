
module uart_alu_runner;

 reg clk_i;
 reg BTN_N = 0;
logic rst_ni;
logic rx_i = 1;

logic [7:0] s_axis_tdata_sim;
logic s_axis_tvalid_sim;
logic m_axis_tready_sim;

// Outputs
logic tx_o;
logic s_axis_tready_sim;
logic [7:0] m_axis_uart_tdata_sim;
logic m_axis_uart_tvalid;

 initial begin
     clk_i = 0;
     forever begin
         #41.666ns; // 12MHz
         clk_i = !clk_i;
     end
 end

 logic pll_out;
 initial begin
     pll_out = 0;
     forever begin
         #15.873ns; // 31.5MHz
         pll_out = !pll_out;
     end
 end
 assign icebreaker.pll.PLLOUTCORE = pll_out;

 icebreaker icebreaker (.*);

 
uart_tx #(
    .DATA_WIDTH(8))
uart_tx_inst (
    .clk(pll_out),
    .rst(!rst_ni),
    .s_axis_tdata(s_axis_tdata_sim),
    .s_axis_tvalid(s_axis_tvalid_sim),
    .s_axis_tready(s_axis_tready_sim),
    .txd(rx_i),
    .busy(),
    .prescale(31500000/76800)
);

uart_rx
#(.DATA_WIDTH(8))
uart_rx_inst
(
    .clk(pll_out),
    .rst(!rst_ni),
    .m_axis_tdata(m_axis_uart_tdata_sim),
    .m_axis_tready(m_axis_tready_sim),
    .m_axis_tvalid(m_axis_uart_tvalid),
    .prescale(31500000/76800),
    .rxd(tx_o)
);


 task automatic reset;
     BTN_N <= 0;
     @(posedge clk_i);
     BTN_N <= 1;
 endtask

task automatic echo(logic [31:0] data);
    s_axis_tdata_sim <= 236;
    repeat(6) @(posedge clk_i);
    s_axis_tvalid_sim <= 1;
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= 0; //res
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= 8; //lsb
    @(negedge s_axis_tready_sim); 
    s_axis_tdata_sim <= 0;//msb
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= data[(1*8)-1:0];
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= data[(2*8)-1:8];
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= data[(3*8)-1:2*8];
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= data[(4*8)-1:3*8];
    @(negedge s_axis_tready_sim);
    s_axis_tvalid_sim <= 0;
    @(posedge s_axis_tready_sim);
    #20
    $display("Test run completed.");

endtask

task automatic transmit(input logic [7:0] data);
    @(posedge clk_i);
    wait(s_axis_tready_sim)
    @(posedge clk_i);
    s_axis_tdata_sim <= data;
    s_axis_tvalid_sim <= 1'b1;
    @(posedge clk_i);
    s_axis_tvalid_sim <= 1'b0;
endtask

task automatic receive(output logic [7:0] data);
    wait(m_axis_tready_sim)
    @(posedge clk_i);
    m_axis_tready_sim <= 1'b1;
    m_axis_tdata_sim = data;
    @(posedge clk_i);
    m_axis_tvalid_sim <= 1'b0;
    @(posedge clk_i);
endtask

endmodule
