onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {ips -> wrappers}
add wave -noupdate -format Logic /tb_video_gen_1/clk_ip
add wave -noupdate -format Logic /tb_video_gen_1/clk_noc
add wave -noupdate -format Logic /tb_video_gen_1/rst_n
add wave -noupdate -format Literal -expand /tb_video_gen_1/av_ip_wra
add wave -noupdate -format Literal -radix hexadecimal -expand /tb_video_gen_1/data_ip_wra
add wave -noupdate -format Literal /tb_video_gen_1/comm_ip_wra
add wave -noupdate -format Literal -expand /tb_video_gen_1/we_ip_wra
add wave -noupdate -format Literal /tb_video_gen_1/full_wra_ip
add wave -noupdate -format Literal /tb_video_gen_1/one_p_wra_ip
add wave -noupdate -divider {wrappers -> ips}
add wave -noupdate -format Logic /tb_video_gen_1/clk_ip
add wave -noupdate -format Logic /tb_video_gen_1/clk_noc
add wave -noupdate -format Literal /tb_video_gen_1/av_wra_ip
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/data_wra_ip
add wave -noupdate -format Literal /tb_video_gen_1/comm_wra_ip
add wave -noupdate -format Literal /tb_video_gen_1/re_ip_wra
add wave -noupdate -format Literal /tb_video_gen_1/empty_wra_ip
add wave -noupdate -format Literal /tb_video_gen_1/one_d_wra_ip
add wave -noupdate -divider {HIBI bus}
add wave -noupdate -format Logic /tb_video_gen_1/av_bus_wra
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/data_bus_wra
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/comm_bus_wra
add wave -noupdate -format Logic /tb_video_gen_1/lock_bus_wra
add wave -noupdate -format Logic /tb_video_gen_1/full_bus_wra
add wave -noupdate -format Literal /tb_video_gen_1/debug_tb_wra
add wave -noupdate -divider {duv: video_gen}
add wave -noupdate -format Logic /tb_video_gen_1/duv/rst_n
add wave -noupdate -format Logic /tb_video_gen_1/duv/clk
add wave -noupdate -format Logic /tb_video_gen_1/duv/hibi_av_out
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/duv/hibi_data_out
add wave -noupdate -format Literal /tb_video_gen_1/duv/hibi_comm_out
add wave -noupdate -format Logic /tb_video_gen_1/duv/hibi_we_out
add wave -noupdate -format Logic /tb_video_gen_1/duv/hibi_full_in
add wave -noupdate -format Logic /tb_video_gen_1/duv/hibi_one_p_in
add wave -noupdate -format Logic /tb_video_gen_1/duv/hibi_av_in
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/duv/hibi_data_in
add wave -noupdate -format Literal /tb_video_gen_1/duv/hibi_comm_in
add wave -noupdate -format Logic /tb_video_gen_1/duv/hibi_re_out
add wave -noupdate -format Logic /tb_video_gen_1/duv/hibi_empty_in
add wave -noupdate -format Logic /tb_video_gen_1/duv/hibi_one_d_in
add wave -noupdate -format Literal /tb_video_gen_1/duv/state_r
add wave -noupdate -format Logic /tb_video_gen_1/duv/picture_start_r
add wave -noupdate -format Literal /tb_video_gen_1/duv/h_count_r
add wave -noupdate -format Literal /tb_video_gen_1/duv/v_count_r
add wave -noupdate -format Literal /tb_video_gen_1/duv/x_move_r
add wave -noupdate -format Literal /tb_video_gen_1/duv/y_move_r
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/duv/image_data_i
add wave -noupdate -format Literal /tb_video_gen_1/duv/curr_pix_r
add wave -noupdate -format Logic /tb_video_gen_1/duv/av_r
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/duv/data_r
add wave -noupdate -format Logic /tb_video_gen_1/duv/we_r
add wave -noupdate -divider {ddr's hibi wrapper}
add wave -noupdate -format Logic /tb_video_gen_1/duv/re_r
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_clk
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_clk
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_sync_clk
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_sync_clk
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/rst_n
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_data_in
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_comm_in
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_full_in
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_lock_in
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_av_in
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_av_in
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_data_in
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_comm_in
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_we_in
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_re_in
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_av_out
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_data_out
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_comm_out
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_full_out
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/bus_lock_out
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_av_out
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_data_out
add wave -noupdate -format Literal -radix hexadecimal /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_comm_out
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_full_out
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_one_p_out
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_empty_out
add wave -noupdate -format Logic /tb_video_gen_1/hibi_net__2/hibi_wrapper_r4_1/agent_one_d_out
add wave -noupdate -divider {hibi wra (x)}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {363168 ns} 0}
configure wave -namecolwidth 212
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
configure wave -timelineunits ns
update
WaveRestoreZoom {252597 ns} {254433 ns}
