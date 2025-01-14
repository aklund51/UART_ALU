`timescale 1ns/1ps
module uart_alu_runner;

// Inputs
logic clk_i;
logic rst_ni;
logic RX_uart_i;

// logic [15:0] prescale = 12'd1250;
logic [7:0] s_axis_tdata;
logic s_axis_tvalid;
logic m_axis_tready;

// Outputs
logic TX_uart_o;
logic s_axis_tready;
logic s_axis_uart_tready;
logic [7:0] m_axis_uart_tdata;
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

uart #(.DATA_WIDTH(8))
uart_inst
(   .clk_i(clk_i),
    .rst_ni(rst_ni),
    .s_axis_tdata(m_axis_uart_tdata),
    .s_axis_tvalid(m_axis_uart_tvalid),
    .s_axis_tready(s_axis_uart_tready),
    .m_axis_tdata(m_axis_uart_tdata),
    .m_axis_tvalid(m_axis_uart_tvalid),
    .m_axis_tready(s_axis_uart_tready),
    .RX_i(RX_uart_i),
    .TX_o(TX_uart_o),
    .prescale(16'd1250)
);
 
uart_tx #(
    .DATA_WIDTH(8))
uart_tx_inst (
    .clk(clk_i),
    .rst(rst_ni),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .txd(RX_uart_i),
    .busy(),
    .prescale(16'd1250)
);


task automatic reset;
    rst_ni <= 1;
    @(posedge clk_i);
    rst_ni <= 0;
endtask

// task automatic sendByte(logic [7:0] data);
//     s_axis_tdata <= data;
//     s_axis_tvalid <= 1'b1;
//     wait(s_axis_tready);
//     @(posedge clk_i);
//     s_axis_tvalid <= 1'b0;

//     #10;

//     m_axis_tready <= 1'b1;
//     @(posedge clk_i);
//     wait(m_axis_tvalid);
//     repeat(2) @(posedge clk_i);
//     m_axis_tready <= 1'b0;

//     #10;

//     if (m_axis_tdata == s_axis_tdata) begin 
//         $display("SUCCESS. SENT: %h, RECEIVED: %h", s_axis_tdata, m_axis_tdata);
//     end else begin
//         $display("FAIL lawl. SENT: %h, RECEIVED: %h", s_axis_tdata, m_axis_tdata);
//     end

// endtask

task automatic echo(logic [7:0] data);
    s_axis_tdata <= data;
    @(posedge clk_i)
    s_axis_tvalid <= 1;
    @(negedge s_axis_tready);
    s_axis_tvalid <= 0;

    @(posedge m_axis_uart_tvalid);

    #10
    
    @(posedge s_axis_uart_tready);
    $display("data input: %h, data_output %h", s_axis_tdata, m_axis_uart_tdata);


endtask

endmodule
