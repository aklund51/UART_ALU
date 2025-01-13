`timescale 1ns/1ps
module uart_alu_runner;

// Inputs
logic clk_i;
logic rst_ni = 0;
logic RX_i;
logic [7:0] s_axis_tdata = 0;
logic s_axis_tvalid = 0;
logic m_axis_tready = 0;
logic [15:0] prescale = 16'd1250;


// Outputs
wire TX_o;
wire s_axis_tready;
wire [7:0] m_axis_tdata;
wire m_axis_tvalid;

localparam realtime ClockPeriod = 5ms;

initial begin
    clk_i = 0;
    forever begin
        #(ClockPeriod/2);
        clk_i = !clk_i;
    end
end


uart uart (.*);
logic [7:0] byte_received;
logic ready_lo;
logic transmit;

task automatic reset;
    rst_ni <= 0;
    @(posedge clk_i);
    rst_ni <= 1;
    @(posedge clk_i);
    rst_ni <= 0;
endtask


task automatic sendByte(logic [7:0] byte_sent);
    s_axis_tvalid <= 1'b1;
    s_axis_tdata <= byte_sent;
    ready_lo <= s_axis_tready;
    transmit <= 1'b0;

    @(posedge clk_i);
    while (!ready_lo) begin
        @(posedge clk_i);
        ready_lo <= (s_axis_tready && s_axis_tvalid);
    end

    s_axis_tvalid <= 0;
    ready_lo <= 0;
    m_axis_tready <= 1;
    transmit <= m_axis_tvalid;
    byte_received <= m_axis_tdata;
    s_axis_tdata <= 0;

    @(posedge clk_i);
    while (!transmit) begin
        transmit <= (m_axis_tready && m_axis_tvalid);
        byte_received <= m_axis_tdata;
        @(posedge clk_i);
    end

    s_axis_tvalid <= 0;
    ready_lo <= 0;
    transmit <= 0;
    m_axis_tready <= 0;

    assert(byte_received == byte_sent);
endtask

endmodule
