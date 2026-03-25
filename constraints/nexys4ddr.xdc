## Nexys4 DDR (Nexys A7-100T) Constraints — Platformer Game

## Clock — 100 MHz oscillator
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk_100mhz]

## Buttons (active-high on Nexys4 DDR)
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports btn_center]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports btn_up]
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports btn_left]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports btn_right]

## VGA Red
set_property -dict {PACKAGE_PIN A3  IOSTANDARD LVCMOS33} [get_ports {vga_r[0]}]
set_property -dict {PACKAGE_PIN B4  IOSTANDARD LVCMOS33} [get_ports {vga_r[1]}]
set_property -dict {PACKAGE_PIN C5  IOSTANDARD LVCMOS33} [get_ports {vga_r[2]}]
set_property -dict {PACKAGE_PIN A4  IOSTANDARD LVCMOS33} [get_ports {vga_r[3]}]

## VGA Green
set_property -dict {PACKAGE_PIN C6  IOSTANDARD LVCMOS33} [get_ports {vga_g[0]}]
set_property -dict {PACKAGE_PIN A5  IOSTANDARD LVCMOS33} [get_ports {vga_g[1]}]
set_property -dict {PACKAGE_PIN B6  IOSTANDARD LVCMOS33} [get_ports {vga_g[2]}]
set_property -dict {PACKAGE_PIN A6  IOSTANDARD LVCMOS33} [get_ports {vga_g[3]}]

## VGA Blue
set_property -dict {PACKAGE_PIN B7  IOSTANDARD LVCMOS33} [get_ports {vga_b[0]}]
set_property -dict {PACKAGE_PIN C7  IOSTANDARD LVCMOS33} [get_ports {vga_b[1]}]
set_property -dict {PACKAGE_PIN D7  IOSTANDARD LVCMOS33} [get_ports {vga_b[2]}]
set_property -dict {PACKAGE_PIN D8  IOSTANDARD LVCMOS33} [get_ports {vga_b[3]}]

## VGA Sync
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports vga_hsync]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports vga_vsync]
