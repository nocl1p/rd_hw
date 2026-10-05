`timescale 1ns / 1ps

module tb_hw5_system;
    // ============================================================
    // Розмір реального кадру
    // ============================================================
    localparam int FRAME_WIDTH  = 320;
    localparam int FRAME_HEIGHT = 200;
    localparam int FRAME_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;

    // ============================================================
    // Сигнали wrapper-а
    // ============================================================
    logic [0:0] button_tri_i;

    logic clk_100MHz;
    logic reset_rtl_0;

    logic       pixel_clk_0;
    logic       pixel_rst_n_0;
    logic [7:0] pixel_data_0;
    logic       pixel_valid_0;
    logic       frame_start_0;
    logic       pixel_ready_0;

    // ============================================================
    // Clock generation
    //
    // System clock = 100 MHz
    // period = 10 ns
    //
    // Pixel clock = 25 MHz
    // period = 40 ns
    // ============================================================
    initial clk_100MHz = 1'b0;
    always #5 clk_100MHz = ~clk_100MHz;

    initial pixel_clk_0 = 1'b0;
    always #20 pixel_clk_0 = ~pixel_clk_0;

    // ============================================================
    // DUT
    //
    // Це вже вся система:
    //
    // MicroBlaze
    // AXI GPIO
    // frame_receiver
    // AXI DMA
    // axi4_full_ram
    // ============================================================
    frame_dma_bd_wrapper dut (
        .button_tri_i  (button_tri_i),
        .clk_100MHz    (clk_100MHz),
        .frame_start_0 (frame_start_0),
        .pixel_clk_0   (pixel_clk_0),
        .pixel_data_0  (pixel_data_0),
        .pixel_ready_0 (pixel_ready_0),
        .pixel_rst_n_0 (pixel_rst_n_0),
        .pixel_valid_0 (pixel_valid_0),
        .reset_rtl_0   (reset_rtl_0)
    );

    // ============================================================
    // Передача одного пікселя
    //
    // Якщо first_pixel = 1, разом із пікселем
    // виставляється frame_start.
    //
    // Якщо frame_receiver ще не готовий,
    // pixel_data і pixel_valid просто утримуються,
    // поки pixel_ready не стане 1.
    // ============================================================
    task automatic send_pixel(
        input logic [7:0] value,
        input logic       first_pixel
    );
        begin
            @(negedge pixel_clk_0);

            pixel_data_0  = value;
            pixel_valid_0 = 1'b1;
            frame_start_0 = first_pixel;

            // Чекаємо, поки frame_receiver дозволить прийом.
            wait (pixel_ready_0 == 1'b1);

            // На цьому posedge відбувається pixel handshake.
            @(posedge pixel_clk_0);

            #1;

            pixel_valid_0 = 1'b0;
            frame_start_0 = 1'b0;
        end
    endtask

    // ============================================================
    // Основний тест
    // ============================================================
    integer i;

    initial begin
        // Початкові значення.
        button_tri_i  = 1'b0;

        pixel_rst_n_0 = 1'b0;
        pixel_data_0  = 8'h00;
        pixel_valid_0 = 1'b0;
        frame_start_0 = 1'b0;

        // reset_rtl_0 - active LOW.
        // 0 = reset активний
        // 1 = нормальна робота
        reset_rtl_0 = 1'b0;
        
        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------
        
        #500;
        
        // Відпускаємо reset системи та pixel-side.
        reset_rtl_0   = 1'b1;
        pixel_rst_n_0 = 1'b1;

        // Даємо MicroBlaze трохи часу вийти з reset.
        #2000;

        // --------------------------------------------------------
        // Натискаємо кнопку.
        //
        // MicroBlaze у своєму main() повинен:
        //
        // 1. побачити button = 1;
        // 2. запустити DMA S2MM;
        // 3. виставити GPIO2/start = 1.
        // --------------------------------------------------------
        button_tri_i = 1'b1;

        $display("Button pressed");

        // --------------------------------------------------------
        // Передаємо перший піксель.
        //
        // Тут task може чекати pixel_ready досить довго.
        //
        // pixel_ready стане 1 тільки коли:
        //
        // MicroBlaze -> GPIO2 -> start
        //                ↓
        // frame_receiver переходить у WAIT_FRAME
        //                ↓
        // бачить наш frame_start
        // --------------------------------------------------------
        send_pixel(8'h00, 1'b1);

        $display("Frame capture started");

        // Кнопку можна відпустити.
        button_tri_i = 1'b0;

        // --------------------------------------------------------
        // Передаємо решту кадру.
        //
        // Значення пікселя:
        //
        // 0, 1, 2 ... 255, 0, 1 ...
        //
        // Таким чином waveform легко перевіряти.
        // --------------------------------------------------------
        for (i = 1; i < FRAME_PIXELS; i = i + 1) begin
            send_pixel(i[7:0], 1'b0);
        end

        $display("All %0d pixels sent", FRAME_PIXELS);

        // --------------------------------------------------------
        // Після останнього пікселя frame_receiver повертається
        // в IDLE, тому pixel_ready повинен стати 0.
        // --------------------------------------------------------
        wait (pixel_ready_0 == 1'b0);

        // Даємо DMA час завершити останні AXI transfers
        // і записати останні дані в RAM.
        #10000;
        
        // --------------------------------------------------------
        // Перевіряємо дані, які DMA записав у RAM.
        //
        // 00 01 02 03 -> 32'h03020100
        // 04 05 06 07 -> 32'h07060504
        //
        // Останні 4 пікселі кадру:
        // FC FD FE FF -> 32'hFFFEFDFC
        // --------------------------------------------------------
        
        if (dut.frame_dma_bd_i.axi4_full_ram_0.inst.mem[0] !== 32'h03020100) begin
            $display("FAIL: RAM word 0 is incorrect");
            $fatal;
        end
        
        if (dut.frame_dma_bd_i.axi4_full_ram_0.inst.mem[1] !== 32'h07060504) begin
            $display("FAIL: RAM word 1 is incorrect");
            $fatal;
        end
        
        if (dut.frame_dma_bd_i.axi4_full_ram_0.inst.mem[2] !== 32'h0B0A0908) begin
            $display("FAIL: RAM word 2 is incorrect");
            $fatal;
        end 
    
        if (dut.frame_dma_bd_i.axi4_full_ram_0.inst.mem[15999] !== 32'hFFFEFDFC) begin
            $display("FAIL: last RAM word is incorrect");
            $fatal;
        end
    
        $display("PASS: RAM contains correct frame data");

        $display("");
        $display("========================================");
        $display("SYSTEM SIMULATION FINISHED");
        $display("Frame size: %0d pixels", FRAME_PIXELS);
        $display("Frame size: %0d bytes", FRAME_PIXELS);
        $display("========================================");

        $finish;
    end
endmodule