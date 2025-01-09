
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

    repeat(4) begin
        // call tasks
    end

    $display( "End simulation." );
    $finish;
end

endmodule
