`timescale 1ns / 1ps
module tb_uart;
    localparam CPB    = 16;                 // small divider for simulation
    localparam BIT_T  = CPB * 10;           // bit time in ns (10 ns clock)

    reg         clk = 0;
    reg  [15:0] sw  = 0;
    reg  [3:0]  btn = 0;
    reg         rxd = 1;
    wire        txd;
    wire [15:0] led;

    uart_top #(.CLKS_PER_BIT(CPB), .DB_CYCLES(4)) dut (
        .clk(clk), .sw(sw), .btn(btn),
        .UART_rxd(rxd), .UART_txd(txd), .led(led));

    always #5 clk = ~clk;

    integer errors = 0;

    task press_send;
        begin
            btn[0] = 1; repeat (20) @(posedge clk);
            btn[0] = 0; repeat (20) @(posedge clk);
        end
    endtask

    // act like the PC: drive a byte serially into UART_rxd
    task send_serial(input [7:0] b);
        integer i;
        begin
            rxd = 0; #(BIT_T);
            for (i = 0; i < 8; i = i + 1) begin rxd = b[i]; #(BIT_T); end
            rxd = 1; #(BIT_T);
        end
    endtask

    task check_led(input [7:0] exp);
        begin
            if (led[7:0] !== exp) begin
                $display("FAIL: expected %h, got %h", exp, led[7:0]);
                errors = errors + 1;
            end else
                $display("PASS: received %h", led[7:0]);
        end
    endtask

    // independent monitor on the TX line: decodes what the DUT transmits
    reg [7:0] mon;
    integer   k;
    always @(negedge txd) begin
        #(BIT_T/2);                              // middle of start bit
        for (k = 0; k < 8; k = k + 1) begin #(BIT_T); mon[k] = txd; end
        #(BIT_T);                                // middle of stop bit
        if (txd !== 1'b1) begin $display("FAIL: stop bit not 1"); errors = errors + 1; end
        $display("[%0t ns] TX monitor decoded %h", $time, mon);
    end

    initial begin
        // reset
        btn[3] = 1; repeat (10) @(posedge clk);
        btn[3] = 0; repeat (10) @(posedge clk);

        // Test 1: internal loopback (sw15 = 1)
        sw[15] = 1;
        sw[7:0] = 8'hA5; press_send; #(BIT_T*12); check_led(8'hA5);
        sw[7:0] = 8'h3C; press_send; #(BIT_T*12); check_led(8'h3C);
        sw[7:0] = 8'h00; press_send; #(BIT_T*12); check_led(8'h00);
        sw[7:0] = 8'hFF; press_send; #(BIT_T*12); check_led(8'hFF);

        // Test 2: external pin / PC mode (sw15 = 0)
        sw[15] = 0;
        send_serial(8'h41); #(BIT_T*2); check_led(8'h41);   // 'A'
        send_serial(8'h7E); #(BIT_T*2); check_led(8'h7E);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule