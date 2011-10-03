vcom -work work ../hdl/hibi_mem_dma.vhd
vcom -work work hibi_mem_dma_tester.vhd

vsim -voptargs=+acc work.hibi_mem_dma_perf_test_tb -t 1ps -error 3473

do hibi_mem_dma_wave.do
run 300us
