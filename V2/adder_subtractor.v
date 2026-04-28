
// ============================================================
// TOP-LEVEL ARITHMETIC MODULE
// mode:
// 00 -> Add
// 01 -> Subtract
// 10 -> Divide
// 11 -> Multiply
// ============================================================
module adder_subtractor_divider (
   input  wire clk,
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

   wire add_overflow;
   wire sub_overflow;
   wire mul_overflow;
   wire div_zero_flag;

   // ---------------- Module instances ----------------
   add_module ADDER (
       .A(A),
       .B(B),
       .result(add_result),
       .overflow(add_overflow)
   );

   sub_module SUBTRACTOR (
       .A(A),
       .B(B),
       .result(sub_result),
       .overflow(sub_overflow)
   );

   mul_module MULTIPLIER (
       .A(A),
       .B(B),
       .result(mul_result),
       .overflow(mul_overflow)
   );

   div_module DIVIDER (
       .A(A),
       .B(B),
       .result(div_result),
       .div_by_zero(div_zero_flag)
   );

   // ---------------- Select operation ----------------
   always @(posedge clk) begin
       result      <= 11'sd0;
       overflow    <= 1'b0;
       div_by_zero <= 1'b0;

       case (mode)

           2'b00: begin
               result   <= add_result;
               overflow <= add_overflow;
           end

           2'b01: begin
               result   <= sub_result;
               overflow <= sub_overflow;
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

endmodule



// ============================================================
// ADD MODULE
// ============================================================
module add_module (
   input  wire signed [10:0] A,
   input  wire signed [10:0] B,
   output wire signed [10:0] result,
   output wire overflow
);

   assign result = A + B;

   assign overflow = (~A[10] & ~B[10] &  result[10]) |
                     ( A[10] &  B[10] & ~result[10]);

endmodule


// ============================================================
// SUBTRACT MODULE
// ============================================================
module sub_module (
   input  wire signed [10:0] A,
   input  wire signed [10:0] B,
   output wire signed [10:0] result,
   output wire overflow
);

   assign result = A - B;

   assign overflow = (~A[10] &  B[10] &  result[10]) |
                     ( A[10] & ~B[10] & ~result[10]);

endmodule


// ============================================================
// MULTIPLY MODULE
// ============================================================
module mul_module (
   input  wire signed [10:0] A,
   input  wire signed [10:0] B,
   output wire signed [10:0] result,
   output wire overflow
);

   wire signed [21:0] mult_full;

   assign mult_full = A * B;

   assign result = mult_full[10:0];

   // Check if 22-bit result fits into signed 11-bit result
   assign overflow = (mult_full[21:11] != {11{mult_full[10]}});

endmodule


// ============================================================
// DIVIDE MODULE
// ============================================================
module div_module (
   input  wire signed [10:0] A,
   input  wire signed [10:0] B,
   output wire signed [10:0] result,
   output wire div_by_zero
);

   assign div_by_zero = (B == 11'sd0);

   assign result = div_by_zero ? 11'sd0 : A / B;

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
    input  wire signed [10:0] value,   // signed result to display
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
    // Absolute value handling (CRITICAL FIX)
    // --------------------------------------------------------
    reg signed [10:0] abs_val;
    reg is_negative;

    always @(posedge clk) begin
        if (value < 0) begin
            abs_val     = -value;
            is_negative = 1'b1;
        end else begin
            abs_val     = value;
            is_negative = 1'b0;
        end
    end

    // --------------------------------------------------------
    // Digit extraction (unsigned only!)
    // --------------------------------------------------------
    reg [3:0] digit;

    wire [3:0] ones     =  abs_val % 10;
    wire [3:0] tens     = (abs_val / 10)  % 10;
    wire [3:0] hundreds = (abs_val / 100) % 10;

    always @(posedge clk) begin
        an = 4'b1111;         // default all digits off

        case (digit_sel)
            2'b00: begin
                an    = 4'b1110;  // rightmost digit
                digit = ones;
            end
            2'b01: begin
                an    = 4'b1101;
                digit = tens;
            end
            2'b10: begin
                an    = 4'b1011;
                digit = hundreds;
            end
            2'b11: begin
                an = 4'b0111;     // leftmost digit
                if (is_negative)
                    digit = 4'hA; // minus sign
                else
                    digit = 4'hF; // blank
            end
        endcase
    end

    // --------------------------------------------------------
    // 7-segment decoder (Basys 3, active low)
    // --------------------------------------------------------
    always @(posedge clk) begin
        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            4'hA: seg = 7'b0111111; // '-' minus sign
            default: seg = 7'b1111111; // blank
        endcase
    end

endmodule
