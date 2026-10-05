`timescale 1ns / 1ps

module tb_frame_receiver;
    // Для simulation використовуємо маленький кадр:
    // 8 x 2 = 16 pixels = 4 слова по 32 біти.
    localparam int IMAGE_WIDTH  = 8;
    localparam int IMAGE_HEIGHT = 2;
    localparam int FIFO_DEPTH   = 16;

    // Pixel clock = 25 MHz.
    logic pixel_clk = 1'b0;
    always #20 pixel_clk = ~pixel_clk;

    // AXI clock = 100 MHz.
    logic m_axis_aclk = 1'b0;
    always #5 m_axis_aclk = ~m_axis_aclk;

    // Reset.
    logic pixel_rst_n    = 1'b0;
    logic m_axis_aresetn = 1'b0;

    // Pixel interface.
    logic [7:0] pixel_data;
    logic       pixel_valid;
    logic       pixel_ready;
    logic       frame_start;

    // Start від MicroBlaze.
    logic start;

    // AXI4-Stream interface.
    logic [31:0] m_axis_tdata;
    logic [3:0]  m_axis_tkeep;
    logic        m_axis_tvalid;
    logic        m_axis_tready;
    logic        m_axis_tlast;

    // Номер прийнятого AXI слова.
    integer word_index = 0;

    // Очікуване значення поточного слова.
    logic [31:0] expected_data;
    logic        expected_last;

    // ============================================================
    // DUT
    // ============================================================
    frame_receiver #(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .pixel_clk(pixel_clk),
        .pixel_rst_n(pixel_rst_n),

        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .pixel_ready(pixel_ready),
        .frame_start(frame_start),

        .start(start),

        .m_axis_aclk(m_axis_aclk),
        .m_axis_aresetn(m_axis_aresetn),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // ============================================================
    // Передача одного пікселя
    //
    // first = 1 означає, що разом із цим пікселем
    // передається frame_start.
    // ============================================================
    task automatic send_pixel(
        input logic [7:0] value,
        input logic       first
    );
        begin
            @(negedge pixel_clk);

            pixel_data  = value;
            pixel_valid = 1'b1;
            frame_start = first;

            // Чекаємо, поки frame_receiver буде готовий.
            wait(pixel_ready);

            // На цьому posedge піксель буде прийнятий.
            @(posedge pixel_clk);

            @(negedge pixel_clk);
            pixel_valid = 1'b0;
            frame_start = 1'b0;
        end
    endtask

    // ============================================================
    // Перевірка AXI4-Stream
    //
    // Transfer відбувається коли:
    //
    // m_axis_tvalid = 1
    // m_axis_tready = 1
    // ============================================================
    always @(posedge m_axis_aclk) begin
        if (!m_axis_aresetn) begin
            word_index = 0;
        end
        else if (m_axis_tvalid && m_axis_tready) begin
            // Визначаємо, яке слово очікуємо.
            case (word_index)
                0: begin
                    expected_data = 32'h04030201;
                    expected_last = 1'b0;
                end

                1: begin
                    expected_data = 32'h08070605;
                    expected_last = 1'b0;
                end

                2: begin
                    expected_data = 32'h0C0B0A09;
                    expected_last = 1'b0;
                end

                3: begin
                    expected_data = 32'h100F0E0D;
                    expected_last = 1'b1;
                end

                default: begin
                    $display("FAIL: received too many AXI words");
                    $fatal;
                end
            endcase

            // Перевіряємо TDATA.
            if (m_axis_tdata !== expected_data) begin
                $display(
                    "FAIL: word %0d: expected %h, got %h",
                    word_index,
                    expected_data,
                    m_axis_tdata
                );
                $fatal;
            end

            // Усі 4 байти повинні бути valid.
            if (m_axis_tkeep !== 4'b1111) begin
                $display(
                    "FAIL: word %0d: incorrect TKEEP",
                    word_index
                );
                $fatal;
            end

            // TLAST повинен бути 1 тільки для останнього слова.
            if (m_axis_tlast !== expected_last) begin
                $display(
                    "FAIL: word %0d: incorrect TLAST",
                    word_index
                );
                $fatal;
            end

            $display(
                "PASS: word %0d = %h, TLAST = %b",
                word_index,
                m_axis_tdata,
                m_axis_tlast
            );

            word_index = word_index + 1;
        end
    end

    // ============================================================
    // Основний тест
    // ============================================================
    initial begin
        pixel_data   = 8'h00;
        pixel_valid  = 1'b0;
        frame_start  = 1'b0;
        start        = 1'b0;

        // DMA у цьому простому testbench завжди готовий.
        m_axis_tready = 1'b1;

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------
        #200;

        pixel_rst_n    = 1'b1;
        m_axis_aresetn = 1'b1;

        repeat (4)
            @(posedge pixel_clk);


        // --------------------------------------------------------
        // START
        //
        // Тримаємо його достатньо довго,
        // щоб він пройшов через CDC synchronizer.
        // --------------------------------------------------------
        start = 1'b1;

        repeat (5)
            @(posedge pixel_clk);

        start = 1'b0;

        repeat (3)
            @(posedge pixel_clk);


        // --------------------------------------------------------
        // Передаємо один кадр із 16 пікселів.
        //
        // Перший pixel передається разом із frame_start.
        // --------------------------------------------------------
        send_pixel(8'h01, 1'b1);

        send_pixel(8'h02, 1'b0);
        send_pixel(8'h03, 1'b0);
        send_pixel(8'h04, 1'b0);

        send_pixel(8'h05, 1'b0);
        send_pixel(8'h06, 1'b0);
        send_pixel(8'h07, 1'b0);
        send_pixel(8'h08, 1'b0);

        send_pixel(8'h09, 1'b0);
        send_pixel(8'h0A, 1'b0);
        send_pixel(8'h0B, 1'b0);
        send_pixel(8'h0C, 1'b0);

        send_pixel(8'h0D, 1'b0);
        send_pixel(8'h0E, 1'b0);
        send_pixel(8'h0F, 1'b0);
        send_pixel(8'h10, 1'b0);

        // --------------------------------------------------------
        // Чекаємо, поки буде передано 4 AXI слова.
        // --------------------------------------------------------
        wait(word_index == 4);

        #100;

        $display("");
        $display("FRAME RECEIVER TEST PASSED");

        $finish;
    end
endmodule