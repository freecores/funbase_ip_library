global env ;

set QUARTUS_ROOTDIR "c:/altera/10.0sp1/quartus"

if [regexp {ModelSim ALTERA} [vsim -version]] {
        # Using Altera OEM Version need to add one more library mapping
        set altgxb_path $env(MODEL_TECH)\/../altera/verilog/altgxb ;
        set alt2gxb_path $env(MODEL_TECH)\/../altera/verilog/stratixiigx_hssi ;
        vmap altgxb_ver $altgxb_path ;
   vmap stratixiigx_hssi_ver $alt2gxb_path ;
} else {
   # Using non-OEM Version, compile all of the libraries
   vlib lpm_ver
   vmap lpm_ver lpm_ver
   vlog -work lpm_ver $QUARTUS_ROOTDIR/eda/sim_lib/220model.v

   vlib altera_mf_ver
   vmap altera_mf_ver altera_mf_ver
   vlog -work altera_mf_ver $QUARTUS_ROOTDIR/eda/sim_lib/altera_mf.v

   vlib sgate_ver
   vmap sgate_ver sgate_ver
   vlog -work sgate_ver $QUARTUS_ROOTDIR/eda/sim_lib/sgate.v

   vlib altgxb_ver
   vmap altgxb_ver altgxb_ver
   vlog -work altgxb_ver $QUARTUS_ROOTDIR/eda/sim_lib/stratixgx_mf.v

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

      vlib arriaii_hssi_ver
      vmap arriaii_hssi_ver arriaii_hssi_ver
      vmap arriaii_hssi arriaii_hssi_ver
      vlog -work arriaii_hssi $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_hssi_atoms.v

      vlib arriaii_pcie_hip_ver
      vmap arriaii_pcie_hip_ver arriaii_pcie_hip_ver
      vmap arriaii_pcie_hip arriaii_pcie_hip_ver
      vlog -work arriaii_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_pcie_hip_atoms.v

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

      vlib stratixv_hssi_ver
      vmap stratixv_hssi_ver stratixv_hssi_ver
      vmap stratixv_hssi stratixv_hssi_ver
      vlog     -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/altera_primitives.v
      vlog -sv -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_hssi_atoms.v
      vlog -sv -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/mentor/stratixv_hssi_atoms_ncrypt.v

      vlib stratixv_pcie_hip_ver
      vmap stratixv_pcie_hip_ver stratixv_pcie_hip_ver
      vmap stratixv_pcie_hip stratixv_pcie_hip_ver
      vlog -sv -work stratixv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_pcie_hip_atoms.v
      vlog -sv -work stratixv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/mentor/stratixv_pcie_hip_atoms_ncrypt.v

   }
}

# Create the work library
vlib work

# Now compile the Verilog files one by one
alias _comp {
set simlist [open sim_filelist r]
while {[gets $simlist vfile] >= 0} {
    vlog +incdir+../../common/testbench/+../../common/incremental_compile_module+.. -work work $vfile
}
close $simlist
}

_comp
# Now run the simulation
alias _vsim  {
vsim -novopt -t ps -L altera_mf_ver -L lpm_ver -L sgate_ver -L altgxb_ver -L stratixiigx_hssi_ver -L  stratixiv_hssi_ver -L stratixiv_pcie_hip_ver  -L arriaii_hssi_ver -L arriaii_pcie_hip_ver  -L cycloneiv_hssi_ver -L cycloneiv_pcie_hip_ver -L hardcopyiv_hssi_ver -L hardcopyiv_pcie_hip_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver a2_pex_x8_chaining_testbench
}

_vsim
set NumericStdNoWarnings 1
set StdArithNoWarnings 1
onbreak { resume }

# Log all nets
# log -r /*

run -all
