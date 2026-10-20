`timescale 1ns / 1ps
module uart_top #(
    parameter CLKS_PER_BIT = 10417,        
    parameter DB_CYCLES    = 1_000_000  
)(
    input         clk,
    input  [15:0] sw,
    input  [3:0]  btn,
    input         UART_rxd,
    output        UART_txd,
    output [15:0] led
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg rst_s1 = 0, rst = 0;
    reg b1 = 0, b2 = 0, b_stable = 0, send_pulse = 0;
    reg [20:0] db_cnt = 0;
    always @(posedge clk) begin
        rst_s1 <= btn[3]; rst <= rst_s1;
        b1 <= btn[0]; b2 <= b1; send_pulse <= 1'b0;
        if (b2 == b_stable) db_cnt <= 0;
        else if (db_cnt == DB_CYCLES-1) begin
            b_stable <= b2; db_cnt <= 0;
            if (b2) send_pulse <= 1'b1;
        end else db_cnt <= db_cnt + 1'b1;
    end

    reg [1:0]  tx_state = IDLE;
    reg [15:0] tx_cnt   = 0;
    reg [2:0]  tx_idx   = 0;
    reg [7:0]  tx_sh    = 0;
    reg        tx       = 1'b1;
    wire       tx_busy  = (tx_state != IDLE);

    always @(posedge clk) begin
        if (rst) begin
            tx_state <= IDLE; tx <= 1'b1; tx_cnt <= 0; tx_idx <= 0;
        end else case (tx_state)
            IDLE: begin
                tx <= 1'b1; tx_cnt <= 0; tx_idx <= 0;
                if (send_pulse) begin tx_sh <= sw[7:0]; tx_state <= START; end
            end
            START: begin
                tx <= 1'b0;
                if (tx_cnt == CLKS_PER_BIT-1) begin tx_cnt <= 0; tx_state <= DATA; end
                else tx_cnt <= tx_cnt + 1'b1;
            end
            DATA: begin
                tx <= tx_sh[tx_idx];
                if (tx_cnt == CLKS_PER_BIT-1) begin
                    tx_cnt <= 0;
                    if (tx_idx == 3'd7) begin tx_idx <= 0; tx_state <= STOP; end
                    else tx_idx <= tx_idx + 1'b1;
                end else tx_cnt <= tx_cnt + 1'b1;
            end
            STOP: begin
                tx <= 1'b1;
                if (tx_cnt == CLKS_PER_BIT-1) begin tx_cnt <= 0; tx_state <= IDLE; end
                else tx_cnt <= tx_cnt + 1'b1;
            end
        endcase
    end


    wire rx_line = sw[15] ? tx : UART_rxd;      
    reg  rx_s1 = 1, rx_s2 = 1;                  
    reg [1:0]  rx_state = IDLE;
    reg [15:0] rx_cnt   = 0;
    reg [2:0]  rx_idx   = 0;
    reg [7:0]  rx_sh    = 0;
    reg [7:0]  rx_data  = 0;
    reg        rx_toggle = 0, frame_err = 0;

    always @(posedge clk) begin
        rx_s1 <= rx_line; rx_s2 <= rx_s1;
        if (rst) begin
            rx_state <= IDLE; rx_cnt <= 0; rx_idx <= 0;
            rx_data <= 0; rx_toggle <= 0; frame_err <= 0;
        end else case (rx_state)
            IDLE: begin
                rx_cnt <= 0; rx_idx <= 0;
                if (rx_s2 == 1'b0) rx_state <= START;        
            end
            START: begin                                        
                if (rx_cnt == (CLKS_PER_BIT-1)/2) begin
                    rx_cnt <= 0;
                    rx_state <= (rx_s2 == 1'b0) ? DATA : IDLE; 
                end else rx_cnt <= rx_cnt + 1'b1;
            end
            DATA: begin                                      
                if (rx_cnt == CLKS_PER_BIT-1) begin
                    rx_cnt <= 0;
                    rx_sh[rx_idx] <= rx_s2;
                    if (rx_idx == 3'd7) begin rx_idx <= 0; rx_state <= STOP; end
                    else rx_idx <= rx_idx + 1'b1;
                end else rx_cnt <= rx_cnt + 1'b1;
            end
            STOP: begin
                if (rx_cnt == CLKS_PER_BIT-1) begin
                    rx_cnt <= 0; rx_state <= IDLE;
                    frame_err <= ~rx_s2;
                    if (rx_s2) begin rx_data <= rx_sh; rx_toggle <= ~rx_toggle; end
                end else rx_cnt <= rx_cnt + 1'b1;
            end
        endcase
    end

    assign UART_txd = tx;
    assign led = {5'b00000, rx_toggle, frame_err, tx_busy, rx_data};
endmodule