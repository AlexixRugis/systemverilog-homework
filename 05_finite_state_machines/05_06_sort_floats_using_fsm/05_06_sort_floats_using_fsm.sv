//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    enum logic[1:0] {
        st_idle     = 2'b00,
        st_sort_1   = 2'b01,
        st_sort_2   = 2'b10
    } state, new_state;

    always_comb begin
        new_state = state;
        f_le_a = 'x;
        f_le_b = 'x;

        case (state)
        st_idle: begin
            f_le_a = unsorted[1];
            f_le_b = unsorted[2];

            if (valid_in & ~f_le_err) begin
                new_state = st_sort_1;
            end
        end
        st_sort_1: begin
            f_le_a = sorted[0];
            f_le_b = sorted[1];

            if (f_le_err) new_state = st_idle;
            else new_state = st_sort_2;
        end
        st_sort_2: begin
            f_le_a = sorted[1];
            f_le_b = sorted[2];

            new_state = st_idle;
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
            valid_out <= '0;
        end
        else begin
            if (state == st_idle) valid_out <= valid_in & f_le_err;
            else valid_out <= ((state == st_sort_2) | f_le_err);
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            sorted <= '0;
            err <= '0;
        end
        else begin
            case (state)
            st_idle: begin
                if (f_le_res) begin
                    sorted <= { unsorted[0], unsorted[1], unsorted[2] };
                end
                else begin
                    sorted <= { unsorted[0], unsorted[2], unsorted[1] };
                end

                err <= valid_in & f_le_err;
            end
            st_sort_1: begin
                if (f_le_res) begin
                    sorted <= { sorted[0], sorted[1], sorted[2] };
                end
                else begin
                    sorted <= { sorted[1], sorted[0], sorted[2] };
                end

                err <= err | f_le_err;
            end
            st_sort_2: begin
                if (f_le_res) begin
                    sorted <= { sorted[0], sorted[1], sorted[2] };
                end
                else begin
                    sorted <= { sorted[0], sorted[2], sorted[1] };
                end

                err <= err | f_le_err;
            end
            endcase
        end
    end

    assign busy = state != st_idle;

endmodule
