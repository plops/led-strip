module divide_clock_by_4(input in,output out);
   reg [1:0] count; 
   always @(posedge in) begin
      count <= count + 1;
   end
   assign out = count[1];
endmodule

module toplevel(ad,rxf_,txe_,rd_,wr_,siwub,clk,clk50,oe_,ws2811,n13,n11,l12,r9,r11,r13,r14,p16,n16,l16,k16);
   input [7:0] ad;
   input       rxf_,txe_,clk,clk50;
   output reg  rd_, oe_;
   
   output      wr_,siwub,ws2811,n13; // n13 is connected to init-done and drives the green led
   output      n11,l12,r9,r11,r13,r14,p16,n16,l16,k16;
  
   wire        clk12_8, // minimum useful freq that can be generated from 60MHz
	       clk3_2;  // frequency of the four parts that make up one 1.25us cell
   

   pll c1(.inclk0(clk),.c0(clk12_8));
   divide_clock_by_4 c2(clk12_8,clk3_2);
   wire clk800;
   
   divide_clock_by_4 c3(clk3_2,clk800);
   
   wire        rdclk,rdreq,wrreq;
   wire [7:0]  q_fifo;
   wire        rdempty,rdfull;
   wire        wrempty,wrfull;
   reg [7:0]   ad_reg;
   
   fifo f (.data(ad_reg),
	   .rdclk(clk800),	.rdreq(rdreq),
	   .wrclk(clk),		.wrreq(wrreq),
	   .q(q_fifo),
	   .rdempty(rdempty),.rdfull(rdfull),
	   .wrempty(wrempty),.wrfull(wrfull));


/* clk period 16.67ns, poll until rxf_ is low (1 to 7.15ns after clk),
/* then pull oe_ low (data valid after 7.15ns and 16.67ns setup time),
/* pull rd_ low after one clock delay (16.67ns later the data is
/* there), and readout bytes with clk; when rxf_ becomes high, stop
/* reading and pull oe_ high and rd_ high: we have the following
/* states 1..waitrx 2..receivedrx 3..oedown 4..rddown 5..read 6..oerdup */

   reg [3:0]   state = 5;
   always @(posedge clk) begin
      case (state) 
	0: begin // wait_rx
	   state <= (rxf_==0 && ~wrfull) ? 1 : 0;
	end
	1: begin // received_rx, not sure if I need this
	   state <= (rxf_ == 0 && ~wrfull) ? 2 : 5;
	end
	2: begin // oe_down
	   oe_ = 1'b0;
	   state <= (rxf_ == 0 && ~wrfull) ? 3 : 5;
	end
	3: begin // rd_down
	   rd_ = 1'b0;
	   state <=(rxf_ == 0 && ~wrfull) ? 4 : 5;
	end
	4: begin // read
	   ad_reg[7:0] <= ad[7:0];
	   state <= (rxf_ == 0 && ~wrfull) ? 4 : 5;
	end
	5: begin // oe_rd_up
	   oe_ = 1'b1;
	   rd_ = 1'b1;
	   state <= 0;
	end
	endcase
   end
   
   assign n11 = rxf_;
   assign l12 = rdfull;
   assign r9 = rdempty;
   assign r11 = consumefifo;
         
   assign r13 = fillfifo;
   assign r14 = wrfull;
   assign p16 = wrempty;
   assign n16 = muxsub;
   
   
   assign wr_ = 1'b1; // i don't want to send data from fpga into computer
   
   reg fillfifo;
   always @(posedge clk) begin
      fillfifo <= fillfifo ? ~wrfull : wrempty; // stop when full, start when empty
   end
      
   assign wrreq = fillfifo & (state == 4);
   
   reg consumefifo;
   always @(posedge clk3_2) begin
      consumefifo <= consumefifo ? ~rdempty : rdfull; // stop when empty, start when full
   end
   
   assign rdreq = consumefifo & clk3_2;
   
   reg muxbit, muxsub;
   reg [3:0] suboff = 4'b0001, subon = 4'b0111;
   reg [2:0] bitcount;
   reg [1:0] subcount; // index for one of the 4 subcells in 1.25us
   
   
   always @(posedge rdreq) begin
      if(subcount == 2'b00) begin // go to next bit when 4 subcells were produced
	 muxbit <= consumefifo ? q_fifo[bitcount] : 1'b0;
	 bitcount <= bitcount + 1;
      end
      muxsub <= muxbit ? subon[subcount] : suboff[subcount];
      subcount <= subcount + 1;
   end
   assign ws2811 = muxsub; // e16 not at rectangle

   // blink the green led
   reg [23:0]  ledcount;
   always @(posedge clk50) begin
      ledcount <= ledcount + 1;
   end
   assign n13 = ledcount[23];    

endmodule
