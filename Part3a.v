module FA (input a, b, cin, output s, cout);

   assign  s    = a ^ b ^ cin;
   assign  cout = (a & b) | (a & cin) | (b & cin);
endmodule

//simple register
module Reg (reset, clk, load, d, q);
	
	input 	reset;			//reset input
	input 	[3:0] d;  	    //parallel input
	input	clk;			//clock
	input	load;			//write enable
	output 	[3:0] q;		//parallel output		
   
	reg [3:0] q;
	
	always @(posedge clk)
	begin
		if (reset)
			q = 0;
		else if (load) 
			q = d;
	end
   	
endmodule


module mux_2to1(input s, input  a,b, output  w );

    assign w = (s) ? a:b ;
    
endmodule

// 4 bit adder
module adder_4bit (a, b,cin, s, cout, overflow );
	input 	[3:0] a, b; 	// data inputs
    input   cin;
	output 	[3:0] s;		// Add/Sub output
	output 	cout;			// Carry out/ Barroe Out output 
	output 	overflow;		// overflow output
   
	
	wire [4:0] c;
	wire overflow;
   
	FA fa [3:0] (a, b, c[3:0], s, c[4:1]);
   
	assign cin = 1'b0;
	assign c[0] = cin;
	assign cout = c[4];
	assign overflow = cout;
   
endmodule



//Shift Register
module SHR (reset, clk, load, sh_en, sin, pin, sout, pout);
	
	input 	[3:0] pin;  	//parallel input
	input 	reset;			//reset input
	input 	sin;			//serial input
	input	clk;			//clock
	input   load;			//write enable for parallel load
	input	sh_en;			//shift enable 
	output 	[3:0] pout;	    //parallel output	
	output 	sout;			//serial out 
   
	reg [3:0] pout;
	
	always @(posedge clk)
	begin
		if (reset)
			pout = 0;
		else if (load) 
			pout = pin;
		else if (sh_en) 
			pout = {sin,pout[3:1]};
	end
   
	assign sout = pout[0];
	
endmodule
module SHRR(reset, clk, load, shift_m, sin, pin, sout, pout);
	
	input 	[3:0] pin;  	//parallel input
	input 	reset;			//reset input
	input 	sin;			//serial input
	input	clk;			//clock
	input   load;			//write enable for parallel load
	input	shift_m;			//shift enable 
	output 	[3:0] pout;	    //parallel output	
	output 	sout;			//serial out 
   
	reg [3:0] pout;
	
	always @(posedge clk)
	begin
		if (reset)
			pout = 0;
		else if (load) 
			pout = pin;
		else if (shift_m) 
			pout = {1'b0,pout[3:1]};
	end
   
	assign sout = pout[0];
	
endmodule




module Controller(reset, start, clk, shift, LD_m, ready,b_0,select,shift_m);
	input  reset;
	input  start;
    input  b_0;
	input  clk;
	output LD_m, shift, ready, select,shift_m; // Controller outputs
	reg    LD_m, shift, ready, select,shift_m;

	integer pstate, nstate;       // Controller states, pstate means present state and nstate means nest state.
	
	
	always @(posedge clk) begin
		if (reset | start)
			pstate = 0;
		else
			pstate = nstate;
	end
	
	always @(start or pstate or b_0 ) begin
		nstate = pstate + 1;
		shift = 1'b0;
		LD_m = 1'b0;
		ready = 1'b0;
		shift_m = 1'b0;

		case (pstate)
			0:
				if (start)
					nstate = 1;
					
			1,2,3,4:

				if(b_0 == 1'b1)begin
					LD_m = 1'b1;
					shift = 1'b1;
					select = 1'b1;
				end
				
				else if(b_0 == 1'b0)begin
					shift_m = 1'b1;
					shift = 1'b1;
					select = 1'b0;
				end


			5: begin
				ready = 1'b1;
				nstate = 5;
				if (start)
					nstate=1;
			   end
			default:
				nstate = 0;
		endcase
	end
endmodule

module Datapath (reset, a,b,clk,start,shift,LD_m,cin_alu, M,ready, b_0,select,shift_m);
	
	input 	[3:0] a, b;
	input 	reset;			//reset input
	input 	start;
	input   clk;
	input   shift, LD_m ;
    input   cin_alu;
	input	select;
	input	shift_m;
	output 	[7:0] M;
	output 	ready ;
	output b_0;
   
	wire [3:0] A_out, B_out, M_out, ALU_out;
	wire overflow, M_reset;
	
	reg  sin;

	Reg A_reg (reset, clk, start, a, A_out);
	SHRR M_reg (reset, clk, LD_m,  shift_m, sin,  {cout,ALU_out[3:1]}, M_so, M_out);
	SHR B_reg (reset, clk, start, shift, mux_out, b, b_0,  B_out);
	adder_4bit ALU   ( A_out,M_out, cin_alu, ALU_out, cout, overflow);
	mux_2to1 mux (select,ALU_out[0],M_so,mux_out);

	
   assign M={M_out,B_out};
endmodule


//Add and Shift multiplier
module Add_Shift (reset, a,b,start,clk,M,ready);
	input 	reset;
	input 	[3:0] a, b;
	input 	start;
	input    clk;
	output 	[7:0] M;
	output 	ready;
	assign cin_alu = 1'b0;

	Datapath 	DP (reset, a,b,clk,start,shift,LD_m,cin_alu, M,ready, b_0,select,shift_m);
	Controller	CU (reset, start, clk, shift, LD_m,  ready, b_0,select,shift_m);
endmodule



module test_multiplier;
	reg  reset,clk, start;
	reg  [3:0] a,b;
	wire [7:0] M;
	wire       ready;

	Add_Shift cut (reset, a,b,start,clk,M,ready);

	integer i;
    //integer j;

	always
		#30 clk = ~clk;

	/*
	initial
	begin
		clk   = 1'b0;
		start = 1'b0;
		reset = 1'b1;    
		a = 4'b1110;
		b = 4'b0101;
		#100 reset = 1'b0;
		#100 start = 1'b1;
		#100 start = 1'b0;
		
	end
	
	*/
/*
  	initial
	begin
		clk   = 1'b0;
		start = 1'b0;
		reset = 1'b1;    
		#100 reset = 1'b0;
		#140 start = 1'b1;
		for ( j = 0; j < 16; j = j + 1) 
		begin
			for (i = 0; i < 16; i=i+1)
			begin
				#100 start = 1'b0;
				#1000 start = 1'b1;
				a = i;
				b = j;
			end
		end
			
		$stop;
	end
  */
  
	initial
	begin
		clk   = 1'b0;
		start = 1'b0;
		reset = 1'b1;    
		 a = $random ;b = $random;
		
		#100 reset = 1'b0;
		#140 start = 1'b1;
		for (i = 0; i < 100; i=i+1)
		begin
			#100 start = 1'b0;
			#800 reset = 1'b1;
			#100 reset = 1'b0;

			#100a = $random ;b = $random;
			#100 start = 1'b1;
			
		end
		$stop;
	end












endmodule
