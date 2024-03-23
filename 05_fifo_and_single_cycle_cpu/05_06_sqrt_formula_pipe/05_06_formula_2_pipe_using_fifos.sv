//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_fifos
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
    // Implement a pipelined module formula_2_pipe_using_fifos that computes the result
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
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 04_10_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    localparam sqrt_pipe_stages = 16;

    //isqrt
    logic [31:0]  isqrt_x_data_0, isqrt_x_data_1, isqrt_x_data_2;
    logic         isqrt_x_vld_0, isqrt_x_vld_1, isqrt_x_vld_2;

    logic [15:0]  isqrt_y_data_0, isqrt_y_data_1, isqrt_y_data_2;
    logic         isqrt_y_vld_0, isqrt_y_vld_1, isqrt_y_vld_2;

    //fifo
    typedef struct packed {
        logic push, pop;
        logic empty, full;
        logic [31:0] wdata, rdata;        
    } sig_fifo;

    sig_fifo sig_fifo_one, sig_fifo_two;

    

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            INSTANCE         ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    flip_flop_fifo_with_counter #(
        .width(32), 
        .depth(sqrt_pipe_stages)
    ) fifo_one (
        .clk        (clk),
        .rst        (rst),
        .push       (sig_fifo_one.push),
        .pop        (sig_fifo_one.pop),
        .write_data (sig_fifo_one.wdata),
        .read_data  (sig_fifo_one.rdata),
        .empty      (sig_fifo_one.empty),
        .full       (sig_fifo_one.full)
    );

    flip_flop_fifo_with_counter #(
        .width(32), 
        .depth(2*sqrt_pipe_stages)
    ) fifo_two (
        .clk        (clk),
        .rst        (rst),
        .push       (sig_fifo_two.push),
        .pop        (sig_fifo_two.pop),
        .write_data (sig_fifo_two.wdata),
        .read_data  (sig_fifo_two.rdata),
        .empty      (sig_fifo_two.empty),
        .full       (sig_fifo_two.full)
    );

    isqrt #(
        .n_pipe_stages(sqrt_pipe_stages)
    ) isqrt_zero (
        .clk    (clk),
        .rst    (rst),

        .x_vld  (isqrt_x_vld_0),
        .x      (isqrt_x_data_0),

        .y_vld  (isqrt_y_vld_0),
        .y      (isqrt_y_data_0)
    );

    isqrt #(
        .n_pipe_stages(sqrt_pipe_stages)
    ) isqrt_one (
        .clk    (clk),
        .rst    (rst),

        .x_vld  (isqrt_x_vld_1),
        .x      (isqrt_x_data_1),

        .y_vld  (isqrt_y_vld_1),
        .y      (isqrt_y_data_1)
    );
    
    isqrt #(
        .n_pipe_stages(sqrt_pipe_stages)
    ) isqrt_two (
        .clk    (clk),
        .rst    (rst),

        .x_vld  (isqrt_x_vld_2),
        .x      (isqrt_x_data_2),

        .y_vld  (isqrt_y_vld_2),
        .y      (isqrt_y_data_2)
    );
    
/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    //isqrt zero
    assign isqrt_x_data_0 = c;
    assign isqrt_x_vld_0 = arg_vld;


    //fifo one
    assign sig_fifo_one.push = arg_vld;
    assign sig_fifo_one.wdata = b;
    assign sig_fifo_one.pop = ~sig_fifo_one.empty & isqrt_y_vld_0;


    //fifo two
    assign sig_fifo_two.push = arg_vld;
    assign sig_fifo_two.wdata = a;
    assign sig_fifo_two.pop = ~sig_fifo_two.empty & isqrt_y_vld_1;


    always_ff @ (posedge clk or posedge rst) begin
        if(rst) begin
            isqrt_x_data_1 <= 32'h0;
            isqrt_x_vld_1 <= 1'b0;
        end
        else begin
            if(sig_fifo_one.pop) isqrt_x_data_1 <= {16'h0, isqrt_y_data_0} + sig_fifo_one.rdata;
            isqrt_x_vld_1 <= sig_fifo_one.pop;
        end
    end

    always_ff @ (posedge clk or posedge rst) begin
        if(rst) begin
            isqrt_x_data_2 <= 32'h0;
            isqrt_x_vld_2 <= 1'b0;
        end
        else begin
            if(sig_fifo_two.pop) isqrt_x_data_2 <= {16'h0, isqrt_y_data_1} + sig_fifo_two.rdata;
            isqrt_x_vld_2 <= sig_fifo_two.pop;
        end
    end


    assign res_vld = isqrt_y_vld_2;
    assign res = {16'h0, isqrt_y_data_2};



endmodule
