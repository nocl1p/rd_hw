// expr_pipelined.v
// Pipelined version of ((a+b)*c)-d -- same registered-input principle
// as expr_plain.v, PLUS the extra pipeline stage splitting (a+b)*c
// from the final subtraction (see lecture, Pipelining section).
// All paths are still register-to-register -- same minimal .xdc as
// expr_plain.v (just create_clock, nothing else).

module expr_pipelined (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire [7:0]  c,
    input  wire [7:0]  d,
    output reg  [15:0] result
);

    // ---- Stage 0: registered inputs (same fix as expr_plain.v) ----
    reg [7:0] a_reg, b_reg, c_reg, d_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_reg <= 8'd0;
            b_reg <= 8'd0;
            c_reg <= 8'd0;
            d_reg <= 8'd0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            d_reg <= d;
        end
    end

    // ---- Stage 1: (a_reg+b_reg)*c_reg, plus pipeline d_reg alongside ----
    reg [15:0] stage1;
    reg [7:0]  d_stage;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1  <= 16'd0;
            d_stage <= 8'd0;
        end else begin
            stage1  <= (a_reg + b_reg) * c_reg;
            d_stage <= d_reg;
        end
    end

    // ---- Stage 2: stage1 - d_stage ----
    always @(posedge clk or posedge rst) begin
        if (rst)
            result <= 16'd0;
        else
            result <= stage1 - d_stage;
    end

endmodule
