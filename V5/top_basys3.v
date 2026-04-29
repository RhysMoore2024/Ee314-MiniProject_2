`timescale 1ns / 1ps
// ============================================================
// TOP-LEVEL BASYS3 CALCULATOR
// ============================================================
// Flow:
//   State 0: Enter A  - set switches, press op button to latch A
//   State 1: Enter B  - set switches, press SAME op to compute
//                       press DIFF op -> flash all LEDs (invalid)
//   State 2: Result   - 7-seg shows result
//   CENTRE (any state) -> reset to state 0
// ============================================================

module top_basys3 (
    input  wire        clk,
    input  wire [15:0] sw,
    input  wire [4:0]  btn,      // [4]=C [3]=U [2]=R [1]=D [0]=L
    output reg  [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an
);

    // --------------------------------------------------------
    // Parameters
    // --------------------------------------------------------
    localparam STATE_A      = 2'b00;
    localparam STATE_B      = 2'b01;
    localparam STATE_RESULT = 2'b10;
    localparam STATE_FLASH  = 2'b11;

    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_DIV = 2'b10;
    localparam OP_MUL = 2'b11;

    localparam BLINK_DURATION = 27'd10_000_000;  // 0.1s on, 0.1s off
    localparam BLINK_COUNT    = 3;

    reg [2:0] blink_num;
    reg       blink_state;

    // --------------------------------------------------------
    // Button debounce
    // --------------------------------------------------------
    parameter DEBOUNCE_MAX = 20'd1_000_000; // 10ms at 100MHz

    reg [19:0] debounce_cnt [4:0];
    reg [4:0]  btn_stable;
    reg [4:0]  btn_prev;
    wire [4:0] btn_pulse;

    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : debounce
            always @(posedge clk) begin
                if (btn[i] == btn_stable[i]) begin
                    debounce_cnt[i] <= 20'd0;
                end else begin
                    debounce_cnt[i] <= debounce_cnt[i] + 1;
                    if (debounce_cnt[i] >= DEBOUNCE_MAX) begin
                        btn_stable[i]   <= btn[i];
                        debounce_cnt[i] <= 20'd0;
                    end
                end
            end
        end
    endgenerate

    always @(posedge clk)
        btn_prev <= btn_stable;

    assign btn_pulse = btn_stable & ~btn_prev;

    wire btn_add   = btn_pulse[3];
    wire btn_sub   = btn_pulse[1];
    wire btn_mul   = btn_pulse[2];
    wire btn_div   = btn_pulse[0];
    wire any_op    = btn_add | btn_sub | btn_mul | btn_div;

    // --------------------------------------------------------
    // Operand mapping: magnitude + sign
    // sw[7]    = sign for A, sw[6:0]  = magnitude
    // sw[15]   = sign for B, sw[14:8] = magnitude
    // --------------------------------------------------------
    wire signed [10:0] A = sw[7]  ? -{{4{1'b0}}, sw[6:0]}  : {{4{1'b0}}, sw[6:0]};
    wire signed [10:0] B = sw[15] ? -{{4{1'b0}}, sw[14:8]} : {{4{1'b0}}, sw[14:8]};

    // --------------------------------------------------------
    // State registers
    // --------------------------------------------------------
    reg [1:0]          state;
    reg [1:0]          mode;
    reg signed [10:0]  latch_A;
    reg signed [10:0]  latch_B;
    reg [26:0]         flash_cnt;
    reg [1:0]          return_state;
    reg                calc_done;

    // --------------------------------------------------------
    // ALU wires
    // --------------------------------------------------------
    wire signed [10:0] result;
    wire               overflow;
    wire               div_by_zero;

    Main alu (
        .clk        (clk),
        .reset      (1'b0),
        .A          (latch_A),
        .B          (latch_B),
        .mode       (mode),
        .result     (result),
        .overflow   (overflow),
        .div_by_zero(div_by_zero)
    );

    // --------------------------------------------------------
    // 7-seg display logic
    // --------------------------------------------------------
    wire err = calc_done && (mode == OP_DIV) && div_by_zero;

    wire signed [10:0] result_abs = result[10] ? -result : result;

    reg [9:0] disp_mag;
    reg       disp_neg;

    always @(posedge clk) begin
        case (state)
            STATE_A: begin
                disp_mag <= sw[6:0];
                disp_neg <= sw[7];
            end
            STATE_B: begin
                disp_mag <= sw[14:8];
                disp_neg <= sw[15];
            end
            STATE_RESULT: begin
                if (overflow)
                disp_mag <= 10'd999;
                else
                disp_mag <= result_abs[9:0];
                disp_neg <= result[10];
            end
            default: begin
                disp_mag <= 10'd0;
                disp_neg <= 1'b0;
            end
        endcase
    end

    seven_seg_display disp (
        .clk   (clk),
        .value (disp_mag),
        .is_neg(disp_neg),
        .err   (err),
        .seg   (seg),
        .an    (an)
    );

    // --------------------------------------------------------
    // State machine (synchronous active high reset)
    // --------------------------------------------------------
    always @(posedge clk) begin

        if (btn[4]) begin
            state       <= STATE_A;
            latch_A     <= 11'sd0;
            latch_B     <= 11'sd0;
            mode        <= OP_ADD;
            flash_cnt   <= 27'd0;
            blink_num   <= 3'd0;
            blink_state <= 1'b0;
            calc_done   <= 1'b0;
        end

        else begin
            case (state)

                // ---- State 0: Enter A ----
                STATE_A: begin
                    if (any_op) begin
                        latch_A   <= A;
                        calc_done <= 1'b0;
                        if      (btn_add) mode <= OP_ADD;
                        else if (btn_sub) mode <= OP_SUB;
                        else if (btn_mul) mode <= OP_MUL;
                        else if (btn_div) mode <= OP_DIV;
                        state <= STATE_B;
                    end
                end

                // ---- State 1: Enter B ----
                STATE_B: begin
                    if (any_op) begin
                        if ((mode == OP_ADD && btn_add) ||
                            (mode == OP_SUB && btn_sub) ||
                            (mode == OP_MUL && btn_mul) ||
                            (mode == OP_DIV && btn_div)) begin
                            latch_B   <= B;
                            calc_done <= 1'b1;
                            state     <= STATE_RESULT;
                        end else begin
                            flash_cnt    <= 27'd0;
                            blink_num    <= 3'd0;
                            blink_state  <= 1'b0;
                            return_state <= STATE_B;
                            state        <= STATE_FLASH;
                        end
                    end
                end

                // ---- State 2: Show result ----
                STATE_RESULT: begin
                    if (any_op) begin
                        latch_A   <= A;
                        calc_done <= 1'b0;
                        if      (btn_add) mode <= OP_ADD;
                        else if (btn_sub) mode <= OP_SUB;
                        else if (btn_mul) mode <= OP_MUL;
                        else if (btn_div) mode <= OP_DIV;
                        state <= STATE_B;
                    end
                end

                // ---- State 3: Flash LEDs ----
                STATE_FLASH: begin
                    flash_cnt <= flash_cnt + 1;
                    if (flash_cnt >= BLINK_DURATION) begin
                        flash_cnt   <= 27'd0;
                        blink_state <= ~blink_state;
                        if (blink_state == 1'b1) begin
                            blink_num <= blink_num + 1;
                            if (blink_num >= BLINK_COUNT - 1) begin
                                blink_num   <= 3'd0;
                                blink_state <= 1'b0;
                                state       <= return_state;
                            end
                        end
                    end
                end

            endcase
        end
    end

    // --------------------------------------------------------
    // LED control
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (state == STATE_FLASH && blink_state == 1'b1)
            led <= 16'hFFFF;
        else if (state == STATE_FLASH && blink_state == 1'b0)
            led <= 16'h0000;
        else begin
            led[7:0]  <= sw[7:0];
            led[15:8] <= sw[15:8];
        end
    end

endmodule
