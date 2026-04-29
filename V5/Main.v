`timescale 1ns / 1ps
// ============================================================
// TOP-LEVEL ARITHMETIC MODULE
// mode:
// 00 -> Add
// 01 -> Subtract
// 10 -> Divide
// 11 -> Multiply
// ============================================================
module Main (
   input  wire clk,
   input  wire reset,
   input  wire signed [10:0] A,
   input  wire signed [10:0] B,
   input  wire [1:0] mode,

   output reg signed [10:0] result,
   output reg overflow,
   output reg div_by_zero
);

   wire signed [10:0] add_result;
   wire signed [10:0] sub_result;
   wire signed [10:0] mul_result;
   wire signed [10:0] div_result;
   
   wire mul_overflow;
   wire div_zero_flag;

   // ---------------- Module instances ----------------
   add_module ADDER (
       .A(A),
       .B(B),
       .result(add_result),
       .clk(clk)
   );

   sub_module SUBTRACTOR (
       .A(A),
       .B(B),
       .result(sub_result),
       .clk(clk)
   );

   mul_module MULTIPLIER (
       .A(A),
       .B(B),
       .result(mul_result),
       .overflow(mul_overflow),
       .clk(clk)
   );

   div_module DIVIDER (
       .A(A),
       .B(B),
       .result(div_result),
       .div_by_zero(div_zero_flag),
       .clk(clk)
   );

   // ---------------- Select operation ----------------
   always @(posedge clk) begin
       if (reset) begin
        result      <= 11'sd0;
        overflow    <= 1'b0;
        div_by_zero <= 1'b0;
    end else begin
        result      <= 11'sd0;
        overflow    <= 1'b0;
        div_by_zero <= 1'b0;

       case (mode)

           2'b00: begin
               result   <= add_result;
           end

           2'b01: begin
               result   <= sub_result;
           end

           2'b10: begin
               result      <= div_result;
               div_by_zero <= div_zero_flag;
           end

           2'b11: begin
               result   <= mul_result;
               overflow <= mul_overflow;
           end

           default: begin
               result      <= 11'sd0;
               overflow    <= 1'b0;
               div_by_zero <= 1'b0;
           end

       endcase
     end
  end
endmodule



// ============================================================
// ADD MODULE
// ============================================================
module add_module (
   input  wire signed [10:0] A,
   input  wire signed [10:0] B,
   input  wire clk,
   output reg  signed [10:0] result
);

   reg signed [11:0] sum_full;

   always @(posedge clk) begin
      sum_full <= A + B;
      result   <= sum_full[10:0];
   end

endmodule


// ============================================================
// SUBTRACT MODULE
// ============================================================
module sub_module (
   input  wire signed [10:0] A,
   input  wire signed [10:0] B,
   input  wire clk,
   output reg  signed [10:0] result
);

   reg signed [11:0] diff_full;

   always @(posedge clk) begin
      diff_full <= A - B;
      result    <= diff_full[10:0];

   end

endmodule


// ============================================================
// MULTIPLY MODULE
// ============================================================
module mul_module (
    input  wire signed [10:0] A,
    input  wire signed [10:0] B,
    input  wire clk,
    output reg  signed [10:0] result,
    output reg  overflow
);
    wire signed [21:0] mult_full = A * B;

    always @(posedge clk) begin
        result   <= mult_full[10:0];
        overflow <= (mult_full > 22'sd999) || (mult_full < -22'sd999);
    end
endmodule


// ============================================================
// DIVIDE MODULE
// ============================================================

module div_module (
   input  wire signed [10:0] A,
   input  wire signed [10:0] B,
   input  wire clk,
   output reg  signed [10:0] result,
   output reg  div_by_zero
);

   always @(posedge clk) begin
      div_by_zero <= (B == 11'sd0);

      if (B == 11'sd0)
         result <= 11'sd0;
      else
         result <= A / B;
   end

endmodule




// ============================================================
// Module  : seven_seg_display
// Purpose : Display signed 11-bit value on 4-digit 7-seg (Basys 3)
//
// Display format:
//   [DIG3] [DIG2] [DIG1] [DIG0]
//     -      H      T      O
//
// - Handles signed numbers correctly
// - Extracts digits from absolute value
// - Displays '-' on leftmost digit if value < 0
// ============================================================

module seven_seg_display (
    input  wire        clk,
    input  wire  [9:0] value,   // signed result to display
    input  wire        err,
    input  wire        is_neg,
    output reg  [6:0]  seg,             // segment outputs (active low)
    output reg  [3:0]  an               // anode control (active low)
);

    // --------------------------------------------------------
    // Clock divider for multiplexing
    // --------------------------------------------------------
    reg [15:0] refresh_cnt = 0;
    reg [1:0]  digit_sel   = 0;

    always @(posedge clk) begin
        refresh_cnt <= refresh_cnt + 1;
        digit_sel   <= refresh_cnt[15:14];
    end

   

    // --------------------------------------------------------
    // Digit extraction (unsigned only!)
    // --------------------------------------------------------
    reg [3:0] digit;

    wire [3:0] ones     =  value % 10;
    wire [3:0] tens     = (value / 10)  % 10;
    wire [3:0] hundreds = (value / 100) % 10;

    always @(posedge clk) begin
        an <= 4'b1111;
    
        case (digit_sel)
            2'b00: begin
                an <= 4'b1110;
                if (err)
                    digit <= 4'hF;  // blank
                else
                    digit <= ones;
            end
            2'b01: begin
                an <= 4'b1101;
                if (err)
                    digit <= 4'hD;  // 'r'
                else
                    digit <= tens;
            end
            2'b10: begin
                an <= 4'b1011;
                if (err)
                    digit <= 4'hC;  // 'r'
                else
                    digit <= hundreds;
            end
            2'b11: begin
                an <= 4'b0111;
                if (err)
                    digit <= 4'hB;  // 'E'
                else if (is_neg)
                    digit <= 4'hA;  // '-'
                else
                    digit <= 4'hF;  // blank
            end
        endcase
    end

    // --------------------------------------------------------
    // 7-segment decoder (Basys 3, active low)
    // --------------------------------------------------------
    always @(posedge clk) begin
        case (digit)
            4'd0: seg <= 7'b1000000;
            4'd1: seg <= 7'b1111001;
            4'd2: seg <= 7'b0100100;
            4'd3: seg <= 7'b0110000;
            4'd4: seg <= 7'b0011001;
            4'd5: seg <= 7'b0010010;
            4'd6: seg <= 7'b0000010;
            4'd7: seg <= 7'b1111000;
            4'd8: seg <= 7'b0000000;
            4'd9: seg <= 7'b0010000;
            4'hA: seg <= 7'b0111111; // '-'
            4'hB: seg <= 7'b0000110; // 'E'
            4'hC: seg <= 7'b1111010; // 'r'
            4'hD: seg <= 7'b1111010; // 'r'
            default: 
                  seg <= 7'b1111111; // blank
        endcase
    end

endmodule
