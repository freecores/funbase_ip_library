--*****************************************************************************
--* File :   manip_memory.vhd  (component)        
--* Author : Ari Metso / PaloDEx group oy
--*          ari.metso@palodexgroup.com
--* Date :   24.03.2010  
--*****************************************************************************
--* Updates :
--*
--*   rel.   dd.mm.yyyy   Author           Description
--*   ----------------------------------------------------------
--*   1      24.03.2010   Ari Metso	       Created
--*
--*****************************************************************************
--* COMMENTS:
--*   File generated originally by the Altera MegaWizard Plug-In Manager with 
--*   following license
--*
-- Copyright (C) 1991-2009 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.
--*
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

library work;
use work.picture_manip_pkg.all;

entity manip_memory IS
	port
	(
        iAClr		: in std_logic ;
		iAddress	: in std_logic_vector( CalcBusWidth( MANIP_BUFF_DEPTH-1)-1 downto 0 );
		iClock		: in std_logic ;
		iData_In	: in std_logic_vector( MANIP_BUFF_WWIDTH-1 downto 0 );
		iRead		: in std_logic ;
		iWrite		: in std_logic ;
		iData_Out   : out std_logic_vector( MANIP_BUFF_WWIDTH-1 downto 0 )
	);
end manip_memory;


architecture arch_manib_mem of manip_memory is

	component altsyncram
	generic (
		clock_enable_input_a            : STRING;
		clock_enable_output_a	        : STRING;
		intended_device_family	        : STRING;
		lpm_hint		                : STRING;
		lpm_type		                : STRING;
		numwords_a		                : NATURAL;
		operation_mode		            : STRING;
		outdata_aclr_a		            : STRING;
		outdata_reg_a		            : STRING;
		power_up_uninitialized	        : STRING;
		ram_block_type		            : STRING;
		read_during_write_mode_port_a	: STRING;
		widthad_a		                : NATURAL;
		width_a		                    : NATURAL;
		width_byteena_a		            : NATURAL
	);
	port (
			wren_a	    : in  std_logic;
			aclr0	    : in  std_logic;
			clock0	    : in  std_logic;
			address_a   : in  std_logic_vector( CalcBusWidth( MANIP_BUFF_DEPTH-1)-1 downto 0 );
			rden_a	    : in  std_logic;
			q_a	        : out std_logic_vector (MANIP_BUFF_WWIDTH-1 downto 0);
			data_a	    : in  std_logic_vector(MANIP_BUFF_WWIDTH-1 downto 0)
	);
	end component;

    signal sub_wire0	: std_logic_vector (31 downto 0);
    
begin
	iData_Out    <= sub_wire0(31 downto 0);

	altsyncram_component : altsyncram
	generic map (
		clock_enable_input_a            => "BYPASS",
		clock_enable_output_a           => "BYPASS",
		intended_device_family          => DEVICE_FAMILY,
		lpm_hint                        => "ENABLE_RUNTIME_MOD=NO",
		lpm_type                        => "altsyncram",
		numwords_a                      => MANIP_BUFF_DEPTH,
		operation_mode                  => "SINGLE_PORT",
		outdata_aclr_a                  => "CLEAR0",
		outdata_reg_a                   => "CLOCK0",
		power_up_uninitialized          => "FALSE",
		ram_block_type                  => MANIP_BUFF_BLOCK_TYPE,
		read_during_write_mode_port_a   => "DONT_CARE",
		widthad_a                       => CalcBusWidth( MANIP_BUFF_DEPTH-1 ),
		width_a                         => MANIP_BUFF_WWIDTH,
		width_byteena_a                 => 1
	)
	port map (
		wren_a      => iWrite,
		aclr0       => '0',
		clock0      => iClock,
		address_a   => iAddress,
		rden_a      => iRead,
		data_a      => iData_In,
		q_a         => sub_wire0
	);

end arch_manib_mem;
--*****************************************************************************
-- END OF FILE
--*****************************************************************************
