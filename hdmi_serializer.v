`timescale 1ns / 1ps

// HDMI Serializer for Spartan-7 / Artix-7
// Uses cascaded OSERDESE2 master/slave for 10:1 serialization
// Followed by OBUFDS for differential output
//
// Bit ordering: TMDS sends LSB first
// D1 of MASTER = tmds_in[0] = first bit transmitted
// D8 of MASTER = tmds_in[7]
// D3 of SLAVE  = tmds_in[8]
// D4 of SLAVE  = tmds_in[9] = last bit transmitted

module hdmi_serializer (
    input  wire        clk_pix,      // pixel clock  e.g. 74.25 MHz
    input  wire        clk_pix_x5,   // 5x clock     e.g. 371.25 MHz
    input  wire        rst,          // active HIGH reset
    input  wire [9:0]  tmds_in,      // 10-bit TMDS word, LSB first
    output wire        tmds_p,       // HDMI differential + output
    output wire        tmds_n        // HDMI differential - output
);

    wire cascade_do, cascade_to;
    wire serial_out_w;

    //------------------------------------------------------------------
    // SLAVE OSERDESE2
    // Handles upper bits [9:8]
    // Its SHIFTOUT feeds the MASTER's SHIFTIN
    //------------------------------------------------------------------
    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"),
        .DATA_RATE_TQ   ("SDR"),
        .DATA_WIDTH     (10),
        .INIT_OQ        (1'b0),
        .INIT_TQ        (1'b0),
        .SERDES_MODE    ("SLAVE"),
        .SRVAL_OQ       (1'b0),
        .SRVAL_TQ       (1'b0),
        .TRISTATE_WIDTH (1)
    ) u_slave (
        .OQ        (),
        .OFB       (),
        .TQ        (),
        .TFB       (),
        .SHIFTOUT1 (cascade_do),   // to master SHIFTIN1
        .SHIFTOUT2 (cascade_to),   // to master SHIFTIN2
        .TBYTEOUT  (),
        .CLK       (clk_pix_x5),
        .CLKDIV    (clk_pix),
        .D1        (1'b0),
        .D2        (1'b0),
        .D3        (tmds_in[8]),   // bit 8 - 9th bit transmitted
        .D4        (tmds_in[9]),   // bit 9 - 10th bit transmitted
        .D5        (1'b0),
        .D6        (1'b0),
        .D7        (1'b0),
        .D8        (1'b0),
        .OCE       (1'b1),
        .RST       (rst),
        .SHIFTIN1  (1'b0),
        .SHIFTIN2  (1'b0),
        .T1        (1'b0),
        .T2        (1'b0),
        .T3        (1'b0),
        .T4        (1'b0),
        .TBYTEIN   (1'b0),
        .TCE       (1'b0)
    );

    //------------------------------------------------------------------
    // MASTER OSERDESE2
    // Handles lower bits [7:0]
    // Receives upper bits from SLAVE via SHIFTIN
    // OQ drives the actual output pin
    //------------------------------------------------------------------
    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"),
        .DATA_RATE_TQ   ("SDR"),
        .DATA_WIDTH     (10),
        .INIT_OQ        (1'b0),
        .INIT_TQ        (1'b0),
        .SERDES_MODE    ("MASTER"),
        .SRVAL_OQ       (1'b0),
        .SRVAL_TQ       (1'b0),
        .TRISTATE_WIDTH (1)
    ) u_master (
        .OQ        (serial_out_w),
        .OFB       (),
        .TQ        (),
        .TFB       (),
        .SHIFTOUT1 (),
        .SHIFTOUT2 (),
        .TBYTEOUT  (),
        .CLK       (clk_pix_x5),
        .CLKDIV    (clk_pix),
        .D1        (tmds_in[0]),   // bit 0 - 1st bit transmitted
        .D2        (tmds_in[1]),
        .D3        (tmds_in[2]),
        .D4        (tmds_in[3]),
        .D5        (tmds_in[4]),
        .D6        (tmds_in[5]),
        .D7        (tmds_in[6]),
        .D8        (tmds_in[7]),   // bit 7 - 8th bit transmitted
        .OCE       (1'b1),
        .RST       (rst),
        .SHIFTIN1  (cascade_do),   // from slave SHIFTOUT1
        .SHIFTIN2  (cascade_to),   // from slave SHIFTOUT2
        .T1        (1'b0),
        .T2        (1'b0),
        .T3        (1'b0),
        .T4        (1'b0),
        .TBYTEIN   (1'b0),
        .TCE       (1'b0)
    );

    //------------------------------------------------------------------
    // OBUFDS - single ended to differential
    //------------------------------------------------------------------
    OBUFDS #(
        .IOSTANDARD ("TMDS_33"),
        .SLEW       ("FAST")
    ) u_obufds (
        .I  (serial_out_w),
        .O  (tmds_p),
        .OB (tmds_n)
    );

endmodule