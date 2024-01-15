//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_impl_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

    // Task:
    // Implement a module that calculates the folmula from the `formula_1_fn.svh` file
    // using two instances of the isqrt module in parallel.
    //
    // Design the FSM to calculate an answer and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

// declaration
    enum bit [1:0] 
    {
        st_idle,
        st_wait_ab_res,
        st_wait_c_res
    } state, state_next;

bit [31:0] c_fix;//временно храним переменную C 
bit [31:0] sum_sqrt_a_plus_b;//хранение промежуточного результата

// logic
always_ff @ (posedge clk or posedge rst)
    if(rst) state <= st_idle;
    else state <= state_next;


always_comb begin
    state_next = state;
    isqrt_1_x_vld = 1'b0;
    isqrt_1_x = a;
    isqrt_2_x_vld = 1'b0;
    isqrt_2_x = b;

    case(state)
        st_idle: begin
            if(arg_vld) begin
                isqrt_1_x_vld = 1'b1;
                isqrt_2_x_vld = 1'b1;
                state_next = st_wait_ab_res;
            end
        end

        st_wait_ab_res: begin
            if(isqrt_1_y_vld && isqrt_2_y_vld) begin//задержки на вычисление одинаковые, в случае разных задержек вычисления (либо плавающих) пришлось бы добавить еще несколько состояний.
                isqrt_1_x = c_fix;
                isqrt_1_x_vld = 1'b1;
                state_next = st_wait_c_res;
            end
        end

        st_wait_c_res: begin
            if(isqrt_1_y_vld) begin
                state_next = st_idle;
            end
        end

        default: state_next = st_idle;
    endcase
end



always_ff @ (posedge clk) begin
    if((state == st_idle) && arg_vld) c_fix <= c;
    if((state == st_wait_ab_res) && isqrt_1_y_vld && isqrt_2_y_vld) sum_sqrt_a_plus_b <= {16'h0, isqrt_1_y} + {16'h0, isqrt_2_y};//extend to 32-bit number
    if((state == st_wait_c_res) && isqrt_1_y_vld) res <= sum_sqrt_a_plus_b + {16'h0, isqrt_1_y};
end


always_ff @ (posedge clk or posedge rst)
    if(rst) res_vld <= 1'b0;
    else res_vld <= (state == st_wait_c_res) & isqrt_1_y_vld;





endmodule
