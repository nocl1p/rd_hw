module decoder #(
    parameter int WIDTH = 4
) (
    // The width is automatically calculated from WIDTH.
    input logic [$clog2(WIDTH)-1:0] code,

    output logic [WIDTH-1:0] out
);

    always_comb begin
        // Default state: all outputs are inactive.
        out = '0;

        // Activate the output bit only when the input code is within the valid range.
        if (code < WIDTH)
            out[code] = 1'b1;
    end

endmodule