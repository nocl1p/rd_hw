#include <climits>
#include "moving_max.h"

/* Ковзний максимум: out_data[n] = найбільше з останніх WINDOW відліків,
   разом із поточним відліком n. */
void moving_max(int in_data[N_SAMPLES], int out_data[N_SAMPLES]) {
    int window[WINDOW];      /* останні WINDOW відліків */

INIT_LOOP:
    for (int k = 0; k < WINDOW; k++) {
        // До приходу реальних даних вважаємо всі позиції
        // найменшим можливим значенням int.
        window[k] = INT_MIN;
    }

MAIN_LOOP:
    for (int n = 0; n < N_SAMPLES; n++) {
        
#pragma HLS PIPELINE II=1
SHIFT_LOOP:
        // Зсуваємо попередні відліки вправо.
        // Важливо йти від WINDOW-1 до 1.
        for (int k = WINDOW - 1; k > 0; k--) {
            window[k] = window[k - 1];
        }

        // Поточний елемент in_data[n] читається рівно один раз.
        window[0] = in_data[n];

        // Шукаємо максимум серед восьми позицій вікна.
        // Для перших семи відліків невикористані позиції містять INT_MIN,
        // тому вони не впливають на результат.
        int max_value = INT_MIN;

MAX_LOOP:
        for (int k = 0; k < WINDOW; k++) {
            if (window[k] > max_value) {
                max_value = window[k];
            }
        }

        out_data[n] = max_value;
    }
}