#include <cstdio>
#include <climits>
#include "moving_max.h"

/*
 * Еталонна реалізація.
 *
 * Вона спеціально написана ІНАКШЕ, ніж moving_max().
 * Тут немає shift register window[].
 *
 * Для кожного n напряму перебираємо:
 *     in[n-7] ... in[n]
 * або всі доступні елементи, якщо n < 7.
 */
static void reference(
    const int in_data[N_SAMPLES],
    int out_data[N_SAMPLES]
) {
    for (int n = 0; n < N_SAMPLES; n++) {
        // Початок поточного вікна.
        int first = n - (WINDOW - 1);

        if (first < 0) {
            first = 0;
        }

        // Перший реально наявний елемент використовуємо
        // як початковий максимум.
        int max_value = in_data[first];

        for (int k = first + 1; k <= n; k++) {
            if (in_data[k] > max_value) {
                max_value = in_data[k];
            }
        }

        out_data[n] = max_value;
    }
}


/*
 * Запускає один тест:
 * 1. moving_max()
 * 2. reference()
 * 3. порівнює всі 64 результати.
 *
 * Повертає кількість знайдених помилок.
 */
static int run_test(const char* test_name, int input[N_SAMPLES]) {
    int dut_out[N_SAMPLES];
    int ref_out[N_SAMPLES];

    moving_max(input, dut_out);
    reference(input, ref_out);

    int errors = 0;

    for (int n = 0; n < N_SAMPLES; n++) {
        if (dut_out[n] != ref_out[n]) {
            printf(
                "%s: ERROR at n=%d: DUT=%d, REF=%d\n",
                test_name,
                n,
                dut_out[n],
                ref_out[n]
            );

            errors++;
        }
    }

    if (errors == 0) {
        printf("%s: PASS\n", test_name);
    }

    return errors;
}


int main() {
    int errors = 0;

    int test1[N_SAMPLES];
    int test2[N_SAMPLES];
    int test3[N_SAMPLES];
    int test4[N_SAMPLES];
    int test5[N_SAMPLES];

    /*
     * TEST 1
     * Зростаюча послідовність:
     * 0, 1, 2, 3, ...
     *
     * Тут максимум вікна майже завжди є поточним елементом.
     */
    for (int i = 0; i < N_SAMPLES; i++) {
        test1[i] = i;
    }

    /*
     * TEST 2
     * Спадна послідовність:
     * 63, 62, 61, ...
     *
     * Тут максимум певний час залишається старішим елементом.
     */
    for (int i = 0; i < N_SAMPLES; i++) {
        test2[i] = N_SAMPLES - 1 - i;
    }

    /*
     * TEST 3
     * Тільки від'ємні числа.
     *
     * Дуже важливий тест для перевірки правильної роботи INT_MIN.
     */
    for (int i = 0; i < N_SAMPLES; i++) {
        test3[i] = -((i * 7) % 41) - 1;
    }

    /*
     * TEST 4
     * Чергування додатних та від'ємних значень.
     */
    for (int i = 0; i < N_SAMPLES; i++) {
        if ((i % 2) == 0) {
            test4[i] = i * 3 + 10;
        } else {
            test4[i] = -(i * 5 + 20);
        }
    }

    /*
     * TEST 5
     * Змішаний детермінований набір.
     *
     * Спеціально додаємо INT_MIN у кількох місцях,
     * щоб перевірити граничне значення типу int.
     */
    for (int i = 0; i < N_SAMPLES; i++) {
        test5[i] = ((i * 37 + 11) % 101) - 50;
    }

    test5[0]  = INT_MIN;
    test5[7]  = INT_MIN;
    test5[31] = INT_MIN;

    errors += run_test("Test 1 - increasing", test1);
    errors += run_test("Test 2 - decreasing", test2);
    errors += run_test("Test 3 - negative",   test3);
    errors += run_test("Test 4 - alternating", test4);
    errors += run_test("Test 5 - mixed",       test5);

    if (errors == 0) {
        printf("\nALL TESTS PASSED\n");
        return 0;
    }

    printf("\nTEST FAILED: %d errors\n", errors);
    return 1;
}