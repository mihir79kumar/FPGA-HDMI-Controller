`timescale 1ns / 1ps

module hdmi_tx_top #(
    parameter        RESP_LATENCY  = 1,
    parameter [13:0] H_TOTAL       = 14'd1650,
    parameter [13:0] H_DRAW_WIDTH  = 14'd1280,
    parameter [13:0] H_SYNC_START  = 14'd1390,
    parameter [13:0] H_SYNC_WIDTH  = 14'd40,
    parameter [13:0] V_TOTAL       = 14'd750,
    parameter [13:0] V_DRAW_HEIGHT = 14'd720,
    parameter [13:0] V_SYNC_START  = 14'd725,
    parameter [13:0] V_SYNC_HEIGHT = 14'd5,
    parameter        HSYNC_POL     = 1,
    parameter        VSYNC_POL     = 1
)(
    input  wire        rstn,
    input  wire        clk,
    input  wire        pclk_x5,

    output reg         req_en,
    output reg         req_sof,
    output reg         req_eof,
    output reg         req_sol,
    output reg         req_eol,

    output wire [13:0] pixel_x,
    output wire [13:0] pixel_y,

    input  wire [7:0]  resp_red,
    input  wire [7:0]  resp_green,
    input  wire [7:0]  resp_blue,

    output wire        hdmi_clk_p,
    output wire        hdmi_clk_n,
    output wire        hdmi_tx0_p,
    output wire        hdmi_tx0_n,
    output wire        hdmi_tx1_p,
    output wire        hdmi_tx1_n,
    output wire        hdmi_tx2_p,
    output wire        hdmi_tx2_n
);

    wire rst = ~rstn;

    // ----------------------------------------------------------------
    // Counters
    // ----------------------------------------------------------------
    reg [13:0] h_cnt = 0;
    reg [13:0] v_cnt = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                v_cnt <= (v_cnt == V_TOTAL - 1) ? 14'd0 : v_cnt + 14'd1;
            end else begin
                h_cnt <= h_cnt + 14'd1;
            end
        end
    end

    // ----------------------------------------------------------------
    // Timing signals
    // ----------------------------------------------------------------
    wire in_active = (h_cnt < H_DRAW_WIDTH) && (v_cnt < V_DRAW_HEIGHT);

    wire hsync_pulse = (h_cnt >= H_SYNC_START) &&
                       (h_cnt <  H_SYNC_START + H_SYNC_WIDTH);
    wire vsync_pulse = (v_cnt >= V_SYNC_START) &&
                       (v_cnt <  V_SYNC_START + V_SYNC_HEIGHT);

    wire hsync = HSYNC_POL ? hsync_pulse : ~hsync_pulse;
    wire vsync = VSYNC_POL ? vsync_pulse : ~vsync_pulse;

    // ----------------------------------------------------------------
    // Expose counters to pixel_gen
    // pixel_gen is combinational so h_cnt/v_cnt are valid NOW
    // ----------------------------------------------------------------
//    assign pixel_x = h_cnt;
//    assign pixel_y = v_cnt;


(* KEEP = "TRUE" *) wire [13:0] px_keep = h_cnt;
(* KEEP = "TRUE" *) wire [13:0] py_keep = v_cnt;
assign pixel_x = px_keep;
assign pixel_y = py_keep;

    // ----------------------------------------------------------------
    // req signals - registered
    // ----------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            req_en  <= 1'b0;
            req_sof <= 1'b0;
            req_eof <= 1'b0;
            req_sol <= 1'b0;
            req_eol <= 1'b0;
        end else begin
            req_en  <= in_active;
            req_sof <= in_active && (h_cnt == 14'd0) && (v_cnt == 14'd0);
            req_eof <= in_active && (h_cnt == H_DRAW_WIDTH-1)
                                 && (v_cnt == V_DRAW_HEIGHT-1);
            req_sol <= in_active && (h_cnt == 14'd0);
            req_eol <= in_active && (h_cnt == H_DRAW_WIDTH-1);
        end
    end

    // ----------------------------------------------------------------
    // Sync pipeline - delay by 1 cycle to align with registered req_en
    // pixel_gen is combinational so resp_rgb is valid same cycle as
    // h_cnt/v_cnt. But req_en is registered (1 cycle delay).
    // So encoder sees resp_rgb valid when req_en was high last cycle
    // = when h_cnt was at previous position.
    // We delay hsync/vsync/active by 1 cycle to match.
    // ----------------------------------------------------------------
    reg hsync_d, vsync_d, active_d;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hsync_d  <= HSYNC_POL ? 1'b0 : 1'b1;
            vsync_d  <= VSYNC_POL ? 1'b0 : 1'b1;
            active_d <= 1'b0;
        end else begin
            hsync_d  <= hsync;
            vsync_d  <= vsync;
            active_d <= in_active;
        end
    end

    // ----------------------------------------------------------------
    // TMDS Encoders
    // ----------------------------------------------------------------
    wire [9:0] tmds_blue, tmds_green, tmds_red;

    tmds_encoder enc_blue (
        .clk      (clk),
        .rst      (rst),
        .data_in  (resp_blue),
        .ctrl_in  ({vsync_d, hsync_d}),
        .video_on (active_d),
        .tmds_out (tmds_blue)
    );

    tmds_encoder enc_green (
        .clk      (clk),
        .rst      (rst),
        .data_in  (resp_green),
        .ctrl_in  (2'b00),
        .video_on (active_d),
        .tmds_out (tmds_green)
    );

    tmds_encoder enc_red (
        .clk      (clk),
        .rst      (rst),
        .data_in  (resp_red),
        .ctrl_in  (2'b00),
        .video_on (active_d),
        .tmds_out (tmds_red)
    );

    // ----------------------------------------------------------------
    // Serializers
    // ----------------------------------------------------------------
    wire [9:0] tmds_clk_word = 10'b1111100000;

    hdmi_serializer ser_clk (
        .clk_pix    (clk),
        .clk_pix_x5 (pclk_x5),
        .rst        (rst),
        .tmds_in    (tmds_clk_word),
        .tmds_p     (hdmi_clk_p),
        .tmds_n     (hdmi_clk_n)
    );

    hdmi_serializer ser_tx0 (
        .clk_pix    (clk),
        .clk_pix_x5 (pclk_x5),
        .rst        (rst),
        .tmds_in    (tmds_blue),
        .tmds_p     (hdmi_tx0_p),
        .tmds_n     (hdmi_tx0_n)
    );

    hdmi_serializer ser_tx1 (
        .clk_pix    (clk),
        .clk_pix_x5 (pclk_x5),
        .rst        (rst),
        .tmds_in    (tmds_green),
        .tmds_p     (hdmi_tx1_p),
        .tmds_n     (hdmi_tx1_n)
    );

    hdmi_serializer ser_tx2 (
        .clk_pix    (clk),
        .clk_pix_x5 (pclk_x5),
        .rst        (rst),
        .tmds_in    (tmds_red),
        .tmds_p     (hdmi_tx2_p),
        .tmds_n     (hdmi_tx2_n)
    );

endmodule