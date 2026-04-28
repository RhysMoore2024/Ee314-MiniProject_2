module top_basys3 (
    input  wire        clk,
    input  wire [15:0]  sw,
    input  wire [4:0]   btn,      // U D L R C
    output wire [15:0]  led,
    output wire [6:0]   seg,
    output wire [3:0]   an
);

    // ----------------------------------------------------
    // Operand mapping (8-bit signed)
    // ----------------------------------------------------
    wire signed [7:0] A8 = sw[7:0];
    wire signed [7:0] B8 = sw[15:8];

    // Sign-extend to 10-bit for ALU
    wire signed [10:0] A = {{3{A8[7]}}, A8};
    wire signed [10:0] B = {{3{B8[7]}}, B8};

    // ----------------------------------------------------
    // Mirror switch values on LEDs
    // ----------------------------------------------------
    assign led[7:0]  = sw[7:0];    // A
    assign led[15:8] = sw[15:8];   // B

    // ----------------------------------------------------
    // Operation select (direction buttons)
    // BTN_U = ADD
    // BTN_D = SUB
    // BTN_R = MUL
    // BTN_L = DIV
    // ----------------------------------------------------
    reg [1:0] mode;

    always @(posedge clk) begin
        if      (btn[3]) mode = 2'b00; // UP    -> ADD (T18)
        else if (btn[1]) mode = 2'b01; // DOWN  -> SUB (U17)
        else if (btn[0]) mode = 2'b10; // LEFT  -> DIV (W19)
        else if (btn[2]) mode = 2'b11; // RIGHT -> MUL (T17)
        else             mode = 2'b00;
    end

    // ----------------------------------------------------
    // ALU instance
    // ----------------------------------------------------
    wire signed [10:0] result;
    wire overflow, div_by_zero;

    adder_subtractor_divider alu (
        .A(A),
        .B(B),
        .mode(mode),
        .result(result),
        .overflow(overflow),
        .div_by_zero(div_by_zero),
        .clk(clk)
    );

    // ----------------------------------------------------
    // Display result on 7-seg
    // ----------------------------------------------------
    seven_seg_display disp (
        .clk(clk),
        .value(result),
        .seg(seg),
        .an(an)
    );

endmodule
