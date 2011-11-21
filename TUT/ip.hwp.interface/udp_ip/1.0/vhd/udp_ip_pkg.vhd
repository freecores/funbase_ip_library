-- constants and stuff
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

library ieee;
use ieee.std_logic_1164.all;

package udp_ip_pkg is

  constant udp_data_width_c    : integer := 16;
  constant tx_len_w_c      : integer := 11;
  constant ip_addr_w_c     : integer := 32;
  constant MAC_addr_w_c    : integer := 48;
  constant port_w_c        : integer := 16;
  constant frame_type_w_c  : integer := 16;
  constant ip_checksum_w_c : integer := 16;

  constant ARP_frame_type_c : std_logic_vector( frame_type_w_c-1 downto 0 ) := x"0806";
  constant IP_frame_type_c : std_logic_vector( frame_type_w_c-1 downto 0 ) := x"0800";
  constant UDP_protocol_c : std_logic_vector( 7 downto 0 ) := x"11";
  
  constant own_ip_c : std_logic_vector( ip_addr_w_c-1 downto 0 ) := x"0A00000A";
  constant MAC_addr_c : std_logic_vector( MAC_addr_w_c-1 downto 0 ) := x"ACDCABBACD00";

end udp_ip_pkg;
