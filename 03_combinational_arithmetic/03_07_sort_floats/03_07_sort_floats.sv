//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module sort_two_floats_ab (
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,

    output logic [FLEN - 1:0] res0,
    output logic [FLEN - 1:0] res1,
    output                    err
);

    logic a_less_or_equal_b;

    f_less_or_equal i_floe (
        .a   ( a                 ),
        .b   ( b                 ),
        .res ( a_less_or_equal_b ),
        .err ( err               )
    );

    always_comb begin : a_b_compare
        if ( a_less_or_equal_b ) begin
            res0 = a;
            res1 = b;
        end
        else
        begin
            res0 = b;
            res1 = a;
        end
    end

endmodule

//----------------------------------------------------------------------------
// Example - different style
//----------------------------------------------------------------------------

module sort_two_floats_array
(
    input        [0:1][FLEN - 1:0] unsorted,
    output logic [0:1][FLEN - 1:0] sorted,
    output                         err
);

    logic u0_less_or_equal_u1;

    f_less_or_equal i_floe
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err                 )
    );

    always_comb
        if (u0_less_or_equal_u1)
            sorted = unsorted;
        else
              {   sorted [0],   sorted [1] }
            = { unsorted [1], unsorted [0] };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_three_floats (
    input        [0:2][FLEN - 1:0] unsorted,
    output logic [0:2][FLEN - 1:0] sorted,
    output                         err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order.
    // The module should be combinational with zero latency.
    // The solution can use up to three instances of the "f_less_or_equal" module.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res2
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    logic err_01;
    logic err_02;
    logic err_12;

    logic u0_less_or_equal_u1;
    logic u0_less_or_equal_u2;
    logic u1_less_or_equal_u2;

    f_less_or_equal i_floe_01
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err_01              )
    );

    f_less_or_equal i_floe_02
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [2]        ),
        .res ( u0_less_or_equal_u2 ),
        .err ( err_02              )
    );

    f_less_or_equal i_floe_12
    (
        .a   ( unsorted [1]        ),
        .b   ( unsorted [2]        ),
        .res ( u1_less_or_equal_u2 ),
        .err ( err_12              )
    );

    assign
        err = err_01 | err_02 | err_12;      

    always_comb
        case ({u0_less_or_equal_u1, u1_less_or_equal_u2, u0_less_or_equal_u2})
        3'b000:     { sorted[0], sorted[1], sorted[2] } = { unsorted[2], unsorted[1], unsorted[0] };
        3'b010:     { sorted[0], sorted[1], sorted[2] } = { unsorted[1], unsorted[2], unsorted[0] };
        3'b011:     { sorted[0], sorted[1], sorted[2] } = { unsorted[1], unsorted[0], unsorted[2] };
        3'b100:     { sorted[0], sorted[1], sorted[2] } = { unsorted[2], unsorted[0], unsorted[1] };
        3'b101:     { sorted[0], sorted[1], sorted[2] } = { unsorted[0], unsorted[2], unsorted[1] };
        default:    sorted = unsorted;
        endcase
        
endmodule
