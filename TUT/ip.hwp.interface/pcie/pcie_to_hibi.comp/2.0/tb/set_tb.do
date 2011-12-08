#-----------------------------------------------------------------------------
# Copyright ??? 2010 Altera Corporation. All rights reserved.  Altera products are
# protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
# other intellectual property laws.
#
# This reference design file, and your use thereof, is subject to and governed by
# the terms and conditions of the applicable Altera Reference Design License Agreement.
# By using this reference design file, you indicate your acceptance of such terms and
# conditions between you and Altera Corporation.  In the event that you do not agree with
# such terms and conditions, you may not use the reference design file. Please promptly
# destroy any copies you have made.
#
# This reference design file being provided on an "as-is" basis and as an accommodation
# and therefore all warranties, representations or guarantees of any kind
# (whether express, implied or statutory) including, without limitation, warranties of
# merchantability, non-infringement, or fitness for a particular purpose, are
# specifically disclaimed.  By making this reference design file available, Altera
# expressly does not recommend, suggest or require that this reference design file be
# used in combination with any other product not provided by Altera.
#-----------------------------------------------------------------------------
global env ;

set QUARTUS_ROOTDIR "c:/altera/11.0/quartus"
set PHY_TYPE_STRATIXVGX 0
set MSIM_AE ""
set NOIMMEDCA ""
set QUIET_COMP -nologo
#-quiet

alias comp_alt {
     # Using non-OEM Version, compile all of the libraries
     set NOIMMEDCA "-noimmedca"
     vlib lpm_ver
     vmap lpm_ver lpm_ver
     vlog -work lpm_ver $QUARTUS_ROOTDIR/eda/sim_lib/220model.v
  
     vlib altera_mf_ver
     vmap altera_mf_ver altera_mf_ver
     vlog -work altera_mf_ver $QUARTUS_ROOTDIR/eda/sim_lib/altera_mf.v
     
     vlib altera_mfr
     vmap altera_mf altera_mf
     vcom -work altera_mf $QUARTUS_ROOTDIR/eda/sim_lib/altera_mf_components.vhd
     vcom -work altera_mf $QUARTUS_ROOTDIR/eda/sim_lib/altera_mf.vhd
     
     vlib sgate_ver
     vmap sgate_ver sgate_ver
     vlog -work sgate_ver $QUARTUS_ROOTDIR/eda/sim_lib/sgate.v
  
     vlib stratixiigx_hssi_ver
     vmap stratixiigx_hssi_ver stratixiigx_hssi_ver
     vlog -work stratixiigx_hssi_ver $QUARTUS_ROOTDIR/eda/sim_lib/stratixiigx_hssi_atoms.v
     vlog -work stratixiigx_hssi_ver $QUARTUS_ROOTDIR/libraries/megafunctions/alt2gxb.v
  
     if [ file exists $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_hssi_atoms.v ] {
  
        vlib stratixiv_hssi_ver
        vmap stratixiv_hssi_ver stratixiv_hssi_ver
        vmap stratixiv_hssi stratixiv_hssi_ver
        vlog -work stratixiv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_hssi_atoms.v
  
        vlib stratixiv_pcie_hip_ver
        vmap stratixiv_pcie_hip_ver stratixiv_pcie_hip_ver
        vmap stratixiv_pcie_hip stratixiv_pcie_hip_ver
        vlog -work stratixiv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_pcie_hip_atoms.v
  
        if { $PHY_TYPE_STRATIXVGX == 0 } {
           vlib arriaii_hssi_ver
           vmap arriaii_hssi_ver arriaii_hssi_ver
           vmap arriaii_hssi arriaii_hssi_ver
           vlog -work arriaii_hssi $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_hssi_atoms.v
  
           vlib arriaii_pcie_hip_ver
           vmap arriaii_pcie_hip_ver arriaii_pcie_hip_ver
           vmap arriaii_pcie_hip arriaii_pcie_hip_ver
           vlog -work arriaii_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_pcie_hip_atoms.v
  
           vlib arriaiigz_hssi_ver
           vmap arriaiigz_hssi_ver arriaiigz_hssi_ver
           vmap arriaiigz_hssi arriaiigz_hssi_ver
           vlog -work arriaiigz_hssi $QUARTUS_ROOTDIR/eda/sim_lib/arriaiigz_hssi_atoms.v
  
           vlib arriaiigz_pcie_hip_ver
           vmap arriaiigz_pcie_hip_ver arriaiigz_pcie_hip_ver
           vmap arriaiigz_pcie_hip arriaiigz_pcie_hip_ver
           vlog -work arriaiigz_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/arriaiigz_pcie_hip_atoms.v
  
           vlib cycloneiv_hssi_ver
           vmap cycloneiv_hssi_ver cycloneiv_hssi_ver
           vmap cycloneiv_hssi cycloneiv_hssi_ver
           vlog -work cycloneiv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/cycloneiv_hssi_atoms.v
  
           vlib cycloneiv_pcie_hip_ver
           vmap cycloneiv_pcie_hip_ver cycloneiv_pcie_hip_ver
           vmap cycloneiv_pcie_hip cycloneiv_pcie_hip_ver
           vlog -work cycloneiv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/cycloneiv_pcie_hip_atoms.v
  
           vlib hardcopyiv_hssi_ver
           vmap hardcopyiv_hssi_ver hardcopyiv_hssi_ver
           vmap hardcopyiv_hssi hardcopyiv_hssi_ver
           vlog -work hardcopyiv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/hardcopyiv_hssi_atoms.v
  
           vlib hardcopyiv_pcie_hip_ver
           vmap hardcopyiv_pcie_hip_ver hardcopyiv_pcie_hip_ver
           vmap hardcopyiv_pcie_hip hardcopyiv_pcie_hip_ver
           vlog -work hardcopyiv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/hardcopyiv_pcie_hip_atoms.v
        } else {
           vlib stratixv_hssi_ver
           vmap stratixv_hssi_ver stratixv_hssi_ver
           vmap stratixv_hssi stratixv_hssi_ver
           vlog     -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/altera_primitives.v
           vlog -sv -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_hssi_atoms.v
           vlog -sv -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/mentor/stratixv_hssi_atoms_ncrypt.v
           vlog -sv -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/altera_lnsim.sv
  
           vlib stratixv_pcie_hip_ver
           vmap stratixv_pcie_hip_ver stratixv_pcie_hip_ver
           vmap stratixv_pcie_hip stratixv_pcie_hip_ver
           vlog -sv -work stratixv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_pcie_hip_atoms.v
           vlog -sv -work stratixv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/mentor/stratixv_pcie_hip_atoms_ncrypt.v
  
        }
     }
}


