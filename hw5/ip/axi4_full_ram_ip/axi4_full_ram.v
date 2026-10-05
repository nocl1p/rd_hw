// axi4_full_ram.v
// Простий AXI4 (Full) slave. Порти названі за офіційною конвенцією
// Vivado (interface_name + "_" + AXI signal name, тут "s_axi_..."),
// щоб Package IP міг АВТОМАТИЧНО розпізнати AXI4-інтерфейс без
// ручного втручання (підтверджено офіційною документацією UG1118).

module axi4_full_ram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter MEM_DEPTH  = 256
) (
    input  wire                        s_axi_aclk,
    input  wire                        s_axi_aresetn,

    input  wire [ADDR_WIDTH-1:0]       s_axi_awaddr,
    input  wire [7:0]                  s_axi_awlen,
    input  wire [2:0]                  s_axi_awsize,
    input  wire [1:0]                  s_axi_awburst,
    input  wire                        s_axi_awvalid,
    output wire                        s_axi_awready,

    input  wire [DATA_WIDTH-1:0]       s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0]     s_axi_wstrb,
    input  wire                        s_axi_wlast,
    input  wire                        s_axi_wvalid,
    output wire                        s_axi_wready,

    output reg  [1:0]                  s_axi_bresp,
    output reg                         s_axi_bvalid,
    input  wire                        s_axi_bready,

    input  wire [ADDR_WIDTH-1:0]       s_axi_araddr,
    input  wire [7:0]                  s_axi_arlen,
    input  wire [2:0]                  s_axi_arsize,
    input  wire [1:0]                  s_axi_arburst,
    input  wire                        s_axi_arvalid,
    output wire                        s_axi_arready,

    output reg  [DATA_WIDTH-1:0]       s_axi_rdata,
    output reg                         s_axi_rlast,
    output reg  [1:0]                  s_axi_rresp,
    output reg                         s_axi_rvalid,
    input  wire                        s_axi_rready
);

    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    localparam WRIDLE = 2'd0, WRDATA = 2'd1, WRRESP = 2'd2;
    reg [1:0] wstate;
    reg [ADDR_WIDTH-1:0] waddr_cur;
    reg [7:0] wburst_cnt;

    assign s_axi_awready = (wstate == WRIDLE);
    assign s_axi_wready  = (wstate == WRDATA);

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            wstate <= WRIDLE;
            s_axi_bvalid <= 1'b0;
        end else case (wstate)
            WRIDLE: begin
                if (s_axi_awvalid) begin
                    waddr_cur  <= s_axi_awaddr;
                    wburst_cnt <= s_axi_awlen;
                    wstate     <= WRDATA;
                end
            end
            WRDATA: begin
                if (s_axi_wvalid && s_axi_wready) begin
                    mem[waddr_cur[ADDR_WIDTH-1:2]] <= s_axi_wdata;
                    waddr_cur <= waddr_cur + 4;
                    if (wburst_cnt == 0) begin
                        wstate <= WRRESP;
                    end else begin
                        wburst_cnt <= wburst_cnt - 1'b1;
                    end
                end
            end
            WRRESP: begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
                if (s_axi_bvalid && s_axi_bready) begin
                    s_axi_bvalid <= 1'b0;
                    wstate <= WRIDLE;
                end
            end
        endcase
    end

    localparam RDIDLE = 2'd0, RDDATA = 2'd1;
    reg [1:0] rstate;
    reg [ADDR_WIDTH-1:0] raddr_cur;
    reg [7:0] rburst_cnt;

    assign s_axi_arready = (rstate == RDIDLE);

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            rstate <= RDIDLE;
            s_axi_rvalid <= 1'b0;
        end else case (rstate)
            RDIDLE: begin
                s_axi_rvalid <= 1'b0;
                if (s_axi_arvalid) begin
                    raddr_cur  <= s_axi_araddr;
                    rburst_cnt <= s_axi_arlen;
                    rstate     <= RDDATA;
                end
            end
            RDDATA: begin
                if (!s_axi_rvalid || (s_axi_rvalid && s_axi_rready)) begin
                    s_axi_rdata  <= mem[raddr_cur[ADDR_WIDTH-1:2]];
                    s_axi_rresp  <= 2'b00;
                    s_axi_rvalid <= 1'b1;
                    s_axi_rlast  <= (rburst_cnt == 0);
                    if (rburst_cnt != 0) begin
                        raddr_cur  <= raddr_cur + 4;
                        rburst_cnt <= rburst_cnt - 1'b1;
                    end else if (s_axi_rvalid && s_axi_rready) begin
                        rstate <= RDIDLE;
                    end
                end
            end
        endcase
    end

endmodule
