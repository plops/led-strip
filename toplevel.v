module toplevel(ad,rxf_,txe_,rd_,wr_,siwub,clk,oe_,ws2811);
	input [7:0] ad;
	input rxf_,txe_,clk;
	output rd_,wr_,siwub,oe_,ws2811;
	
	
	
	wire clk12_8, // minimum useful freq that can be generated from 60MHz
	     clk3_2,  // frequency of the four parts that make up one 1.25us cell
		  clk800,  // one bit in the ws2811 stream (1.25us cells)
		  clk100;  // one byte in the ws2811 stream
	pll c1(clk,clk12_8);
	divide_clock_by_4 c2(clk12_8,clk3_2);
	divide_clock_by_4 c3(clk3_2,clk800);
	divide_clock_by_8 c4(clk800,clk100);

	wire	  rdclk,rdreq,wrreq;
	wire [7:0] q_fifo;
	wire	  rdempty,rdfull;
	wire	  wrempty,wrfull;
	reg [7:0] ad_reg;
	
	fifo f (
	.data(ad_reg),
	.rdclk(clk100),
	.rdreq(rdreq),
	.wrclk(clk),
	.wrreq(wrreq),
	.q(q_fifo),
	.rdempty(rdempty),
	.rdfull(rdfull),
	.wrempty(wrempty),
	.wrfull(wrfull));
		
	reg read_ftdi_p;
	always @(posedge clk) begin
		read_ftdi_p <= (rxf_==1'b0);  // ftdi signals it can be read
	end
		
	assign oe_ = !read_ftdi_p;	// set ftdi data port to output/input
	assign rd_ = !read_ftdi_p;
	
	always @(posedge clk) begin
		if(read_ftdi_p & ~oe_ & ~wrfull)
			ad_reg[7:0] <= ad[7:0];
	end

   reg fillfifo;
   always @(posedge clk) begin
		if(~fillfifo)
			fillfifo <= wrempty; // start when empty
		else
			fillfifo <= ~wrfull; // stop when full
	end
	
	assign wr_ = 1'b1;

	assign wrreq = fillfifo & read_ftdi_p;
	
	reg consumefifo;
	always @(posedge clk3_2) begin
		if(consumefifo)
			consumefifo <= ~rdempty; // stop when empty
		else
			consumefifo <= rdfull; // start when full
	end
	
	assign rdreq = consumefifo;
	
	reg muxbit, muxsub, carry = 1'b0;
	reg [1:0] suboff = 4'b1000, subon = 4'b1110;
	reg [2:0] bitcount;
	reg [1:0] subcount; // index for one of the 4 subcells in 1.25us
	always @(posedge clk3_2) begin
		if(carry == 1'b0) begin // go to next bit when 4 subcells were produced
			muxbit <= consumefifo ? q_fifo[bitcount] : 1'b0;
			bitcount <= bitcount + 1;
		end
		muxsub <= muxbit ? subon[subcount] : suboff[subcount];
		{carry, subcount} <= subcount + 1;
	end
	assign ws2811 = muxsub;
endmodule