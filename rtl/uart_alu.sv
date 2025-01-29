`timescale 1ns / 1ps

module uart_alu 
#(parameter DATA_WIDTH = 8)
(
    input clk_i,
    input reset_i,
    input RX_i,
    output TX_o
);

    // UART signals
    logic [0:0] s_axis_tready, s_axis_tvalid;
    logic [0:0] m_axis_tready, m_axis_tvalid;
    logic [DATA_WIDTH-1:0] s_axis_tdata, m_axis_tdata;

    // Divider and multiplier signals
    logic [0:0] div_ready_i, div_valid_i, div_valid_o, div_ready_o;
    logic [0:0] mult_ready_i, mult_ready_o, mult_valid_i, mult_valid_o;
    logic [4*DATA_WIDTH-1:0] mult_result_o, div_result_o;


    // misc signals
    logic [4*DATA_WIDTH-1:0] acc_q, acc_d, curr_num_q, curr_num_d;
    logic [31:0] len_packet_d, len_packet_q;
    logic [1:0] byte_count_d, byte_count_q;
    logic [0:0] echo_skip_d, echo_skip_q;
    logic [0:0] reset_sync_pre, reset_sync_q, reset_inv;


    always_ff @(posedge clk_i) begin
        reset_sync_pre <= reset_i;
    end

    always_ff @(posedge clk_i) begin
        reset_inv <= ~reset_sync_pre;
    end

    always_ff @(posedge clk_i) begin
        reset_sync_q <= reset_inv;
    end

    typedef enum logic[4:0] {FETCH_OPCODE, RESERVE, LSB_LEN, MSB_LEN, 
    OPERAND_ONE, OPERAND_TWO, ECHO, ADD, TRANSMIT, MUL, DIV} ALU_CTRL_STATE;

    wire [DATA_WIDTH-1:0] ECHO_OPCODE = 8'hec;
    wire [DATA_WIDTH-1:0] ADD_OPCODE = 8'h01;
    wire [DATA_WIDTH-1:0] MUL_OPCODE = 8'h02;
    wire [DATA_WIDTH-1:0] DIV_OPCODE = 8'h03;

    ALU_CTRL_STATE curr_state_q, next_state_d, save_state_q, save_state_d;

    uart 
    #(.DATA_WIDTH(8))
    uart_inst
    (   .clk_i(clk_i),
        .rst_ni(reset_sync_q),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .RX_i(RX_i),
        .TX_o(TX_o),
        .prescale(31500000/76800) // ~ 410.156
    );


    bsg_imul_iterative 
    #(.width_p(4*DATA_WIDTH))
    multiplier
    (
        .clk_i(clk_i),
        .reset_i(reset_sync_q),
        .v_i(mult_valid_i),
        .ready_and_o(mult_ready_o),
        .opA_i(acc_q),
        .signed_opA_i(1'b1),
        .opB_i(curr_num_q),
        .signed_opB_i(1'b1),
        .gets_high_part_i(1'b0),
        .v_o(mult_valid_o),
        .result_o(mult_result_o),
        .yumi_i(mult_ready_i)
    );

    bsg_idiv_iterative
    #(.width_p(4*DATA_WIDTH), .bitstack_p(), .bits_per_iter_p())
    divider
    (
        .clk_i(clk_i),
        .reset_i(reset_sync_q),
        .v_i(div_valid_i),
        .ready_and_o(div_ready_o),
        .dividend_i(acc_q),
        .divisor_i(curr_num_q),
        .signed_div_i(1'b1),
        .v_o(div_valid_o),
        .quotient_o(div_result_o),
        .remainder_o(),
        .yumi_i(div_ready_i)
    );


    always_ff @(posedge clk_i) begin
        if (reset_sync_q) begin
            curr_state_q <= FETCH_OPCODE;
            //save_state_q <= FETCH_OPCODE;
            echo_skip_q <= 1'b0;
            byte_count_q <= 0;
            len_packet_q <= 0;
            acc_q <= 0;
            curr_num_q <= 0;
            

        end else begin
            curr_state_q <= next_state_d;
            save_state_q <= save_state_d;
            echo_skip_q <= echo_skip_d;
            byte_count_q <= byte_count_d;
            len_packet_q <= len_packet_d;
            acc_q <= acc_d;
            curr_num_q <= curr_num_d;
        end
    end


    always_comb begin
        next_state_d = curr_state_q;
        save_state_d = save_state_q;
        echo_skip_d = echo_skip_q;
        byte_count_d = byte_count_q;
        len_packet_d = len_packet_q;
        acc_d = acc_q;
        curr_num_d = curr_num_q;
        m_axis_tready = 1'b1;
        s_axis_tvalid = 1'b0;
        s_axis_tdata = 'd0;
        mult_ready_i = 1'b0;
        mult_valid_i = 1'b0;
        div_ready_i = 1'b0;
        div_valid_i = 1'b0;

        unique case(curr_state_q)
            FETCH_OPCODE: begin
                echo_skip_d = 1'b0;
                if (m_axis_tvalid) begin // ECHO OPCODE 0xEC, ADD 0x01, MUL 0x02, DIV 0x03
                    if (m_axis_tdata == ECHO_OPCODE) begin
                        echo_skip_d = 1'b1;
                        save_state_d = ECHO;
                        next_state_d = RESERVE;
                    end else if (m_axis_tdata == ADD_OPCODE) begin
                        save_state_d = ADD;
                        next_state_d = RESERVE;
                    end else if (m_axis_tdata == MUL_OPCODE) begin
                        save_state_d = MUL;
                        next_state_d = RESERVE;
                    end else if (m_axis_tdata == DIV_OPCODE) begin
                        save_state_d = DIV;
                        next_state_d = RESERVE;
                    end else begin
                        next_state_d = FETCH_OPCODE;
                    end
                end
            end

            RESERVE: begin
                if (m_axis_tvalid) begin
                    next_state_d = LSB_LEN;
                end
            end

            LSB_LEN: begin
                if (m_axis_tvalid) begin
                    len_packet_d[DATA_WIDTH-1:0] = m_axis_tdata;
                    next_state_d = MSB_LEN;
                end
            end

            MSB_LEN: begin
                if (m_axis_tvalid) begin
                    len_packet_d[2*DATA_WIDTH-1:DATA_WIDTH] = m_axis_tdata;
                    next_state_d = echo_skip_q ? ECHO : OPERAND_ONE;
                end

                byte_count_d = 0;
                acc_d = 0;
                curr_num_d = 0;
            end

            ECHO: begin
                m_axis_tready = 1'b0;

                if (m_axis_tvalid && s_axis_tready) begin
                    m_axis_tready = 1'b1;
                    s_axis_tdata = m_axis_tdata;
                    s_axis_tvalid = 1'b1;
                    len_packet_d = len_packet_q - 1;
                end

                if (len_packet_q == 'd4) begin
                    next_state_d = FETCH_OPCODE;
                    byte_count_d = 'd0;
                end
            end

            OPERAND_ONE: begin
                if (m_axis_tvalid) begin
                    byte_count_d = byte_count_q + 1;
                    len_packet_d = len_packet_q - 1;

                    // load number
                    acc_d[byte_count_q*8+:8] = m_axis_tdata;

                    if (byte_count_q == 'd3) begin
                        byte_count_d = 0;
                        next_state_d = OPERAND_TWO;
                    end
                end
            end

            OPERAND_TWO: begin
                if (m_axis_tvalid) begin
                    byte_count_d = byte_count_q + 1;
                    len_packet_d = len_packet_q - 1;

                    // read four bytes then go to operation
                    if (byte_count_q == 'd3) begin
                        byte_count_d = 0;
                        next_state_d = save_state_q;
                    end else if (len_packet_q == 'd4) begin
                        byte_count_d = 0;
                        next_state_d = TRANSMIT;
                    end
                    curr_num_d[byte_count_q*8+:8] = m_axis_tdata;
                end
            end 

            ADD: begin
                m_axis_tready = 1'b0;
                acc_d = acc_q + curr_num_q;

                if (len_packet_q == 'd4) begin
                    next_state_d = TRANSMIT;
                end else begin
                    next_state_d = OPERAND_TWO;
                end
            end

            MUL: begin
                m_axis_tready = 1'b0;
                mult_ready_i = 1'b1;

                if (mult_ready_o && byte_count_q == 'd0) begin
                    byte_count_d = byte_count_q + 1;
                    mult_valid_i = 1'b1;
                end

                if(mult_valid_o) begin
                    acc_d = mult_result_o;
                    byte_count_d = 0;

                    if(len_packet_q == 'd4) begin
                        next_state_d = TRANSMIT;
                    end else begin
                        next_state_d = OPERAND_TWO;
                    end
                end
            end

            DIV: begin
                m_axis_tready = 1'b0;
                div_ready_i = 1'b1;

                if (div_ready_o && byte_count_q == 'd0) begin
                    byte_count_d = byte_count_q + 1;
                    div_valid_i = 1'b1;
                end

                if (div_valid_o) begin
                    acc_d = div_result_o;
                    byte_count_d = 0;
                    next_state_d = TRANSMIT;
                end
            end

            TRANSMIT: begin
                m_axis_tready = 1'b0;
                if (s_axis_tready) begin
                    if (byte_count_q == 'd3) begin
                        byte_count_d = 0;
                        next_state_d = FETCH_OPCODE;
                    end
                    s_axis_tdata = acc_q[byte_count_q*8+:8];
                    s_axis_tvalid = 1'b1;
                    byte_count_d = byte_count_q + 1;
                end
            end
        endcase
    end
endmodule
