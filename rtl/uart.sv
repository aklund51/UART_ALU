
`timescale 1ns / 1ps

module uart
#(parameter DATA_WIDTH = 8
 )
(
    input wire clk_i,
    input wire rst_ni,

    // UART Interface
    input wire RX_i,
    output wire TX_o,

    
    // AXI input
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,


    // AXI output
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,

    input wire [15:0] prescale

);


    uart_rx
    #(.DATA_WIDTH(DATA_WIDTH))
    uart_rx_inst
    (
    .clk(clk_i)
    ,.rst(rst_ni)

    ,.m_axis_tdata(m_axis_tdata)
    ,.m_axis_tvalid(m_axis_tvalid) 
    ,.m_axis_tready(m_axis_tready)

    ,.rxd(RX_i)

    ,.busy()
    ,.overrun_error()
    ,.frame_error()

    ,.prescale(prescale)

);

    uart_tx
    #(.DATA_WIDTH(DATA_WIDTH))
    uart_tx_inst
    (
        .clk(clk_i)
        ,.rst(rst_ni)

        ,.s_axis_tdata(s_axis_tdata)
        ,.s_axis_tvalid(s_axis_tvalid) 
        ,.s_axis_tready(s_axis_tready)

        ,.txd(TX_o)

        ,.busy()

        ,.prescale(prescale)
    );

    
endmodule
