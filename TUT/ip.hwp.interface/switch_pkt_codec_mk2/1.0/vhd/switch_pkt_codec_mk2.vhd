-------------------------------------------------------------------------------
-- Title      : Switch reader for ase_mesh1
-- Project    : 
-------------------------------------------------------------------------------
-- File       : switch_pkt_codec_mk2.vhd
-- Author     : Lasse Lehtonen
-- Company    : 
-- Created    : 2011-11-09
-- Last update: 2011-11-09
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2011 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2011-11-09  1.0      lehton87        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity switch_pkt_codec_mk2 is

  generic (
    target_id_g : integer);
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    cmd_in    : in  std_logic_vector(1 downto 0);
    data_in   : in  std_logic_vector(31 downto 0);
    stall_out : out std_logic;
    cmd_out   : out std_logic_vector(1 downto 0);
    data_out  : out std_logic_vector(31 downto 0);
    stall_in  : in  std_logic;
    switch_in : in  std_logic);

end switch_pkt_codec_mk2;


architecture rtl of switch_pkt_codec_mk2 is

  signal switch1_r : std_logic;
  signal switch2_r : std_logic;
  signal switch3_r : std_logic;

  type fsm_type is (idle, cmd, data);
  signal state_r : fsm_type;
  
begin  -- rtl
  
  stall_out <= '0';


  main_p : process (clk, rst_n)
  begin  -- process main_p
    if rst_n = '0' then                 -- asynchronous reset (active low)

      switch1_r <= '0';
      switch2_r <= '0';
      state_r <= idle;
      
    elsif clk'event and clk = '1' then  -- rising clock edge

      switch1_r <= switch_in;
      switch2_r <= switch1_r;
      switch3_r <= switch2_r;
      
      case state_r is        
        when idle =>
          if stall_in = '0' then
            cmd_out <= "00";
            data_out <= (others => '0');
            if switch3_r /= switch2_r then
              state_r <= cmd;
            end if;
          end if;          

        when cmd =>
          if stall_in = '0' then
            data_out <= std_logic_vector(to_unsigned(target_id_g, 32));
            cmd_out <= "01";
            state_r <= data;
          end if;

        when data =>
          if stall_in = '0' then
            data_out <= std_logic_vector(to_unsigned(42, 32));
            cmd_out <= "10";
            state_r <= idle;
          end if;
          
        when others => null;
      end case;
      
    end if;
  end process main_p;
  

end rtl;
