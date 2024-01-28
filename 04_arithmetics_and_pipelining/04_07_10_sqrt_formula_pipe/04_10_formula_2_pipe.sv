//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);
    // Task:
    //
    // Implement a pipelined module formula_2_pipe that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
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


//STAGE 0

logic [31:0] a_stage_zero [0:pipe_stages-1];
logic [31:0] b_stage_zero [0:pipe_stages-1];
wire         sqrt_c_valid;
wire [15:0]  sqrt_c_result;


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

always_ff @ (posedge clk) begin
    a_stage_zero[0] <= a;
    b_stage_zero[0] <= b;
    
    for(int i = 1; i < pipe_stages; i++) begin
        a_stage_zero[i] <= a_stage_zero[i-1];
        b_stage_zero[i] <= b_stage_zero[i-1];
    end
end


//STAGE 1
logic [31:0] a_stage_one [0:pipe_stages-1];
wire         sqrt_bc_valid;
wire [15:0]  sqrt_bc_result;

isqrt #(
    .n_pipe_stages(pipe_stages)
) isqrt_b_plus_sqrt_c (
    .clk    (clk),
    .rst    (rst),

    .x_vld  (sqrt_c_valid),
    .x      (b_stage_zero[pipe_stages-1] + {16'h0, sqrt_c_result}),

    .y_vld  (sqrt_bc_valid),
    .y      (sqrt_bc_result)
);

always_ff @ (posedge clk) begin
    a_stage_one[0] <= a_stage_zero[pipe_stages-1];
    
    for(int i = 1; i < pipe_stages; i++) begin
        a_stage_one[i] <= a_stage_one[i-1];
    end
end


//STAGE 2

isqrt #(
    .n_pipe_stages(pipe_stages)
) isqrt_a_plus_isqrt_b_plus_sqrt_c (
    .clk    (clk),
    .rst    (rst),

    .x_vld  (sqrt_bc_valid),
    .x      (a_stage_one[pipe_stages-1] + {16'h0, sqrt_bc_result}),

    .y_vld  (res_vld),
    .y      (res[15:0])
);

assign res[31:16] = 16'h0;

endmodule
