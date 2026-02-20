module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                       clk,
    input                       rst,

    input  [ n_inputs - 1 : 0 ] up_vlds,
    input  [ n_inputs - 1 : 0 ]
           [ width    - 1 : 0 ] up_data,

    output                      down_vld,
    output [ width   - 1 : 0 ]  down_data
);

    // Task:
    //
    // Implement a module that accepts many outputs of the computational blocks
    // and outputs them one by one in order. Input signals "up_vlds" and "up_data"
    // are coming from an array of non-pipelined computational blocks.
    // These external computational blocks have a variable latency.
    //
    // The order of incoming "up_vlds" is not determent, and the task is to
    // output "down_vld" and corresponding data in a round-robin manner,
    // one after another, in order.
    //
    // Comment:
    // The idea of the block is kinda similar to the "parallel_to_serial" block
    // from Homework 2, but here block should also preserve the output order.

    logic [n_inputs - 1:0]              vld_delayed;
    logic [n_inputs - 1:0][width - 1:0] input_delayed;

    logic [n_inputs - 1:0] cnt;

    logic dispatch;
    assign dispatch = |(cnt & vld_delayed); 

    always_ff @(posedge clk) begin
        if (rst) begin
            cnt <= { {(n_inputs - 1){1'b0}}, 1'b1 };
        end
        else if (dispatch) begin
            cnt <= { cnt[n_inputs - 2:0], cnt[n_inputs - 1] };
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            vld_delayed <= '0;
        end
        else begin
            for (int i = 0; i < n_inputs; i++) begin
                if (up_vlds[i] | (cnt[i] & vld_delayed[i])) begin
                    vld_delayed[i] <= up_vlds[i];
                    input_delayed[i] <= up_data[i];
                end
            end
        end
    end

    logic [width - 1:0] out_data;

    always_comb begin
        out_data = '0;
        for (int i = 0; i < n_inputs; i++) begin
            if (cnt[i] & vld_delayed[i]) begin
                out_data |= input_delayed[i];
            end
        end
    end

    assign down_vld = dispatch;
    assign down_data = out_data;

endmodule
