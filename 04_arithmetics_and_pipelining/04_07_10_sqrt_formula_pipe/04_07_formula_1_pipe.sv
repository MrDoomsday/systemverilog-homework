//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output reg        res_vld,
    output reg [31:0] res
);
    // Task:
    //
    // Implement a pipelined module formula_1_pipe that computes the result
    // of the formula defined in the file formula_1_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_1_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm
localparam pipe_stages = 16;

reg     [15:0]  sqrt_a_result;
reg             sqrt_a_valid;

reg     [15:0]  sqrt_b_result;
reg             sqrt_b_valid;

reg     [15:0]  sqrt_c_result;
reg             sqrt_c_valid;


isqrt #(
    .n_pipe_stages(pipe_stages)
) isqrt_a (
    .clk    (clk),
    .rst    (rst),

    .x_vld  (arg_vld),
    .x      (a),

    .y_vld  (sqrt_a_valid),
    .y      (sqrt_a_result)
);


isqrt #(
    .n_pipe_stages(pipe_stages)
) isqrt_b (
    .clk    (clk),
    .rst    (rst),

    .x_vld  (arg_vld),
    .x      (b),

    .y_vld  (sqrt_b_valid),
    .y      (sqrt_b_result)
);


isqrt #(
    .n_pipe_stages(pipe_stages)
) isqrt_c (
    .clk    (clk),
    .rst    (rst),

    .x_vld  (arg_vld),
    .x      (c),

    .y_vld  (sqrt_c_valid),
    .y      (sqrt_c_result)
);

wire res_vld_next = sqrt_a_valid | sqrt_b_valid | sqrt_c_valid;

//output
always_ff @ (posedge clk) begin
    if(res_vld_next) res <= {16'h0, sqrt_a_result} + {16'h0, sqrt_b_result} + {16'h0, sqrt_c_result};
end

always_ff @ (posedge clk) begin
    if(rst) res_vld <= 1'b0;
    else res_vld <= res_vld_next;//если вдруг один из модулей дал сбой - остальные не дадут отвала valid'а
end

endmodule
