`timescale 1ns / 1ps

module tb_microblaze_system;
    logic clk = 1'b0;

    logic reset_rtl_0 = 1'b0;

    logic [3:0] btn_tri_i = 4'b0000;
    logic [0:0] sw_tri_i  = 1'b0;

    wire [3:0] led_tri_o;

    always #5 clk = ~clk;

    microblaze_system_wrapper dut (
        .clk         (clk),
        .reset_rtl_0 (reset_rtl_0),
        .btn_tri_i   (btn_tri_i),
        .sw_tri_i    (sw_tri_i),
        .led_tri_o   (led_tri_o)
    );

    task automatic press_button(
        input logic [3:0] button_mask
    );
        begin
            btn_tri_i = button_mask;

            #20_000;

            btn_tri_i = 4'b0000;

            #20_000;
        end
    endtask

    task automatic wait_led_change(
        input logic [3:0] previous_led,
        input time timeout_ns
    );
        time start_time;

        begin
            start_time = $time;

            while ((led_tri_o === previous_led) && (($time - start_time) < timeout_ns)) begin
                @(posedge clk);
            end


            if (led_tri_o === previous_led) begin
                $display(
                    "FAIL: LED did not change before timeout at %0t",
                    $time
                );

                $fatal;
            end
        end
    endtask

    function automatic logic [3:0] rotate_backward(
        input logic [3:0] led
    );
        rotate_backward = ((led >> 1) | (led << 3)) & 4'hF;
    endfunction

    initial begin
        logic [3:0] old_led;
        logic [3:0] expected_led;

        $display("====================================");
        $display(" MicroBlaze running LED simulation");
        $display("====================================");

        reset_rtl_0 = 1'b0;

        #1_000;

        reset_rtl_0 = 1'b1;

        $display("Reset released at %0t", $time);

        /*
        * ------------------------------------------------
        * TEST 1
        * Wait for software initialization.
        *
        * main.c should write:
        *
        * LED0 = 1
        *
        * 0001
        * ------------------------------------------------
        */
        wait (led_tri_o === 4'b0001);

        $display(
            "PASS: Initial LED = %b at %0t",
            led_tri_o,
            $time
        );

        /*
        * ------------------------------------------------
        * TEST 2
        * Normal forward movement.
        *
        * Default speed is MEDIUM:
        *
        * 0001 -> 0010
        * ------------------------------------------------
        */
        old_led = led_tri_o;

        wait_led_change(
            old_led,
            300_000
        );

        if (led_tri_o !== 4'b0010) begin
            $display(
                "FAIL: Expected 0010, got %b",
                led_tri_o
            );

            $fatal;
        end

        $display(
            "PASS: Forward movement, LED = %b at %0t",
            led_tri_o,
            $time
        );

        /*
        * ------------------------------------------------
        * TEST 3
        * BTN0 -> faster.
        * ------------------------------------------------
        */
        press_button(4'b0001);

        old_led = led_tri_o;

        wait_led_change(
            old_led,
            150_000
        );

        $display(
            "PASS: Faster mode changed LED at %0t",
            $time
        );

        /*
        * ------------------------------------------------
        * TEST 4
        * BTN1 -> slower.
        * ------------------------------------------------
        */
        press_button(4'b0010);

        old_led = led_tri_o;

        wait_led_change(
            old_led,
            300_000
        );

        $display(
            "PASS: Slower mode changed LED at %0t",
            $time
        );

        /*
        * ------------------------------------------------
        * TEST 5
        * BTN2 -> STOP.
        * ------------------------------------------------
        */
        press_button(4'b0100);

        old_led = led_tri_o;

        /*
        * Wait longer than the current LED interval.
        */
        #500_000;

        if (led_tri_o !== old_led) begin
            $display(
                "FAIL: LED changed while paused"
            );
            
            $fatal;
        end

        $display(
            "PASS: Pause works, LED stayed %b",
            led_tri_o
        );

        /*
        * ------------------------------------------------
        * TEST 6
        * BTN3 -> RESUME.
        * ------------------------------------------------
        */
        press_button(4'b1000);

        old_led = led_tri_o;

        wait_led_change(
            old_led,
            300_000
        );

        $display(
            "PASS: Resume works, LED = %b",
            led_tri_o
        );

        /*
        * ------------------------------------------------
        * TEST 7
        * Change direction with SW0.
        *
        * SW0 = 1 -> backward.
        * ------------------------------------------------
        */
        sw_tri_i = 1'b1;

        // Give software time to read the switch.
        #20_000;

        old_led = led_tri_o;

        expected_led = rotate_backward(old_led);

        wait_led_change(
            old_led,
            300_000
        );


        if (led_tri_o !== expected_led) begin
            $display(
                "FAIL: Backward direction expected %b, got %b",
                expected_led,
                led_tri_o
            );

            $fatal;
        end

        $display(
            "PASS: Backward direction, LED = %b",
            led_tri_o
        );

        $display("");
        $display("====================================");
        $display(" ALL TESTS PASSED");
        $display("====================================");

        #50_000;

        $finish;
    end
endmodule