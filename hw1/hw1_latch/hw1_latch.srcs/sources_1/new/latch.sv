module latch (
    input logic d0,
    input logic d1,
    input logic sel,
    output logic y
);

    always_comb begin
        case (sel)
            1'b0: y = d0;
            default: y = d1;
        endcase
    end

endmodule