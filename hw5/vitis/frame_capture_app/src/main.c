#include "xparameters.h"
#include "xgpio.h"
#include "xaxidma.h"
#include "xstatus.h"

// ============================================================
// Налаштування кадру
//
// 320 x 200 pixels
// 1 pixel = 8 bit = 1 byte
//
// 320 * 200 = 64000 bytes
// ============================================================

#define FRAME_WIDTH         320U
#define FRAME_HEIGHT        200U
#define FRAME_SIZE_BYTES    (FRAME_WIDTH * FRAME_HEIGHT)

// RAM знаходиться в address space DMA Data_S2MM:
// Base = 0x00000000
// Range = 64 KiB
#define FRAME_BUFFER_ADDR   0x00000000U

// AXI GPIO:
// Channel 1 -> button input
// Channel 2 -> frame_receiver start output
#define GPIO_BUTTON_CHANNEL 1U
#define GPIO_START_CHANNEL  2U

#define BUTTON_MASK         0x1U
#define START_MASK          0x1U


XGpio Gpio;
XAxiDma AxiDma;


// ============================================================
// Ініціалізація AXI GPIO
// ============================================================

static int InitGpio(void)
{
    int Status;

    Status = XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_CTRL_BASEADDR);

    if (Status != XST_SUCCESS)
        return XST_FAILURE;

    // Channel 1 -> input.
    //
    // У XGpio:
    // 1 у direction mask = input
    // 0 у direction mask = output
    XGpio_SetDataDirection(&Gpio, GPIO_BUTTON_CHANNEL, BUTTON_MASK);

    // Channel 2 -> output.
    XGpio_SetDataDirection(&Gpio, GPIO_START_CHANNEL, 0x0U);

    // Початково frame_receiver не запущений.
    XGpio_DiscreteWrite(&Gpio, GPIO_START_CHANNEL, 0x0U);

    return XST_SUCCESS;
}


// ============================================================
// Ініціалізація AXI DMA
// ============================================================

static int InitDma(void)
{
    XAxiDma_Config *Config;
    int Status;

    // Знаходимо конфігурацію DMA за його base address.
    Config = XAxiDma_LookupConfig(XPAR_AXI_DMA_FRAME_BASEADDR);

    if (Config == NULL)
        return XST_FAILURE;

    Status = XAxiDma_CfgInitialize(&AxiDma, Config);

    if (Status != XST_SUCCESS)
        return XST_FAILURE;

    // У нашому Block Design Scatter-Gather вимкнено.
    // Нам потрібен Simple Mode.
    if (XAxiDma_HasSg(&AxiDma))
        return XST_FAILURE;

    return XST_SUCCESS;
}


// ============================================================
// MAIN
// ============================================================

int main(void)
{
    int Status;
    u32 Button;

    // --------------------------------------------------------
    // Ініціалізуємо GPIO.
    // --------------------------------------------------------

    Status = InitGpio();

    if (Status != XST_SUCCESS)
        return XST_FAILURE;


    // --------------------------------------------------------
    // Ініціалізуємо DMA.
    // --------------------------------------------------------

    Status = InitDma();

    if (Status != XST_SUCCESS)
        return XST_FAILURE;


    // ========================================================
    // Основний цикл
    // ========================================================

    while (1) {
        // ----------------------------------------------------
        // Чекаємо натискання кнопки.
        // ----------------------------------------------------

        do {
            Button = XGpio_DiscreteRead(&Gpio, GPIO_BUTTON_CHANNEL);
        }
        while ((Button & BUTTON_MASK) == 0U);


        // ----------------------------------------------------
        // СПОЧАТКУ запускаємо DMA.
        //
        // DMA отримує:
        //
        // destination = 0x00000000
        // length      = 64000 bytes
        // direction   = Stream -> Memory
        //
        // Після цього DMA готовий приймати AXI4-Stream.
        // ----------------------------------------------------

        Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)FRAME_BUFFER_ADDR, FRAME_SIZE_BYTES, XAXIDMA_DEVICE_TO_DMA);

        if (Status != XST_SUCCESS)
            return XST_FAILURE;


        // ----------------------------------------------------
        // Тепер запускаємо frame_receiver.
        //
        // GPIO Channel 2:
        //
        // 0 -> 1
        //
        // frame_receiver синхронізує цей сигнал у pixel_clk
        // domain і формує start_pulse.
        // ----------------------------------------------------

        XGpio_DiscreteWrite(&Gpio, GPIO_START_CHANNEL, START_MASK);


        // ----------------------------------------------------
        // Чекаємо завершення DMA S2MM.
        //
        // Поки DMA приймає кадр і записує його в RAM,
        // XAxiDma_Busy() повертає ненульове значення.
        // ----------------------------------------------------

        while (
            XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA)
        ) {
        }


        // ----------------------------------------------------
        // Кадр записаний.
        //
        // Повертаємо START у 0.
        // Для наступного кадру знову буде потрібен фронт 0 -> 1.
        // ----------------------------------------------------

        XGpio_DiscreteWrite(&Gpio, GPIO_START_CHANNEL, 0x0U);


        // ----------------------------------------------------
        // Чекаємо відпускання кнопки.
        //
        // Без цього одна довга натиснута кнопка могла б
        // одразу запустити наступний кадр.
        // ----------------------------------------------------

        do {
            Button = XGpio_DiscreteRead(&Gpio, GPIO_BUTTON_CHANNEL);
        }
        while ((Button & BUTTON_MASK) != 0U);
    }


    return 0;
}