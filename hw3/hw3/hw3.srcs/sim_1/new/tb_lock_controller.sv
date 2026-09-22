`timescale 1ns / 1ps

module tb_lock_controller;
    logic clk;
    logic rst;
    logic [3:0] digit_in;
    logic unlocked_led;
    
    localparam logic [1:0] LOCKED = 2'b00;
    localparam logic [1:0] WAIT_D2 = 2'b01;
    localparam logic [1:0] WAIT_D3 = 2'b10;
    localparam logic [1:0] UNLOCKED = 2'b11;
    
    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------
    lock_controller dut (
        .clk(clk),
        .rst(rst),
        .digit_in(digit_in),
        .unlocked_led(unlocked_led)
    );
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    // --------------------------------------------------------
    // Функція перевірки поточного стану FSM
    // --------------------------------------------------------
    task automatic check_state(
        input logic [1:0] expected_state,
        input string step_name
    );
        if (dut.state === expected_state)
            $display("PASS: %s, state = %b", step_name, dut.state);
        else
            $display("FAIL: %s, expected=%b, got=%b", step_name, expected_state, dut.state);
    endtask
    
    // --------------------------------------------------------
    // Функція подачі цифри
    // --------------------------------------------------------
    task automatic enter_digit(
        input logic [3:0] digit,
        input logic [1:0] expected_state,
        input string step_name
    );
        digit_in = digit;
        
        @(posedge clk); #1;
        
        check_state(expected_state, step_name);
    endtask
    
    initial begin
        rst = 1'b0;
        digit_in = 4'd0;
        
        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------
        #2; rst = 1'b1;
        
        #1;
        
        check_state(LOCKED, "async reset -> LOCKED");
        
        rst = 1'b0;
        
        // ----------------------------------------------------
        // Правильна послідовність 5 -> 3 -> 7
        // ----------------------------------------------------
        enter_digit(4'd5, WAIT_D2, "digit 5: LOCKED -> WAIT_D2");
        enter_digit(4'd3, WAIT_D3, "digit 3: WAIT_D2 -> WAIT_D3");
        enter_digit(4'd7, UNLOCKED, "digit 7: WAIT_D3 -> UNLOCKED");
        
        if (unlocked_led === 1'b1)
            $display("PASS: unlocked_led = 1 in UNLOCKED");
        else
            $display("FAIL: unlocked_led expected=1, got=%b", unlocked_led);
            
        // ----------------------------------------------------
        // UNLOCKED state має залишатися UNLOCKED
        // ----------------------------------------------------
        enter_digit(4'd0, UNLOCKED, "UNLOCKED stays UNLOCKED");
        
        // ----------------------------------------------------
        // Неправильна цифра повинна повернути замок у LOCKED
        // ----------------------------------------------------
        #2; rst = 1'b1;
        
        #1;
        
        check_state(LOCKED, "reset before error test");
        
        rst = 1'b0;
        
        // Перша цифра правильна.
        enter_digit(4'd5, WAIT_D2, "digit 5 before error");
        
        // Друга цифра правильна.
        enter_digit(4'd9, LOCKED, "wrong second digit -> LOCKED");
        
        if (unlocked_led === 1'b0)
            $display("PASS: unlocked_led = 0 in LOCKED");
        else
            $display("FAIL: unlocked_led expected=0, got=%b", unlocked_led);
            
        $finish;
    end
endmodule
