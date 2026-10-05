`timescale 1ns / 1ps

module tb_async_fifo;
    localparam int DATA_WIDTH = 8;
    localparam int DEPTH      = 16;

    logic wr_clk = 1'b0;
    logic rd_clk = 1'b0;

    logic wr_rst_n = 1'b0;
    logic rd_rst_n = 1'b0;

    logic [DATA_WIDTH-1:0] wr_data;
    logic                  wr_en;
    logic                  full;

    logic [DATA_WIDTH-1:0] rd_data;
    logic                  rd_en;
    logic                  empty;

    always #20 wr_clk = ~wr_clk;
    always #5 rd_clk = ~rd_clk;

    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) dut (
        .wr_clk   (wr_clk),
        .wr_rst_n (wr_rst_n),

        .wr_data  (wr_data),
        .wr_en    (wr_en),
        .full     (full),

        .rd_clk   (rd_clk),
        .rd_rst_n (rd_rst_n),

        .rd_data  (rd_data),
        .rd_en    (rd_en),
        .empty    (empty)
    );

    // ====================================================
    // Task: запис одного елемента у FIFO
    //
    // Чекаємо, доки FIFO не буде full.
    // Потім подаємо дані та wr_en на один такт wr_clk.
    // ====================================================
    task automatic fifo_write(
        input logic [DATA_WIDTH-1:0] value
    );
        begin
            // Чекаємо вільного місця у FIFO.
            wait (!full);

            // Змінюємо сигнали на negedge,
            // щоб вони гарантовано були стабільними
            // до наступного posedge wr_clk.
            @(negedge wr_clk);

            wr_data = value;
            wr_en   = 1'b1;

            // На наступному posedge DUT виконає запис.
            // На наступному negedge прибираємо wr_en.
            @(negedge wr_clk);

            wr_en = 1'b0;
        end
    endtask

    // ====================================================
    // Task: читання одного елемента та перевірка
    //
    // Чекаємо, поки FIFO не перестане бути empty.
    // Подаємо rd_en і перевіряємо отримані дані.
    // ====================================================
    task automatic fifo_read_and_check(
        input logic [DATA_WIDTH-1:0] expected
    );
        begin
            // Чекаємо, поки у FIFO з'являться дані.
            wait (!empty);

            // Подаємо rd_en на negedge,
            // щоб він був стабільним до posedge rd_clk.
            @(negedge rd_clk);

            rd_en = 1'b1;

            // FIFO має synchronous read.
            // На цьому posedge:
            // rd_data <= mem[rbin[...]]
            @(posedge rd_clk);

            // Невелика затримка потрібна,
            // щоб non-blocking assignments DUT
            // уже оновили rd_data.
            #1;

            if (rd_data !== expected) begin
                $display(
                    "FAIL: expected %02h, got %02h at %0t",
                    expected,
                    rd_data,
                    $time
                );

                $fatal;
            end

            $display(
                "PASS: read %02h at %0t",
                rd_data,
                $time
            );

            // Завершуємо імпульс rd_en.
            @(negedge rd_clk);

            rd_en = 1'b0;
        end
    endtask

    initial begin
        // Початкові значення
        wr_data = '0;
        wr_en   = 1'b0;
        rd_en   = 1'b0;

        wr_rst_n = 1'b0;
        rd_rst_n = 1'b0;

        // RESET
        $display("");
        $display("Starting reset...");

        #200;

        wr_rst_n = 1'b1;
        rd_rst_n = 1'b1;

        $display("Reset released");

        // Даємо обом clock domain кілька тактів
        // після reset.
        repeat (4) @(posedge rd_clk);

        // =================================================
        // TEST 1
        //
        // Звичайний запис і читання.
        // Перевіряємо порядок даних.
        // =================================================
        $display("");
        $display("=============================");
        $display(" TEST 1: WRITE / READ");
        $display("=============================");

        // Записуємо 8 значень.
        fifo_write(8'h11);
        fifo_write(8'h22);
        fifo_write(8'h33);
        fifo_write(8'h44);

        fifo_write(8'h55);
        fifo_write(8'h66);
        fifo_write(8'h77);
        fifo_write(8'h88);

        // Через CDC write pointer не з'являється
        // у read domain миттєво.
        // fifo_read_and_check сам чекатиме !empty.
        // Читаємо та перевіряємо ті самі значення.
        fifo_read_and_check(8'h11);
        fifo_read_and_check(8'h22);
        fifo_read_and_check(8'h33);
        fifo_read_and_check(8'h44);

        fifo_read_and_check(8'h55);
        fifo_read_and_check(8'h66);
        fifo_read_and_check(8'h77);
        fifo_read_and_check(8'h88);

        // Після останнього читання даємо read-side
        // кілька тактів для оновлення EMPTY.
        repeat (4) @(posedge rd_clk);

        #1;

        if (!empty) begin
            $display(
                "FAIL: FIFO should be EMPTY after TEST 1"
            );

            $fatal;
        end

        $display(
            "PASS: FIFO became EMPTY after TEST 1"
        );

        // =================================================
        // TEST 2
        //
        // Перевірка FULL.
        //
        // FIFO має DEPTH = 16.
        // Записуємо рівно 16 значень.
        // =================================================
        $display("");
        $display("=============================");
        $display(" TEST 2: FULL FLAG");
        $display("=============================");

        // Записуємо:
        // A0 A1 A2 ... AE AF
        // Це рівно 16 елементів.
        for (int i = 0; i < DEPTH; i++) begin
            fifo_write(8'hA0 + i);
        end

        // Даємо write-side один такт,
        // щоб зареєструвався full.
        @(posedge wr_clk);

        #1;

        // FIFO повинен бути повністю заповнений.
        if (!full) begin
            $display(
                "FAIL: FIFO should be FULL"
            );

            $fatal;
        end

        $display(
            "PASS: FIFO became FULL"
        );

        // =================================================
        // Читаємо один елемент
        // Це повинно звільнити одну комірку.
        // =================================================
        fifo_read_and_check(8'hA0);

        // Read pointer змінився у rd_clk domain.
        // Щоб write side побачив цю зміну,
        // pointer повинен пройти:
        //
        // rgray
        //   ->
        // rgray_sync1
        //   ->
        // rgray_sync2
        //   ->
        // full_next
        //   ->
        // full
        //
        // Тому full не зникає миттєво.
        repeat (4) @(posedge wr_clk);

        #1;


        if (full) begin
            $display(
                "FAIL: FIFO should no longer be FULL"
            );

            $fatal;
        end

        $display(
            "PASS: FULL cleared after one read"
        );

        // =================================================
        // Читаємо решту FIFO
        // Залишились:
        // A1 ... AF
        // =================================================

        for (int i = 1; i < DEPTH; i++) begin
            fifo_read_and_check(8'hA0 + i);
        end

        // Даємо read domain кілька тактів,
        // щоб EMPTY гарантовано оновився.
        repeat (4) @(posedge rd_clk);

        #1;

        if (!empty) begin
            $display(
                "FAIL: FIFO should be EMPTY after TEST 2"
            );

            $fatal;
        end

        $display(
            "PASS: FIFO became EMPTY after reading all data"
        );

        $display("");
        $display("=================================");
        $display("   ASYNC FIFO TEST PASSED");
        $display("=================================");
        $display("");

        #100;

        $finish;
    end
endmodule