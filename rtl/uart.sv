`timescale 1ns / 1ps

module uart #(
    parameter DATA_WIDTH = 8
)
(
    input                   clk_i,
    input                   rst_ni,

    input [DATA_WIDTH-1:0]  s_axis_tdata,
    input                   s_axis_tvalid,
    output                  s_axis_tready,

    output [DATA_WIDTH-1:0]  m_axis_tdata,
    output                   m_axis_tvalid,
    input                    m_axis_tready,

    input                    RX_i,
    output                   TX_o,

    input [15:0]             prescale

);

uart_tx #(
    .DATA_WIDTH(DATA_WIDTH)
)
uart_tx_inst (
    .clk(clk_i),
    .rst(rst_ni),
    // axi input
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    // output
    .txd(TX_o),
    // status
    .busy(),
    // configuration
    .prescale(prescale)
);

uart_rx #(
    .DATA_WIDTH(DATA_WIDTH)
)
uart_rx_inst (
    .clk(clk_i),
    .rst(rst_ni),
    // axi output
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    // input
    .rxd(RX_i),
    // status
    .busy(),
    .overrun_error(),
    .frame_error(),
    // configuration
    .prescale(prescale)
);

endmodule
