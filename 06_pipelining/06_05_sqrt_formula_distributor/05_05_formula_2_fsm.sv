//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    // Task:
    //
    // Implement a module that calculates the formula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    enum logic[1:0] {
        st_idle             = 2'b00,
        st_wait_c_res       = 2'b01,
        st_wait_b_c_res     = 2'b10,
        st_wait_a_b_c_res   = 2'b11
    } state, new_state;

    logic [31:0] next_res;

    always_comb begin
        new_state = state;

        isqrt_x_vld = '0;
        isqrt_x     = 'x;

        case (state)
        st_idle: begin
            isqrt_x = c;

            if (arg_vld) begin
                isqrt_x_vld = '1;
                new_state = st_wait_c_res;
            end
        end
        st_wait_c_res: begin
            isqrt_x = b + 32'(isqrt_y);

            if (isqrt_y_vld) begin
                isqrt_x_vld = '1;
                new_state = st_wait_b_c_res;
            end
        end
        st_wait_b_c_res: begin
            isqrt_x = a + 32'(isqrt_y);

            if (isqrt_y_vld) begin
                isqrt_x_vld = '1;
                new_state = st_wait_a_b_c_res;
            end
        end
        st_wait_a_b_c_res: begin
            if (isqrt_y_vld) begin
                new_state = st_idle;
            end
        end
        endcase
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= st_idle;
        end
        else begin
            state <= new_state;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            res_vld <= '0;
            res <= '0;
        end
        else begin
            res_vld <= (state == st_wait_a_b_c_res & isqrt_y_vld);
            res <= isqrt_y;
        end
    end

endmodule
