//`timescale 1ns/1ps
module uart_alu_runner;

logic clk_i;
logic rst_ni;
logic RX_i;
wire TX_o;

logic [7:0] s_axis_tdata;
wire [7:0] m_axis_tdata;

logic s_axis_tready, s_axis_tvalid;
logic m_axis_tready;
wire m_axis_tvalid;

wire tx_busy, rx_busy, rx_frame_error, rx_overrun_error;

logic [15:0] prescale;

// logic led_o;

localparam realtime ClockPeriod = 5ms;

initial begin
    clk_i = 0;
    forever begin
        #(ClockPeriod/2);
        clk_i = !clk_i;
    end
end

uart
#(.DATA_WIDTH(8))
uart_dut_inst
(
    // Inputs
    .clk_i(clk_i),
    .reset_i(rst_ni),
    .RX_i(RX_i),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .m_axis_tready(m_axis_tready),
    .prescale(prescale),

    // Outputs
    .TX_o(TX_o),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .tx_busy(tx_busy),
    .rx_busy(rx_busy),
    .rx_frame_error(rx_busy),
    .rx_overrun_error(rx_overrun_error)
);
initial begin

end

task automatic reset;
    rst_ni <= 0;
    @(posedge clk_i);
    rst_ni <= 1;
endtask

task automatic transmit_data;
   input 
   repeat (12'd1250) begin
    @(posedge clk_i)
   end

endtask

/*
task automatic task_2;
    // perform task @(some signal high/low)
endtask
*/

endmodule
