module uart_alu (
    input clk_i,
    input reset_unsafe_i
);
    // reset to be used in synchronous design
    logic [0:0] reset_l;
    always_ff @(posedge clk_i) begin 
        reset_l <= reset_unsafe_i;
    end
    
endmodule
