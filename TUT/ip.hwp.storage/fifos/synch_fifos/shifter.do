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
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/dut/intermediate_signal
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/dut/first_slot/data_reg
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/dut/map_slots__3/gen_slot_i/data_reg
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/dut/map_slots__2/gen_slot_i/data_reg
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/dut/map_slots__1/gen_slot_i/data_reg
add wave -noupdate -format Literal -radix unsigned /tb_fifo2/dut/map_slots__0/gen_slot_i/data_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {102 ns}
WaveRestoreZoom {0 ns} {442 ns}
configure wave -namecolwidth 220
configure wave -valuecolwidth 110
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
