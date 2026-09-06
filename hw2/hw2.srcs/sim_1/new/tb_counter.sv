`timescale 1ns / 1ps

module tb_counter;
    logic clk;
    logic rst;
    logic load;
    logic [3:0] data_in;
    logic en;
    logic up_down;
    
    logic [3:0] count;

    counter dut (
        .clk(clk),
        .rst(rst),
        .load(load),
        .data_in(data_in),
        .en(en),
        .up_down(up_down),
        .count(count)
    );
    
    initial clk = 1'b0;
    always #5 clk = ~clk;
    
    task automatic check_count(
        input logic [3:0] expected,
        input string name
    );
        if (count === expected)
            $display("PASS: %s, count=%0d", name, count);
        else
            $display("FAIL: %s, expected=%0d, got=%0d", name, expected, count);
    endtask
    
    initial begin
        // Початкові значення сигналів
        rst = 1'b0;
        load = 1'b0;
        data_in = 4'd0;
        en = 1'b0;
        up_down = 1'b1;
        
        // Так як ми не задаємо початкове значення count = ...,
        // то до ініціалізації значення rst значення count = X, 
        // так як в behavioral simulation початковий стан не ініціалізованого регістра невідомий
        #2;
        
        rst = 1'b1;
        
        @(posedge clk); #1;
        rst = 1'b0;
        
        // Задача 3: завантаження значення 10
        load = 1'b1;
        data_in = 4'd10;
        
        @(posedge clk); #1;
        
        load = 1'b0;
        
        check_count(4'd10, "load 10");
            
        // Задача 4: рахунок вгору
        // 10 -> 11 -> 12 -> 13
        
        en = 1'b1;
        up_down = 1'b1;
        
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        
        check_count(4'd13, "count up to 13");
            
        // Задача 4: перехід через межу 4-бітного лічильника
        // 13 -> 14 -> 15 -> 0
            
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        
        check_count(4'd0, "count up wrap-around");
            
        // Задача 5: утримання значення при en = 0
        
        en = 1'b0;
        up_down = 1'b1;
        
        @(posedge clk); #1;
        @(posedge clk); #1;
        
        check_count(4'd0, "hold value with en=0");
            
        // Задача 6: рахунок вниз із переходом через межу
        // 0 -> 15
        
        en = 1'b1;
        up_down = 1'b0;
        
        @(posedge clk); #1;
        
        check_count(4'd15, "count down wrap-around");
            
        // Задача 7: перевірка пріоритету load над en
        
        load = 1'b1;
        data_in = 4'd5;
        
        en = 1'b1;
        up_down = 1'b1;
        
        @(posedge clk); #1;
        
        check_count(4'd5, "load has priority over en");
            
        load = 1'b0;
        
        // Додаткове завдання: звичайний рахунок вниз без переходу через межу
        // 8 -> 7
        
        load = 1'b1;
        data_in = 4'd8;
        en = 1'b0;
        
        @(posedge clk); #1;
        
        load = 1'b0;
        
        check_count(4'd8, "bonus load 8");
        
        en = 1'b1;
        up_down = 1'b0;
        
        @(posedge clk); #1;
        
        check_count(4'd7, "bonus count down 8 to 7");

        $finish;
    end
endmodule
