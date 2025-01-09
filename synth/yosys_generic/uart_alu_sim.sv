
module uart_alu_sim (
    input  logic clk_i,
    input  logic rst_ni,
    output logic led_o
);

uart_alu #(
    .ResetValue(100)
) uart_alu (.*);

endmodule
