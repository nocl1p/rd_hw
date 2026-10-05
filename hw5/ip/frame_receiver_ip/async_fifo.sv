// ============================================================================
// async_fifo.sv
//
// Асинхронний FIFO для передачі даних між двома незалежними тактовими доменами.
//
// Призначення:
//   - приймати дані у wr_clk-домені;
//   - зберігати їх у внутрішній пам'яті;
//   - видавати дані у rd_clk-домені;
//   - безпечно передавати інформацію про read/write pointers
//     між двома clock domain.
//
// Алгоритм роботи:
//
// 1. Write side
//    Якщо wr_en = 1 і FIFO не full:
//      - wr_data записується у поточну адресу пам'яті;
//      - binary write pointer збільшується;
//      - нове значення pointer перетворюється у Gray code.
//
// 2. Read side
//    Якщо rd_en = 1 і FIFO не empty:
//      - дані читаються з поточної адреси пам'яті;
//      - binary read pointer збільшується;
//      - нове значення pointer перетворюється у Gray code.
//
// 3. CDC
//    Binary pointers напряму між clock domain не передаються.
//    Для CDC використовуються Gray pointers, оскільки між сусідніми
//    значеннями Gray code змінюється лише один біт.
//
//    rgray:
//      rd_clk domain -> 2-stage synchronizer -> wr_clk domain
//
//    wgray:
//      wr_clk domain -> 2-stage synchronizer -> rd_clk domain
//
// 4. EMPTY
//    FIFO вважається порожнім, коли наступний read pointer
//    дорівнює синхронізованому write pointer.
//
// 5. FULL
//    FIFO вважається повним, коли наступний write pointer
//    знаходиться на один повний оберт FIFO попереду
//    синхронізованого read pointer.
// ============================================================================

