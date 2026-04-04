//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module generate_tokens_by_number_with_flow_control
#(
    WIDTH = 4
)
(
    input                 clk,
    input                 rst,

    input                 up_valid,
    output                up_ready,
    input  [WIDTH-1 : 0]  n_tokens,

    output                down_valid,
    input                 down_ready,
    output                down_token
);

    // Task:
    // Implement a module that recive an integer N_tokens and generate N_tokens pulses. The module must use signals valid-ready for
    // transfer tokens.

    logic up_handshake;
    assign up_handshake = up_valid & up_ready;
    logic down_handshake;
    assign down_handshake = down_valid & down_ready;

    logic [WIDTH-1:0] remaining;
    logic has_data;
    logic up_ready_internal;
    assign has_data = |remaining;
    assign up_ready_internal = ~has_data;

    logic down_valid_internal;
    logic down_token_internal;

    assign down_valid_internal = has_data;
    assign down_token_internal = has_data;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            remaining <= '0;
        end
        else begin
            if (up_handshake) begin
                remaining <= n_tokens;
            end

            if (down_handshake) begin
                remaining <= remaining - 1'b1;
            end
        end
    end

    assign up_ready = up_ready_internal;
    assign down_valid = down_valid_internal;
    assign down_token = down_token_internal;

endmodule
