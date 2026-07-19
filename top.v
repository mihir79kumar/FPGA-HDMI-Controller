`timescale 1ns / 1ps

module top (
    input  wire        clk_100,
    output wire        hdmi_clk_p,
    output wire        hdmi_clk_n,
    output wire [2:0]  hdmi_tx_p,
    output wire [2:0]  hdmi_tx_n,
    output wire        clk_lock_led
);

    wire clk_74, clk_371, locked;
    assign clk_lock_led = locked;

    clk_wiz_0 u_clkwiz (
        .clk_in1  (clk_100),
        .clk_out1 (clk_74),
        .clk_out2 (clk_371),
        .locked   (locked),
        .reset    (1'b0)
    );

    wire rstn = locked;

    wire        req_en, req_sof, req_eof, req_sol, req_eol;
    wire [7:0]  resp_red, resp_green, resp_blue;
    wire [13:0] pixel_x, pixel_y;    // NEW - coordinate wires

    hdmi_tx_top #(
        .RESP_LATENCY  (1),
        .H_TOTAL       (1650),
        .H_DRAW_WIDTH  (1280),
        .H_SYNC_START  (1390),
        .H_SYNC_WIDTH  (40),
        .V_TOTAL       (750),
        .V_DRAW_HEIGHT (720),
        .V_SYNC_START  (725),
        .V_SYNC_HEIGHT (5),
        .HSYNC_POL     (1),
        .VSYNC_POL     (1)
    ) u_hdmi (
        .rstn        (rstn),
        .clk         (clk_74),
        .pclk_x5     (clk_371),
        .req_en      (req_en),
        .req_sof     (req_sof),
        .req_eof     (req_eof),
        .req_sol     (req_sol),
        .req_eol     (req_eol),
        .pixel_x     (pixel_x),      // NEW
        .pixel_y     (pixel_y),      // NEW
        .resp_red    (resp_red),
        .resp_green  (resp_green),
        .resp_blue   (resp_blue),
        .hdmi_clk_p  (hdmi_clk_p),
        .hdmi_clk_n  (hdmi_clk_n),
        .hdmi_tx0_p  (hdmi_tx_p[0]),
        .hdmi_tx0_n  (hdmi_tx_n[0]),
        .hdmi_tx1_p  (hdmi_tx_p[1]),
        .hdmi_tx1_n  (hdmi_tx_n[1]),
        .hdmi_tx2_p  (hdmi_tx_p[2]),
        .hdmi_tx2_n  (hdmi_tx_n[2])
    );

    pixel_gen #(
        .W (1280),
        .H (720)
    ) u_pixels (
        .clk        (clk_74),
        .req_en     (req_en),
        .x          (pixel_x),       // direct coordinates
        .y          (pixel_y),
        .resp_red   (resp_red),
        .resp_green (resp_green),
        .resp_blue  (resp_blue)
    );

endmodule