//Full Adder
module FA (input a, b, cin, output s, cout);
  
   assign #(3)  s    = a ^ b ^ cin;
   assign #(2)  cout = (a & b) | (a & cin) | (b & cin);

endmodule

//partial products
module array_multiplier_4bit(input [3:0] a, b, output [7:0] product );
    
    wire [15:0] and_w;
    wire [11:0] s_w;
    wire [11:0] c_w;

    and and_00 (and_w[0], a[0], b[0]);
    and and_01 (and_w[1], a[1], b[0]);
    and and_02 (and_w[2], a[2], b[0]);
    and and_03 (and_w[3], a[3], b[0]);

    and and_04 (and_w[4], a[0], b[1]);
    and and_05 (and_w[5], a[1], b[1]);
    and and_06 (and_w[6], a[2], b[1]);
    and and_07 (and_w[7], a[3], b[1]);

    and and_08 (and_w[8],  a[0], b[2]);
    and and_09 (and_w[9],  a[1], b[2]);
    and and_10 (and_w[10], a[2], b[2]);
    and and_11 (and_w[11], a[3], b[2]);

    and and_12 (and_w[12],  a[0], b[3]);
    and and_13 (and_w[13],  a[1], b[3]);
    and and_14 (and_w[14],  a[2], b[3]);
    and and_15 (and_w[15],  a[3], b[3]);

    
    assign zero = 1'b0;

    //first row
    FA FA_00 (.a (and_w[4]),  .b (and_w[1]),  .cin (zero),      .s (s_w[0]), .cout (c_w[0]) );
    FA FA_01 (.a (and_w[2]),  .b (and_w[5]),  .cin (and_w[8]),  .s (s_w[1]), .cout (c_w[1]) );
    FA FA_02 (.a (and_w[6]),  .b (and_w[9]),  .cin (and_w[12]), .s (s_w[2]), .cout (c_w[2]) );
    FA FA_03 (.a (and_w[13]), .b (and_w[10]), .cin (and_w[7]), .s (s_w[3]), .cout (c_w[3]) );

    //second row
    FA FA_04 (.a (s_w[1]),    .b (c_w[0]),    .cin (zero),   .s (s_w[4]), .cout (c_w[4]) );
    FA FA_05 (.a (s_w[2]),    .b (and_w[3]),  .cin (c_w[1]), .s (s_w[5]), .cout (c_w[5]) );
    FA FA_06 (.a (s_w[3]),    .b (c_w[2]),    .cin (zero),   .s (s_w[6]), .cout (c_w[6]) );
    FA FA_07 (.a (and_w[14]), .b (and_w[11]), .cin (c_w[3]), .s (s_w[7]), .cout (c_w[7]) );

    //third row 
    FA FA_08 (.a (s_w[5]),    .b (c_w[4]), .cin (zero),    .s (s_w[8]),  .cout (c_w[8]) );
    FA FA_09 (.a (s_w[6]),    .b (c_w[5]), .cin (c_w[8]),  .s (s_w[9]),  .cout (c_w[9]) );
    FA FA_10 (.a (s_w[7]),    .b (c_w[6]), .cin (c_w[9]),  .s (s_w[10]), .cout (c_w[10]) );
    FA FA_11 (.a (and_w[15]), .b (c_w[7]), .cin (c_w[10]), .s (s_w[11]), .cout (c_w[11]) );

    //product
    assign product[0] = and_w[0];
    assign product[1] = s_w[0];
    assign product[2] = s_w[4];
    assign product[3] = s_w[8];
    assign product[4] = s_w[9];
    assign product[5] = s_w[10];
    assign product[6] = s_w[11];
    assign product[7] = c_w[11];



    
endmodule

module array_multiplier_TB;

    reg [3:0] a, b;
    wire [7:0] w;

    array_multiplier_4bit UUT1 (a,b,w);


    integer i;

/*
    initial begin
        a = 4'b1111;
        b = 4'b1100;
    end
*/

    initial
	    begin
		
            for (i = 0 ; i < 100; i=i+1)
            begin

            a = $random;
            b = $random;
            #50 a =0;
            b= 0;
                
            end
            $stop;
	    end

    
endmodule