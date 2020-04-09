// Screen buffer divided in 80x30 tiles, each containing the 7 bit address of a character
module buffer 
#(
    parameter H_TILES = 1280/8,             // 1280x960 resolution and chars of 8x16 pixels
    parameter V_TILES = 1024/16,
    parameter NUM_TILES = H_TILES*V_TILES, // 160x64 = 2400
    parameter ADDR_COL_WIDTH = 8,          // log2(160)
    parameter ADDR_ROW_WIDTH = 6,          // log2(64)
    parameter DATA_WIDTH = 7               // log2(128 possible characters)
)
(
    input wire                  clk_i,       // 108 MHz clock
    input wire                  wr_en_i,     // write enable for the data input
    input wire [ADDR_COL_WIDTH-1:0] col_w_i, // column of tile to write
    input wire [ADDR_ROW_WIDTH-1:0] row_w_i, // row of tile to write
    input wire [ADDR_COL_WIDTH-1:0] col_r_i, // column of tile to read
    input wire [ADDR_ROW_WIDTH-1:0] row_r_i, // row of tile to read
    input wire [DATA_WIDTH-1:0] din_i,       // data input, the ASCII code of the character
    output reg [DATA_WIDTH-1:0] dout_o       // data output
);

    reg [DATA_WIDTH-1:0] bmem [0:NUM_TILES-1]; // memory of the current frame

    // memory initialization
    integer i,j;
    initial begin
        for (i=0; i<V_TILES;i=i+1) begin
            for (j=0; j<H_TILES;j=j+1) begin
                bmem[i*H_TILES+j]=7'd00;
            end
        end
    end

    // read and write operation
    always @(posedge clk_i)
    begin
        dout_o <= bmem[(col_r_i << ADDR_ROW_WIDTH) + row_r_i]; 
        if (wr_en_i) begin
            bmem[(col_r_i << ADDR_ROW_WIDTH) + row_r_i] <= din_i;
        end
    end

endmodule
