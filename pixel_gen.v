`timescale 1ns / 1ps

module pixel_gen #(
    parameter W = 1280,
    parameter H = 720
)(
    input  wire        clk,
    input  wire        req_en,
    input  wire [13:0] x,
    input  wire [13:0] y,
    output wire [7:0]  resp_red,
    output wire [7:0]  resp_green,
    output wire [7:0]  resp_blue
);

    wire [7:0] r_bar =
        (x < 14'd160)  ? 8'hFF :
        (x < 14'd320)  ? 8'hFF :
        (x < 14'd480)  ? 8'h00 :
        (x < 14'd640)  ? 8'h00 :
        (x < 14'd800)  ? 8'hFF :
        (x < 14'd960)  ? 8'hFF :
        (x < 14'd1120) ? 8'h00 : 8'h00;

    wire [7:0] g_bar =
        (x < 14'd160)  ? 8'hFF :
        (x < 14'd320)  ? 8'hFF :
        (x < 14'd480)  ? 8'hFF :
        (x < 14'd640)  ? 8'hFF :
        (x < 14'd800)  ? 8'h00 :
        (x < 14'd960)  ? 8'h00 :
        (x < 14'd1120) ? 8'h00 : 8'h00;

    wire [7:0] b_bar =
        (x < 14'd160)  ? 8'hFF :
        (x < 14'd320)  ? 8'h00 :
        (x < 14'd480)  ? 8'hFF :
        (x < 14'd640)  ? 8'h00 :
        (x < 14'd800)  ? 8'hFF :
        (x < 14'd960)  ? 8'h00 :
        (x < 14'd1120) ? 8'hFF : 8'h00;

    // Top is bright, bottom is dimmer
    wire dim = y[9];

    assign resp_red   = req_en ? (dim ? {1'b0, r_bar[7:1]} : r_bar) : 8'h00;
    assign resp_green = req_en ? (dim ? {1'b0, g_bar[7:1]} : g_bar) : 8'h00;
    assign resp_blue  = req_en ? (dim ? {1'b0, b_bar[7:1]} : b_bar) : 8'h00;

endmodule