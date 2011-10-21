onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/clk_in
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/clk_out
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/rst_n
add wave -noupdate -format Literal -radix decimal /tb_fifo_mixed_clocks2/dut/data_in
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/write_enable
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/full
add wave -noupdate -format Literal -radix decimal /tb_fifo_mixed_clocks2/dut/data_out
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/read_enable
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/empty
add wave -noupdate -format Literal -radix decimal /tb_fifo_mixed_clocks2/dut/input_buffer
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/full_reg
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/empty_reg
add wave -noupdate -format Literal -radix decimal /tb_fifo_mixed_clocks2/dut/write_token
add wave -noupdate -format Literal -radix decimal /tb_fifo_mixed_clocks2/dut/read_token
add wave -noupdate -format Logic -radix decimal /tb_fifo_mixed_clocks2/dut/write_turned
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {92 ns}
WaveRestoreZoom {0 ns} {257 ns}
configure wave -namecolwidth 211
configure wave -valuecolwidth 39
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
run 700
