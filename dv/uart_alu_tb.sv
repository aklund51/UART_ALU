
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
<<<<<<< HEAD
        // uart_alu_runner.echo({8'h42, 8'h69, 8'h42, 8'h69});
        uart_alu_runner.add();
=======
        //uart_alu_runner.echo({8'h42, 8'h69, 8'h42, 8'h69});
        uart_alu_runner.fuzz_add(100);
>>>>>>> b4ec67e421729e52bf10e57417b8f3ca9e8c2c48
    end

    $display( "End simulation." );
    $finish;
end

endmodule
