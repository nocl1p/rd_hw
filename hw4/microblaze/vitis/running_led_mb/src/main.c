#include "xparameters.h"
#include "xgpio.h"
#include "xtmrctr.h"
#include "xstatus.h"
#include "xil_types.h"

#define GPIO_CHANNEL  1U
#define TIMER_NUMBER  0U

#define BTN_FASTER    0x01U
#define BTN_SLOWER    0x02U
#define BTN_STOP      0x04U
#define BTN_RESUME    0x08U

#define LED_MASK      0x0FU
#define BTN_MASK      0x0FU
#define SW_MASK       0x01U

#define SPEED_FAST    0U
#define SPEED_MEDIUM  1U
#define SPEED_SLOW    2U

static const u32 speed_ticks[] = {
    10000U,
    20000U,
    40000U
};

static u32 rotate_led_forward(u32 led)
{
    return ((led << 1U) | (led >> 3U)) & LED_MASK;
}

static u32 rotate_led_backward(u32 led)
{
    return ((led >> 1U) | (led << 3U)) & LED_MASK;
}

int main(void)
{
    XGpio led_gpio;
    XGpio btn_gpio;
    XGpio sw_gpio;
    XTmrCtr timer;

    int status;

    u32 led_value = 0x01U;

    u32 buttons = 0U;
    u32 previous_buttons = 0U;
    u32 pressed_buttons;

    u32 direction;

    u32 speed_index = SPEED_MEDIUM;
    u32 interval_ticks = speed_ticks[SPEED_MEDIUM];

    u32 current_tick;
    u32 last_tick;

    int paused = 0;

    status = XGpio_Initialize(&led_gpio, XPAR_AXI_GPIO_LED_BASEADDR);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = XGpio_Initialize(&btn_gpio, XPAR_AXI_GPIO_BTN_BASEADDR);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = XGpio_Initialize(&sw_gpio, XPAR_AXI_GPIO_SW_BASEADDR);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XGpio_SetDataDirection(&led_gpio, GPIO_CHANNEL, 0x00U);
    XGpio_SetDataDirection(&btn_gpio, GPIO_CHANNEL, BTN_MASK);
    XGpio_SetDataDirection(&sw_gpio, GPIO_CHANNEL, SW_MASK);

    status = XTmrCtr_Initialize(&timer, XPAR_AXI_TIMER_0_BASEADDR);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XTmrCtr_SetOptions(&timer, TIMER_NUMBER, XTC_AUTO_RELOAD_OPTION);
    XTmrCtr_SetResetValue(&timer, TIMER_NUMBER, 0U);
    XTmrCtr_Reset(&timer, TIMER_NUMBER);
    XTmrCtr_Start(&timer, TIMER_NUMBER);

    XGpio_DiscreteWrite(&led_gpio, GPIO_CHANNEL, led_value);

    last_tick = XTmrCtr_GetValue(&timer, TIMER_NUMBER);

    while (1) {
        buttons = XGpio_DiscreteRead(&btn_gpio, GPIO_CHANNEL) & BTN_MASK;

        direction = XGpio_DiscreteRead(&sw_gpio, GPIO_CHANNEL) & SW_MASK;

        pressed_buttons = buttons & (~previous_buttons);
        previous_buttons = buttons;

        if ((pressed_buttons & BTN_FASTER) != 0U) {
            if (speed_index > SPEED_FAST) {
                speed_index--;
                interval_ticks = speed_ticks[speed_index];

                last_tick = XTmrCtr_GetValue(&timer, TIMER_NUMBER);
            }
        }

        if ((pressed_buttons & BTN_SLOWER) != 0U) {

            if (speed_index < SPEED_SLOW) {
                speed_index++;
                interval_ticks = speed_ticks[speed_index];

                last_tick = XTmrCtr_GetValue(&timer, TIMER_NUMBER);
            }
        }

        if ((pressed_buttons & BTN_STOP) != 0U) {
            paused = 1;
        }

        if ((pressed_buttons & BTN_RESUME) != 0U) {

            paused = 0;

            last_tick = XTmrCtr_GetValue(&timer, TIMER_NUMBER);
        }

        current_tick = XTmrCtr_GetValue(&timer, TIMER_NUMBER);

        if ((!paused) &&
            ((u32)(current_tick - last_tick) >= interval_ticks)) {

            last_tick = current_tick;

            if (direction == 0U) {
                led_value = rotate_led_forward(led_value);
            }
            else {
                led_value = rotate_led_backward(led_value);
            }

            XGpio_DiscreteWrite(&led_gpio, GPIO_CHANNEL, led_value);
        }
    }

    return XST_SUCCESS;
}