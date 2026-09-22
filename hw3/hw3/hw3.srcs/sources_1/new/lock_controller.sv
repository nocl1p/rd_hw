module lock_controller(
    input logic clk,
    input logic rst,
    input logic [3:0] digit_in,
    output logic unlocked_led
);
    // Код замка: 5 -> 3 -> 7
    localparam logic [3:0] CODE_D1 = 4'd5;
    localparam logic [3:0] CODE_D2 = 4'd3;
    localparam logic [3:0] CODE_D3 = 4'd7;
    
    typedef enum logic [1:0] {
        LOCKED = 2'b00,
        WAIT_D2 = 2'b01,
        WAIT_D3 = 2'b10,
        UNLOCKED = 2'b11
    } state_t;
    
    state_t state;
    state_t next_state;
    
    // --------------------------------------------------------
    // Регістр стану
    // --------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= LOCKED;
        else
            state <= next_state;
    end
    
    // --------------------------------------------------------
    // Логіка переходів
    // --------------------------------------------------------
    always_comb begin
        next_state = state;
        
        case (state)
            LOCKED: begin
                if (digit_in == CODE_D1)
                    next_state = WAIT_D2;
                else
                    next_state = LOCKED;
            end
            
            WAIT_D2: begin
                if (digit_in == CODE_D2)
                    next_state = WAIT_D3;
                else
                    next_state = LOCKED;
            end
            
            WAIT_D3: begin
                if (digit_in == CODE_D3)
                    next_state = UNLOCKED;
                else
                    next_state = LOCKED;
            end
            
            UNLOCKED: begin
                next_state = UNLOCKED;
            end
            
            default: begin
                next_state = LOCKED;
            end
        endcase
    end
    
    // --------------------------------------------------------
    // Логіка виходу
    // --------------------------------------------------------
    always_comb begin
        unlocked_led = (state == UNLOCKED);
    end
endmodule
