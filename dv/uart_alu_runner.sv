`timescale 1ns/1ps
module uart_alu_runner;

// Inputs
logic clk_i;
logic rst_ni;
logic rx_i;

logic [7:0] s_axis_tdata_sim;
logic s_axis_tvalid_sim;
logic m_axis_tready_sim;
// Outputs
logic tx_o;
logic s_axis_tready_sim;
logic [7:0] m_axis_tdata_sim;
logic m_axis_tvalid_sim;

localparam realtime ClockPeriod = 5ms;//31.746ns;

initial begin
    clk_i = 0;
    forever begin
        #(ClockPeriod/2);
        clk_i = !clk_i;
    end
end

// dut
 uart_alu 
 uart_alu_inst(   
    .clk_i(clk_i),
    .reset_i(~rst_ni),
    .RX_i(rx_i),
    .TX_o(tx_o)
);
 
uart_tx #(
    .DATA_WIDTH(8))
uart_tx_inst (
    .clk(clk_i),
    .rst(rst_ni),
    .s_axis_tdata(s_axis_tdata_sim),
    .s_axis_tvalid(s_axis_tvalid_sim),
    .s_axis_tready(s_axis_tready_sim),
    .txd(rx_i),
    .busy(),
    .prescale(31500000/76800)
);

uart_rx
#(.DATA_WIDTH(8))
uart_rx_inst
(
    .clk(clk_i),
    .rst(rst_ni),
    .m_axis_tdata(m_axis_tdata_sim),
    .m_axis_tready(m_axis_tready_sim),
    .m_axis_tvalid(m_axis_tvalid_sim),
    .prescale(31500000/76800),
    .rxd(tx_o)
);



task automatic reset;
    rst_ni <= 1;
    @(posedge clk_i);
    rst_ni <= 0;
endtask

task automatic transmit(input logic [7:0] data);
    @(posedge clk_i);
    //wait(s_axis_tready_sim)
    @(posedge clk_i);
    s_axis_tdata_sim <= data;
    s_axis_tvalid_sim <= 1'b1;
    @(posedge clk_i);
    s_axis_tvalid_sim <= 1'b0;
endtask

task automatic receive(output logic [7:0] data);
    //wait(m_axis_tready_sim)
    @(posedge clk_i);
    m_axis_tready_sim <= 1'b1;
    m_axis_tdata_sim = data;
    @(posedge clk_i);
    m_axis_tvalid_sim <= 1'b0;
    @(posedge clk_i);
endtask

task automatic echo(logic [31:0] data);
    s_axis_tdata_sim <= 236; // send echo
    repeat(6) @(posedge clk_i);
    s_axis_tvalid_sim <= 1;
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= 0; //res
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= 8; //lsb
    @(negedge s_axis_tready_sim); 
    s_axis_tdata_sim <= 0;//msb
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= data[(1*8)-1:0];
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= data[(2*8)-1:8];
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= data[(3*8)-1:2*8];
    @(negedge s_axis_tready_sim);
    s_axis_tdata_sim <= data[(4*8)-1:3*8];
    @(negedge s_axis_tready_sim);
    s_axis_tvalid_sim <= 0;
    @(posedge s_axis_tready_sim);
    #20
    $display("Test run completed.");
endtask

task automatic send_packet(input [7:0] opcode, input logic [15:0] packet_len, input logic [7:0] data[]);
    logic [7:0] header[3:0];
    header[0] = opcode;
    header[1] = 8'h00;
    header[2] = packet_len[7:0];
    header[3] = packet_len[15:8];

    foreach (header[item]) begin
        transmit(header[item]);
    end

    foreach (data[item]) begin
        transmit(data[item]);
    end
endtask

task automatic receive_result(output logic [31:0] result);
    logic [7:0] bytes [3:0];
    foreach (bytes[item]) begin
        receive(bytes[item]);
    end
    result = {bytes[3], bytes[2], bytes[1], bytes[0]};
endtask

task automatic compute_add(input logic [31:0] numbers[], input int amt_operands, input logic [31:0] expected);
    logic [7:0] data[];
    logic [15:0] len_packet;
    logic [31:0] result;

    data = new[amt_operands*4]; // byte array
    for (int bytes = 0; bytes < amt_operands; bytes++) begin
        data[bytes*4+3] = numbers[bytes][31:24];
        data[bytes*4+2] = numbers[bytes][23:16];
        data[bytes*4+1] = numbers[bytes][15:8];
        data[bytes*4] = numbers[bytes][7:0];
    end

    len_packet = 16'd4 + 16'(data.size());
    send_packet(8'h01, len_packet, data);
    @(posedge clk_i);
    receive_result(result);

    if (result === expected) begin
        $display("PASS");
    end else begin
        $display("FAIL");
        $display("Expected: %0d", $signed(expected));
        $display("Received: %0d", $signed(result));
    end
endtask

task automatic fuzz_add(input int tests);
    logic [31:0] expected, list[];
    int operands;

    for (int test = 0; test < tests; test++) begin
        operands = $urandom_range(2, 50); // arbitrary range of operands
        list = new[operands];

        foreach (list[i]) begin
            list[i] = $urandom();
        end

        expected = 0;
        foreach (list[i]) expected += list[i];

        compute_add(list, operands, expected);
    end
endtask

endmodule
