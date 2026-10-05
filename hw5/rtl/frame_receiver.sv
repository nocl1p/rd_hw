// ============================================================================
// frame_receiver.sv
//
// Призначення:
//   Прийняти один кадр 8-бітних пікселів із зовнішнього джерела,
//   перенести дані з pixel_clk domain у m_axis_aclk domain через
//   asynchronous FIFO, зібрати по 4 пікселі в одне 32-бітне слово
//   і видати кадр через AXI4-Stream Master у AXI DMA S2MM.
//
// IMAGE_WIDTH  = 320
// IMAGE_HEIGHT = 200
// FRAME_PIXELS = 64000 байтів
// FRAME_WORDS  = 16000 слів по 32 біти
//
// Загальний шлях даних:
//
//   pixel_data[7:0]
//        |
//        | pixel_clk
//        v
//   +------------+
//   | async FIFO |
//   +------------+
//        |
//        | m_axis_aclk
//        v
//   8 -> 32 packer
//        |
//        v
//   AXI4-Stream Master
//        |
//        v
//   DMA S_AXIS_S2MM
//
// Прийом кадру:
//   1. Модуль знаходиться в IDLE та ігнорує вхідні пікселі.
//   2. MicroBlaze формує перехід start: 0 -> 1.
//   3. Модуль переходить у WAIT_FRAME.
//   4. Після frame_start починається CAPTURE.
//   5. Приймаються рівно FRAME_PIXELS пікселів.
//   6. Після останнього пікселя pixel-side повертається в IDLE.
//
// Pixel handshake:
//   Піксель реально прийнятий тільки коли:
//
//       pixel_valid && pixel_ready
//
//   Якщо pixel_valid = 1, але pixel_ready = 0,
//   джерело повинно утримувати pixel_data незмінним до прийому.
//
// AXI4-Stream handshake:
//   32-бітне слово реально передане тільки коли:
//
//       m_axis_tvalid && m_axis_tready
//
//   Поки m_axis_tready = 0, модуль утримує TDATA/TVALID/TLAST.
//
// FRAME_PIXELS у цій версії має бути кратним 4, оскільки кожне
// AXI4-Stream слово містить рівно 4 пікселі.
// ============================================================================

