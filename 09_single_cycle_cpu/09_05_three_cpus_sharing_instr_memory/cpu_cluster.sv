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

module cpu_cluster
#(
    parameter nCPUs = 3
)
(
    input                        clk,      // clock
    input                        rst,      // reset

    input   [nCPUs - 1:0][31:0]  rstPC,    // program counter set on reset
    input   [nCPUs - 1:0][ 4:0]  regAddr,  // debug access reg address
    output  [nCPUs - 1:0][31:0]  regData   // debug access reg data
);

wire [7:0]   req;
assign req[nCPUs-1:0] = '1;
assign req[7:nCPUs] = '0;

wire [7:0]  gnt;

round_robin_arbiter_8 arbiter (
    .clk(clk),
    .rst(rst),
    .req(req),
    .gnt(gnt)
);

wire [nCPUs - 1:0][31:0] imAddr;
reg [31:0] romAddr;
wire [31:0] imData;

always_comb begin
    romAddr = '0;
    for (int i = 0; i < nCPUs; i++) begin
        romAddr |= {32{gnt[i]}} & imAddr[i];
    end
end

instruction_rom #(
    .ADDR_W(32)
) rom(
    .a(romAddr),
    .rd(imData)
);

generate
    for (genvar i = 0; i < nCPUs; i++) begin : cpu_gen
        sr_cpu cpu (
            .clk(clk),
            .rst(rst),
            .rstPC(rstPC[i]),
            .imAddr(imAddr[i]),
            .imData(imData),
            .imDataVld(gnt[i]),
            .regAddr(regAddr[i]),
            .regData(regData[i])
        );
    end
endgenerate


endmodule
