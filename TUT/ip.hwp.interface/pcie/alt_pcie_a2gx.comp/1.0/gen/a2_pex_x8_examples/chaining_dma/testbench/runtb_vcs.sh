#!/bin/tcsh

setenv QUARTUS_ROOTDIR 'c:/altera/10.0sp1/quartus'

# work around long Altera Attribute
#
set serdes_file = `ls ../../../*serdes.v`
cat $serdes_file |grep -v ALTERA_ATTRIBUTE > tmp.serdes
mv tmp.serdes $serdes_file
cat ../../common/testbench/altpcie_reconfig_4sgx.v |grep -v ALTERA_ATTRIBUTE > tmp.reconfig
mv tmp.reconfig ../../common/testbench/altpcie_reconfig_4sgx.v
cat ../../common/testbench/altpcie_reconfig_3cgx.v |grep -v ALTERA_ATTRIBUTE > tmp.reconfig
mv tmp.reconfig ../../common/testbench/altpcie_reconfig_3cgx.v

cat sim_filelist | sed -e "/_icm.v/ s/^/-v /g" -e "/example_.*_top/ s/^/-v /g" -e "/altpcie_/ s/^/-v /g" > sim_filelist.f
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
echo "-sv $QUARTUS_ROOTDIR/eda/sim_lib/synopsys/stratixv_hssi_atoms_ncrypt.v" >> sim_filelist.f
echo "-sv $QUARTUS_ROOTDIR/eda/sim_lib/synopsys/stratixv_pcie_hip_atoms_ncrypt.v" >> sim_filelist.f
vcs -ntb_opts check -R +vcs+lic+wait +error+100 +v2k +incdir+../../common/testbench/+../../common/incremental_compile_module -f sim_filelist.f -l transcript

