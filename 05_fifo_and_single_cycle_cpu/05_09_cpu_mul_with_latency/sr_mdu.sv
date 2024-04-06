
module sr_mdu #(
    parameter MUL_LATENCY = 2
)(
    input   logic clk,
    input   logic reset_n,

    input        [31:0] srcA,
    input        [31:0] srcB,
    input               src_vld,
    input               src_clear,
    input        [ 2:0] op,
    output logic [31:0] result,
    output logic        result_vld
);


    bit mul_vld;
    bit [31:0] mul_res;


    pipe_mul #(
        .LATENCY(MUL_LATENCY)
    ) mul_inst (
        .clk        (clk),
        .reset_n    (reset_n),
        .clear      (src_clear),

        .srcA       (srcA), 
        .srcB       (srcB),
        .src_vld    (src_vld & (op == 3'b000)),

        .res        (mul_vld),
        .res_vld    (mul_res)
    ); 


/*
    opcode:
    3'b000 - MULT
*/


/*перспектива для ввода деления и т.д.*/
    always_comb begin
        result = 32'h0;
        result_vld = 1'b0;
        case(op)
            3'b000: begin
                result = mul_res;
                result_vld = mul_vld;
            end
            default: begin
                result = 32'h0;
                result_vld = 1'b0;            
            end
        endcase
    end


endmodule
