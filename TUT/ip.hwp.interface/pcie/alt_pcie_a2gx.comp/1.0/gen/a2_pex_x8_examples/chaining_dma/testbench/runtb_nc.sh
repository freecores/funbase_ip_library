#!/bin/tcsh
cat sim_filelist | sed -e "/_icm.v/ s/^/-v /g" -e "/example_.*_top/ s/^/-v /g" -e "/altpcie_/ s/^/-v /g"> sim_filelist.f

setenv QUARTUS_ROOTDIR 'c:/altera/10.0sp1/quartus'

echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/220model.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/altera_mf.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/sgate.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/stratixgx_mf.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/stratixiigx_hssi_atoms.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/libraries/megafunctions/alt2gxb.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_hssi_atoms.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_pcie_hip_atoms.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_hssi_atoms.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_pcie_hip_atoms.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/cycloneiv_hssi_atoms.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/cycloneiv_pcie_hip_atoms.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/hardcopyiv_hssi_atoms.v" >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/hardcopyiv_pcie_hip_atoms.v" >> sim_filelist.f
echo "-sv $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_hssi_atoms.v" >> sim_filelist.f
echo "-sv $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_pcie_hip_atoms.v" >> sim_filelist.f
echo "-sv $QUARTUS_ROOTDIR/eda/sim_lib/altera_primitives.v" >> sim_filelist.f
echo "-sv $QUARTUS_ROOTDIR/eda/sim_lib/cadence/stratixv_hssi_atoms_ncrypt.v" >> sim_filelist.f
echo "-sv $QUARTUS_ROOTDIR/eda/sim_lib/cadence/stratixv_pcie_hip_atoms_ncrypt.v" >> sim_filelist.f

ncverilog +DEFINE+VCS -f sim_filelist.f +incdir+../../common/testbench/+../../common/incremental_compile_module -l transcript
