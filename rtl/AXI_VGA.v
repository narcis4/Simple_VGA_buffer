////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	easyaxil
// {{{
// Project:	WB2AXIPSP: bus bridges and other odds and ends
//
// Purpose:	Demonstrates a simple AXI-Lite interface.
//
//	This was written in light of my last demonstrator, for which others
//	declared that it was much too complicated to understand.  The goal of
//	this demonstrator is to have logic that's easier to understand, use,
//	and copy as needed.
//
//	Since there are two basic approaches to AXI-lite signaling, both with
//	and without skidbuffers, this example demonstrates both so that the
//	differences can be compared and contrasted.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2020, Gisselquist Technology, LLC
// {{{
//
// This file is part of the WB2AXIP project.
//
// The WB2AXIP project contains free software and gateware, licensed under the
// Apache License, Version 2.0 (the "License").  You may not use this project,
// or this file, except in compliance with the License.  You may obtain a copy
// of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations
// under the License.
//
////////////////////////////////////////////////////////////////////////////////
// }}}
//
`default_nettype none
//
module AXI_VGA #(
		// {{{
		parameter	C_AXI_ADDR_WIDTH = $clog2(2400), // Addr width based on the number of registers
		parameter	C_AXI_DATA_WIDTH = 32, // Width of the AXI-lite bus
		parameter [0:0]	OPT_SKIDBUFFER = 1'b0, // This determines if we want to use more logic to achieve 1 transaction per bus cycle
		parameter [0:0]	OPT_LOWPOWER = 0, // Lowpower option to disable channels if inactive
		parameter	ADDRLSB = $clog2(C_AXI_DATA_WIDTH)-3 // Least significant bits from address not used due to write strobes
		// }}}
	) (
		// {{{
		input wire					        S_AXI_ACLK, // AXI bus clock
		input wire					        S_AXI_ARESETN, // AXI reset
		//
		input wire					        S_AXI_AWVALID, // The write address from the master in AWADDR is valid and can be read
		output wire					        S_AXI_AWREADY, // The slave (the VGA) is ready to read the write address
		input wire [C_AXI_ADDR_WIDTH-1:0]   S_AXI_AWADDR, // The write address for the transaction
		input wire [2:0]			        S_AXI_AWPROT, // The write address protection level (level of priviledge)
		//
		input wire					        S_AXI_WVALID, // The write data in WDATA is valid and can be read
		output wire					        S_AXI_WREADY, // The VGA is ready to read the write data
		input wire [C_AXI_DATA_WIDTH-1:0]   S_AXI_WDATA, // The write data from the master
		input wire [C_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB, // This determines which bytes of the write data to write and to leave the rest unchanged
		//
		output wire					        S_AXI_BVALID, // Write acknowledgement
		input wire					        S_AXI_BREADY, // The master is ready to receive the write acknowledgement
		output wire [1:0]				    S_AXI_BRESP, // The VGA sends the result code for the write operation
		//
		input wire					        S_AXI_ARVALID, // The read address from the master in ARADDR is valid and can be read
		output wire					        S_AXI_ARREADY, // The VGA is ready to read the read address
		input wire [C_AXI_ADDR_WIDTH-1:0]	S_AXI_ARADDR, // The read address for the transaction
		input wire [2:0]				    S_AXI_ARPROT, // The read address level of priviledge
		//
		output wire					        S_AXI_RVALID, // The read data in RDATA is valid and can be read by the master
		input wire					        S_AXI_RREADY, // The master is ready to read the RDATA
		output wire	[C_AXI_DATA_WIDTH-1:0]  S_AXI_RDATA, // The read data from the slave
		output wire [1:0]				    S_AXI_RRESP, // The VGA sends the result for the read operation
		// }}}
        output wire [15:0] vga_o // The VGA signal containing the RGB and horizontal and vertical sync signals
	);

	////////////////////////////////////////////////////////////////////////
	//
	// Register/wire signal declarations
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{
	wire i_reset = !S_AXI_ARESETN;

	wire				                axil_write_ready; // Same as AWREADY
	wire [C_AXI_ADDR_WIDTH-1:0]	awskd_addr; // Same as AWADDR //wire [C_AXI_ADDR_WIDTH-ADDRLSB-1:0]	awskd_addr; 
	//
	wire [C_AXI_DATA_WIDTH-1:0]	        wskd_data; // Same as WDATA
	wire [C_AXI_DATA_WIDTH/8-1:0]       wskd_strb; // Same as WSTRB
	reg			                        axil_bvalid; // Same as BVALID
	//
	wire				                axil_read_ready; // The VGA is about to read the ARADDR
	wire [C_AXI_ADDR_WIDTH-1:0] arskd_addr; // Same as ARADDR //wire [C_AXI_ADDR_WIDTH-ADDRLSB-1:0] arskd_addr;
	wire [C_AXI_DATA_WIDTH-1:0]	    axil_read_data; // Same as RDATA
	reg				                    axil_read_valid; // Same as RVALID

    wire axil_read_req; // The VGA is about to read from the registers into RDATA

	//reg	[31:0]	r0, r1, r2, r3;
	//wire [31:0]	wskd_r0, wskd_r1, wskd_r2, wskd_r3;


	////////////////////////////////////////////////////////////////////////
	//
	// AXI-lite signaling
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{

	//
	// Write signaling
	//
	// {{{

	generate if (OPT_SKIDBUFFER) begin : SKIDBUFFER_WRITE
		wire	awskd_valid, wskd_valid;

		skidbuffer #(.OPT_OUTREG(0),
				.OPT_LOWPOWER(OPT_LOWPOWER),
				.DW(C_AXI_ADDR_WIDTH-ADDRLSB))
		axilawskid(//
			.i_clk(S_AXI_ACLK), .i_reset(i_reset),
			.i_valid(S_AXI_AWVALID), .o_ready(S_AXI_AWREADY),
			.i_data(S_AXI_AWADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB]),
			.o_valid(awskd_valid), .i_ready(axil_write_ready),
			.o_data(awskd_addr));

		skidbuffer #(.OPT_OUTREG(0),
				.OPT_LOWPOWER(OPT_LOWPOWER),
				.DW(C_AXI_DATA_WIDTH+C_AXI_DATA_WIDTH/8))
		axilwskid(//
			.i_clk(S_AXI_ACLK), .i_reset(i_reset),
			.i_valid(S_AXI_WVALID), .o_ready(S_AXI_WREADY),
			.i_data({ S_AXI_WDATA, S_AXI_WSTRB }),
			.o_valid(wskd_valid), .i_ready(axil_write_ready),
			.o_data({ wskd_data, wskd_strb }));

		assign	axil_write_ready = awskd_valid && wskd_valid
				&& (!S_AXI_BVALID || S_AXI_BREADY);

	end else begin : SIMPLE_WRITES // Handshaking and control of the of the AXI write signals

		reg	axil_awready;

		initial	axil_awready = 1'b0;
		always @(posedge S_AXI_ACLK) begin
		    if (!S_AXI_ARESETN)
			    axil_awready <= 1'b0;
		    else
			    axil_awready <= !axil_awready
				    && (S_AXI_AWVALID && S_AXI_WVALID)
				    && (!S_AXI_BVALID || S_AXI_BREADY);
        end

		assign	S_AXI_AWREADY = axil_awready;
		assign	S_AXI_WREADY  = axil_awready;

		assign 	awskd_addr = S_AXI_AWADDR[C_AXI_ADDR_WIDTH-1:0]; //assign 	awskd_addr = S_AXI_AWADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB];
		assign	wskd_data  = S_AXI_WDATA;
		assign	wskd_strb  = S_AXI_WSTRB;

		assign	axil_write_ready = axil_awready;

	end endgenerate

	initial	axil_bvalid = 0;
	always @(posedge S_AXI_ACLK) begin
	    if (i_reset)
		    axil_bvalid <= 0;
	    else if (axil_write_ready)
		    axil_bvalid <= 1;
	    else if (S_AXI_BREADY)
		    axil_bvalid <= 0;
    end

	assign	S_AXI_BVALID = axil_bvalid;
	assign	S_AXI_BRESP = 2'b00;
	// }}}

	//
	// Read signaling
	//
	// {{{

	generate if (OPT_SKIDBUFFER) begin : SKIDBUFFER_READ

		wire	arskd_valid;

		skidbuffer #(.OPT_OUTREG(0),
				.OPT_LOWPOWER(OPT_LOWPOWER),
				.DW(C_AXI_ADDR_WIDTH-ADDRLSB))
		axilarskid(//
			.i_clk(S_AXI_ACLK), .i_reset(i_reset),
			.i_valid(S_AXI_ARVALID), .o_ready(S_AXI_ARREADY),
			.i_data(S_AXI_ARADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB]),
			.o_valid(arskd_valid), .i_ready(axil_read_ready),
			.o_data(arskd_addr));

		assign	axil_read_ready = arskd_valid
				&& (!axil_read_valid || S_AXI_RREADY);

	end else begin : SIMPLE_READS // Handshaking and control of the AXI read signals

		reg	axil_arready;

		always @(*) axil_arready = !S_AXI_RVALID;

		assign	arskd_addr = S_AXI_ARADDR[C_AXI_ADDR_WIDTH-1:0]; //assign	arskd_addr = S_AXI_ARADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB];
		assign	S_AXI_ARREADY = axil_arready;
		assign	axil_read_ready = (S_AXI_ARVALID && S_AXI_ARREADY);
        
        assign  axil_read_req = (!S_AXI_RVALID || S_AXI_RREADY);

	end endgenerate

	initial	axil_read_valid = 1'b0;
	always @(posedge S_AXI_ACLK) begin
	    if (i_reset)
		    axil_read_valid <= 1'b0;
	    else if (axil_read_ready)
		    axil_read_valid <= 1'b1;
	    else if (S_AXI_RREADY)
		    axil_read_valid <= 1'b0;
    end

	assign	S_AXI_RVALID = axil_read_valid;
	assign	S_AXI_RDATA  = axil_read_data;
	assign	S_AXI_RRESP = 2'b00;
	// }}}

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// AXI-lite register logic
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{

	// apply_wstrb(old_data, new_data, write_strobes)
	// assign	wskd_r0 = apply_wstrb(r0, wskd_data, wskd_strb);
	// assign	wskd_r1 = apply_wstrb(r1, wskd_data, wskd_strb);
	// assign	wskd_r2 = apply_wstrb(r2, wskd_data, wskd_strb);
	// assign	wskd_r3 = apply_wstrb(r3, wskd_data, wskd_strb);

	/* initial	r0 = 0;
	initial	r1 = 0;
	initial	r2 = 0;
	initial	r3 = 0;
	always @(posedge S_AXI_ACLK) begin
	    if (i_reset) begin
		    r0 <= 0;
		    r1 <= 0;
		    r2 <= 0;
		    r3 <= 0;
	    end 
        else if (axil_write_ready) begin
		    case(awskd_addr)
		    2'b00:	r0 <= wskd_r0;
		    2'b01:	r1 <= wskd_r1;
		    2'b10:	r2 <= wskd_r2;
		    2'b11:	r3 <= wskd_r3;
		    endcase
	    end
    end*/

	/*initial	axil_read_data = 0;
	always @(posedge S_AXI_ACLK) begin
	    if (OPT_LOWPOWER && !S_AXI_ARESETN)
		    axil_read_data <= 0;
	    else if (!S_AXI_RVALID || S_AXI_RREADY) begin
		    case(arskd_addr)
		    2'b00:	axil_read_data	<= r0;
		    2'b01:	axil_read_data	<= r1;
		    2'b10:	axil_read_data	<= r2;
		    2'b11:	axil_read_data	<= r3;
		    endcase

		    if (OPT_LOWPOWER && !axil_read_ready)
			    axil_read_data <= 0;
	    end
    end*/

	/* function [C_AXI_DATA_WIDTH-1:0]	apply_wstrb;
		input	[C_AXI_DATA_WIDTH-1:0]		prior_data;
		input	[C_AXI_DATA_WIDTH-1:0]		new_data;
		input	[C_AXI_DATA_WIDTH/8-1:0]	wstrb;

		integer	k;
		for (k=0; k<C_AXI_DATA_WIDTH/8; k=k+1) begin
			apply_wstrb[k*8 +: 8]
				= wstrb[k] ? new_data[k*8 +: 8] : prior_data[k*8 +: 8];
		end
	endfunction */
	// }}}

	// Verilator lint_off UNUSED
	wire	unused;
	assign	unused = &{ 1'b0, S_AXI_AWPROT, S_AXI_ARPROT,
			S_AXI_ARADDR[ADDRLSB-1:0],
			S_AXI_AWADDR[ADDRLSB-1:0] };
	// Verilator lint_on  UNUSED
	// }}}

`ifdef	FORMAL
    top top_inst( .clk_i(S_AXI_ACLK), .PMOD(vga_o), .axil_wdata_i(wskd_data), .axil_wstrb_i(wskd_strb), .axil_waddr_i(awskd_addr), .axil_wready_i(axil_write_ready), 
.axil_rreq_i(axil_read_req), .axil_raddr_i(arskd_addr), .axil_rdata_o(axil_read_data), .f_rdata_i(axil_read_data), .f_past_valid_i(f_past_valid), 
.f_reset_i(S_AXI_ARESETN), .f_ready_i(axil_read_ready));//, .clk_axi_i(S_AXI_ACLK));
	////////////////////////////////////////////////////////////////////////
	//
	// Formal properties used in verfiying this core
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{
	reg	f_past_valid;
	initial	f_past_valid = 0;
	always @(posedge S_AXI_ACLK)
		f_past_valid <= 1;

	////////////////////////////////////////////////////////////////////////
	//
	// The AXI-lite control interface
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{
	localparam	F_AXIL_LGDEPTH = 4;
	wire	[F_AXIL_LGDEPTH-1:0]	faxil_rd_outstanding,
					faxil_wr_outstanding,
					faxil_awr_outstanding;

	faxil_slave #(
		// {{{
		.C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
		.C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
		.F_LGDEPTH(F_AXIL_LGDEPTH),
		.F_AXI_MAXWAIT(2),
		.F_AXI_MAXDELAY(2),
		.F_AXI_MAXRSTALL(3),
		.F_OPT_COVER_BURST(4)
		// }}}
	) faxil(
		// {{{
		.i_clk(S_AXI_ACLK), .i_axi_reset_n(S_AXI_ARESETN),
		//
		.i_axi_awvalid(S_AXI_AWVALID),
		.i_axi_awready(S_AXI_AWREADY),
		.i_axi_awaddr( S_AXI_AWADDR),
		.i_axi_awcache(4'h0),
		.i_axi_awprot( S_AXI_AWPROT),
		//
		.i_axi_wvalid(S_AXI_WVALID),
		.i_axi_wready(S_AXI_WREADY),
		.i_axi_wdata( S_AXI_WDATA),
		.i_axi_wstrb( S_AXI_WSTRB),
		//
		.i_axi_bvalid(S_AXI_BVALID),
		.i_axi_bready(S_AXI_BREADY),
		.i_axi_bresp( S_AXI_BRESP),
		//
		.i_axi_arvalid(S_AXI_ARVALID),
		.i_axi_arready(S_AXI_ARREADY),
		.i_axi_araddr( S_AXI_ARADDR),
		.i_axi_arcache(4'h0),
		.i_axi_arprot( S_AXI_ARPROT),
		//
		.i_axi_rvalid(S_AXI_RVALID),
		.i_axi_rready(S_AXI_RREADY),
		.i_axi_rdata( S_AXI_RDATA),
		.i_axi_rresp( S_AXI_RRESP),
		//
		.f_axi_rd_outstanding(faxil_rd_outstanding),
		.f_axi_wr_outstanding(faxil_wr_outstanding),
		.f_axi_awr_outstanding(faxil_awr_outstanding)
		// }}}
		);

	always @(*)
	if (OPT_SKIDBUFFER)
	begin
		assert(faxil_awr_outstanding== (S_AXI_BVALID ? 1:0)
			+(S_AXI_AWREADY ? 0:1));
		assert(faxil_wr_outstanding == (S_AXI_BVALID ? 1:0)
			+(S_AXI_WREADY ? 0:1));

		assert(faxil_rd_outstanding == (S_AXI_RVALID ? 1:0)
			+(S_AXI_ARREADY ? 0:1));
	end else begin
		assert(faxil_wr_outstanding == (S_AXI_BVALID ? 1:0));
		assert(faxil_awr_outstanding == faxil_wr_outstanding);

		assert(faxil_rd_outstanding == (S_AXI_RVALID ? 1:0));
	end

	always @(posedge S_AXI_ACLK)
	if (f_past_valid && $past(S_AXI_ARESETN
			&& axil_read_ready))
	begin
		assert(S_AXI_RVALID);
        /*case(arskd_addr)
            12'd2397: assert(S_AXI_RDATA == $past({8'b0, bmem[arskd_addr+2], 1'b0, bmem[arskd_addr+1], 1'b0, bmem[arskd_addr]}));
            12'd2398: assert(S_AXI_RDATA == $past({16'b0, bmem[arskd_addr+1], 1'b0, bmem[arskd_addr]}));
            12'd2399: assert(S_AXI_RDATA == $past({24'b0, bmem[arskd_addr]}));
            default: assert(S_AXI_RDATA == $past({bmem[arskd_addr+3], 1'b0, bmem[arskd_addr+2], 1'b0, bmem[arskd_addr+1], 1'b0, bmem[arskd_addr]}));
        endcase*/
	end

	//
	// Check that our low-power only logic works by verifying that anytime
	// S_AXI_RVALID is inactive, then the outgoing data is also zero.
	//
	always @(*)
	if (OPT_LOWPOWER && !S_AXI_RVALID)
		assert(S_AXI_RDATA == 0);

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Cover checks
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{

	// While there are already cover properties in the formal property
	// set above, you'll probably still want to cover something
	// application specific here

	// }}}
	// }}}
`else
    top top_inst( .clk_i(S_AXI_ACLK), .PMOD(vga_o), .axil_wdata_i(wskd_data), .axil_wstrb_i(wskd_strb), .axil_waddr_i(awskd_addr), .axil_wready_i(axil_write_ready), 
.axil_rreq_i(axil_read_req), .axil_raddr_i(arskd_addr), .axil_rdata_o(axil_read_data));
`endif
endmodule

`default_nettype wire

