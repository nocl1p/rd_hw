`timescale 1ns / 1ps

module tb_moving_max;
    logic clk;
    logic rst;
    logic start;

    wire done;
    wire idle;
    wire ready;

    wire        in_ce;
    wire [5:0]  in_addr;
    logic [31:0] in_q;

    wire        out_ce;
    wire        out_we;
    wire [5:0]  out_addr;
    wire [31:0] out_d;

    logic signed [31:0] in_mem  [0:63];
    logic signed [31:0] out_mem [0:63];

    logic signed [31:0] ref_mem [0:63];

    moving_max_0 dut (
        .ap_clk            (clk),
        .ap_rst            (rst),

        .ap_start          (start),
        .ap_done           (done),
        .ap_idle           (idle),
        .ap_ready          (ready),

        .in_data_ce0       (in_ce),
        .in_data_address0  (in_addr),
        .in_data_q0        (in_q),

        .out_data_ce0      (out_ce),
        .out_data_we0      (out_we),
        .out_data_address0 (out_addr),
        .out_data_d0       (out_d)
    );

    initial begin
        clk = 1'b0;
    end
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Модель вхідної RAM
    //
    // HLS-блок виставляє адресу та CE.
    // На фронті clk пам'ять повертає значення за цією адресою.
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            in_q <= 32'd0;
        else if (in_ce)
            in_q <= in_mem[in_addr];
    end

    // ------------------------------------------------------------
    // Модель вихідної RAM
    //
    // Коли HLS виставляє CE=1 і WE=1,
    // записуємо результат у out_mem.
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (out_ce && out_we) begin
            out_mem[out_addr] <= out_d;
        end
    end

    initial begin : TEST
        integer errors;

        rst   = 1'b1;
        start = 1'b0;
        errors = 0;

        // --------------------------------------------------------
        // Формуємо змішаний вхідний вектор
        // --------------------------------------------------------
        for (int i = 0; i < 64; i++) begin
            // Значення приблизно від -50 до +50.
            // Послідовність детермінована, не випадкова.
            in_mem[i] =
                ((i * 37 + 11) % 101) - 50;

            out_mem[i] = 'x;
            ref_mem[i] = 0;
        end

        // --------------------------------------------------------
        // Рахуємо еталон:
        //
        // out[n] = max(in[n-7] ... in[n])
        //
        // Для n < 7 беремо тільки існуючі елементи.
        // --------------------------------------------------------
        for (int n = 0; n < 64; n++) begin
            integer first;
            logic signed [31:0] max_value;

            if (n < 7)
                first = 0;
            else
                first = n - 7;

            max_value = in_mem[first];

            for (int k = first + 1; k <= n; k++) begin
                if (in_mem[k] > max_value)
                    max_value = in_mem[k];
            end

            ref_mem[n] = max_value;
        end

        // --------------------------------------------------------
        // Reset
        // ap_rst у нашого IP ACTIVE HIGH
        // --------------------------------------------------------
        repeat (4) @(posedge clk);

        @(negedge clk);
        rst = 1'b0;

        // Даємо блоку трохи часу вийти зі reset
        repeat (2) @(posedge clk);

        // --------------------------------------------------------
        // Запускаємо HLS-блок
        //
        // ap_start тримаємо активним, поки блок не підтвердить
        // прийняття запуску через ap_ready.
        // --------------------------------------------------------
        @(negedge clk);
        start = 1'b1;

        wait (ready == 1'b1);

        @(negedge clk);
        start = 1'b0;

        // --------------------------------------------------------
        // Чекаємо завершення обробки 64 елементів
        // --------------------------------------------------------
        wait (done == 1'b1);

        // Даємо останньому запису в out_mem гарантовано завершитися
        @(posedge clk);
        #1;

        // --------------------------------------------------------
        // Перевіряємо всі 64 результати
        // --------------------------------------------------------
        for (int n = 0; n < 64; n++) begin
            if (out_mem[n] !== ref_mem[n]) begin
                $display(
                    "ERROR: n=%0d, DUT=%0d, REF=%0d",
                    n,
                    out_mem[n],
                    ref_mem[n]
                );

                errors = errors + 1;
            end
        end

        if (errors == 0) begin
            $display("");
            $display("PASS: moving_max produced all 64 correct values");
            $display("");
        end
        else begin
            $display("");
            $display("FAIL: %0d errors found", errors);
            $display("");
        end

        #100;
        $finish;
    end
endmodule