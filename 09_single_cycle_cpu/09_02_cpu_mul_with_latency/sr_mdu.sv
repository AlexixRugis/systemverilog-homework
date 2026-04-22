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

module sr_mdu
# (
    parameter n_delay = 2
)
(
    input               clk,
    input               rst,

    input               i_vld,
    input        [31:0] srcA,
    input        [31:0] srcB,
    output              o_vld,
    output logic [31:0] result,
    output              busy
);

wire [31:0] prod = 32'(srcA * srcB);

shift_register_with_valid #(
    .width(32),
    .depth(n_delay)
) sr(
    .clk(clk),
    .rst(rst),
    .in_data(prod),
    .in_valid(i_vld),
    .out_data(result),
    .out_valid(o_vld)
);

assign busy = 1'b0;

endmodule

//----------------------------------------------------------------------------

module shift_register_with_valid
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input                rst,
    input  [width - 1:0] in_data,
    input                in_valid,
    output [width - 1:0] out_data,
    output               out_valid
);
    logic               valid[0:depth - 1];
    logic [width - 1:0] data [0:depth - 1];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < depth; i ++)
                valid [i] <= 1'b0;
        end
        else begin
            valid[0] <= in_valid;

            for (int i = 1; i < depth; i ++)
                valid[i] <= valid[i - 1];
        end
    end

    always_ff @ (posedge clk)
    begin   
        if (in_valid) begin
            data [0] <= in_data;
        end

        for (int i = 1; i < depth; i ++)
            if (valid[i - 1])
                data [i] <= data [i - 1];
    end

    assign out_data  = data [depth - 1];
    assign out_valid = valid[depth - 1];

endmodule

