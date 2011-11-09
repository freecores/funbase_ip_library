-------------------------------------------------------------------------------
-- Title      : Address flit ripper / replacer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : addr_rip.vhd
-- Author     : Lasse Lehtonen
-- Company    : 
-- Created    : 2011-10-12
-- Last update: 2011-10-25
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
--
-- Rips the address flit when wanted or replaces the network address
-- with original address (or doesn't do a thing).
--
-------------------------------------------------------------------------------
-- Copyright (c) 2011 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2011-10-12  1.0      lehton87        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity addr_rip is
  
  generic (
    cmd_width_g    : positive;
    data_width_g   : positive;
    addr_flit_en_g : natural;
    rip_addr_g     : natural);

  port (
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    net_cmd_in    : in  std_logic_vector(cmd_width_g-1 downto 0);
    net_data_in   : in  std_logic_vector(data_width_g-1 downto 0);
    net_stall_out : out std_logic;
    ip_cmd_out    : out std_logic_vector(cmd_width_g-1 downto 0);
    ip_data_out   : out std_logic_vector(data_width_g-1 downto 0);
    ip_stall_in   : in  std_logic);

end addr_rip;


architecture rtl of addr_rip is

  signal was_addr_r : std_logic;
  
begin  -- rtl

  addr_check_p : process (clk, rst_n)
  begin  -- process addr_check_p
    if rst_n = '0' then                 -- asynchronous reset (active low)
      was_addr_r <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      if net_cmd_in = "01" then
        was_addr_r <= '1';
      else
        was_addr_r <= '0';
      end if;
    end if;
  end process addr_check_p;

  ip_data_out   <= net_data_in;
  net_stall_out <= ip_stall_in;

  rip : if rip_addr_g = 1 generate
    replace : if addr_flit_en_g = 1 generate
      m1 : process (net_cmd_in, was_addr_r)
      begin  -- process m
        if net_cmd_in = "01" then
          ip_cmd_out <= "00";
        elsif was_addr_r = '1' then
          ip_cmd_out <= "01";
        else
          ip_cmd_out <= net_cmd_in;
        end if;
      end process m1;
    end generate replace;

    dont_replace : if addr_flit_en_g = 0 generate
      m2: process (net_cmd_in)
      begin  -- process m2
        if net_cmd_in = "01" then
          ip_cmd_out <= "00";
        else
          ip_cmd_out <= net_cmd_in;
        end if;
      end process m2;
    end generate dont_replace;
  end generate rip;

  dont_rip : if rip_addr_g = 0 generate
    replace1 : if addr_flit_en_g = 1 generate
      m3 : process (net_cmd_in, was_addr_r)
      begin  -- process m
        if net_cmd_in = "01" then
          ip_cmd_out <= "00";
        elsif was_addr_r = '1' then
          ip_cmd_out <= "01";
        else
          ip_cmd_out <= net_cmd_in;
        end if;
      end process m3;
    end generate replace1;

    dont_replace1 : if addr_flit_en_g = 0 generate
      ip_cmd_out <= net_cmd_in;
    end generate dont_replace1;
  end generate dont_rip;

end rtl;
