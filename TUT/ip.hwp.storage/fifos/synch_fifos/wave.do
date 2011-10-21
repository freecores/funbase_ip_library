onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /tb_fifo2/clk
add wave -noupdate -format Logic /tb_fifo2/rst_n
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/data_in
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/data_out
add wave -noupdate -format Logic /tb_fifo2/write_enable
add wave -noupdate -format Logic /tb_fifo2/read_enable
add wave -noupdate -format Logic /tb_fifo2/full
add wave -noupdate -format Logic /tb_fifo2/one_place_left
add wave -noupdate -format Logic /tb_fifo2/empty
add wave -noupdate -format Logic /tb_fifo2/one_data_left
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/read_data
add wave -noupdate -format Literal /tb_fifo2/test_phase
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/dut/fifo_buffer
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {0 ns}
WaveRestoreZoom {0 ns} {1 us}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
