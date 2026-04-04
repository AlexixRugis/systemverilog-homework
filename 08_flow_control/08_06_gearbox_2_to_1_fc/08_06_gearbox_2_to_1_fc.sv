//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_2_to_1_fc
# (
    parameter width = 8
)
(
    input                    clk,
    input                    rst,

    input                    up_valid,
    output                   up_ready,
    input   [ 2*width - 1:0] up_data,

    output                   down_valid,
    input                    down_ready,
    output  [   width - 1:0] down_data
);

    // Task:
    // Implement a module that generates tokens from of one token.
    // Example:
    // "0110" => "01", "10"
    //
    // The module must use signals valid-ready for transfer tokens.

    logic up_ready_internal;
    logic down_valid_internal;
    logic [width-1:0] down_data_internal;

    logic down_handshake;
    assign down_handshake = down_valid & down_ready;

    logic [width-1:0] lower_word;

    enum logic [0:0] {
        S_PUSH_UPPER,
        S_PUSH_LOWER
    } cur_state, next_state;

    always_comb begin
        next_state = cur_state;

        up_ready_internal = 1'b0;
        down_valid_internal = 1'b0;
        down_data_internal = 'x;

        case (cur_state)
        S_PUSH_UPPER: begin
            up_ready_internal = down_ready;
            down_valid_internal = up_valid;
            down_data_internal = up_data[2*width-1:width];

            if (down_handshake) begin
                next_state = S_PUSH_LOWER;
            end
        end
        S_PUSH_LOWER: begin
            up_ready_internal = 1'b0;
            down_valid_internal = 1'b1;
            down_data_internal = lower_word;

            if (down_handshake) begin
                next_state = S_PUSH_UPPER;
            end
        end
    endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cur_state <= S_PUSH_UPPER;
        end
        else begin
            cur_state <= next_state;

            if (cur_state == S_PUSH_UPPER & down_handshake) begin
                lower_word <= up_data[width-1:0];
            end 
        end
    end

    assign up_ready = up_ready_internal;
    assign down_valid = down_valid_internal;
    assign down_data = down_data_internal;

endmodule
