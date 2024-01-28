//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
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
    //
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm
enum bit [2:0] 
{
    SEND_A, 
    SEND_B, 
    SEND_C
} state_in, state_in_next;

//вообще нам ничего не сказано про то, будут ли держаться a,b,c несколько тактов, поэтому фиксируем в регистрах на всякий случай
reg [31:0] b_reg, c_reg;

enum bit [2:0] 
{
    REC_RES_A, 
    REC_RES_B, 
    REC_RES_C
} state_out, state_out_next;

/********************************************************************************************************************/
/********************************************************************************************************************/
/*********************************************    SENDER   **********************************************************/
/********************************************************************************************************************/
/********************************************************************************************************************/

always_ff @ (posedge clk) begin
    if(rst) state_in <= SEND_A;
    else state_in <= state_in_next;
end

always_comb begin
    state_in_next = state_in;

    isqrt_x_vld = 1'b0;
    isqrt_x = a;

    case(state_in)
        SEND_A: begin
            if(arg_vld) begin
                isqrt_x = a;
                isqrt_x_vld = 1'b1;
                state_in_next = SEND_B;
            end
        end

        SEND_B: begin
            isqrt_x = b_reg;
            isqrt_x_vld = 1'b1;
            state_in_next = SEND_C;
        end

        SEND_C: begin
            isqrt_x = c_reg;
            isqrt_x_vld = 1'b1;
            state_in_next = SEND_A;
        end

        default: begin
            state_in_next = SEND_A;
        end
    endcase
end


always_ff @ (posedge clk) begin
    if((state_in == SEND_A) && arg_vld) begin
        b_reg <= b;
        c_reg <= c;
    end
end



/********************************************************************************************************************/
/********************************************************************************************************************/
/*********************************************  RECEIVER   **********************************************************/
/********************************************************************************************************************/
/********************************************************************************************************************/

always_ff @ (posedge clk) begin
    if(rst) state_out <= REC_RES_A;
    else state_out <= state_out_next;
end


always_comb begin
    state_out_next = state_out;

    case(state_out)
        REC_RES_A: begin
            if(isqrt_y_vld) begin
                state_out_next = REC_RES_B;
            end
        end

        REC_RES_B: begin
            if(isqrt_y_vld) begin
                state_out_next = REC_RES_C;
            end
        end
        
        REC_RES_C: begin
            if(isqrt_y_vld) begin
                state_out_next = REC_RES_A;
            end
        end

        default: begin
            state_out_next = REC_RES_A;
        end
    endcase
end


always_ff @ (posedge clk) begin
    if(rst) res_vld <= 1'b0;
    else res_vld <= (state_out == REC_RES_C) && isqrt_y_vld;
end

always_ff @ (posedge clk) begin
    if(isqrt_y_vld) begin
        if(state_out == REC_RES_A) res <= {16'h0, isqrt_y};
        else res <= res + {16'h0, isqrt_y};
    end
end



endmodule
