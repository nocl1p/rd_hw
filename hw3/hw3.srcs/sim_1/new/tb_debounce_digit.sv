`timescale 1ns / 1ps

module tb_debounce_digit;
    logic clk;
    logic rst;
    logic [3:0] digit_raw;
    logic [3:0] digit_clean;
    
    debounce_digit #(
        .WIDTH(4),
        .COUNT_MAX(3)
    ) dut (
        .clk(clk),
        .rst(rst),
        .digit_raw(digit_raw),
        .digit_clean(digit_clean)
    );
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    initial begin
        rst = 1'b0;
        digit_raw = 4'd0;
        
        // Асинхронний reset
        #2;
        rst = 1'b1;
        
        #2;
        rst = 1'b0;
        
        // ----------------------------------------------------
        // Імітуємо bounce
        // ----------------------------------------------------
        digit_raw = 4'd5;
        @(posedge clk);
        
        digit_raw = 4'd0;
        @(posedge clk);
        
        digit_raw = 4'd5;
        @(posedge clk);
        
        digit_raw = 4'd0;
        @(posedge clk);
        
        // ----------------------------------------------------
        // Тепер сигнал стабільний
        // ----------------------------------------------------
        digit_raw = 4'd5;
        
        repeat (4)
            @(posedge clk);
        
        if (digit_clean === 4'd5)
            $display("PASS: debounce accepted stable digit 5");
        else
            $display("FAIL: expected digit_clean=5, got=%0d", digit_clean);
            
        $finish;
    end
endmodule
