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

module instruction_rom
#(
    parameter SIZE = 64,
    parameter LATENCY = 10
)
(
    input               clk,
    input               reset_n,
    //channel address
    input        [31:0] a,
    input               a_vld,

    //channel data
    output logic [31:0] rd,
    output logic        rd_vld
);

    reg [31:0] rom [0:SIZE - 1];
    reg [LATENCY-1:0][31:0] rdata ;
    reg [LATENCY-1:0] rvalid;

    // We intentionally introduce latency here

    always_ff @ (posedge clk) begin
        rdata[0] <= rom [a];
    end

    initial $readmemh ("program.hex", rom);

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) rvalid <= {LATENCY{1'b0}};
        else rvalid <= {rvalid[LATENCY-2:0], a_vld};
    end

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            for(int i = 1; i < LATENCY; i++) begin
                rdata[i] <= 32'h0;
            end
        end
        else begin
            for(int i = 1; i < LATENCY; i++) begin
                rdata[i] <= rdata[i-1];
            end
        end
    end

    assign rd = rdata[LATENCY-1];
    assign rd_vld = rvalid[LATENCY-1];

endmodule
