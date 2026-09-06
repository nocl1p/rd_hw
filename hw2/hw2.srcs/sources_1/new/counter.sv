module counter(
    input logic clk,
    input logic rst,
    input logic load,
    input logic [3:0] data_in,
    input logic en,
    input logic up_down,
    output logic [3:0] count
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 4'd0;
        end
           
        else if (load) begin
            count <= data_in;
        end
            
        else if (en) begin
            if (up_down)
                count <= count + 4'd1;
            else
                count <= count - 4'd1;
        end
    end

endmodule
