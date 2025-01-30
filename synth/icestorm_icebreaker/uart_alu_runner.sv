
module uart_alu_runner;

 reg clk_i;
 reg BTN_N = 1;
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

 initial begin
     clk_i = 0;
     forever begin
         #41.666ns; // 12MHz
         clk_i = !clk_i;
     end
 end

 logic pll_out;
 initial begin
     pll_out = 0;
     forever begin
         #16.393ns; // 30.5MHz
         pll_out = !pll_out;
     end
 end
 assign icebreaker.pll.PLLOUTCORE = pll_out;

 icebreaker icebreaker 
 (  .clk_i(clk_i),
    .rst_ni(!BTN_N),
    .rx_i(rx_i),
    .tx_o(tx_o));

 
uart_tx #(
    .DATA_WIDTH(8))
uart_tx_inst (
    .clk(pll_out),
    .rst(!BTN_N),
    .s_axis_tdata(s_axis_tdata_sim),
    .s_axis_tvalid(s_axis_tvalid_sim),
    .s_axis_tready(s_axis_tready_sim),
    .txd(rx_i),
    .busy(),
    .prescale(30500000/76800)
);

uart_rx
#(.DATA_WIDTH(8))
uart_rx_inst
(
    .clk(pll_out),
    .rst(!BTN_N),
    .m_axis_tdata(m_axis_tdata_sim),
    .m_axis_tready(m_axis_tready_sim),
    .m_axis_tvalid(m_axis_tvalid_sim),
    .prescale(30500000/76800),
    .rxd(tx_o)
);


 task automatic reset;
     BTN_N <= 0;
     @(posedge pll_out);
     BTN_N <= 1;
 endtask

task automatic echo(logic [31:0] data);
    s_axis_tdata_sim <= 236;
    repeat(6) @(posedge pll_out);
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
    //wait(m_axis_tvalid);
    #20
    $display("Test run completed.");

endtask

task automatic transmit(input logic [7:0] data);
    @(posedge pll_out);
    //wait(s_axis_tready_sim)
    @(posedge pll_out);
    s_axis_tdata_sim <= data;
    s_axis_tvalid_sim <= 1'b1;
    @(negedge s_axis_tready_sim);
    s_axis_tvalid_sim <= 1'b0;
endtask

task automatic receive(output logic [7:0] data);
    //wait(m_axis_tready_sim)
    @(posedge pll_out);
    m_axis_tready_sim <= 1'b1;
    @(negedge m_axis_tvalid_sim);
    data = m_axis_tdata_sim;
    m_axis_tready_sim <= 0;
endtask


task automatic send_packet(input [7:0] opcode, input logic [15:0] packet_len, input logic [7:0] data[]);
    logic [7:0] header[3:0];
    header[3] = opcode;
    header[2] = 8'h00;
    header[1] = packet_len[7:0];
    header[0] = packet_len[15:8];

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
    result = {bytes[0], bytes[1], bytes[2], bytes[3]};
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

    len_packet = amt_operands*4 +4;
    send_packet(8'h01, len_packet, data);
    @(posedge pll_out);
    receive_result(result);

    if (result === expected) begin
        $display("PASS");
    end else begin
        $display("FAIL");
        $display("Expected: %0d", $signed(expected));
        $display("Received: %0d", $signed(result));
    end

    @(posedge pll_out);
endtask

task automatic fuzz_add(input int tests);
    logic [31:0] expected, list[];
    int operands;

    for (int test = 0; test < tests; test++) begin
        operands = $urandom_range(2, 5); // arbitrary range of operands
        list = new[operands];

        foreach (list[i]) begin
            list[i] = $urandom();
        end

        expected = 0;
        foreach (list[i]) expected += list[i];

        compute_add(list, operands, expected);
    end
endtask


task automatic compute_mul(input logic [31:0] numbers[], input int amt_operands, input logic [31:0] expected);
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

    len_packet = amt_operands*4 +4;
    send_packet(8'h02, len_packet, data);
    @(posedge pll_out);
    receive_result(result);

    if (result === expected) begin
        $display("PASS");
    end else begin
        $display("FAIL");
        $display("Expected: %0d", $signed(expected));
        $display("Received: %0d", $signed(result));
    end

    @(posedge pll_out);
endtask


task automatic fuzz_mul(input int tests);
    logic [31:0] expected, list[];
    int operands;

    for (int test = 0; test < tests; test++) begin
        operands = $urandom_range(2, 5); // arbitrary range of operands
        list = new[operands];

        foreach (list[i]) begin
            list[i] = $urandom();
        end

        expected = 1;
        foreach (list[i]) expected *= list[i];

        compute_mul(list, operands, expected);
    end
endtask

task automatic compute_div(input logic [31:0] numbers[], input int amt_operands, input logic [31:0] expected);
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

    len_packet = amt_operands*4 +4;
    send_packet(8'h03, len_packet, data);
    @(posedge pll_out);
    receive_result(result);

    if (result === expected) begin
        $display("PASS");
        $display("Expected & Received: %0d", $signed(expected));
    end else begin
        $display("FAIL");
        $display("Expected: %0d", $signed(expected));
        $display("Received: %0d", $signed(result));
    end

    @(posedge pll_out);
endtask

task automatic fuzz_div(input int tests);
    logic [31:0] expected, list[];

    for (int test = 0; test < tests; test++) begin
        list = new[2]; // only 2 operands

        foreach (list[i]) begin
            list[i] = $urandom();
        end

        expected = 0;
        if (list[1] !== 0) begin
            list[1] = $urandom(); // gen new number so cant divide by zero
        end

        expected = $signed(list[0])/$signed(list[1]);

        compute_div(list, 2, expected);
    end
endtask

endmodule