# Create the work library
vlib work

# Now compile the Verilog files one by one
alias _comp {
set simlist [open ../alt_pcie_ctrl/a2_pex_x8_/a2_pex_x8_examples/chaining_dma/testbench/sim_filelist r]
while {[gets $simlist vfile] >= 0} {
    vlog +incdir+../alt_pcie_ctrl/a2_pex_x8_/a2_pex_x8_examples/common/testbench/+../alt_pcie_ctrl/a2_pex_x8_/a2_pex_x8_examples/common/incremental_compile_module+../alt_pcie_ctrl/a2_pex_x8_/a2_pex_x8_examples/chaining_dma/testbench/+../alt_pcie_ctrl/a2_pex_x8_/a2_pex_x8_examples/chaining_dma/ -work work ../alt_pcie_ctrl/a2_pex_x8_/a2_pex_x8_examples/chaining_dma/testbench/$vfile
}
close $simlist
}

alias simulate {
  eval vsim $NOIMMEDCA -novopt -t ps -L altera_mf_ver -L lpm_ver -L sgate_ver -L stratixiigx_hssi_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L arriaii_hssi_ver -L arriaii_pcie_hip_ver -L arriaiigz_hssi_ver -L arriaiigz_pcie_hip_ver -L cycloneiv_hssi_ver -L cycloneiv_pcie_hip_ver -L hardcopyiv_hssi_ver -L hardcopyiv_pcie_hip_ver a2_pex_x8_chaining_testbench
  do tb_wave.do
  run 140us
}

alias simulate_adv {
  eval vsim $NOIMMEDCA -novopt -t ps -L altera_mf_ver -L lpm_ver -L sgate_ver -L stratixiigx_hssi_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L arriaii_hssi_ver -L arriaii_pcie_hip_ver -L arriaiigz_hssi_ver -L arriaiigz_pcie_hip_ver -L cycloneiv_hssi_ver -L cycloneiv_pcie_hip_ver -L hardcopyiv_hssi_ver -L hardcopyiv_pcie_hip_ver a2_pex_x8_chaining_testbench
  do tb_wave.do
  
  run 79620ns
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/tx_st_valid_o 0 0
  run 16ns
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/tx_st_valid_o
  
  run 5517ps
  
#  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/rx_stream_valid0 0 0
#  noforce sim:/a2_pex_x8_chaining_testbench/ep/rx_stream_valid0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/gen_1/pcie_dma_0/ipkt_re_in 0 0
  
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_is_read_req_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in x\"400\" 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_length_in x\"20\" 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_req_id_in x\"1000\" 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_tag_in x\"f\" 0
  
  run 130ns
  
#  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/gen_1/pcie_dma_0/ipkt_re_in
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in
  
  run 2us
  
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in x\"100\" 0
  run 130ns
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in
  run 40ns
  
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in x\"200\" 0
  run 130ns
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in
  run 40ns
  
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in x\"300\" 0
  run 130ns
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in
  run 40ns
  
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in x\"400\" 0
  run 130ns
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in
  run 40ns
  
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in x\"500\" 0
  run 130ns
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in
  run 40ns
  
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in x\"600\" 0
  run 130ns
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in
  run 40ns
  
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in x\"700\" 0
  run 130ns
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in
  run 40ns
  
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in 1 0
  force -freeze sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in x\"800\" 0
  run 130ns
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_valid_in
  run 2us
  
#  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_is_read_req_in
#  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_addr_in
#  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_length_in
#  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_req_id_in
#  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/hibi_if_0/ipkt_tag_in
  
#  noforce sim:/a2_pex_x8_chaining_testbench/ep/rx_stream_valid0
  noforce sim:/a2_pex_x8_chaining_testbench/ep/test_app/pcie_to_hibi_0/gen_1/pcie_dma_0/ipkt_re_in
  
#  run 140us
}