module async_fifo #(
    // Ширина одного елемента FIFO в бітах,
    // бо один піксель це pixel_data[7:0],
    // FIFO приймає їх по одному
    parameter int DATA_WIDTH = 8,
    
    // Кількість елементів,
    // які FIFO може зберігати одночасно
    parameter int DEPTH = 1024
) (
    // ----------------------------------------------------
    // Вхідна сторона FIFO для прийому даних
    // ----------------------------------------------------
    input logic wr_clk, // Тактовий сигнал для запису
    input logic wr_rst_n,

    input logic [DATA_WIDTH-1:0] wr_data, // Дані, які ми хочемо записати
    input logic wr_en, // Сигнал дозволу запису

    output logic full, // Сигнал, що FIFO заповнений

    // ----------------------------------------------------
    // Вихідна сторона FIFO для читання даних
    // ----------------------------------------------------
    input  logic rd_clk, // Тактовий сигнал для читання
    input  logic rd_rst_n,

    output logic [DATA_WIDTH-1:0] rd_data, // Дані, які FIFO видає назовні
    input  logic rd_en, // Сигнал дозволу читання

    output logic empty // Сигнал, що FIFO порожній
);

    // Кількість біт, потрібна, щоб адресувати всі комірки FIFO
    localparam int ADDR_WIDTH = $clog2(DEPTH);
    
    // Ширина вказівника читання/запису
    localparam int PTR_WIDTH  = ADDR_WIDTH + 1;

    // Пам'ять FIFO
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];


    // Поточне значення write pointer у двійковому вигляді
    // показує, де буде наступний запис у FIFO
    // wbin = 0 -> наступний запис у mem[0]
    // wbin = 1 -> наступний запис у mem[1]
    // wbin = 2 -> наступний запис у mem[2]
    logic [PTR_WIDTH-1:0] wbin;
    
    // Яким стане write pointer на наступному такті
    logic [PTR_WIDTH-1:0] wbin_next;
    
    // Той самий write pointer, але у Gray code
    logic [PTR_WIDTH-1:0] wgray;
    
    // Майбутнє Gray-значення write pointer
    logic [PTR_WIDTH-1:0] wgray_next;

    // Поточний read pointer у binary вигляді.
    // Він показує, з якої комірки FIFO ми будемо читати наступний елемент
    logic [PTR_WIDTH-1:0] rbin;
    
    // Яким стане read pointer після наступної операції читання
    logic [PTR_WIDTH-1:0] rbin_next;

    // Той самий read pointer, але у Gray code
    logic [PTR_WIDTH-1:0] rgray;
    
    // Майбутнє значення read pointer у Gray code
    logic [PTR_WIDTH-1:0] rgray_next;

    // ====================================================
    // Синхронізація вказівників між двома тактовими доменами
    //
    // rgray_sync1 / rgray_sync2:
    //   передають read pointer (rgray) з rd_clk-домену
    //   у wr_clk-домен. Write-частина використовує
    //   синхронізований read pointer для визначення,
    //   чи FIFO заповнений.
    //
    // wgray_sync1 / wgray_sync2:
    //   передають write pointer (wgray) з wr_clk-домену
    //   у rd_clk-домен. Read-частина використовує
    //   синхронізований write pointer для визначення,
    //   чи FIFO порожній.
    //
    // full_next  - значення сигналу full для наступного стану.
    // empty_next - значення сигналу empty для наступного стану.
    // ====================================================
    (* ASYNC_REG = "TRUE" *) logic [PTR_WIDTH-1:0] rgray_sync1;
    (* ASYNC_REG = "TRUE" *) logic [PTR_WIDTH-1:0] rgray_sync2;

    (* ASYNC_REG = "TRUE" *) logic [PTR_WIDTH-1:0] wgray_sync1;
    (* ASYNC_REG = "TRUE" *) logic [PTR_WIDTH-1:0] wgray_sync2;

    logic full_next;
    logic empty_next;

    // ====================================================
    // Перевірка параметрів FIFO
    //
    // Цей блок виконується один раз на початку simulation.
    //
    // DEPTH повинен бути не меншим за 4.
    //
    // Також DEPTH повинен бути степенем двійки:
    // 4, 8, 16, 32, ..., 1024 тощо.
    // ====================================================
    initial begin
        if (DEPTH < 4) begin
            $fatal(1, "async_fifo: DEPTH must be >= 4");
        end

        if ((DEPTH & (DEPTH - 1)) != 0) begin
            $fatal(1, "async_fifo: DEPTH must be a power of two");
        end
    end

    // ====================================================
    // Обчислення наступних значень вказівників
    // та перетворення Binary -> Gray
    //
    // Write pointer збільшується тільки тоді,
    // коли запис реально дозволений:
    // wr_en = 1 і FIFO не заповнений.
    //
    // Read pointer збільшується тільки тоді,
    // коли читання реально дозволене:
    // rd_en = 1 і FIFO не порожній.
    //
    // Після обчислення наступного binary pointer
    // він переводиться у Gray code.
    // Gray-вказівники потрібні для безпечної передачі
    // між різними тактовими доменами.
    // ====================================================
    always_comb begin
        // Наступне значення write pointer.
        // Якщо запис прийнятий - збільшуємо на 1,
        // інакше залишаємо без змін
        wbin_next = wbin + ((wr_en && !full) ? 1'b1 : 1'b0);
        
        // Перетворення наступного write pointer
        // з binary у Gray code
        wgray_next = (wbin_next >> 1) ^ wbin_next;

        rbin_next = rbin + ((rd_en && !empty) ? 1'b1 : 1'b0);
        rgray_next = (rbin_next >> 1) ^ rbin_next;
    end

    // ====================================================
    // Порт запису FIFO
    //
    // Логіка працює у wr_clk-домені.
    //
    // Під час reset:
    //   - binary write pointer обнуляється;
    //   - Gray write pointer обнуляється.
    //
    // Під час нормальної роботи:
    //   - поточні покажчики оновлюються значеннями *_next;
    //   - якщо wr_en = 1 і FIFO не заповнений,
    //     wr_data записується у комірку пам'яті,
    //     на яку вказує поточний write pointer.
    //
    // Для адресації пам'яті використовуються тільки
    // молодші ADDR_WIDTH бітів wbin.
    // Старший біт потрібен для логіки full.
    // ====================================================
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wbin <= '0;
            wgray <= '0;
        end
        else begin
            // Оновлюємо write pointer
            wbin <= wbin_next;
            wgray <= wgray_next;

            // Записуємо дані тільки якщо FIFO не заповнений
            if (wr_en && !full) begin
                mem[wbin[ADDR_WIDTH-1:0]] <= wr_data;
            end
        end
    end

    // ====================================================
    // Порт читання FIFO
    //
    // Логіка працює у rd_clk-домені.
    //
    // Під час reset:
    //   - binary read pointer обнуляється;
    //   - Gray read pointer обнуляється;
    //   - вихідні дані rd_data обнуляються.
    //
    // Під час нормальної роботи:
    //   - read pointer оновлюється значенням rbin_next;
    //   - Gray pointer оновлюється значенням rgray_next;
    //   - якщо rd_en = 1 і FIFO не порожній,
    //     з пам'яті читається елемент, на який вказує
    //     поточний read pointer.
    //
    // Для адресації пам'яті використовуються тільки
    // молодші ADDR_WIDTH бітів rbin.
    // ====================================================
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rbin    <= '0;
            rgray   <= '0;
            rd_data <= '0;
        end
        else begin
            // Оновлюємо read pointer
            rbin  <= rbin_next;
            rgray <= rgray_next;

            // Читаємо тільки якщо FIFO не порожній
            if (rd_en && !empty) begin
                rd_data <= mem[rbin[ADDR_WIDTH-1:0]];
            end
        end
    end

    // ====================================================
    // Синхронізація read pointer у write clock domain
    //
    // rgray формується у rd_clk-домені, але write-частині
    // потрібно знати положення read pointer, щоб визначати
    // стан full.
    //
    // Оскільки rd_clk і wr_clk незалежні, rgray не можна
    // використовувати у write-домені напряму.
    //
    // Для безпечнішого CDC використовуються два послідовні
    // регістри:
    //   rgray_sync1 - перший етап синхронізації;
    //   rgray_sync2 - другий етап, який використовується
    //                 у подальшій логіці.
    // ====================================================
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rgray_sync1 <= '0;
            rgray_sync2 <= '0;
        end
        else begin
            rgray_sync1 <= rgray;
            rgray_sync2 <= rgray_sync1;
        end
    end

    // ====================================================
    // Синхронізація write pointer у read clock domain
    //
    // wgray формується у wr_clk-домені, але read-частині
    // потрібно знати положення write pointer, щоб визначати
    // стан empty.
    //
    // Оскільки wr_clk і rd_clk незалежні, wgray не можна
    // використовувати у read-домені напряму.
    //
    // Для синхронізації використовуються два послідовні
    // регістри:
    //   wgray_sync1 - перший етап синхронізації;
    //   wgray_sync2 - другий етап, який використовується
    //                 у подальшій логіці.
    // ====================================================
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wgray_sync1 <= '0;
            wgray_sync2 <= '0;
        end
        else begin
            wgray_sync1 <= wgray;
            wgray_sync2 <= wgray_sync1;
        end
    end

    // ====================================================
    // Визначення стану EMPTY
    //
    // FIFO вважається порожнім, якщо наступне значення
    // read pointer дорівнює синхронізованому write pointer.
    //
    // rgray_next показує, де буде read pointer після
    // поточної можливої операції читання.
    //
    // wgray_sync2 - синхронізоване у rd_clk-домені
    // значення write pointer.
    //
    // Якщо вони рівні, це означає, що всі записані
    // елементи вже прочитані і FIFO стає порожнім.
    // ====================================================
    always_comb begin
        empty_next = (rgray_next == wgray_sync2);
    end

    // ====================================================
    // Визначення стану FULL
    //
    // FIFO стає повним, коли наступний write pointer
    // знаходиться рівно на один повний оберт FIFO
    // попереду синхронізованого read pointer.
    //
    // У binary-представленні це означало б:
    //   - адресні біти write/read pointer однакові;
    //   - додатковий wrap bit відрізняється.
    //
    // Оскільки між clock domain передаються Gray-покажчики,
    // для перевірки FULL потрібно інвертувати два старші
    // біти синхронізованого read pointer, а решту бітів
    // залишити без змін.
    //
    // Якщо отримане значення дорівнює wgray_next,
    // поточний запис заповнить останню вільну комірку,
    // тому FIFO стане повним.
    // ====================================================
    always_comb begin
        full_next = (wgray_next == {
                ~rgray_sync2[PTR_WIDTH-1:PTR_WIDTH-2],
                 rgray_sync2[PTR_WIDTH-3:0]
            }
		);
    end

    // ====================================================
    // Сигнал empty належить до read clock domain,
    // тому оновлюється по фронту rd_clk.
    //
    // Під час reset FIFO вважається порожнім:
    // empty = 1.
    //
    // Під час нормальної роботи в empty записується
    // попередньо обчислене значення empty_next.
    // ====================================================
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            empty <= 1'b1;
        end
        else begin
            empty <= empty_next;
        end
    end

    // ====================================================
    // Сигнал full належить до write clock domain,
    // тому оновлюється по фронту wr_clk.
    //
    // Під час reset FIFO вважається не заповненим:
    // full = 0.
    //
    // Під час нормальної роботи в full записується
    // попередньо обчислене значення full_next.
    // ====================================================
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            full <= 1'b0;
        end
        else begin
            full <= full_next;
        end
    end
endmodule