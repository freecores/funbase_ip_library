-------------------------------------------------------------
This is readme for compoenent Nios-to-HIBI-version2 aka. N2H2
-------------------------------------------------------------

Purpose : N2H2 connects Nios II CPU to HIBI network and acts as s DMA controller.



Main idea: 
	N2H2 can copy data from Nios's local memory to   HIBI.
	N2H2 can copy data to   Nios's local memory from HIBI.

	SW running on Nios controls N2H2 via a couple of memory-mapped registers.
	Each transfers needs at least 3 parameters: 
		1. address in local memory
		2. address in HIBI
		3. number or transferred words

Directory structure: 

	doc/			Brief documentation
	drv/			SW driver functions
	kci.xml			Component description for Kactus integrator tool
	readme.txt		This file
 	Sopc_64b/		Files for using this in Altera's SOPC builder integrator tool
	Sopc_component/		Files for using this in Altera's SOPC builder integrator tool
	tb/			Testbenches for VHDL description
	vhd/			RTL source codes



History:
	Original design by Ari Kulmala, 2005

	Directory "sopc_component" copied from svn\hibi\trunk\Hibi\IP\Adapters\N2H2\V2\Sopc_component. Modifications in inc-subdirectory (bug fix), class.ptf and n2h2_chan.vhd (default for hibi_addr_cmp_lo_g changed).

	Files of directory .\Sopc_component\hdl copied from svn\hibi\trunk\Hibi\IP\Adapters\N2H2\V2\Sopc_component\hdl, but only those files that are referenced in class.ptf. The SOPC component is probably out of sync with real VHDL-files, but...

	Directory "vhd" copied from svn\hibi\trunk\Hibi\IP\Adapters\N2H2\V2\Ver_02

	
	Modified by Lasse Lehtonen, 2011:
	
	Added ability to receive packets that haven't been configured
	before the packet arrives. Also added interrupt to detect lost
	tx packets (may happen when sending "second" packet too soon
	without polling for the completeon of the previous packet).

	Those Sopc_* directories are probably useless - use the TCL
	file in vhd/ to add the component to SOPC.