module frame_receiver #(
    parameter int IMAGE_WIDTH  = 320,
    parameter int IMAGE_HEIGHT = 200,
    parameter int FIFO_DEPTH   = 1024
) (
    // Pixel clock domain
    input  logic        pixel_clk,
    input  logic        pixel_rst_n,

    input  logic [7:0]  pixel_data,     // Поточний 8-бітний піксель
    input  logic        pixel_valid,    // pixel_data містить дійсний піксель
    output logic        pixel_ready,    // Модуль готовий прийняти піксель
    input  logic        frame_start,    // Початок нового кадру

    // Команда запуску від MicroBlaze / AXI GPIO
    input  logic        start,

    // AXI4-Stream clock domain
    input  logic        m_axis_aclk,
    input  logic        m_axis_aresetn,

    output logic [31:0] m_axis_tdata,   // 4 пікселі по 8 біт
    output logic [3:0]  m_axis_tkeep,   // Які байти TDATA є дійсними
    output logic        m_axis_tvalid,  // TDATA містить дійсне слово
    input  logic        m_axis_tready,  // DMA готовий прийняти слово
    output logic        m_axis_tlast    // Останнє 32-бітне слово кадру
);

    // =========================================================================
    // Параметри кадру
    // =========================================================================
    localparam int FRAME_PIXELS    = IMAGE_WIDTH * IMAGE_HEIGHT;
    localparam int FRAME_WORDS     = FRAME_PIXELS / 4;
    localparam int PIXEL_CNT_WIDTH = (FRAME_PIXELS > 1) ? $clog2(FRAME_PIXELS) : 1;
    localparam int WORD_CNT_WIDTH  = (FRAME_WORDS > 1) ? $clog2(FRAME_WORDS) : 1;

    // =========================================================================
    // START CDC
    //
    // start приходить з іншого clock domain.
    // Два регістри синхронізують його в pixel_clk domain.
    // start_sync2_d зберігає попереднє значення start_sync2,
    // щоб визначити позитивний фронт 0 -> 1.
    // =========================================================================
    (* ASYNC_REG = "TRUE" *) logic start_sync1;
    (* ASYNC_REG = "TRUE" *) logic start_sync2;

    logic start_sync2_d;
    logic start_pulse;

    // =========================================================================
    // FSM прийому кадру
    //
    // IDLE:
    //   кадр не приймається, чекаємо START.
    //
    // WAIT_FRAME:
    //   START отриманий, чекаємо frame_start.
    //
    // CAPTURE:
    //   приймаємо рівно FRAME_PIXELS пікселів.
    // =========================================================================
    typedef enum logic [1:0] {
        IDLE,
        WAIT_FRAME,
        CAPTURE
    } capture_state_t;

    capture_state_t capture_state;

    logic [PIXEL_CNT_WIDTH-1:0] pixel_count;
    logic                       pixel_accept;

    // =========================================================================
    // Asynchronous FIFO
    //
    // Write side працює від pixel_clk.
    // Read side працює від m_axis_aclk.
    //
    // FIFO зберігає по одному 8-бітному пікселю.
    // =========================================================================
    logic [7:0] fifo_wr_data;
    logic       fifo_wr_en;
    logic       fifo_full;

    logic [7:0] fifo_rd_data;
    logic       fifo_rd_en;
    logic       fifo_empty;

    // =========================================================================
    // 8 -> 32 packer
    //
    // Перші три байти тимчасово зберігаються у pack_reg:
    //
    //   byte 0 -> pack_reg[7:0]
    //   byte 1 -> pack_reg[15:8]
    //   byte 2 -> pack_reg[23:16]
    //
    // Після четвертого байта формується:
    //
    //   m_axis_tdata = {byte3, byte2, byte1, byte0}
    //
    // Наприклад:
    //   11 22 33 44 -> 32'h44332211
    // =========================================================================
    logic [23:0] pack_reg;
    logic [1:0]  byte_count;
    logic [WORD_CNT_WIDTH-1:0] word_count;

    // =========================================================================
    // FSM packer-а
    //
    // PACK_REQ:
    //   якщо FIFO не empty, формуємо fifo_rd_en.
    //
    // PACK_WAIT:
    //   synchronous FIFO вже видав fifo_rd_data;
    //   зберігаємо отриманий байт.
    //
    // PACK_SEND:
    //   32-бітне слово готове.
    //   Чекаємо m_axis_tvalid && m_axis_tready.
    // =========================================================================
    typedef enum logic [1:0] {
        PACK_REQ,
        PACK_WAIT,
        PACK_SEND
    } pack_state_t;

    pack_state_t pack_state;

    // =========================================================================
    // Синхронізація START у pixel_clk domain
    // =========================================================================
    always_ff @(posedge pixel_clk or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            start_sync1   <= 1'b0;
            start_sync2   <= 1'b0;
            start_sync2_d <= 1'b0;
        end
        else begin
            start_sync1   <= start;
            start_sync2   <= start_sync1;
            start_sync2_d <= start_sync2;
        end
    end

    // Один імпульс pixel_clk тільки в момент переходу START 0 -> 1.
    assign start_pulse = start_sync2 && !start_sync2_d;

    // =========================================================================
    // Pixel-side handshake
    //
    // pixel_ready = 1 тільки якщо:
    //   - FIFO має вільне місце;
    //   - ми вже приймаємо кадр;
    //
    // або frame_start щойно прийшов у WAIT_FRAME.
    //
    // Другий випадок дозволяє прийняти перший піксель у той самий
    // такт, у якому frame_start = 1.
    // =========================================================================
    always_comb begin
        pixel_ready = !fifo_full &&
                      ((capture_state == CAPTURE) ||
                      ((capture_state == WAIT_FRAME) && frame_start));
    end

    // Піксель вважається прийнятим тільки після handshake.
    assign pixel_accept = pixel_valid && pixel_ready;

    // Прийнятий піксель одразу записується у FIFO.
    assign fifo_wr_data = pixel_data;
    assign fifo_wr_en   = pixel_accept;

    // =========================================================================
    // Asynchronous FIFO instance
    //
    // Ліва сторона:
    //   pixel_clk, 8-бітні пікселі від зовнішнього джерела.
    //
    // Права сторона:
    //   m_axis_aclk, байти для 8 -> 32 packer-а.
    // =========================================================================
    async_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(FIFO_DEPTH)
    ) pixel_fifo (
        .wr_clk(pixel_clk),
        .wr_rst_n(pixel_rst_n),
        .wr_data(fifo_wr_data),
        .wr_en(fifo_wr_en),
        .full(fifo_full),

        .rd_clk(m_axis_aclk),
        .rd_rst_n(m_axis_aresetn),
        .rd_data(fifo_rd_data),
        .rd_en(fifo_rd_en),
        .empty(fifo_empty)
    );

    // =========================================================================
    // FSM прийому кадру
    // =========================================================================
    always_ff @(posedge pixel_clk or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            capture_state <= IDLE;
            pixel_count   <= '0;
        end
        else begin
            case (capture_state)
                // Нічого не приймаємо, чекаємо команду від MicroBlaze.
                IDLE: begin
                    pixel_count <= '0;

                    if (start_pulse)
                        capture_state <= WAIT_FRAME;
                end

                // START уже отриманий. Чекаємо початок нового кадру.
                WAIT_FRAME: begin
                    pixel_count <= '0;

                    if (frame_start) begin
                        capture_state <= CAPTURE;

                        // frame_start і перший pixel_valid можуть
                        // з'явитися в один і той самий такт.
                        if (pixel_accept)
                            pixel_count <= 1;
                    end
                end

                // Приймаємо пікселі тільки при pixel_valid && pixel_ready.
                CAPTURE: begin
                    if (pixel_accept) begin
                        if (pixel_count == FRAME_PIXELS - 1) begin
                            // Прийнятий останній піксель кадру.
                            pixel_count   <= '0;
                            capture_state <= IDLE;
                        end
                        else begin
                            pixel_count <= pixel_count + 1'b1;
                        end
                    end
                end

                default: begin
                    capture_state <= IDLE;
                    pixel_count   <= '0;
                end
            endcase
        end
    end

    // =========================================================================
    // FIFO read control
    //
    // Новий байт запитуємо тільки коли packer готовий його прийняти.
    // fifo_empty захищає від читання порожнього FIFO.
    // =========================================================================
    assign fifo_rd_en = (pack_state == PACK_REQ) && !fifo_empty;

    // =========================================================================
    // AXI4-Stream TKEEP
    //
    // Кадр має 64000 байтів, тобто рівно 16000 повних 32-бітних слів.
    // Тому всі 4 байти кожного TDATA завжди дійсні.
    // =========================================================================
    assign m_axis_tkeep = 4'b1111;

    // =========================================================================
    // 8 -> 32 packer + AXI4-Stream Master
    // =========================================================================
    always_ff @(posedge m_axis_aclk or negedge m_axis_aresetn) begin
        if (!m_axis_aresetn) begin
            pack_state    <= PACK_REQ;
            pack_reg      <= '0;
            byte_count    <= '0;
            word_count    <= '0;
            m_axis_tdata  <= '0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end
        else begin
            case (pack_state)
                // -------------------------------------------------------------
                // Запит наступного байта.
                //
                // fifo_rd_en = 1 у цьому стані, якщо FIFO не empty.
                // FIFO має synchronous read, тому дані забираємо
                // тільки у наступному стані PACK_WAIT.
                // -------------------------------------------------------------
                PACK_REQ: begin
                    if (!fifo_empty)
                        pack_state <= PACK_WAIT;
                end

                // -------------------------------------------------------------
                // fifo_rd_data містить байт, запитаний у PACK_REQ.
                // -------------------------------------------------------------
                PACK_WAIT: begin
                    case (byte_count)
                        2'd0: begin
                            // Перший байт майбутнього 32-бітного слова.
                            pack_reg[7:0] <= fifo_rd_data;
                            byte_count    <= 2'd1;
                            pack_state    <= PACK_REQ;
                        end

                        2'd1: begin
                            // Другий байт.
                            pack_reg[15:8] <= fifo_rd_data;
                            byte_count     <= 2'd2;
                            pack_state     <= PACK_REQ;
                        end

                        2'd2: begin
                            // Третій байт.
                            pack_reg[23:16] <= fifo_rd_data;
                            byte_count      <= 2'd3;
                            pack_state      <= PACK_REQ;
                        end

                        2'd3: begin
                            // Четвертий байт завершує 32-бітне слово.
                            m_axis_tdata  <= {fifo_rd_data, pack_reg[23:0]};
                            m_axis_tvalid <= 1'b1;

                            // FRAME_WORDS слів нумеруються 0..FRAME_WORDS-1.
                            // TLAST = 1 тільки для останнього слова кадру.
                            if (word_count == FRAME_WORDS - 1)
                                m_axis_tlast <= 1'b1;
                            else
                                m_axis_tlast <= 1'b0;

                            byte_count <= '0;
                            pack_state <= PACK_SEND;
                        end
                    endcase
                end

                // -------------------------------------------------------------
                // Готове слово утримується на AXI4-Stream до handshake.
                //
                // Якщо TREADY = 0:
                //   TDATA, TVALID і TLAST не змінюються.
                //
                // Якщо TVALID && TREADY:
                //   DMA прийняв слово, можна формувати наступне.
                // -------------------------------------------------------------
                PACK_SEND: begin
                    if (m_axis_tvalid && m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast  <= 1'b0;

                        if (word_count == FRAME_WORDS - 1)
                            word_count <= '0;
                        else
                            word_count <= word_count + 1'b1;

                        pack_state <= PACK_REQ;
                    end
                end

                default: begin
                    pack_state    <= PACK_REQ;
                    pack_reg      <= '0;
                    byte_count    <= '0;
                    word_count    <= '0;
                    m_axis_tdata  <= '0;
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast  <= 1'b0;
                end
            endcase
        end
    end
endmodule