//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module convert_first_to_last_with_flow_control
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    output               up_ready,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    input                down_ready,
    output               down_last,
    output [width - 1:0] down_data
);

    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // The module should respect and set correct valid and ready signals
    // to control flow from the upstream and to the downstream.

    logic [width-1:0] data_shifted;
    logic first_tick;

    logic up_ready_internal;
    assign up_ready_internal = down_ready;

    logic handshake;
    assign handshake = up_valid & up_ready;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            first_tick <= 1'b1;
        end
        else begin
            if (handshake) begin
                first_tick <= 1'b0;
                data_shifted <= up_data;
            end
        end
    end

    assign up_ready = up_ready_internal;
    assign down_valid = up_valid & ~first_tick;
    assign down_data = data_shifted;
    assign down_last = up_first;

endmodule
