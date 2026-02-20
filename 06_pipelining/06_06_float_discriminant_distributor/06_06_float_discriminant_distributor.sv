module float_discriminant_distributor_reorder
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

module float_discriminant_distributor (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);

    // Task:
    //
    // Implement a module that will calculate the discriminant based
    // on the triplet of input number a, b, c. The module must be pipelined.
    // It should be able to accept a new triple of arguments on each clock cycle
    // and also, after some time, provide the result on each clock cycle.
    // The idea of the task is similar to the task 04_11. The main difference is
    // in the underlying module 03_08 instead of formula modules.
    //
    // Note 1:
    // Reuse your file "03_08_float_discriminant.sv" from the Homework 03.
    //
    // Note 2:
    // Latency of the module "float_discriminant" should be clarified from the waveform.

    localparam N = 16;

    logic [N - 1:0]                 cnt;
    logic [N - 1:0][FLEN - 1:0]     a_delayed;
    logic [N - 1:0][FLEN - 1:0]     b_delayed;
    logic [N - 1:0][FLEN - 1:0]     c_delayed;
    logic [N - 1:0]                 vld_delayed;
    logic [N - 1:0]                 comp_vld;
    logic [N - 1:0][FLEN - 1:0]     comp_res;
    logic [N - 1:0]                 comp_res_negative;
    logic [N - 1:0]                 comp_res_err;
    logic [N - 1:0]                 comp_busy;

    genvar i;
    generate
        for (i = 0; i < N; i++) begin
            float_discriminant comp_block(
                .clk(clk),
                .rst(rst),

                .arg_vld(vld_delayed[i]),
                .a(a_delayed[i]),
                .b(b_delayed[i]),
                .c(c_delayed[i]),

                .res_vld(comp_vld[i]),
                .res(comp_res[i]),
                .res_negative(comp_res_negative[i]),
                .err(comp_res_err[i]),

                .busy(comp_busy[i])
            );
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (rst) begin
            vld_delayed <= '0;
        end
        else begin
            vld_delayed <= cnt & {N{arg_vld}};
        end
    end

    always_ff @(posedge clk) begin
        for (int i = 0; i < N; i++) begin
            if (arg_vld & cnt[i]) begin
                a_delayed[i] <= a;
                b_delayed[i] <= b;
                c_delayed[i] <= c;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            cnt <= {{(N-1){1'b0}}, 1'b1};
        end
        else if (arg_vld) begin
            cnt <= { cnt[N - 2:0], cnt[N-1] };
        end
    end

    logic [N - 1:0][FLEN + 1:0]  data_merged;
    always_comb begin
        for (int i = 0; i < N; i++) begin
            data_merged[i] = { comp_res_err[i], comp_res_negative[i], comp_res[i] };
        end
    end

    logic               out_vld;
    logic [FLEN + 1:0]  out_data;

    float_discriminant_distributor_reorder #(FLEN + 2, N) reorder_block(
        .clk(clk),
        .rst(rst),
        
        .up_vlds(comp_vld),
        .up_data(data_merged),

        .down_vld(out_vld),
        .down_data(out_data)
    );

    assign res_vld = out_vld;
    assign res = out_data[FLEN - 1 : 0];
    assign res_negative = out_data[FLEN];
    assign err = out_data[FLEN + 1];

    assign busy = |(cnt & comp_busy);

endmodule
