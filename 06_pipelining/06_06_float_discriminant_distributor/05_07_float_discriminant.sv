//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    localparam [FLEN - 1:0] four = 64'h4010_0000_0000_0000;

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    logic [FLEN - 1:0]  mult_a;
    logic [FLEN - 1:0]  mult_b;
    logic               mult_valid_in;
    logic [FLEN - 1:0]  mult_res;
    logic               mult_valid_out;
    logic               mult_error;
    logic               mult_error_delay;

    f_mult f_mult_inst(.clk(clk), .rst(rst),
    .a(mult_a), .b(mult_b), .up_valid(mult_valid_in), 
    .res(mult_res), .down_valid(mult_valid_out), .error(mult_error));

    logic [FLEN - 1:0]  sub_a;
    logic [FLEN - 1:0]  sub_b;
    logic               sub_valid_in;
    logic [FLEN - 1:0]  sub_res;
    logic               sub_valid_out;
    logic               sub_error;
    logic               sub_error_delay;

    f_sub f_sub_inst(.clk(clk), .rst(rst),
    .a(sub_a), .b(sub_b), .up_valid(sub_valid_in),
    .res(sub_res), .down_valid(sub_valid_out), .error(sub_error));

    logic               has_err;

    always_ff @ (posedge clk) begin
        sub_error_delay <= sub_error;
        mult_error_delay <= mult_error;
    end

    assign has_err = mult_valid_out & mult_error_delay | sub_valid_out & sub_error_delay;

    logic [FLEN - 1 : 0]    reg_b2;

    enum logic[2:0] {
        st_idle         = 3'b000,
        st_wait_b2      = 3'b001,
        st_wait_ac      = 3'b010,
        st_wait_4ac     = 3'b011,
        st_wait_sub     = 3'b100
    } state, new_state;

    always_comb begin
        new_state = state;

        mult_a = 'x;
        mult_b = 'x;
        mult_valid_in = '0;
        sub_a = 'x;
        sub_b = 'x;
        sub_valid_in = '0;

        case (state)
        st_idle: begin
            mult_a = b;
            mult_b = b;

            if (arg_vld) begin
                mult_valid_in = '1;
                new_state = st_wait_b2;
            end
        end
        st_wait_b2: begin
            mult_a = a;
            mult_b = c;

            if (mult_valid_out) begin
                mult_valid_in = '1;

                new_state = st_wait_ac;
            end
        end
        st_wait_ac: begin
            mult_a = mult_res;
            mult_b = four;

            if (mult_valid_out) begin
                mult_valid_in = '1;
                new_state = st_wait_4ac;
            end
        end
        st_wait_4ac: begin
            sub_a = reg_b2;
            sub_b = mult_res;

            if (mult_valid_out) begin
                sub_valid_in = '1;
                new_state = st_wait_sub;
            end
        end
        st_wait_sub: begin
            if (sub_valid_out) begin
                new_state = st_idle;
            end
        end
        endcase

        if (has_err) begin
            new_state = st_idle;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            reg_b2 <= '0;
        end
        else begin
            if (state == st_wait_b2 & mult_valid_out) begin
                reg_b2 <= mult_res;
            end
        end
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
            err <= '0;
        end
        else begin
            res_vld <= (state != st_idle & new_state == st_idle);
            res <= sub_res;
            err <= has_err;
        end
    end

    assign res_negative = res[FLEN - 1];
    assign busy = state != st_idle;


endmodule
