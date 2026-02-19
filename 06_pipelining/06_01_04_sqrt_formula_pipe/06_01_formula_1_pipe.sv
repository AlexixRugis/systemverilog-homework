//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe
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
    // Implement a pipelined module formula_1_pipe that computes the result
    // of the formula defined in the file formula_1_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_1_pipe has to be pipelined.
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
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    logic           sqrt_a_vld;
    logic [31:0]    sqrt_a_data;
    logic           sqrt_b_vld;
    logic [31:0]    sqrt_b_data;
    logic           sqrt_c_vld;
    logic [31:0]    sqrt_c_data;
    logic           sqrt_all_vld;

    isqrt isqrt_inst_a(
        .clk(clk),
        .rst(rst),

        .x_vld(arg_vld),
        .x(a),
        .y_vld(sqrt_a_vld),
        .y(sqrt_a_data)
    );

    isqrt isqrt_inst_b(
        .clk(clk),
        .rst(rst),

        .x_vld(arg_vld),
        .x(b),
        .y_vld(sqrt_b_vld),
        .y(sqrt_b_data)
    );

    isqrt isqrt_inst_c(
        .clk(clk),
        .rst(rst),

        .x_vld(arg_vld),
        .x(c),
        .y_vld(sqrt_c_vld),
        .y(sqrt_c_data)
    );

    assign sqrt_all_vld = sqrt_a_vld & sqrt_b_vld & sqrt_c_vld;

    logic [31:0]    sum_ab;
    logic [31:0]    val_c;
    logic [31:0]    sum_abc;
    
    logic           sum_ab_vld;
    logic           out_vld;

    always_ff @(posedge clk) begin
        if (rst) begin
            sum_ab_vld <= '0;
            out_vld <= '0;
        end
        else begin
            sum_ab_vld <= sqrt_all_vld;
            out_vld <= sum_ab_vld;
        end
    end

    always @(posedge clk) begin
        if (sqrt_all_vld) begin
            sum_ab <= sqrt_a_data + sqrt_b_data;
            val_c <= sqrt_c_data;
        end
    end

    always @(posedge clk) begin
        if (sum_ab_vld) begin
            sum_abc <= sum_ab + val_c;
        end
    end

    assign res_vld = out_vld;
    assign res = sum_abc;

endmodule
