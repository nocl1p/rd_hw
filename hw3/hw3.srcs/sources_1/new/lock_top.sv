module lock_top(
    input logic clk,
    input logic rst,
    input logic [3:0] digit_raw,
    output logic unlocked_led
);
    logic [3:0] digit_clean;
    
    debounce_digit#(
        .WIDTH(4),
        .COUNT_MAX(200_000)
    ) debounce_inst (
        .clk(clk),
        .rst(rst),
        .digit_raw(digit_raw),
        .digit_clean(digit_clean)
    );
    
    lock_controller lock_inst (
        .clk(clk),
        .rst(rst),
        .digit_in(digit_clean),
        .unlocked_led(unlocked_led)
    );
endmodule
