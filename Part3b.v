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


// Adder-Subtractor Module
module ASM (a, b, m, f, cout, overflow);
	input 	[3:0] a, b; 	// data inputs
	input 	m;				// mode input: m=0 means ADD  and  m=1 means SUB
	output 	[3:0] f;		// Add/Sub output
	output 	cout;			// Carry out/ Barroe Out output 
	output 	overflow;		// overflow output
   
	wire [3:0] bp;
	wire [4:0] 	 c;
	wire overflow;
   
	FA fa [3:0] (a, bp, c[3:0], f, c[4:1]);
   
	assign bp = b ^ {m,m,m,m};
	assign c[0] = m;
	assign cout = c[4];
	assign overflow = c[4] ^ c[3];
   
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


module Controller(reset, start, clk, shift, LD_m,m, ready,b_0, b_3);
	input  reset;
	input  start;
    input  b_0;
	input  b_3;
	input  clk;
	output LD_m, shift, ready, m; // Controller outputs
	reg    LD_m, shift, ready, m;

	integer pstate, nstate;       // Controller states, pstate means present state and nstate means nest state.
	
	
	always @(posedge clk) begin
		if (reset | start)
			pstate = 0;
		else
			pstate = nstate;
	end
	
	always @(start or pstate or b_0 or b_3 ) begin
		nstate = pstate + 1;
		shift = 1'b0;
		LD_m = 1'b0;
		m = 1'b0;
		ready = 1'b0;

		case (pstate)
			0:
				if (start)
					nstate = 1;
			1,3,5:
				
				if (b_0 == 1'b1)
					LD_m=1'b1;
			7:
				if(b_0 == 1'b1)begin
					LD_m=1'b1;
					m = 1'b1;
				end

			2,4,6,8:
				shift = 1'b1;
			9: begin
				ready = 1'b1;
				nstate = 9;
				if (start)
					nstate=1;
			   end
			default:
				nstate = 0;
		endcase
	end
endmodule

module Datapath (reset, a,b,clk,start,shift,LD_m, m,M,ready, b_0,b_3);
	
	input 	[3:0] a, b;
	input 	reset;			//reset input
	input 	start;
	input   clk;
	input   shift, LD_m , m;
	output 	[7:0] M;
	output 	ready ;
	output b_0;
	output b_3;
   
	wire [3:0] A_out, B_out, M_out, ALU_out;
	wire overflow, M_reset;
	
	reg  sin;

	Reg A_reg (reset, clk, start, a, A_out);
	SHR M_reg (reset, clk, LD_m,  shift, sin,  ALU_out, M_so, M_out);
	SHR B_reg (reset, clk, start, shift, M_so, b, b_0,  B_out);
	ASM ALU   (M_out,A_out,m ,ALU_out, cout, overflow  );

	
	// generate serial in (sin) for arithmetic shift operation.
	always @(posedge clk) begin
		if (reset | start)
			sin = 1'b0;
		else 
			if (LD_m)
				if (overflow)
					sin = cout;
				else
					sin = ALU_out[3];
			else
				sin=M_out[3];
	end
   

   assign M={M_out,B_out};
   assign b_3 = B_out[3];
endmodule


//Add and Shift multiplier
module Add_Shift (reset, a,b,start,clk,M,ready);
	input 	reset;
	input 	[3:0] a, b;
	input 	start;
	input    clk;
	output 	[7:0] M;
	output 	ready;
	

	Datapath 	DP (reset, a,b,clk,start,shift,LD_m,m, M,ready, b_0,b_3);
	Controller	CU (reset, start, clk, shift, LD_m, m, ready, b_0, b_3);
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
		a = 4'b1101;
		b = 4'b1011;
		#100 reset = 1'b0;
		#140 start = 1'b1;
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
