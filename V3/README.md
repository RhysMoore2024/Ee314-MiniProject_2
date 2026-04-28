This is the third version with these features added
1. Debounce
2. Swap A and B buttons to make more sense
3. Renamed Adder_Subtractor to Main.v for simplicity, same for the Testbench (Main_tb.v)

New Flow
INPUTS
btn[4] = CENTRE    -> reset from anywhere
btn[3] = UP        -> ADD
btn[1] = DOWN      -> SUB
btn[2] = RIGHT     -> MUL
btn[0] = LEFT      -> DIV

FLOW
State 0 (enter A)  -> 7-seg shows live switch value
                      press op button -> latch A, record op, go to state 1

State 1 (enter B)  -> 7-seg shows live switch value
                      press SAME op  -> latch B, compute, go to state 2
                      press DIFF op  -> all LEDs flash ~0.5s, stay in state 1

State 2 (result)   -> 7-seg shows result
                      press CENTRE   -> reset to state 0

CENTRE (any state) -> reset to state 0

LEDs
Normal             -> mirrors switches (A on led[7:0], B on led[15:8])
Invalid button     -> all 16 LEDs on for ~0.5s
