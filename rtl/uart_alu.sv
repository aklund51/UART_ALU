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



    // misc signals
    logic [(4*DATA_WIDTH)-1:0] acc_q, acc_d, curr_num_q, curr_num_d;
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

    typedef enum logic[3:0] {FETCH_OPCODE, RESERVE, LSB_LEN, MSB_LEN, 
    OPERAND_ONE, OPERAND_TWO, ECHO, ADD, TRANSMIT, MUL, DIV} ALU_CTRL_STATE;

    wire [DATA_WIDTH-1:0] ECHO_OPCODE = 8'hec;
    wire [DATA_WIDTH-1:0] ADD_OPCODE = 8'h01;
    wire [DATA_WIDTH-1:0] MUL_OPCODE = 8'h02;
    wire [DATA_WIDTH-1:0] DIV_OPCODE = 8'h03;

    ALU_CTRL_STATE curr_state_q, next_state_d, later_state_q, later_state_d;

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
        .prescale(31500000/(9600*8))
    );

    // receive by default
    always_comb begin
        m_axis_tready = 1'b1;
        s_axis_tvalid = 1'b0;
        s_axis_tdata = 'd0;
    end

    always_ff @(posedge clk_i) begin
        if (reset_sync) begin
            curr_state_q <= FETCH_OPCODE;
            later_state_q <= FETCH_OPCODE;
            echo_skip_q <= 1'b0;
            byte_count_q <= 0;
            len_packet_q <= 0;
            acc_q <= 0;
            curr_num_q <= 0;

        end else begin
            curr_state_q <= next_state_d;
            later_state_q <= later_state_d;
            echo_skip_q <= echo_skip_d;
            byte_count_q <= byte_count_d;
            len_packet_q <= len_packet_d;
            acc_q <= acc_d;
            curr_num_q <= curr_num_d;

        end
    end


    always_comb begin
        next_state_d = curr_state_q;
        later_state_d = later_state_q;
        echo_skip_d = echo_skip_q;
        byte_count_d = byte_count_q;
        len_packet_d = len_packet_q;
        acc_d = acc_q;
        curr_num_d = curr_num_q;


    unique case(curr_state_q)
        FETCH_OPCODE: begin
            echo_skip_d = 1'b0;
            if (m_axis_tvalid) begin // ECHO OPCODE 0xec, ADD 0x01, MUL 0x02, DIV 0x03
            case (m_axis_tdata)
                ECHO_OPCODE: begin
                    later_state_d = ECHO;
                    echo_skip_d = 1'b1;
                end
                ADD_OPCODE: later_state_d = ADD;
                MUL_OPCODE: later_state_d = MULT;
                DIV_OPCODE: later_state_d = DIV;
                default: later_state_d = FETCH_OPCODE;
            endcase
                next_state_d = RESERVE;
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

                //
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

                curr_num_d[byte_count_q*8+:8] = m_axis_tdata;
                // read four bytes then go to operation
                if (byte_count_q == 'd3) begin
                    byte_count_d = 0;
                    next_state_d = later_state_q;
                end else if (len_packet_q == 'd4) begin
                    byte_count_d = 0;
                    next_state_d = TRANSMIT;
                end
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

        /*
        MULT: begin

        end

        DIV: begin

        end
        */

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
   
