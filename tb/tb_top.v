`timescale 1us/1ns

module tb_top;

    localparam	C_AXI_ADDR_WIDTH = $clog2(2400);
	localparam	C_AXI_DATA_WIDTH = 32;
	localparam	ADDRLSB = $clog2(C_AXI_DATA_WIDTH)-3;

    reg                          clk;	       
    //reg RSTN_BUTTON, // rstn,
    wire [15:0]                  pmod;        
    reg [C_AXI_DATA_WIDTH-1:0]   axil_wdata; 
    reg [C_AXI_DATA_WIDTH/8-1:0] axil_wstrb; 
    reg [C_AXI_ADDR_WIDTH-1:0]   axil_waddr; 
    reg                          axil_wready;
    reg                          axil_rreq;   
    reg [C_AXI_ADDR_WIDTH-1:0]   axil_raddr;
    wire [C_AXI_DATA_WIDTH-1:0]  axil_rdata;
   
    reg error;

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        #40000 if (error == 1'b0) $display("PASS");
        $finish;
    end

    // this test sends a character 'A' to write and then checks that the corresponding pixels are white
    initial begin
        clk = 1'b0;
        error = 1'b0;
        axil_wdata = 32'd65;
        axil_wstrb = 4'b0001;
        axil_waddr = 12'd0;
        axil_wready = 1'b1;
        axil_rreq = 1'b0;
        axil_raddr = 12'd0;
        error = 1'b0;
        #0.025 axil_wready = 1'b0;
        #0.04 axil_wdata = 32'd67;
        axil_waddr = 12'd2399;
        axil_wready = 1'b1;
        #0.04 axil_wready = 1'b0;
        // wait for the start of the next frame and then the first white pixel
        #17546.75 wait(pmod[7:0] == 8'hFF);
        // next pixel of the character 'A' is at next line -1 pixel, so (800 horizontal cycles -1)*0.04 clk = 31.96, add 0.01 to have time to change output
        #31.97 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 1");
            error = 1'b1;
        end
        // next pixel is 2 away
        #0.08 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 2");
            error = 1'b1;
        end
        #31.92 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 3");
            error = 1'b1;
        end
        #0.08 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 4");
            error = 1'b1;
        end
        #31.92 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 5");
            error = 1'b1;
        end
        #0.08 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 6");
            error = 1'b1;
        end
        #31.88 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 7");
            error = 1'b1;
        end
        #0.16 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 8");
            error = 1'b1;
        end
        #31.84 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 9");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 10");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 11");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 12");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 13");
            error = 1'b1;
        end
        #31.84 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 14");
            error = 1'b1;
        end
        #0.16 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 15");
            error = 1'b1;
        end
        #31.84 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 16");
            error = 1'b1;
        end
        #0.16 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 17");
            error = 1'b1;
        end
        #31.80 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 18");
            error = 1'b1;
        end
        #0.24 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 19");
            error = 1'b1;
        end
        #31.76 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 20");
            error = 1'b1;
        end
        #0.24 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 21");
            error = 1'b1;
        end
        #31.76 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 22");
            error = 1'b1;
        end
        #0.24 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 23");
            error = 1'b1;
        end
        $display("Character C");
        #10 wait(pmod[7:0] == 8'hFF); // character 'C'
        #0.05 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 1");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 2");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 3");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 4");
            error = 1'b1;
        end
        #31.80 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 5");
            error = 1'b1;
        end
        #0.24 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 6");
            error = 1'b1;
        end
        #31.76 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 7");
            error = 1'b1;
        end
        #32 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 8");
            error = 1'b1;
        end
        #32 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 9");
            error = 1'b1;
        end
        #32 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 10");
            error = 1'b1;
        end
        #32 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 11");
            error = 1'b1;
        end
        #32 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 12");
            error = 1'b1;
        end
        #32 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 13");
            error = 1'b1;
        end
        #32 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 14");
            error = 1'b1;
        end
        #0.24 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 15");
            error = 1'b1;
        end
        #31.80 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 16");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 17");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 18");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 19");
            error = 1'b1;
        end
        #0.04 if (pmod[7:0] != 8'hFF) begin
            $display("ERROR 20");
            error = 1'b1;
        end
    end
        
    top dut_top( .clk_i(clk), .PMOD(pmod), .axil_wdata_i(axil_wdata), .axil_wstrb_i(axil_wstrb), .axil_waddr_i(axil_waddr), .axil_wready_i(axil_wready),
.axil_rreq_i(axil_rreq), .axil_raddr_i(axil_raddr), .axil_rdata_o(axil_rdata));

    /* Make a regular pulsing clock. */
    always #0.01 clk = !clk;

endmodule // test
