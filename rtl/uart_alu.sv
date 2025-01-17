`timescale 1ns / 1ps

module uart_alu 
#(parameter DATA_WIDTH = 8)
(
    input clk_i,
    input reset_i,
    input RX_i,
    output TX_o,
    output LEDG_N
);

    logic [0:0] s_axis_tready, s_axis_tvalid;
    logic [0:0] m_axis_tready, m_axis_tvalid;
    logic [DATA_WIDTH-1:0] s_axis_tdata, m_axis_tdata;

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

    assign LEDG_N = 1'b0;

    typedef enum logic[3:0] {FETCH_OPCODE, RESERVE, LSB_LEN, MSB_LEN, 
    OPERAND_ONE, OPERAND_TWO, ECHO, ADD, TRANSMIT, MUL, DIV} ALU_CTRL_STATE;

    ALU_CTRL_STATE curr_state_r, next_state_r, later_state_r;

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

    always_ff @(posedge clk_i or posedge reset_sync_q) begin
        if (reset_sync) begin
            curr_state_r <= IDLE;
        end else begin
            curr_state_r <= next_state_r;
        end
    end

    always_comb begin
        next_state_r = curr_state_r

        unique case(curr_state_r)
            FETCH_OPCODE: begin
                if (m_axis_tvalid) begin // ECHO OPCODE 0x01, ADD 0x02, MUL 0x03, DIV 0x04
                    if (m_axis_tdata == 'h01) begin
                        later_state_r = ECHO;
                    end else if (m_axis_tdata == 'h02) begin
                        later_state_r = ADD;
                    end else if (m_axis_tdata == 'h03) begin
                        later_state_r = MUL;
                    end else if (m_axis_tdata == 'h04) begin
                        later_state_r = DIV;
                    end
                    next_state_r = RESERVE;
                end
            end

            RESERVE: begin
                if (m_axis_tvalid) begin
                    next_state_r = LSB_LEN;
                end
            end

            LSB_LEN: begin
                if (m_axis_tvalid) begin
                    //
                    next_state_r = MSB_LEN;
                end
            end

            MSB_LEN: begin

            end

            OPERAND_ONE: begin

            end

            OPERAND_TWO: begin

            end 

            ADD: begin

            end

            ECHO: begin

            end
        endcase
    end

   endmodule
   
