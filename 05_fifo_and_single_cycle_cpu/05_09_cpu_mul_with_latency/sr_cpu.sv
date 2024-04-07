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

module sr_cpu
(
    input           clk,      // clock
    input           rst,      // reset

    output  [31:0]  imAddr,   // instruction memory address
    input   [31:0]  imData,   // instruction memory data

    input   [ 4:0]  regAddr,  // debug access reg address
    output  [31:0]  regData   // debug access reg data
);
    // control wires

    wire            aluZero;
    wire            regWrite;
    wire  [2:0]     aluControl;
    logic           pc_en;
    logic           ir_en;
    logic [31:0]    instr;

    // instruction decode wires
    wire [ 6:0] cmdOp;
    wire [ 4:0] rd;
    wire [ 2:0] cmdF3;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 6:0] cmdF7;
    wire [31:0] immI;
    wire [31:0] immB;
    wire [31:0] immU;

    // program counter
    logic   [31:0]  pc, pc_next;
    logic   [31:0]  pc_old;//адрес текущей инструкции, которая обрабатыввется процессором
    logic   [1:0]   pc_sel;
    wire    [31:0]  pc_plus4 = pc_old + 32'd4;
    wire    [31:0]  pc_branch = pc_old + immB;

    // ALU or MDU
    logic [31:0]    rd1_reg, rd2_reg;//выходные данные из регистрового файла
    logic [1:0]     srcA_sel, srcB_sel;//мультиплексоры для входных операндов АЛУ
    logic [31:0]    srcA, srcB;

    logic           mdu_clear, mdu_vld_in, mdu_vld_out;
    logic [2:0]     mdu_op;
    logic [31:0]    alu_res, mdu_res;
    logic [31:0]    alu_r, mdu_r;//защелкнутые в регистры результаты с АЛУ и блоков умножения

    //register file
    logic [2:0] wd_sel;

    always_comb begin
        case(pc_sel)
            2'b00: pc_next = pc_plus4;
            2'b01: pc_next = alu_r;
            2'b10: pc_next = pc_branch;
            default: pc_next = pc_plus4;
        endcase
    end

    register_with_rst #(
        .WIDTH_DATA(32)
    ) r_pc (
        .clk    (clk    ), 
        .rst    (rst    ),
        .d      (pc_next), 
        .en     (pc_en  ),
        .q      (pc     )
    );

    // program memory access
    assign imAddr = pc >> 2;

    register_with_rst #(
        .WIDTH_DATA(64)
    ) r_instr (
        .clk    (clk            ), 
        .rst    (rst            ),
        .d      ({pc, imData}   ), 
        .en     (ir_en          ),
        .q      ({pc_old, instr})
    );


    // instruction decode

    sr_decode id
    (
        .instr      ( instr       ),
        .cmdOp      ( cmdOp       ),
        .rd         ( rd          ),
        .cmdF3      ( cmdF3       ),
        .rs1        ( rs1         ),
        .rs2        ( rs2         ),
        .cmdF7      ( cmdF7       ),
        .immI       ( immI        ),
        .immB       ( immB        ),
        .immU       ( immU        )
    );

    // register file

    wire [31:0] rd0;
    wire [31:0] rd1;
    wire [31:0] rd2;
    logic [31:0] wd3;

    sr_register_file rf
    (
        .clk        ( clk         ),
        .a0         ( regAddr     ),
        .a1         ( rs1         ),
        .a2         ( rs2         ),
        .a3         ( rd          ),
        .rd0        ( rd0         ),
        .rd1        ( rd1         ),
        .rd2        ( rd2         ),
        .wd3        ( wd3         ),
        .we3        ( regWrite    )
    );


    always_ff @ (posedge clk) begin
        rd2_reg <= rd2;
        rd1_reg <= rd1;
    end

    // alu
    always_comb begin
        case(srcA_sel)
            2'b00:     srcA = rd1_reg;
            2'b01:     srcA = pc_old;
            2'b10:     srcA = 32'h0;
            default:   srcA = 32'h0;
        endcase

        case(srcB_sel)
            2'b00:     srcB = rd2_reg;
            2'b01:     srcB = immI;//immediate
            2'b10:     srcB = immB;//branch
            2'b11:     srcB = immU;//upper immediate
            default:   srcB = 32'h0;
        endcase
    end

    sr_alu alu
    (
        .srcA       ( srcA        ),
        .srcB       ( srcB        ),
        .oper       ( aluControl  ),
        .zero       ( aluZero     ),
        .result     ( alu_res     )
    );


    sr_mdu #(
        .MUL_LATENCY(`MUL_LATENCY)
    ) mdu (
        .clk        (clk        ),
        .reset_n    (~rst       ),

        .srcA       (srcA       ),
        .srcB       (srcB       ),
        .src_vld    (mdu_vld_in ),
        .src_clear  (mdu_clear  ),
        .op         (mdu_op     ),
        .result     (mdu_res    ),
        .result_vld (mdu_vld_out)
    );

    always_ff @ (posedge clk) begin
        alu_r <= alu_res;
        mdu_r <= mdu_res;
    end

    always_comb begin
        case(wd_sel)
            3'b000: wd3 = alu_r;
            3'b001: wd3 = mdu_r;
            default: wd3 = alu_r;
        endcase
    end

    // control
    sr_control sm_control (
        .clk(clk),
        .reset_n(~rst),

        .cmdOp      ( cmdOp       ),
        .cmdF3      ( cmdF3       ),
        .cmdF7      ( cmdF7       ),
        .aluZero    ( aluZero     ),
        .regWrite   ( regWrite    ),
        .aluControl ( aluControl  ),


    
        .pc_en      (pc_en      ), 
        .pc_sel     (pc_sel     ),
        .ir_en      (ir_en      ),
        .srcA_sel   (srcA_sel   ), 
        .srcB_sel   (srcB_sel   ),
        .mdu_clear  (mdu_clear  ), 
        .mdu_vld_in (mdu_vld_in ),
        .mdu_vld_out(mdu_vld_out),
        .mdu_op     (mdu_op     ),
        .wd_sel     (wd_sel     )
    );




    // debug register access
    assign regData = (regAddr != '0) ? rd0 : pc;

endmodule
