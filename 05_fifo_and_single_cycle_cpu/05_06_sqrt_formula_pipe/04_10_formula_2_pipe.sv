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



/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    // NOTHING TO DO HERE
    localparam sqrt_pipe_stages = 16;

    //isqrt
    bit [2:0][31:0]  isqrt_x_data;
    bit [2:0]        isqrt_x_vld;

    bit [2:0][15:0]  isqrt_y_data;
    bit [2:0]        isqrt_y_vld;

    //fifo
    typedef struct packed {
        bit push, pop;
        bit empty, full;
        bit [31:0] wdata, rdata;        
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

        .x_vld  (isqrt_x_vld[0]),
        .x      (isqrt_x_data[0]),

        .y_vld  (isqrt_y_vld[0]),
        .y      (isqrt_y_data[0])
    );

    isqrt #(
        .n_pipe_stages(sqrt_pipe_stages)
    ) isqrt_one (
        .clk    (clk),
        .rst    (rst),

        .x_vld  (isqrt_x_vld[1]),
        .x      (isqrt_x_data[1]),

        .y_vld  (isqrt_y_vld[1]),
        .y      (isqrt_y_data[1])
    );
    
    isqrt #(
        .n_pipe_stages(sqrt_pipe_stages)
    ) isqrt_two (
        .clk    (clk),
        .rst    (rst),

        .x_vld  (isqrt_x_vld[2]),
        .x      (isqrt_x_data[2]),

        .y_vld  (isqrt_y_vld[2]),
        .y      (isqrt_y_data[2])
    );
    
/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    //isqrt zero
    assign isqrt_x_data[0] = c;
    assign isqrt_x_vld[0] = arg_vld;


    //fifo one
    assign sig_fifo_one.push = arg_vld;
    assign sig_fifo_one.wdata = b;
    assign sig_fifo_one.pop = ~sig_fifo_one.empty & isqrt_y_vld[0];


    //fifo two
    assign sig_fifo_two.push = arg_vld;
    assign sig_fifo_two.wdata = a;
    assign sig_fifo_two.pop = ~sig_fifo_two.empty & isqrt_y_vld[1];


    always_ff @ (posedge clk or posedge rst) begin
        if(rst) begin
            isqrt_x_data[1][31:0] <= 32'h0;
            isqrt_x_vld[1] <= 1'b0;
        end
        else begin
            if(sig_fifo_one.pop) isqrt_x_data[1] <= {16'h0, isqrt_y_data[0]} + sig_fifo_one.rdata;
            isqrt_x_vld[1] <= sig_fifo_one.pop;
        end
    end

    always_ff @ (posedge clk or posedge rst) begin
        if(rst) begin
            isqrt_x_data[2] <= 32'h0;
            isqrt_x_vld[2] <= 1'b0;
        end
        else begin
            if(sig_fifo_two.pop) isqrt_x_data[2] <= {16'h0, isqrt_y_data[1]} + sig_fifo_two.rdata;
            isqrt_x_vld[2] <= sig_fifo_two.pop;
        end
    end


    assign res_vld = isqrt_y_vld[2];
    assign res = {16'h0, isqrt_y_data[2][15:0]};


endmodule
