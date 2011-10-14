# Configuration file formats:
#
# tbrx_conf_hibisend.dat : dest_agent_n, delay, amount
# tbrx_conf_rx.dat       : mem_addr, sender, irq_amount (=words to receive)
# tbrx_data_file.dat     : mem_addr, sender, irq_amount (=words to receive)
#
#



quit -sim

vlib work

# HW files

vcom -check_synthesis -pedantic ../vhd/one_hot_mux.vhd
vcom -check_synthesis -pedantic ../vhd/step_counter2.vhd
vcom -check_synthesis -pedantic ../vhd/n2h2_rx_chan.vhd
vcom -check_synthesis -pedantic ../vhd/n2h2_rx_channels.vhd
vcom -check_synthesis -pedantic ../vhd/n2h2_tx_vl.vhd
vcom -check_synthesis -pedantic ../vhd/n2h2_chan.vhd


# TB files

vcom ./blocks/txt_util.vhd
vcom ./blocks/fifo.vhd
vcom ./blocks/tb_n2h2_pkg.vhd
vcom ./blocks/hibi_sender_n2h2.vhd
vcom ./blocks/avalon_cfg_reader.vhd
vcom ./blocks/avalon_cfg_writer.vhd
vcom ./blocks/avalon_reader.vhd
vcom ./blocks/sram_scalable_v3.vhd
vcom ./blocks/tb_n2h2_rx.vhd

vsim -t 1ns work.tb_n2h2_rx
do ./blocks/wave_tb_n2h2_rx.do