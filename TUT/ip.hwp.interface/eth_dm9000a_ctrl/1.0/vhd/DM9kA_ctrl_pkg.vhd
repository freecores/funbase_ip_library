-------------------------------------------------------------------------------
-- Funbase IP library Copyright (C) 2011 TUT Department of Computer Systems
--
-- This source file may be used and distributed without
-- restriction provided that this copyright statement is not
-- removed from the file and that any derivative work contains
-- the original copyright notice and the associated disclaimer.
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.opencores.org/lgpl.shtml
-------------------------------------------------------------------------------
-- package for constants

library ieee;
use ieee.std_logic_1164.all;

package DM9kA_ctrl_pkg is

  constant data_width_c : integer := 16;
  constant tx_len_w_c : integer := 11;
  constant sleep_time_w_c : integer := 32;
  constant submodules_c : integer := 3;
  
  -- init reg addresses
  constant NCR_c    : std_logic_vector( 7 downto 0 ) := x"00";
  constant NSR_c    : std_logic_vector( 7 downto 0 ) := x"01";
  constant TCR_c    : std_logic_vector( 7 downto 0 ) := x"02";
  constant RCR_c    : std_logic_vector( 7 downto 0 ) := x"05";
  constant BPTR_c   : std_logic_vector( 7 downto 0 ) := x"08";
  constant FCTR_c   : std_logic_vector( 7 downto 0 ) := x"09";
  constant FCR_c    : std_logic_vector( 7 downto 0 ) := x"0A";
  constant WUCR_r   : std_logic_vector( 7 downto 0 ) := x"0F";
  constant GPCR_c   : std_logic_vector( 7 downto 0 ) := x"1E";
  constant GPR_c    : std_logic_vector( 7 downto 0 ) := x"1F";
  constant TCR2_c   : std_logic_vector( 7 downto 0 ) := x"2D";
  constant ETXCSR_c : std_logic_vector( 7 downto 0 ) := x"30";
  constant ISR_c    : std_logic_vector( 7 downto 0 ) := x"FE";
  constant IMR_c    : std_logic_vector( 7 downto 0 ) := x"FF";
  constant tx_data_reg_c : std_logic_vector( 7 downto 0 ) := x"F8";
  constant rx_data_reg_c : std_logic_vector( 7 downto 0 ) := x"F2";
  constant rx_peek_reg_c : std_logic_vector( 7 downto 0 ) := x"F0";
  -- tx packet length low register address
  constant TXPLL_c : std_logic_vector( 7 downto 0 ) := x"FC";
  constant TXPLH_c : std_logic_vector( 7 downto 0 ) := x"FD";

  -- MAC address registers
  constant MAC1_c : std_logic_vector( 7 downto 0 ) := x"10";
  constant MAC2_c : std_logic_vector( 7 downto 0 ) := x"11";
  constant MAC3_c : std_logic_vector( 7 downto 0 ) := x"12";
  constant MAC4_c : std_logic_vector( 7 downto 0 ) := x"13";
  constant MAC5_c : std_logic_vector( 7 downto 0 ) := x"14";
  constant MAC6_c : std_logic_vector( 7 downto 0 ) := x"15";

  -- MAC address of the device
  constant MAC_addr_c : std_logic_vector( 47 downto 0 ) := x"ACDCABBACD00";
  
  constant MAC_len_c : integer := 6;
  constant eth_header_len_c : integer := 14;
  constant eth_checksum_len_c : integer := 4;

  -- sleeping times
  constant power_up_sleep_c : integer := 75000;  -- 3 ms with 25MHz
  constant reset_sleep_c : integer := 125;  -- 5 us with 25MHz

  -- whether to raise the tx request bit or not:
  -- 0: DM9000A must be configured to start tx in advance (reg ETXCSR)
  -- 1: send module raises tx req bit in TCR after writing tx data
  constant send_cmd_en_c : integer := 1;

end DM9kA_ctrl_pkg;
