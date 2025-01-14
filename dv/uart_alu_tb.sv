
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

    uart_alu_runner.reset();
    repeat(3) @(posedge uart_alu_runner.clk_i);

    repeat(1) begin 
        uart_alu_runner.echo(8'hff);
        uart_alu_runner.echo(8'h88);
        uart_alu_runner.echo(8'h30);
        uart_alu_runner.echo(8'h00);
        uart_alu_runner.echo(8'h11);
    end

    $display( "End simulation." );
    $finish;
end

endmodule
