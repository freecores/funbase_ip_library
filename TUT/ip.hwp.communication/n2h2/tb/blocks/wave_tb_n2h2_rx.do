onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {TB top}
add wave -noupdate -format Logic /tb_n2h2_rx/clk
add wave -noupdate -format Logic /tb_n2h2_rx/clk2
add wave -noupdate -format Logic /tb_n2h2_rx/rst_n
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/avalon_addr_from_rx
add wave -noupdate -format Logic /tb_n2h2_rx/avalon_we_from_rx
add wave -noupdate -format Literal /tb_n2h2_rx/avalon_be_from_rx
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/avalon_writedata_from_rx
add wave -noupdate -format Logic /tb_n2h2_rx/avalon_waitrequest_to_rx
add wave -noupdate -format Literal /tb_n2h2_rx/avalon_waitreqvec_to_rx
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/hibi_data_to_rx
add wave -noupdate -format Logic /tb_n2h2_rx/hibi_av_to_rx
add wave -noupdate -format Logic /tb_n2h2_rx/hibi_empty_to_rx
add wave -noupdate -format Literal /tb_n2h2_rx/hibi_comm_to_rx
add wave -noupdate -format Logic /tb_n2h2_rx/hibi_re_from_rx
add wave -noupdate -format Literal /tb_n2h2_rx/avalon_cfg_addr_to_rx
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/avalon_cfg_writedata_to_rx
add wave -noupdate -format Logic /tb_n2h2_rx/avalon_cfg_we_to_rx
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/avalon_cfg_readdata_from_rx
add wave -noupdate -format Logic /tb_n2h2_rx/avalon_cfg_re_to_rx
add wave -noupdate -format Logic /tb_n2h2_rx/avalon_cfg_cs_to_rx
add wave -noupdate -format Logic /tb_n2h2_rx/rx_irq_from_rx
add wave -noupdate -format Logic /tb_n2h2_rx/tx_start_from_rx
add wave -noupdate -format Logic /tb_n2h2_rx/tx_status_done_to_rx
add wave -noupdate -format Logic /tb_n2h2_rx/start_to_cfg
add wave -noupdate -format Literal /tb_n2h2_rx/avalon_cfg_addr_from_cfg
add wave -noupdate -format Logic /tb_n2h2_rx/avalon_cfg_cs_from_cfg
add wave -noupdate -format Logic /tb_n2h2_rx/done_from_cfg
add wave -noupdate -format Logic /tb_n2h2_rx/init_to_cfg
add wave -noupdate -format Logic /tb_n2h2_rx/start_to_cfg_reader
add wave -noupdate -format Literal /tb_n2h2_rx/avalon_cfg_addr_from_cfg_reader
add wave -noupdate -format Logic /tb_n2h2_rx/avalon_cfg_cs_from_cfg_reader
add wave -noupdate -format Logic /tb_n2h2_rx/done_from_cfg_reader
add wave -noupdate -format Logic /tb_n2h2_rx/done_from_hibi_sender
add wave -noupdate -format Logic /tb_n2h2_rx/pause_hibi_send
add wave -noupdate -format Logic /tb_n2h2_rx/pause_ack_hibi_send
add wave -noupdate -format Literal /tb_n2h2_rx/not_my_addr_from_readers
add wave -noupdate -format Literal /tb_n2h2_rx/system_control_r
add wave -noupdate -format Logic /tb_n2h2_rx/hibi_sender_start
add wave -noupdate -format Logic /tb_n2h2_rx/hibi_sender_rst_n
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/my_own_addr_c
add wave -noupdate -format Logic /tb_n2h2_rx/avalon_reader_rst_n
add wave -noupdate -format Logic /tb_n2h2_rx/hibi_data_read
add wave -noupdate -format Logic /tb_n2h2_rx/irq_was_up
add wave -noupdate -format Literal /tb_n2h2_rx/irq_counter
add wave -noupdate -divider {DUT rx}
add wave -noupdate -format Logic /tb_n2h2_rx/dut/clk
add wave -noupdate -format Logic /tb_n2h2_rx/dut/rst_n
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/avalon_addr_out
add wave -noupdate -format Logic /tb_n2h2_rx/dut/avalon_we_out
add wave -noupdate -format Literal /tb_n2h2_rx/dut/avalon_be_out
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/avalon_writedata_out
add wave -noupdate -format Logic /tb_n2h2_rx/dut/avalon_waitrequest_in
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/hibi_data_in
add wave -noupdate -format Logic /tb_n2h2_rx/dut/hibi_av_in
add wave -noupdate -format Logic /tb_n2h2_rx/dut/hibi_empty_in
add wave -noupdate -format Literal /tb_n2h2_rx/dut/hibi_comm_in
add wave -noupdate -format Logic /tb_n2h2_rx/dut/hibi_re_out
add wave -noupdate -format Literal /tb_n2h2_rx/dut/avalon_cfg_addr_in
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/avalon_cfg_writedata_in
add wave -noupdate -format Logic /tb_n2h2_rx/dut/avalon_cfg_we_in
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/avalon_cfg_readdata_out
add wave -noupdate -format Logic /tb_n2h2_rx/dut/avalon_cfg_re_in
add wave -noupdate -format Logic /tb_n2h2_rx/dut/avalon_cfg_cs_in
add wave -noupdate -format Logic /tb_n2h2_rx/dut/rx_irq_out
add wave -noupdate -format Logic /tb_n2h2_rx/dut/tx_start_out
add wave -noupdate -format Literal /tb_n2h2_rx/dut/tx_comm_out
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/tx_mem_addr_out
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/tx_hibi_addr_out
add wave -noupdate -format Literal /tb_n2h2_rx/dut/tx_amount_out
add wave -noupdate -format Logic /tb_n2h2_rx/dut/tx_status_done_in
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/mem_addr_r
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/sender_addr_r
add wave -noupdate -format Literal -radix unsigned /tb_n2h2_rx/dut/irq_amount_r
add wave -noupdate -format Literal /tb_n2h2_rx/dut/control_r
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/tx_mem_addr_r
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/tx_hibi_addr_r
add wave -noupdate -format Literal /tb_n2h2_rx/dut/tx_amount_r
add wave -noupdate -format Literal /tb_n2h2_rx/dut/tx_comm_r
add wave -noupdate -format Literal /tb_n2h2_rx/dut/init_chan_r
add wave -noupdate -format Literal /tb_n2h2_rx/dut/irq_chan_r
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/current_mem_addr_r
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/current_be_r
add wave -noupdate -format Literal /tb_n2h2_rx/dut/avalon_be_r
add wave -noupdate -format Literal /tb_n2h2_rx/dut/status_r
add wave -noupdate -format Logic /tb_n2h2_rx/dut/irq_reset_r
add wave -noupdate -format Logic /tb_n2h2_rx/dut/hibi_re_r
add wave -noupdate -format Logic /tb_n2h2_rx/dut/avalon_we_r
add wave -noupdate -format Logic /tb_n2h2_rx/dut/unknown_rx
add wave -noupdate -format Logic /tb_n2h2_rx/dut/unknown_rx_irq_r
add wave -noupdate -format Logic /tb_n2h2_rx/dut/unknown_rx_r
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/avalon_addr_r
add wave -noupdate -format Logic /tb_n2h2_rx/dut/curr_chan_avalon_we_r
add wave -noupdate -format Literal /tb_n2h2_rx/dut/avalon_wes
add wave -noupdate -format Literal /tb_n2h2_rx/dut/matches
add wave -noupdate -format Literal /tb_n2h2_rx/dut/matches_cmb
add wave -noupdate -format Literal /tb_n2h2_rx/dut/irq_ack_r
add wave -noupdate -format Literal -radix hexadecimal /tb_n2h2_rx/dut/avalon_addr_temp
add wave -noupdate -format Literal /tb_n2h2_rx/dut/avalon_be_temp
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1191 ns} 0}
configure wave -namecolwidth 211
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ms
update
WaveRestoreZoom {0 ns} {2052 ns}
