`timescale 1ns/1ps
module uart_alu_runner;

// Inputs
logic clk_i;
logic rst_ni;
logic rx_i;

// logic [15:0] prescale = 12'd1250;
logic [7:0] s_axis_tdata_sim;
logic s_axis_tvalid_sim;
logic m_axis_tready_sim;

// Outputs
logic tx_o;
logic s_axis_tready_sim;
logic s_axis_uart_tready_sim;
logic [7:0] m_axis_uart_tdata_sim;
logic m_axis_tvalid;
logic m_axis_uart_tvalid;


localparam realtime ClockPeriod = 5ms;

initial begin
    clk_i = 0;
    forever begin
        #(ClockPeriod/2);
        clk_i = !clk_i;
    end
end

//dut
 uart_alu 
 uart_alu_inst(   
    .clk_i(clk_i),
    .reset_i(~rst_ni),
    .RX_i(rx_i),
    .TX_o(tx_o)
);
 
uart_tx #(
    .DATA_WIDTH(8))
uart_tx_inst (
    .clk(clk_i),
    .rst(rst_ni),
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
    .clk(clk_i),
    .rst(rst_ni),
    .m_axis_tdata(m_axis_uart_tdata_sim),
    .m_axis_tready(m_axis_tready_sim),
    .m_axis_tvalid(m_axis_uart_tvalid),
    .prescale(31500000/76800),
    .rxd(tx_o)
);



task automatic reset;
    rst_ni <= 1;
    @(posedge clk_i);
    rst_ni <= 0;
endtask

task automatic add(logic [31:0] operand_1, logic [31:0] operand_2, logic [31:0] operand3);

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
    repeat(10000) @(posedge clk_i);
    $display("Test run completed.");


endtask



task automatic echo(logic [31:0] data);
    s_axis_tdata_sim <= 236; // send echo
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

task automatic add(logic [31:0] data);
    s_axis_tdata_sim <= 8'h01; // send add
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
    repeat(10000) @(posedge clk_i);
    $display("Test run completed.");

endtask

endmodule
