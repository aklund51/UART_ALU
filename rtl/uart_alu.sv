`timescale 1ns / 1ps

module uart_alu (
    input clk_i,
    input reset_unsafe_i,
    input RX_i,
    output TX_o
);
    localparam prescale_lp = 1250;
    
    wire [7:0] axis_tdata_w;
    wire [0:0] m_axis_tvalid_w;
    wire [0:0] s_axis_tready_w;
    logic [0:0] reset_l;


    // reset to be used in synchronous design
    always_ff @(posedge clk_i) begin 
        reset_l <= reset_unsafe_i;
    end


    uart
    #(.DATA_WIDTH(8))
    uart_inst
    (.clk_i(clk_i),
    .rst_ni(reset_l),
    .RX_i(RX_i),
    .TX_o(TX_o),
    .s_axis_tdata(axis_tdata_w),
    .s_axis_tvalid(m_axis_tvalid_w),
    .s_axis_tready(s_axis_tready_w),
    .m_axis_tdata(axis_tdata_w),
    .m_axis_tvalid(m_axis_tvalid_w),
    .m_axis_tready(s_axis_tready_w),

    // Status
    .tx_busy(),
    .rx_busy(),
    .rx_overrun_error(),
    .rx_frame_error(),

    // Configuration
    .prescale(prescale_lp)
);



endmodule
