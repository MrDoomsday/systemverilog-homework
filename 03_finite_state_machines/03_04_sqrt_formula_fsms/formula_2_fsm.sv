//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_fsm
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

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);
    // Task:
    // Implement a module that calculates the folmula from the `formula_2_fn.svh` file
    // using only one instance of the isrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
enum bit [1:0] 
{
    st_idle,
    st_wait_sqrt_1,//sqrt(c)
    st_wait_sqrt_2,//sqrt(b+sqrt(c))
    st_wait_sqrt_3//sqrt(a + sqrt(b + sqrt(c)))
} state, state_next;

bit [31:0] a_fix, b_fix;


always_ff @ (posedge clk or posedge rst)
    if(rst) state <= st_idle;
    else state <= state_next;

always_comb begin
   state_next = state;
   isqrt_x = c;
   isqrt_x_vld = 1'b0;

   case(state)
    st_idle: begin
        if(arg_vld) begin
            isqrt_x_vld = 1'b1;
            state_next = st_wait_sqrt_1;
        end
    end

    st_wait_sqrt_1: begin
        if(isqrt_y_vld) begin
            isqrt_x_vld = 1'b1;
            isqrt_x = {16'h0, isqrt_y} + b_fix;
            state_next = st_wait_sqrt_2;
        end
    end

    st_wait_sqrt_2: begin
        if(isqrt_y_vld) begin
            isqrt_x_vld = 1'b1;
            isqrt_x = {16'h0, isqrt_y} + a_fix;
            state_next = st_wait_sqrt_3;
        end
    end

    st_wait_sqrt_3: begin
        if(isqrt_y_vld) begin
            state_next = st_idle;
        end
    end

    default: state_next = st_idle;
   endcase
end

always_ff @ (posedge clk) begin
    if((state == st_idle) && arg_vld) begin
        a_fix <= a;
        b_fix = b;
    end

end

always_ff @ (posedge clk or posedge rst)
    if(rst) begin
        res_vld <= 1'b0;
        res <= 32'h0;
    end
    else begin
        res_vld <= (state == st_wait_sqrt_3) & isqrt_y_vld;
        res <= {16'h0, isqrt_y};
    end


endmodule
