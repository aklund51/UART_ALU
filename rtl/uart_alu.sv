`timescale 1ns / 1ps

module uart_alu (
    input clk_i,
    input reset_i,
    input RX_i,
    output TX_o,
    output LEDG_N
);

    logic [0:0] reset_l;
    //should print 'A'
    wire [7:0] axis_tdata_w = 8'd65;
    logic [0:0] m_axis_tvalid_l;
    wire [0:0] s_axis_tready_w;

    always_ff @(posedge clk_i) begin
        reset_l <= reset_i;
    end

    // uart #(.DATA_WIDTH(8))
    // uart_inst
    // (   .clk_i(clk_i),
    //     .rst_ni(rst_ni),
    //     .s_axis_tdata(axis_tdata_w),
    //     .s_axis_tvalid(m_axis_tvalid_w),
    //     .s_axis_tready(s_axis_tready_w),
    //     .m_axis_tdata(axis_tdata_w),
    //     .m_axis_tvalid(m_axis_tvalid_w),
    //     .m_axis_tready(s_axis_tready_w),
    //     .RX_i(RX_i),
    //     .TX_o(TX_o),
    //     .prescale(16'd1250)
    // );


assign LEDG_N = 1'b0;

always_ff @(posedge clk_i) begin
    if(reset_l) begin
        m_axis_tvalid_l <= 0;
    end
    else begin
        m_axis_tvalid_l <= 1;
    end

end

uart_tx #(
    .DATA_WIDTH(8))
uart_tx_inst (
    .clk(clk_i),
    .rst(reset_l),
    .s_axis_tdata(axis_tdata_w),
    .s_axis_tvalid(m_axis_tvalid_l),
    .s_axis_tready(s_axis_tready_w),
    .txd(TX_o),
    .busy(),
    .prescale(31500000/(9600*8))
);



endmodule
