# FPGA-HDMI-Controller— Spartan-7 FPGA

A from-scratch Verilog implementation of an HDMI transmitter for the Boolean board (Xilinx Spartan-7), driving a static 1280×720@60Hz color-bar test pattern to a physical display. Built to verify correct HDMI timing generation, TMDS encoding, and high-speed serialization on real hardware — no external IP cores used for the video path.

## Features

- **Clock Wizard (MMCM/PLL)** IP core generating 74.25 MHz pixel clock and 371.25 MHz (5×) serialization clock from a 100 MHz onboard oscillator, with `locked` status monitored via LED
- **1280×720@60Hz** video timing generator (CVT/CEA-861 standard timings)
- **TMDS 8b/10b encoding** per HDMI 1.3a spec — transition-minimized XOR/XNOR encoding with running-disparity DC balancing
- **10:1 serialization** using cascaded master/slave `OSERDESE2` primitives at a 371.25 MHz bit clock
- **OBUFDS** differential output stage for TMDS signaling
- Static color-bar pattern generator for end-to-end signal integrity verification
## Module Overview

| Module | Description |
|---|---|
| `top.v` | Top-level wrapper — instantiates Clock Wizard and integrates all sub-modules |
| `clk_wiz_0` | Xilinx Clock Wizard IP — generates 74.25 MHz pixel clock and 371.25 MHz serial clock from 100 MHz input, with reset/locked handshake |
| `hdmi_tx_top.v` | Horizontal/vertical timing counters, sync generation, TMDS channel instantiation |
| `pixel_gen.v` | Static color-bar RGB pattern generator |
| `tmds_encoder.v` | HDMI-spec TMDS 8b/10b encoder with DC balancing |
| `hdmi_serializer.v` | Dual-OSERDESE2 10:1 serializer + OBUFDS differential driver |
| `boolean_hdmi.xdc` | Pin constraints for the Boolean (Spartan-7) board |

## Clock Wizard Configuration

| Parameter | Value |
|---|---|
| Input clock | 100 MHz |
| Output clock 1 (pixel clock) | 74.25 MHz |
| Output clock 2 (serial clock) | 371.25 MHz (5× pixel clock) |
| Reset | Active-high, tied to `1'b0` (free-running) |
| Locked output | Gates system reset (`rstn = locked`) and drives status LED |

The design waits for the Clock Wizard's `locked` signal before releasing reset to the HDMI pipeline, ensuring the MMCM has stabilized before any timing or TMDS logic becomes active.

## Hardware Setup

- **Board:** Boolean board (Xilinx Spartan-7)
- **Input clock:** 100 MHz onboard oscillator
- **Output:** HDMI connector (TMDS0/1/2 + clock, differential pairs)
- **Display:** Any standard HDMI-input TV/monitor supporting 1280×720@60Hz

## Result

Verified stable, glitch-free color-bar output on a physical TV.

**Output:**

<p align="center">
  <img src="images/output_1.png" width="85%">
  </p>
  <p align="center">
  <img src="images/output_2.png" width="85%">
</p>

## Tools

Xilinx Vivado · Verilog HDL
Spartan-7 . Boolean Board
