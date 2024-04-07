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

module register_with_rst #(
    parameter WIDTH_DATA = 32
)(
    input                           clk,
    input                           rst,
    input        [WIDTH_DATA-1:0]   d,
    input                           en,
    output logic [WIDTH_DATA-1:0]   q
);

    always_ff @ (posedge clk)
        if (rst) q <= {WIDTH_DATA{1'b0}};
        else if(en) q <= d;

endmodule
