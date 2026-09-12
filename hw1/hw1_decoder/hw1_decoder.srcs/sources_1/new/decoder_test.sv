module decoder_test (
    input  logic [2:0] code,
    output logic [3:0] out4,
    output logic [7:0] out8
);

    decoder #(
        .WIDTH(4)
    ) decoder_4 (
        .code(code[1:0]),
        .out(out4)
    );

    decoder #(
        .WIDTH(8)
    ) decoder_8 (
        .code(code),
        .out(out8)
    );

endmodule