alias simu_debug {
  eval vsim $NOIMMEDCA -novopt -t ps -L altera_mf_ver -L lpm_ver -L sgate_ver -L stratixiigx_hssi_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L arriaii_hssi_ver -L arriaii_pcie_hip_ver -L arriaiigz_hssi_ver -L arriaiigz_pcie_hip_ver -L cycloneiv_hssi_ver -L cycloneiv_pcie_hip_ver -L hardcopyiv_hssi_ver -L hardcopyiv_pcie_hip_ver a2_pex_x8_chaining_testbench
  do tb_wave.do
  run 140us
}

proc comp_list {comp_dir} {
  set simlist_file [open $comp_dir/sim_filelist r]
  if { [ file exists $comp_dir/incdir_list ] } {
    set incdirlist_file [open $comp_dir/incdir_list r]
    while {[gets $incdirlist_file temp_str] >= 0} {
      append incdirlist "+$comp_dir/$temp_str"
    }
  } else {
    set incdirlist ""
  }
  
  while {[gets $simlist_file vfile] >= 0} {
    if { [ regexp {\.v$} $vfile ] || [ regexp {\.vo$} $vfile ] } {
      regexp {.*/} $vfile inc_dir
      vlog -reportprogress 300 +incdir+$comp_dir/$inc_dir$incdirlist -work work $comp_dir/$vfile
    } else {
      vcom -work work -check_synthesis -error 1400 $comp_dir/$vfile
    }
  }
  close $simlist_file
}


alias comp_p2h {
  vcom -work work -check_synthesis -error 1400 ../../../../../ip.hwp.support/txt_util/1.0/hdl/*.vhd $QUIET_COMP
  vcom -work work -check_synthesis -error 1400 ../../../../../ip.hwp.storage/onchip_mem/alt_mem_dc_dw.comp/1.0/hdl/*.vhd $QUIET_COMP
  vcom -work work -check_synthesis -error 1400 ../../../../../ip.hwp.storage/onchip_mem/alt_mem_sc.comp/1.0/hdl/*.vhd $QUIET_COMP
  vcom -work work -check_synthesis -error 1400 ../../../../../ip.hwp.storage/onchip_fifo/alt_fifo_dc_dw.comp/1.0/hdl/*.vhd $QUIET_COMP
  vcom -work work -check_synthesis -error 1400 ../../../../../ip.hwp.storage/onchip_fifo/alt_fifo_sc.comp/1.0/hdl/*.vhd $QUIET_COMP
  comp_list ./
  vcom -work work -check_synthesis -error 1400 ../tb/hibiv3_seg_r3.vhd $QUIET_COMP
  vcom -work work -check_synthesis -error 1400 ../tb/pcie_to_hibi_test_app.vhd $QUIET_COMP
  vlog -reportprogress 300 -work work ../tb/a2_pex_x8_app_if.v $QUIET_COMP
}

alias comp {
  comp_alt
  comp_list ../../../../../ip.hwp.communication/hibi/hibi_segment_small/3.0/tb
  comp_list ../../../../../ip.hwp.storage/ddrx/alt_ddr2_agx2.comp/2.0/tb
  comp_list ../../../../../ip.hwp.storage/ddrx/hibi_mem_dma.comp/2.0/tb
  comp_list ../../../../../ip.hwp.interface/pcie/alt_pcie_a2gx.comp/1.0/tb
  comp_p2h
}

alias comp_sim {
  comp_p2h
  simulate
}

alias comp_sim_adv {
  comp_p2h
  simulate_adv
}

echo "--------------------------------------------------------------------------------------------------------------"
echo " command 'comp' compiles all the necessary files for running the testbench"
echo "  - this command has to be run only once"
echo ""
echo " command 'comp_sim' compiles only the pcie_to_hibi and starts the simulation"
echo " - use this command each time you have made changes to the pcie_to_hibi and want to verify it's functionality"
echo "--------------------------------------------------------------------------------------------------------------"
