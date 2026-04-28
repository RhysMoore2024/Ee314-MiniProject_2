`timescale 1ns / 1ps

module Main_tb;

   reg  signed [10:0] A;
   reg  signed [10:0] B;
   reg         [1:0] mode;
   wire signed [10:0] result;
   wire              overflow;
   wire              div_by_zero;
   reg               clk;

   // Instantiate DUT
   Main uut (
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
    A = 11'sd0;
    B = 11'sd0;
    mode = 0;

       // ---------------- ADDITION ----------------
    #10; A = 11'sd15;   B = 11'sd10;   mode = 2'b00;  #10; // 15 + 10 = 25
    #10; A = 11'sd0;    B = 11'sd42;   mode = 2'b00;  #10; // 0 + 42 = 42
    #10; A = -11'sd20;  B = 11'sd50;   mode = 2'b00;  #10; // -20 + 50 = 30
    #10; A = -11'sd10;  B = -11'sd15;  mode = 2'b00;  #10; // -10 + -15 = -25
    #10; A = 11'sd511;  B = 11'sd1;    mode = 2'b00;  #10; // overflow
    // ---------------- SUBTRACTION ----------------
    #10; A = 11'sd30;   B = 11'sd10;   mode = 2'b01;  #10; // 30 - 10 = 20
    #10; A = 11'sd55;   B = 11'sd55;   mode = 2'b01;  #10; // 55 - 55 = 0
    #10; A = 11'sd5;    B = 11'sd20;   mode = 2'b01;  #10; // 5 - 20 = -15
    #10; A = -11'sd10;  B = -11'sd30;  mode = 2'b01;  #10; // -10 - (-30) = 20
    #10; A = 11'sd511;  B = -11'sd1;   mode = 2'b01;  #10; // overflow
    // ---------------- DIVISION ----------------
    #10; A = 11'sd40;   B = 11'sd5;    mode = 2'b10;  #10; // 40 / 5 = 8
    #10; A = -11'sd30;  B = 11'sd3;    mode = 2'b10;  #10; // -30 / 3 = -10
    #10; A = 11'sd25;   B = -11'sd5;   mode = 2'b10;  #10; // 25 / -5 = -5
    #10; A = 11'sd10;   B = 11'sd0;    mode = 2'b10;  #10; // div by zero
    // ---------------- MULTIPLICATION ----------------
    #10; A = 11'sd6;    B = 11'sd7;    mode = 2'b11;  #10; // 6 * 7 = 42
    #10; A = -11'sd8;   B = 11'sd4;    mode = 2'b11;  #10; // -8 * 4 = -32
    #10; A = 11'sd9;    B = -11'sd3;   mode = 2'b11;  #10; // 9 * -3 = -27
    #10; A = 11'sd20;   B = 11'sd0;    mode = 2'b11;  #10; // 20 * 0 = 0
    #10; A = 11'sd100;  B = 11'sd6;    mode = 2'b11;  #10; // 600 -> overflow
    #10; $finish;
         
   end

endmodule
