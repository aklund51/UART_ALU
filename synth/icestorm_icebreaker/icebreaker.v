
module icebreaker (
    input  wire clk_i,
    input  wire reset_unsafe_i,
    input  wire RX_i,
    output wire TX_o,
    output wire LEDG_N
);




// icepll -i 12 -o 50
// SB_PLL40_PAD #(
//     .FEEDBACK_PATH("SIMPLE"),
//     .DIVR(4'd0),
//     .DIVF(7'd66),
//     .DIVQ(3'd4),
//     .FILTER_RANGE(3'd1)
// ) pll (
//     .LOCK(),
//     .RESETB(1'b1),
//     .BYPASS(1'b0),
//     .PACKAGEPIN(clk_12),
//     .PLLOUTCORE(clk_50)
// );

// blinky #(
//     .ResetValue(5000000)
// ) blinky (
//     .clk_i(clk_50),
//     .rst_ni(BTN_N),
//     .led_o(led)
// );

wire clk_12 = clk_i;
wire clk_48;

// icepll -i 12 -o 31.5
SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'd0),
    .DIVF(7'd83),
    .DIVQ(3'd5),
    .FILTER_RANGE(3'd1)
) pll (
    .LOCK(),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .PACKAGEPIN(clk_12),
    .PLLOUTCORE(clk_48)
);

uart_alu 
uart_alu_inst(
    .clk_i(clk_48),
    .reset_i(reset_unsafe_i),
    .RX_i(RX_i),
    .TX_o(TX_o),
    .LEDG_N(LEDG_N));

endmodule
