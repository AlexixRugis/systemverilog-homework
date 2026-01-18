//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module conv_first_to_last_no_ready
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    output               down_last,
    output [width - 1:0] down_data
);
    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // See README for full description of the task with timing diagram.

    logic   [width-1:0] data_shifted;
    logic               first_tick;

    assign down_data =  data_shifted;
    assign down_valid = ~first_tick & up_valid;
    assign down_last = ~first_tick & up_first;

    always_ff @ (posedge clock) begin
        if (reset) begin
            first_tick <= '1;
        end
        else if (up_valid) begin
            first_tick <= '0;
            data_shifted <= up_data;
        end
    end

endmodule
