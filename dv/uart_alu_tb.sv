
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

    repeat(1) begin 
        uart_alu_runner.sendByte();
        uart_alu_runner.waitForEcho();
    end

    $display( "End simulation." );
    $finish;
end

endmodule
