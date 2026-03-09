//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_fifos
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
    // Implement a pipelined module formula_2_pipe_using_fifos that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 06_04_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    localparam N = 16;

    logic [31:0]    sqrt_c_res;
    logic           sqrt_c_vld;
    logic [31:0]    sqrt_b_res;
    logic           sqrt_b_vld;
    logic [31:0]    sqrt_a_res;
    logic           sqrt_a_vld;

    logic [31:0]    bc_res;
    logic           bc_vld;
    logic [31:0]    abc_res;
    logic           abc_vld;

    logic [31:0]    b_delayed;
    logic [31:0]    a_delayed;

    flip_flop_fifo_with_counter #(
        .width(32),
        .depth(N)
    ) fifo_b(
        .clk(clk),
        .rst(rst),
        
        .push(arg_vld),
        .write_data(b),
        .pop(sqrt_c_vld),
        .read_data(b_delayed)
    );

    flip_flop_fifo_with_counter #(
        .width(32),
        .depth(2*N+1)
    ) fifo_a(
        .clk(clk),
        .rst(rst),
        
        .push(arg_vld),
        .write_data(a),
        .pop(sqrt_b_vld),
        .read_data(a_delayed)
    );

    isqrt isqrt_inst_c(
        .clk(clk),
        .rst(rst),

        .x(c),
        .x_vld(arg_vld),
        .y(sqrt_c_res),
        .y_vld(sqrt_c_vld)
    );

    isqrt isqrt_inst_b(
        .clk(clk),
        .rst(rst),

        .x(bc_res),
        .x_vld(bc_vld),
        .y(sqrt_b_res),
        .y_vld(sqrt_b_vld)
    );

    isqrt isqrt_inst_a(
        .clk(clk),
        .rst(rst),

        .x(abc_res),
        .x_vld(abc_vld),
        .y(sqrt_a_res),
        .y_vld(sqrt_a_vld)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            bc_vld <= '0;
            abc_vld <= '0;
        end
        else begin
            bc_vld <= sqrt_c_vld;
            abc_vld <= sqrt_b_vld;
        end
    end

    always_ff @(posedge clk) begin
        if (sqrt_c_vld) begin
            bc_res <= b_delayed + sqrt_c_res;
        end
        if (sqrt_b_vld) begin
            abc_res <= a_delayed + sqrt_b_res;
        end
    end

    assign res_vld = sqrt_a_vld;
    assign res = sqrt_a_res;

endmodule
