//`timescale 1ns/1ps
module uart_alu_runner;

// Inputs
logic clk_i;
logic rst_ni;
logic RX_i;
logic [7:0] s_axis_tdata;
logic s_axis_tready, s_axis_tvalid;
logic m_axis_tready;
logic [15:0] prescale;

logic [31:0] itervar;

// Outputs
wire TX_o;
wire [7:0] m_axis_tdata;
wire m_axis_tvalid;
wire tx_busy, rx_busy, rx_frame_error, rx_overrun_error;


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

task automatic reset;
    rst_ni <= 0;
    @(posedge clk_i);
    rst_ni <= 1;
    @(posedge clk_i);
    rst_ni <= 0;
endtask

task automatic sendByte;
    @(posedge clk_i);
    itervar = 0;
    s_axis_tdata = 8'b10101010;
    s_axis_tready = 1'b1;
    s_axis_tvalid = 1'b1;
    m_axis_tready = 1'b1;
    prescale = 12'd1250;
    #(prescale * 8 * 10); // Wait 1 bit time

    // Start bit
    RX_i = 1'b0;
    
    for (itervar = 0; itervar < 8; itervar++) begin
        RX_i = s_axis_tdata[itervar];
        #(prescale * 8 *10); // Wait 1 bit time
    end

    // Stop bit
    RX_i = 1'b1;
    #(prescale * 16 * 10); // Wait 1 bit time
    s_axis_tvalid = 1'b0;
endtask


task automatic waitForEcho;
    begin
        wait(TX_o == 0); // Wait for start bit, never arrives as of now
        #(prescale * 8 * 10); // Wait for data to finish
    end
endtask


/*
task automatic task_2;
    // perform task @(some signal high/low)
endtask
*/

endmodule
