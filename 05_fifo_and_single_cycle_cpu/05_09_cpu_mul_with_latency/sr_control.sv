//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Yuri Panchul & Mike Kuskov
//  for systemverilog-homework project.
//

`include "sr_cpu.svh"

module sr_control
(
    input logic clk,
    input logic reset_n,

    input        [6:0]  cmdOp,
    input        [2:0]  cmdF3,
    input        [6:0]  cmdF7,
    input               aluZero,
    output  logic       regWrite,
    output  logic [2:0] aluControl,
    
    output  logic       pc_en, ir_en,
    output  logic [1:0] pc_sel,
    output  logic [1:0] srcA_sel, srcB_sel,
    output  logic       mdu_clear, mdu_vld_in,
    input   logic       mdu_vld_out,
    output  logic [2:0] mdu_op,
    output  logic [2:0] wd_sel

);

    wire detect_add = { cmdF7, cmdF3, cmdOp } == { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  };
    wire detect_or = { cmdF7, cmdF3, cmdOp } == { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   };
    wire detect_srl = { cmdF7, cmdF3, cmdOp } == { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  };
    wire detect_sltu = { cmdF7, cmdF3, cmdOp } == { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU };
    wire detect_sub = { cmdF7, cmdF3, cmdOp } == { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  };
    wire detect_mul = { cmdF7, cmdF3, cmdOp } == { `RVF7_MUL,  `RVF3_MUL,  `RVOP_MUL  };

    wire detect_addi = {/* cmdF7, */cmdF3, cmdOp } == {/* `RVF7_ANY,  */`RVF3_ADDI, `RVOP_ADDI };
    
    wire detect_lui = {/* cmdF7, cmdF3, */cmdOp } == {/* `RVF7_ANY,  `RVF3_ANY,  */`RVOP_LUI  };

    wire detect_beq = { /*cmdF7, */cmdF3, cmdOp } == { /*`RVF7_ANY,  */`RVF3_BEQ,  `RVOP_BEQ  };
    wire detect_bne = { /*cmdF7, */cmdF3, cmdOp } == { /*`RVF7_ANY,  */`RVF3_BNE,  `RVOP_BNE  };

    wire instr_r = detect_add || detect_or || detect_srl || detect_sltu || detect_sub || detect_mul;
    wire instr_i = detect_addi;
    wire instr_u = detect_lui;
    wire instr_b = detect_beq | detect_bne;

    enum bit [3:0] {
        FETCH = 0,
        DECODE = 1,
        EXECUTE_R = 2,
        EXECUTE_I = 3,
        EXECUTE_U = 4,
        EXECUTE_B = 5,
        ALUWB = 6,
        BRANCH = 7
    } state, state_next;

    logic aluZero_reg;

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) state <= FETCH;
        else state <= state_next;
    end


    always_comb begin
        state_next = state;

        regWrite = 1'b0;
        aluControl = 3'b0;
        
        pc_en = 1'b0;
        pc_sel = 2'b0;
        ir_en = 1'b0;
        srcA_sel = 2'b0;
        srcB_sel = 2'b0;
        mdu_clear = 1'b0; 
        mdu_vld_in = 1'b0;
        mdu_op = 3'h0;
        wd_sel = 3'h0;


        case(state)
            FETCH: begin
                ir_en = 1'b1;
                state_next = DECODE;
            end

            DECODE: begin
                if(instr_r) begin
                    state_next = EXECUTE_R;
                end
                else if(instr_i) begin
                    state_next = EXECUTE_I;
                end
                else if(instr_u) begin
                    state_next = EXECUTE_U;
                end
                else if(instr_b) begin
                    state_next = EXECUTE_B;
                end
                else begin
                    state_next = state;//в случае отсутствующей команды попадаем в бесконечный цикл
                end
            end

            EXECUTE_R: begin
                if(detect_mul) begin
                    mdu_vld_in = 1'b1;
                    mdu_op = 3'h0;
                    if(mdu_vld_out) begin
                        state_next = ALUWB;
                    end
                end
                else  begin
                    srcA_sel = 2'b0;
                    srcB_sel = 2'b0;
                    if(detect_add)          aluControl = `ALU_ADD;
                    else if(detect_or)      aluControl = `ALU_OR;
                    else if(detect_srl)     aluControl = `ALU_SRL;
                    else if(detect_sltu)    aluControl = `ALU_SLTU;
                    else if(detect_sub)     aluControl = `ALU_SUB;
                    state_next = ALUWB;
                end
            end

            EXECUTE_I: begin
                if(detect_addi) begin
                    srcA_sel = 2'b00;
                    srcB_sel = 2'b01;
                    aluControl = `ALU_ADD;
                end
                state_next = ALUWB;
            end

            EXECUTE_U: begin
                if(detect_lui) begin
                    srcA_sel = 2'b10;
                    srcB_sel = 2'b11;
                    aluControl = `ALU_ADD;
                end
                state_next = ALUWB;
            end

            EXECUTE_B: begin
                aluControl = `ALU_SUB;
                srcA_sel = 2'b00;
                srcB_sel = 2'b00;

                state_next = BRANCH;//потом удалим
            end

            BRANCH: begin
                pc_en = 1'b1;

                if(detect_beq) begin
                    if(aluZero_reg) begin
                        pc_sel = 2'b10;
                    end
                    else begin
                        pc_sel = 2'b00;
                    end
                end
                else if(detect_bne) begin
                    if(aluZero_reg) begin
                        pc_sel = 2'b00;
                    end
                    else begin
                        pc_sel = 2'b10;
                    end
                end

                state_next = FETCH;
            end

            ALUWB: begin
                regWrite = 1'b1;

                if(detect_mul) wd_sel = 3'b001;
                else wd_sel = 3'b000;

                pc_en = 1'b1;
                pc_sel = 2'b0;
                
                state_next = FETCH;
            end
            
            default: begin
                state_next = FETCH;
            end
        endcase

    end

    always_ff @ (posedge clk) begin
        aluZero_reg <= aluZero;
    end

endmodule
