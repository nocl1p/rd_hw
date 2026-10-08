module hw6_top (
    input logic clk
);
    // ----------------------------------------------------
    // Сигнали між VIO та ALU
    // ----------------------------------------------------
    logic [3:0] a;
    logic [3:0] b;
    logic [1:0] op;
    logic       oe;
    logic       rst;

    // Результат роботи ALU
    logic [3:0] result;

    // ----------------------------------------------------
    // ALU
    // ----------------------------------------------------
    alu u_alu (
        .clk    (clk),
        .rst    (rst),
        .a      (a),
        .b      (b),
        .op     (op),
        .oe     (oe),
        .result (result)
    );
    
    ila_0 u_ila (
        .clk    (clk),

        .probe0 (a),
        .probe1 (b),
        .probe2 (op),
        .probe3 (oe),
        .probe4 (result)
    );

    vio_0 u_vio (
        .clk        (clk),

        .probe_in0  (result),

        .probe_out0 (a),
        .probe_out1 (b),
        .probe_out2 (op),
        .probe_out3 (oe),
        .probe_out4 (rst)
    );
endmodule