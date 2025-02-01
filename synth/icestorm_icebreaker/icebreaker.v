module icebreaker (
    input  wire clk_i,
    input  wire rst_ni,
    input  wire rx_i,
    output wire tx_o
);



wire clk_12 = clk_i;
wire clk_31;

// icepll -i 12 -o 30.5
SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'd0),
    .DIVF(7'd80),
    .DIVQ(3'd5),
    .FILTER_RANGE(3'd1)
) pll (
    .LOCK(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .PACKAGEPIN(clk_12),
    .PLLOUTCORE(clk_31)
);

uart_alu 
uart_alu_inst(
    .clk_i(clk_31),
    .reset_i(!rst_ni),
    .RX_i(rx_i),
    .TX_o(tx_o));

endmodule
