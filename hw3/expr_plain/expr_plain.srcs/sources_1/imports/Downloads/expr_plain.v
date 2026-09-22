// expr_plain.v
// Non-pipelined version of ((a+b)*c)-d.
//
// IMPORTANT DESIGN CHOICE: inputs ARE registered (a_reg/b_reg/c_reg/
// d_reg), matching the same pattern already used in alu.v/counter.v
// in this course. This means EVERY timing path in this module is
// register-to-register -- there is no port-to-register path left
// unconstrained. The .xdc for this module needs ONLY:
//
//     create_clock -period 4.000 -name sys_clk [get_ports clk]
//
// No set_input_delay/set_output_delay, no PACKAGE_PIN, no IOSTANDARD.
// This is the fix for the "Unconstrained Paths" / WNS=inf problem --
// registering the inputs removes the actual root cause instead of
// adding more constraint commands on top of an unregistered design.

module expr_plain (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire [7:0]  c,
    input  wire [7:0]  d,
    output reg  [15:0] result
);

    // ---- Stage 0: registered inputs (this is what fixes it) ----
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

    // ---- Stage 1: the long combinational path + registered output ----
    always @(posedge clk or posedge rst) begin
        if (rst)
            result <= 16'd0;
        else
            result <= ((a_reg + b_reg) * c_reg) - d_reg;
    end

endmodule
