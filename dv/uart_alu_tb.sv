module uart_alu_tb
    import config_pkg::*;
    import dv_pkg::*;
    ;

uart_alu_runner uart_alu_runner ();

always begin
    $dumpfile( "dump.fst" );
    $dumpvars;
    $display( "Begin simulation." );
    $urandom(100);
    $timeformat( -3, 3, "ms", 0);

    repeat(3) uart_alu_runner.reset();
    repeat(3) @(posedge uart_alu_runner.clk_i);

    repeat(1) begin 
        uart_alu_runner.echo({8'h42, 8'h69, 8'h42, 8'h69});
        uart_alu_runner.reset();
        uart_alu_runner.fuzz_add(3);
        uart_alu_runner.reset();
        uart_alu_runner.fuzz_mul(3);
        uart_alu_runner.reset();
        uart_alu_runner.fuzz_div(3);
    end

    $display( "End simulation." );
    $finish;
end
endmodule
