module fifo_consumer(input [7:0] fifo,output obit, input clk);
	reg muxbit;
	reg [2:0] state;
	always @(posedge clk) begin
		muxbit <= fifo[state];
		state <= state + 1;
	end
	assign obit = muxbit;
endmodule


module convert_ws2811_pattern(input bit,output [3:0] seq);
	assign seq = bit ? 4'b1110 : 4'b1000;
endmodule

module shift_register_4
#(parameter N=4)
(input clk,input sr_in, output sr_out);
	reg [N-1:0] sr;
	always @ (posedge clk)
	begin
			sr[N-1:1] <= sr[N-2:0];
			sr[0] <= sr_in;
	end
	assign sr_out = sr[N-1];
endmodule

module toplevel(ad,rxf_,txe_,rd_,wr_,siwub,clk,oe_,ws2811,myclk,onboardclk);
	input [7:0] ad;
	input rxf_,txe_,clk;
	input onboardclk;
	output rd_,wr_,siwub,oe_,ws2811,myclk;
	
	
	assign wr_ = 1'b1;
	
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

	assign wrreq = fillfifo & read_ftdi_p;
	
	reg consumefifo;
	always @(posedge clk800) begin
		if(consumefifo)
			consumefifo <= ~rdempty; // stop when empty
		else
			consumefifo <= rdfull; // start when full
	end
	
	assign rdreq = consumefifo;
	
	fifo_consumer consum(.fifo(q_fifo),.obit(ws2811),.clk(clk800));
	
	
	reg [7:0] count;
	always @(posedge onboardclk) begin
		count <= count + 1;
	end
		
	
	assign myclock = wrreq; // e14
//	assign ws2811 = clk100; // e16
	
	
	
endmodule