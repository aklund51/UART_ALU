`timescale 1ns / 1ps

module uart_alu (
    input clk_i,
    input reset_i,
    input RX_i,
    output TX_o,
    output LEDG_N
);

    wire [0:0] s_axis_tready;
    wire [7:0] m_axis_tdata;
    wire [0:0] m_axis_tvalid;

    logic [0:0] reset_sync_pre, reset_sync, reset_inv;


    always_ff @(posedge clk_i) begin
        reset_sync_pre <= reset_i;
    end

    always_ff @(posedge clk_i) begin
        reset_inv <= ~reset_sync_pre;
    end

    always_ff @(posedge clk_i) begin
        reset_sync <= reset_inv;
    end


    assign LEDG_N = 1'b0;


    uart #(.DATA_WIDTH(8))
    uart_inst
    (   .clk_i(clk_i),
        .rst_ni(reset_sync),
        .s_axis_tdata(m_axis_tdata),
        .s_axis_tvalid(m_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(s_axis_tready),
        .RX_i(RX_i),
        .TX_o(TX_o),
        .prescale(31500000/(9600*8))
    );

   endmodule
   
