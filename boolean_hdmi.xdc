# -----------------------------------------------
# Boolean Board - HDMI XDC (corrected)
# -----------------------------------------------

# Mandatory - prevents CFGBVS DRC warning
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# 100 MHz system clock - pin F14
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports {clk_100}]
create_clock -period 10.000 -name sys_clk [get_ports {clk_100}]

# HDMI Clock differential pair
set_property -dict {PACKAGE_PIN R14 IOSTANDARD TMDS_33} [get_ports {hdmi_clk_p}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD TMDS_33} [get_ports {hdmi_clk_n}]

# HDMI Data channel 0 - Blue
set_property -dict {PACKAGE_PIN R15 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_p[0]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_n[0]}]

# HDMI Data channel 1 - Green
set_property -dict {PACKAGE_PIN R16 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_p[1]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_n[1]}]

# HDMI Data channel 2 - Red
set_property -dict {PACKAGE_PIN N15 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_p[2]}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_n[2]}]

# PLL locked LED - G2
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {clk_lock_led}]