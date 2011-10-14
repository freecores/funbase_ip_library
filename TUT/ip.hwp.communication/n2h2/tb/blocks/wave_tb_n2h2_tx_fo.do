onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {TB top}
add wave -noupdate -format Literal /tb_n2h2_tx/test_control
add wave -noupdate -format Literal /tb_n2h2_tx/test_case_control
add wave -noupdate -format Logic /tb_n2h2_tx/clk
add wave -noupdate -format Logic /tb_n2h2_tx/clk2
add wave -noupdate -format Logic /tb_n2h2_tx/rst_n
add wave -noupdate -format Logic /tb_n2h2_tx/tx_status_from_n2h_tx
add wave -noupdate -format Logic /tb_n2h2_tx/tx_irq_to_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/amount_to_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/amount_vec_to_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/dpram_vec_addr_to_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/dpram_addr_to_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/comm_to_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/hibi_data_vec_from_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/hibi_data_from_n2h_tx
add wave -noupdate -format Logic /tb_n2h2_tx/hibi_av_from_n2h_tx
add wave -noupdate -format Logic /tb_n2h2_tx/hibi_full_to_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/hibi_comm_from_n2h_tx
add wave -noupdate -format Logic /tb_n2h2_tx/hibi_we_from_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/avalon_addr_from_n2h_tx
add wave -noupdate -format Logic /tb_n2h2_tx/avalon_read_from_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/avalon_vec_readdata_to_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/avalon_readdata_to_n2h_tx
add wave -noupdate -format Logic /tb_n2h2_tx/avalon_waitrequest_to_n2h_tx
add wave -noupdate -format Logic /tb_n2h2_tx/avalon_readdatavalid_to_n2h_tx
add wave -noupdate -format Literal /tb_n2h2_tx/counter
add wave -noupdate -format Literal /tb_n2h2_tx/new_hibi_addr
add wave -noupdate -format Literal /tb_n2h2_tx/new_amount
add wave -noupdate -format Literal /tb_n2h2_tx/new_dpram_addr
add wave -noupdate -format Literal /tb_n2h2_tx/global_hibi_address
add wave -noupdate -format Literal /tb_n2h2_tx/global_amount
add wave -noupdate -format Literal /tb_n2h2_tx/global_comm
add wave -noupdate -format Literal /tb_n2h2_tx/global_dpram_addr
add wave -noupdate -format Literal /tb_n2h2_tx/avalon_data_counter
add wave -noupdate -format Literal /tb_n2h2_tx/avalon_addr_counter
add wave -noupdate -format Literal /tb_n2h2_tx/avalon_amount
add wave -noupdate -format Logic /tb_n2h2_tx/avalon_addr_sent
add wave -noupdate -format Literal /tb_n2h2_tx/avalon_last_addr
add wave -noupdate -format Logic /tb_n2h2_tx/hibi_addr_came
add wave -noupdate -format Literal /tb_n2h2_tx/hibi_data_counter
add wave -noupdate -format Literal /tb_n2h2_tx/hibi_amount
add wave -noupdate -divider {DUT tx}
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/clk
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/rst_n
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/avalon_addr_out
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/avalon_re_out
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/avalon_readdata_in
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/avalon_waitrequest_in
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/avalon_readdatavalid_in
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/hibi_data_out
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/hibi_av_out
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/hibi_full_in
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/hibi_comm_out
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/hibi_we_out
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/tx_start_in
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/tx_status_done_out
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/tx_comm_in
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/tx_hibi_addr_in
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/tx_ram_addr_in
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/tx_amount_in
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/control_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/addr_cnt_en_r
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/addr_cnt_value_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/addr_cnt_load_r
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/addr_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/amount_cnt_en_r
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/amount_cnt_value_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/amount_cnt_load_r
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/amount_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/addr_amount_eq
add wave -noupdate -format Literal /tb_n2h2_tx/n2h2_tx_1/addr_to_stop_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/avalon_re_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/start_re_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/hibi_write_addr_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/data_src_sel
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/hibi_we_r
add wave -noupdate -format Logic /tb_n2h2_tx/n2h2_tx_1/hibi_stop_we_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {100549517 ns} 0}
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
WaveRestoreZoom {29948127 ns} {164575814 ns}
