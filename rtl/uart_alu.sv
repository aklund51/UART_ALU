`timescale 1ns / 1ps

module uart_alu (
    input clk_i,
    input reset_i,
    input RX_i,
    output TX_o,
    output LEDG_N
);

    // logic [0:0] reset_l;
    // logic [0:0] s_axis_tdata;
    // logic [0:0] s_axis_tready;
    // logic [0:0] s_axis_tvalid;
    // logic [0:0] m_axis_tdata;
    // logic [0:0] m_axis_tready;
    // logic [0:0] m_axis_tvalid;

    // always_ff @(posedge clk_i) begin
    //     reset_l <= reset_i;
    // end


    // assign LEDG_N = ~(|axis_tdata);

    // always_ff @(posedge clk_i) begin
    //     if (reset_l) begin
    //         s_axis_tdata <= 0;
    //         s_axis_tvalid <= 0;
    //         m_axis_tready <= 0;
    //     end else begin
    //         if (s_axis_tvalid) begin
    //             // attempting to transmit a byte
    //             // so can't receive one at the moment
    //             m_axis_tready <= 0;
    //             // if it has been received, then clear the valid flag
    //             if (s_axis_tready) begin
    //                 s_axis_tvalid <= 0;
    //             end
    //         end else begin
    //             // ready to receive byte
    //             m_axis_tready <= 1;
    //             if (m_axis_tvalid) begin
    //                 // got one, so make sure it gets the correct ready signal
    //                 // (either clear it if it was set or set it if we just got a
    //                 // byte out of waiting for the transmitter to send one)
    //                 m_axis_tready <= ~m_axis_tready;
    //                 // send byte back out
    //                 s_axis_tdata <= m_axis_tdata;
    //                 s_axis_tvalid <= 1;
    //             end
    //         end
    //     end
    // end


    // uart #(.DATA_WIDTH(8))
    // uart_inst
    // (   .clk_i(clk_i),
    //     .rst_ni(reset_l),
    //     .s_axis_tdata(s_axis_tdata),
    //     .s_axis_tvalid(s_axis_tvalid),
    //     .s_axis_tready(s_axis_tready),
    //     .m_axis_tdata(m_axis_tdata),
    //     .m_axis_tvalid(m_axis_tvalid),
    //     .m_axis_tready(m_axis_tready),
    //     .RX_i(RX_i),
    //     .TX_o(TX_i),
    //     .prescale(31500000/(9600*8))
    // );


    logic [0:0] reset_sync_pre, reset_sync, reset_inv;
    //should print 'A'
    wire [7:0] axis_tdata_w = 8'd65;
    logic [0:0] m_axis_tvalid_l;
    wire [0:0] s_axis_tready_w;

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

always_ff @(posedge clk_i) begin
    if(reset_sync) begin
        m_axis_tvalid_l <= 0;
    end
    else begin
        m_axis_tvalid_l <= s_axis_tready_w;
    end

end

uart_tx #(
    .DATA_WIDTH(8))
uart_tx_inst (
    .clk(clk_i),
    .rst(reset_sync),
    .s_axis_tdata(axis_tdata_w),
    .s_axis_tvalid(m_axis_tvalid_l),
    .s_axis_tready(s_axis_tready_w),
    .txd(TX_o),
    .busy(),
    .prescale(31500000/(9600*8))
);


endmodule
