
`timescale 1ns / 1ps

module tb_adder_subtractor;

   reg  signed [10:0] A;
   reg  signed [10:0] B;
   reg         [1:0] mode;
   wire signed [10:0] result;
   wire              overflow;
   wire              div_by_zero;
   reg               clk;

   // Instantiate DUT
   adder_subtractor_divider uut (
       .A          (A),
       .B          (B),
       .mode       (mode),
       .result     (result),
       .overflow   (overflow),
       .div_by_zero(div_by_zero),
       .clk        (clk)
   );
   
   always #5 clk <= ~clk;
    
   initial begin
       clk = 0;
       A = 0;
       B = 0;
       mode = 0;

       // ---------------- ADDITION ----------------
       #10; A = 10'sd15;   B = 10'sd10;   mode = 2'b00; // 15 + 10 = 25
       #10; A = 10'sd0;    B = 10'sd42;   mode = 2'b00; // 0 + 42 = 42
       #10; A = -10'sd20;  B = 10'sd50;   mode = 2'b00; // -20 + 50 = 30
       #10; A = -10'sd10;  B = -10'sd15;  mode = 2'b00; // -10 + -15 = -25
       #10; A = 10'sd511;  B = 10'sd1;    mode = 2'b00; // overflow

       // ---------------- SUBTRACTION ----------------
       #10; A = 10'sd30;   B = 10'sd10;   mode = 2'b01; // 30 - 10 = 20
       #10; A = 10'sd55;   B = 10'sd55;   mode = 2'b01; // 55 - 55 = 0
       #10; A = 10'sd5;    B = 10'sd20;   mode = 2'b01; // 5 - 20 = -15
       #10; A = -10'sd10;  B = -10'sd30;  mode = 2'b01; // -10 - (-30) = 20
       #10; A = 10'sd511;  B = -10'sd1;   mode = 2'b01; // overflow

       // ---------------- DIVISION ----------------
       #10; A = 10'sd40;   B = 10'sd5;    mode = 2'b10; // 40 / 5 = 8
       #10; A = -10'sd30;  B = 10'sd3;    mode = 2'b10; // -30 / 3 = -10
       #10; A = 10'sd25;   B = -10'sd5;   mode = 2'b10; // 25 / -5 = -5
       #10; A = 10'sd10;   B = 10'sd0;    mode = 2'b10; // div by zero

       // ---------------- MULTIPLICATION ----------------
       #10; A = 10'sd6;    B = 10'sd7;    mode = 2'b11; // 6 * 7 = 42
       #10; A = -10'sd8;   B = 10'sd4;    mode = 2'b11; // -8 * 4 = -32
       #10; A = 10'sd9;   B = -10'sd3;   mode = 2'b11; // -9 * -3 = 27
       #10; A = 10'sd20;   B = 10'sd0;    mode = 2'b11; // 20 * 0 = 0
       #10; A = 10'sd100;  B = 10'sd6;    mode = 2'b11; // 600 -> overflow for 10-bit signed

       #10; $finish;
       
       
   end

endmodule
