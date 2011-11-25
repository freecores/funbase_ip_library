#!/bin/sh
#
# Skripti kaantaa kaikki vhdl-tiedostot ja tekee niista makefilen
# Ymparistomuuttjat 
#	TMP_DIR 	kertoo mihin hakemistoon kaannetyt fiilut laitetaan.
#	

clear

if test -z $TMP_DIR
then
	echo "Env variable TMP_DIR, which defines the location of Modelsim's work dir, is not set"
	echo "->Exit"
	exit
fi

	mkdir $TMP_DIR

	#Poistetaan vanha codelib ja tehdaan ja mapataan uusi
	echo "Removing old vhdl library "
	rm -rf $TMP_DIR/codelib
	rm -rf $TMP_DIR/st


echo; echo "Creating a new library at"
echo $TMP_DIR; echo

vlib $TMP_DIR/codelib
vmap work $TMP_DIR/codelib

# vlib $TMP_DIR/st
# vmap st $TMP_DIR/st


# ST:n kirjastokomponenttien simulointimallit
# echo 'Compliling ST synthesis libraries'
# vcom -quiet -work st /export/prog/IC/st/hcmos9/HCMOS9SIGE_8.0/CORE9GPLL_SNPS_AVT_4.1_1.1/VHDL_FUNCT/CORE9GPLL_COMPONENTS.vhd
# vcom -quiet -work st /export/prog/IC/st/hcmos9/HCMOS9SIGE_8.0/CORE9GPLL_SNPS_AVT_4.1_1.1/VHDL_FUNCT/CORE9GPLL_VHDL_FUNCT.vhd

#vcom -quiet -work st /export/prog/IC/st/hcmos9/HCMOS9SIGE_8.0/CORE9GPLL_SNPS_AVT_4.1_1.1/VHDL_FUNCT/CORE9GPLL_COMPONENTS.vhd
#vcom -quiet -work st /export/prog/IC/st/hcmos9/HCMOS9SIGE_8.0/CORE9GPLL_SNPS_AVT_4.1_1.1/VHDL_FUNCT/CORE9GPLL_VHDL_FUNCT.vhd



echo; echo "Compiling vhdl codes"; echo

echo; echo "Compiling HIBI"; echo

HIBI_DIR="../../hibi/vhd"
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/hibiv2_pkg.vhd

vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/addr_decoder.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/addr_data_demuxes.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/addr_data_muxes.vhd

vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/cfg_init_pkg.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/cfg_mem.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/copy_of_multiclk_fifo.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/dyn_arb.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/lfsr.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/fifo.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/double_fifo_demux_wr.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/double_fifo_mux_rd.vhd

vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/rx_ctrl.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/tx_ctrl.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/receiver.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/transmitter.vhd

vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/hibi_wrapper_r1.vhd
vcom -quiet -check_synthesis -pedanticerrors $HIBI_DIR/hibi_wrapper_r4.vhd

echo
echo "Compile basic tester component"
TESTER_DIR="../vhd"
vcom -quiet -check_synthesis -pedanticerrors $TESTER_DIR/txt_util.vhd
vcom -quiet -check_synthesis -pedanticerrors $TESTER_DIR/basic_tester_pkg.vhd
vcom -quiet -check_synthesis -pedanticerrors $TESTER_DIR/basic_tester_rx.vhd
vcom -quiet -check_synthesis -pedanticerrors $TESTER_DIR/basic_tester_tx.vhd



# Testipenkki
echo; echo "Compiling vhdl testbenches";echo
vcom -quiet ../tb/tb_basic_tester.vhd


echo;echo "Creating a new makefile"
rm -f makefile.vhd
vmake $TMP_DIR/codelib > makefile.vhd

echo " --------Create_Makefile done------------- "



