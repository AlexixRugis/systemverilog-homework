module sqrt_formula_distributor
# (
    parameter formula = 1,
              impl    = 1
)
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
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.

    localparam N = 50;

    logic [N - 1:0] comp_vld;
    logic [31:0]    comp_res [0:N - 1];
    logic [N - 1:0] cnt;

    logic [N - 1:0] vld_delayed;
    logic [31:0]    a_delayed [0:N-1];
    logic [31:0]    b_delayed [0:N-1];
    logic [31:0]    c_delayed [0:N-1];

    genvar i;
    generate
        for (i = 0; i < N; i++) begin
            if (formula == 1 && impl == 1)
            begin : if_1_1
                formula_1_impl_1_top i_formula_1_impl_1_top (
                    .clk(clk),
                    .rst(rst),
                    
                    .arg_vld(vld_delayed[i]),
                    .a(a_delayed[i]),
                    .b(b_delayed[i]),
                    .c(c_delayed[i]),
                    .res_vld(comp_vld[i]),
                    .res(comp_res[i])
                );
            end
            else if (formula == 1 && impl == 2)
            begin : if_1_2
                formula_1_impl_2_top i_formula_1_impl_2_top (
                    .clk(clk),
                    .rst(rst),
                    
                    .arg_vld(vld_delayed[i]),
                    .a(a_delayed[i]),
                    .b(b_delayed[i]),
                    .c(c_delayed[i]),
                    .res_vld(comp_vld[i]),
                    .res(comp_res[i])
                );
            end
            else
            begin : if_else
                formula_2_top        i_formula_2_top        (
                    .clk(clk),
                    .rst(rst),
                    
                    .arg_vld(vld_delayed[i]),
                    .a(a_delayed[i]),
                    .b(b_delayed[i]),
                    .c(c_delayed[i]),
                    .res_vld(comp_vld[i]),
                    .res(comp_res[i])
                );
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (rst) begin
            vld_delayed <= '0;
        end
        else begin
            vld_delayed <= cnt & {N{arg_vld}};
        end
    end

    always_ff @(posedge clk) begin
        for (int i = 0; i < N; i++) begin
            if (arg_vld & cnt[i]) begin
                a_delayed[i] <= a;
                b_delayed[i] <= b;
                c_delayed[i] <= c;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            cnt <= {{(N-1){1'b0}}, 1'b1};
        end
        else if (arg_vld) begin
            cnt <= { cnt[N - 2:0], cnt[N-1] };
        end
    end

    logic [31:0] res_comb;

    always_comb begin
        res_comb = '0;
        for (int i = 0; i < N; i++) begin
            res_comb |= comp_res[i] & {32{comp_vld[i]}};
        end
    end

    assign res_vld = |comp_vld;
    assign res = res_comb;

endmodule
