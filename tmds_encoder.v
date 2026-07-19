`timescale 1ns / 1ps

// TMDS encoder - clean rewrite based on HDMI spec 1.3a Section 5.4.2
// Verified against WangXuan RTL structure

module tmds_encoder (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  data_in,
    input  wire [1:0]  ctrl_in,
    input  wire        video_on,
    output reg  [9:0]  tmds_out
);

// ---------------------------------------------------------------
// Stage 1 : count ones in data_in
// ---------------------------------------------------------------
wire [3:0] n1d;
assign n1d = data_in[0] + data_in[1] + data_in[2] + data_in[3]
           + data_in[4] + data_in[5] + data_in[6] + data_in[7];

// ---------------------------------------------------------------
// Stage 2 : build q_m (transition minimised word)
// if n1d > 4 OR (n1d==4 AND bit0==0) use XNOR, else use XOR
// ---------------------------------------------------------------
wire [8:0] q_m;
wire       use_xnor_enc = (n1d > 4) || (n1d == 4 && data_in[0] == 1'b0);

assign q_m[0] = data_in[0];
assign q_m[1] = use_xnor_enc ? (q_m[0] ~^ data_in[1])
                              : (q_m[0]  ^ data_in[1]);
assign q_m[2] = use_xnor_enc ? (q_m[1] ~^ data_in[2])
                              : (q_m[1]  ^ data_in[2]);
assign q_m[3] = use_xnor_enc ? (q_m[2] ~^ data_in[3])
                              : (q_m[2]  ^ data_in[3]);
assign q_m[4] = use_xnor_enc ? (q_m[3] ~^ data_in[4])
                              : (q_m[3]  ^ data_in[4]);
assign q_m[5] = use_xnor_enc ? (q_m[4] ~^ data_in[5])
                              : (q_m[4]  ^ data_in[5]);
assign q_m[6] = use_xnor_enc ? (q_m[5] ~^ data_in[6])
                              : (q_m[5]  ^ data_in[6]);
assign q_m[7] = use_xnor_enc ? (q_m[6] ~^ data_in[7])
                              : (q_m[6]  ^ data_in[7]);
assign q_m[8] = ~use_xnor_enc; // 1 = XOR was used

// ---------------------------------------------------------------
// Stage 3 : count ones/zeros in q_m[7:0] for DC balance
// ---------------------------------------------------------------
wire [3:0] n1q_m, n0q_m;
assign n1q_m = q_m[0] + q_m[1] + q_m[2] + q_m[3]
             + q_m[4] + q_m[5] + q_m[6] + q_m[7];
assign n0q_m = 4'd8 - n1q_m;

// ---------------------------------------------------------------
// Stage 4 : DC balance - running disparity counter
// ---------------------------------------------------------------
reg [4:0] cnt; // running disparity: signed, stored as unsigned offset
               // cnt=16 means balanced (0 disparity)
               // cnt>16 means positive disparity (more 1s sent)
               // cnt<16 means negative disparity (more 0s sent)

// Control tokens from HDMI spec Table 5-2
wire [9:0] ctrl_token;
assign ctrl_token = (ctrl_in == 2'b00) ? 10'b1101010100 :
                    (ctrl_in == 2'b01) ? 10'b0010101011 :
                    (ctrl_in == 2'b10) ? 10'b0101010100 :
                                         10'b1010101011 ;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        tmds_out <= 10'b1101010100;
        cnt      <= 5'd16; // balanced
    end else if (!video_on) begin
        // blanking period - send control token, reset disparity
        tmds_out <= ctrl_token;
        cnt      <= 5'd16;
    end else begin
        // active video - DC balance
        if (cnt == 5'd16 || n1q_m == n0q_m) begin
            // perfectly balanced so far
            // choose inversion based on q_m[8] (XOR/XNOR indicator)
            tmds_out[9]   <= ~q_m[8];
            tmds_out[8]   <=  q_m[8];
            if (q_m[8]) begin
                tmds_out[7:0] <= q_m[7:0];
                cnt <= cnt + n1q_m - n0q_m;
            end else begin
                tmds_out[7:0] <= ~q_m[7:0];
                cnt <= cnt + n0q_m - n1q_m;
            end
        end else if ((cnt > 5'd16 && n1q_m > n0q_m) ||
                     (cnt < 5'd16 && n1q_m < n0q_m)) begin
            // need to reduce disparity - invert the word
            tmds_out[9]   <= 1'b1;
            tmds_out[8]   <= q_m[8];
            tmds_out[7:0] <= ~q_m[7:0];
            cnt <= cnt + {3'b0, q_m[8], 1'b0} + n0q_m - n1q_m;
        end else begin
            // keep the word as-is
            tmds_out[9]   <= 1'b0;
            tmds_out[8]   <= q_m[8];
            tmds_out[7:0] <= q_m[7:0];
            cnt <= cnt - {3'b0, ~q_m[8], 1'b0} + n1q_m - n0q_m;
        end
    end
end

endmodule