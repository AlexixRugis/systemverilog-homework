//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
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
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    enum logic [1:0] {
        ST_GET_A,
        ST_GET_B,
        ST_GET_C
    } in_state, new_in_state;

    enum logic [1:0] {
        ST_PUT_A,
        ST_PUT_B,
        ST_PUT_C
    } out_state, new_out_state;

    logic [31:0]        out_sum;
    logic               out_vld;

    logic [31:0]        b_stage_2;
    logic [31:0]        c_stage_2;
    logic               c_stage_2_vld;
    logic [31:0]        c_stage_3;

    always_ff @(posedge clk) begin
        if (rst) begin
            c_stage_2_vld <= '0;
        end
        else begin
            c_stage_2_vld <= arg_vld;
        end
    end

    always_ff @(posedge clk) begin
        if (arg_vld) begin
            b_stage_2 <= b;
            c_stage_2 <= c;
        end
        if (c_stage_2_vld) begin
            c_stage_3 <= c_stage_2;
        end
    end

    always_comb begin
        new_in_state = in_state;
        isqrt_x = 'x;
        isqrt_x_vld = '0;
        
        case(in_state)
        ST_GET_A: begin
            if (arg_vld) begin
                new_in_state = ST_GET_B;
                isqrt_x = a;
                isqrt_x_vld = '1;
            end
        end
        ST_GET_B: begin
            new_in_state = ST_GET_C;
            isqrt_x = b_stage_2;
            isqrt_x_vld = '1;
        end
        ST_GET_C: begin
            new_in_state = ST_GET_A;
            isqrt_x = c_stage_3;
            isqrt_x_vld = '1;
        end
        endcase
    end

    always_comb begin
        new_out_state = out_state;

        case(out_state)
        ST_PUT_A: begin
            if (isqrt_y_vld) begin
                new_out_state = ST_PUT_B;
            end
        end
        ST_PUT_B: begin
            if (isqrt_y_vld) begin
                new_out_state = ST_PUT_C;
            end
        end
        ST_PUT_C: begin
            if (isqrt_y_vld) begin
                new_out_state = ST_PUT_A;
            end
        end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            out_vld <= '0;
        end
        else begin
            case (out_state)
            ST_PUT_A: begin
                out_vld <= '0;
                if (isqrt_y_vld) begin
                    out_sum <= isqrt_y;
                end
            end
            ST_PUT_B: begin
                if (isqrt_y_vld) begin
                    out_sum <= out_sum + isqrt_y;
                end
            end
            ST_PUT_C: begin
                if (isqrt_y_vld) begin
                    out_sum <= out_sum + isqrt_y;
                    out_vld <= '1;
                end
            end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            in_state <= ST_GET_A;
            out_state <= ST_PUT_A;
        end
        else begin
            in_state <= new_in_state;
            out_state <= new_out_state;
        end
    end

    assign res = out_sum;
    assign res_vld = out_vld;

endmodule
