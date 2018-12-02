#!/bin/sh
cp ../synth_top_tb.vhd  ../tb_clock_process.vhd ../tb_uart_pkg.vhd ../tb_logger.vhd .
ghdl -i --std=08 --no-vital-checks -Pxilinx-vivado/unisim/v08 post_route.vhd tb_clock_process.vhd tb_uart_pkg.vhd tb_logger.vhd synth_top_tb.vhd
ghdl -m --std=08 --no-vital-checks -Pxilinx-vivado/unisim/v08 -frelaxed-rules synth_top_tb
