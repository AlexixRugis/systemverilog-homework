//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2_fc
# (
    parameter width = 8
)
(
    input                   clk,
    input                   rst,
    input                   up_valid,
    output                  up_ready,
    input  [   width - 1:0] up_data,
    output                  down_valid,
    output [ 2*width - 1:0] down_data,
    input                   down_ready
);

    // Task:
    // Implement a module that generates one token from of two tokens.
    // Example:
    // "01", "10" => "0110"
    //
    // The module must use signals valid-ready for transfer tokens.

    logic up_ready_internal;
    logic down_valid_internal;
    logic [2*width-1:0] down_data_internal;

    logic up_handshake;
    assign up_handshake = up_valid & up_ready;
    logic down_handshake;
    assign down_handshake = down_valid & down_ready;

    enum logic [0:0] {
        S_READ_UPPER,
        S_READ_LOWER
    } cur_state, next_state;

    always_comb begin
        next_state = cur_state;

        up_ready_internal = 1'b0;

        case (cur_state)
        S_READ_UPPER: begin
            up_ready_internal = ~down_valid_internal | down_ready;

            if (up_handshake) begin
                next_state = S_READ_LOWER;
            end
        end
        S_READ_LOWER: begin
            up_ready_internal = 1'b1;

            if (up_handshake) begin
                next_state = S_READ_UPPER;
            end
        end
    endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cur_state <= S_READ_UPPER;
            down_valid_internal <= 1'b0;
        end
        else begin
            cur_state <= next_state;

            if (up_handshake) begin
                case(cur_state)
                    S_READ_UPPER: begin
                        down_data_internal[2*width-1:width] <= up_data;
                    end
                    S_READ_LOWER: begin
                        down_data_internal[width-1:0] <= up_data;
                        down_valid_internal <= 1'b1;
                    end
                endcase
            end

            if (down_handshake) begin
                down_valid_internal <= 1'b0;
            end
        end
    end

    assign up_ready = up_ready_internal;
    assign down_valid = down_valid_internal;
    assign down_data = down_data_internal;

endmodule
