module pipe_mul #(
    parameter LATENCY = 2
)(
    input   logic clk,
    input   logic reset_n,
    input   logic clear,

    input   logic [31:0] srcA, srcB,
    input   logic src_vld,

    output  logic [31:0] res,
    output  logic res_vld
);

    logic [31:0]    srcA_reg, srcB_reg;
    logic [63:0]    full_mul;
    logic [LATENCY-1:0][31:0]    pipe_data;
    logic [LATENCY-1:0]          pipe_vld;
    genvar i;

    always_ff @ (posedge clk) begin
        srcA_reg <= srcA;
        srcB_reg <= srcB;
    end

/*Quartus и Questa понимают эту конструкцию, но только не iverilog...*/
    // assign full_mul = srcA_reg * srcB_reg;
    // assign pipe_data[0] = full_mul[31:0];

    always_comb begin
        full_mul = srcA_reg * srcB_reg;
        pipe_data[0] = full_mul[31:0];
    end

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) pipe_vld[0] <= 1'b0;
        else if(clear) pipe_vld[0] <= 1'b0;
        else pipe_vld[0] <= src_vld;
    end


    generate
        for(i = 1; i < LATENCY; i++) begin:gen_mul_pipe

            always_ff @ (posedge clk) begin
                pipe_data[i] <= pipe_data[i-1];
            end

            always_ff @ (posedge clk or negedge reset_n) begin
                if(!reset_n) pipe_vld[i] <= 1'b0;
                else if(clear) pipe_vld[i] <= 1'b0;
                else pipe_vld[i] <= pipe_vld[i-1];
            end
        end
    endgenerate

    assign res = pipe_data[LATENCY-1];
    assign res_vld = pipe_vld[LATENCY-1];


endmodule