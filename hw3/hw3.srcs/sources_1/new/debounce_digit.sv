module debounce_digit #(
    parameter int WIDTH = 4,
    parameter int COUNT_MAX = 200_000
) (
    input logic clk,
    input logic rst,
    input logic [WIDTH-1:0] digit_raw,
    output logic [WIDTH-1:0] digit_clean
);
    // Кількість бітів, необхідна для лічильника
    localparam int COUNTER_WIDTH = $clog2(COUNT_MAX + 1);
    
    // Окремий лічильник для кожного біта вхідного числа
    logic [COUNTER_WIDTH-1:0] counter [0:WIDTH-1];
    
    integer i;
    
    // --------------------------------------------------------
    // Нове значення приймається лише після того,
    // як воно стабільно утримувалося COUNT_MAX тактів
    // --------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            digit_clean <= '0;
            
            for (i = 0; i < WIDTH; i = i + 1)
                counter[i] <= '0;
        end
        else begin
            for (i = 0; i < WIDTH; i = i + 1) begin
                // Вхід відрізняється від уже підтвердженого
                if (digit_raw[i] != digit_clean[i]) begin
                    if (counter[i] == COUNT_MAX - 1) begin
                        // Нове значення було стабільним достатньо довго - приймаємо його
                        digit_clean[i] <= digit_raw[i];
                        counter[i] <= '0;
                    end
                    else begin
                        counter[i] <= counter[i] + 1'b1;
                    end
                end
                else begin
                // Якщо raw знову збігається з clean, попередня зміна не підтвердилася
                    counter[i] <= '0;
                end
            end
        end
    end
endmodule
