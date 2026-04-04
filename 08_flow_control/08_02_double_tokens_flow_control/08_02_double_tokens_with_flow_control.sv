//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens_with_flow_control
(
    input  clk,
    input  rst,

    input  up_valid,
    output up_ready,
    input  up_token,

    output down_valid,
    input  down_ready,
    output down_data
);

  // Task:
  // Implement module double input signals (tokens). The module must use signals valid-ready for
  // transfer tokens. If the module receives more than 100 sequential tokens then it must set up_ready = 0;

  logic up_handshake;
  assign up_handshake = up_valid & up_ready;
  logic down_handshake;
  assign down_handshake = down_valid & down_ready;

  logic [7:0] one_cnt;

  logic has_data;
  assign has_data = |one_cnt;

  logic full;
  assign full = ~down_handshake & one_cnt >= 8'd200;
  assign up_ready = ~full;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      one_cnt <= '0;
    end
    else begin
      case ({ up_handshake & up_token, down_handshake & down_data })
      2'b01: one_cnt <= one_cnt - 1'd1;
      2'b10: one_cnt <= one_cnt + 2'd2;
      2'b11: one_cnt <= one_cnt + 1'd1;
      endcase
    end
  end

  assign down_valid = up_valid | down_ready;
  assign down_data = up_valid & up_token | has_data;

endmodule
