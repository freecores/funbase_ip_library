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
-- Title      : Multi mutex
-- Project    : Funbase
-------------------------------------------------------------------------------
-- File       : multi_mutex.vhd
-- Author     : Juha Arvio
-- Company    : TUT
-- Last update: 14.10.2011
-- Version    : 0.1
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 14.10.2011   0.1     arvio     Created
-- 14.10.2011   0.1    arvio
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- synthesis translate_off
use std.textio.all;
use work.txt_util.all;
-- synthesis translate_on

entity multi_mutex is
  generic ( RESOURCES : integer := 64;
            RESOURCES_WIDTH : integer := 6;
            RES_DATA_WIDTH : integer := 8;
            RES_AMOUNT_WIDTH : integer := 8 );

  port (
    clk_rsv : in std_logic;
    clk_rls : in std_logic;
    rst_n : in std_logic;
    
    reserve_in : in std_logic;
    reserve_ready_out : out std_logic;
    reserve_res_out : out std_logic_vector(RESOURCES_WIDTH-1 downto 0);
    reserve_amount_in : in std_logic_vector(RES_AMOUNT_WIDTH-1 downto 0);
    reserve_data_in : in std_logic_vector(RES_DATA_WIDTH-1 downto 0);
    
    release_in : in std_logic;
    release_ready_out : out std_logic;
    release_res_in : in std_logic_vector(RESOURCES_WIDTH-1 downto 0);
    release_amount_in : in std_logic_vector(RES_AMOUNT_WIDTH-1 downto 0);
    release_data_out : out std_logic_vector(RES_DATA_WIDTH-1 downto 0) );

end multi_mutex;

architecture rtl of multi_mutex is
  function i2s(value : integer; width : integer) return std_logic_vector is
  begin
    return conv_std_logic_vector(value, width);
  end;
  
  function s2i(value : std_logic_vector) return integer is
  begin
    return conv_integer(value);
  end;
  
  type release_state_t is (WAIT_RELEASE, READ_RES);
  signal release_state_r : release_state_t;
  type reserve_state_t is (WAIT_RESERVE, WRITE_RESDATA, DELAY, SEARCH_FREE_RES);
  signal reserve_state_r : reserve_state_t;
  
  signal reserve_ready_r : std_logic;
  signal release_ready_r : std_logic;
  signal res_we_0_r : std_logic;
  signal res_we_1_r : std_logic;
  
  signal res_amount_r : std_logic_vector(RES_AMOUNT_WIDTH-1 downto 0);
  signal res_data_r : std_logic_vector(RES_DATA_WIDTH-1 downto 0);
  
  signal res_rdata_0 : std_logic_vector(RES_DATA_WIDTH+RES_AMOUNT_WIDTH-1 downto 0);
  signal res_wdata_0 : std_logic_vector(RES_DATA_WIDTH+RES_AMOUNT_WIDTH-1 downto 0);
  signal res_addr_0_r : std_logic_vector(RESOURCES_WIDTH-1 downto 0);
--  signal free_res_addr_r : std_logic_vector(RESOURCES_WIDTH-1 downto 0);
  
  signal res_rdata_1 : std_logic_vector(RES_DATA_WIDTH+RES_AMOUNT_WIDTH-1 downto 0);
  signal res_wdata_1 : std_logic_vector(RES_DATA_WIDTH+RES_AMOUNT_WIDTH-1 downto 0);
begin
  
  reserve_ready_out <= reserve_ready_r;
  release_ready_out <= release_ready_r;
  
  process (clk_rsv, rst_n)
  begin
    if (rst_n = '0') then
      reserve_ready_r <= '0';
      res_we_0_r <= '0';
      res_addr_0_r <= (others => '0');
      
    elsif (clk_rsv'event and clk_rsv = '1') then
      reserve_ready_r <= '0';
      res_we_0_r <= '0';
      
      case reserve_state_r is
        when WAIT_RESERVE =>
          if (reserve_in = '1') then
            res_we_0_r <= '1';
            reserve_ready_r <= '1';
            reserve_state_r <= WRITE_RESDATA;
          end if;
         
         when WRITE_RESDATA =>
           res_addr_0_r <= res_addr_0_r + 1;
           reserve_state_r <= DELAY;
           
         when DELAY =>
           reserve_state_r <= SEARCH_FREE_RES;
         
         when others => --SEARCH_FREE_RES =>
           if (res_rdata_0(RES_AMOUNT_WIDTH+RES_DATA_WIDTH-1 downto RES_DATA_WIDTH) = 0) then
             reserve_state_r <= WAIT_RESERVE;
--             free_res_addr_r <= res_addr_0_r;
           else
             reserve_state_r <= DELAY;
             res_addr_0_r <= res_addr_0_r + 1;
           end if;
      end case;
    end if;
  end process;
  
  process (clk_rls, rst_n)
  begin
    if (rst_n = '0') then
      release_ready_r <= '0';
      res_we_1_r <= '0';
      res_amount_r <= (others => '0');
      res_data_r <= (others => '0');
      
    elsif (clk_rls'event and clk_rls = '1') then
      release_ready_r <= '0';
      res_we_1_r <= '0';
      
      case release_state_r is
        when WAIT_RELEASE =>
          release_ready_r <= '1';
          if (release_in = '1') then
            release_state_r <= READ_RES;
          end if;
         
         when others => --READ_RES =>
           res_amount_r <= res_rdata_1(RES_AMOUNT_WIDTH+RES_DATA_WIDTH-1 downto RES_DATA_WIDTH) - release_amount_in;
           res_data_r <= res_rdata_1(RES_DATA_WIDTH-1 downto 0);
           res_we_1_r <= '1';
           release_state_r <= WAIT_RELEASE;
      end case;
    end if;
  end process;
  
  release_data_out <= res_rdata_1(RES_DATA_WIDTH-1 downto 0);
  res_wdata_0 <= reserve_amount_in & reserve_data_in;
  res_wdata_1 <= res_amount_r & res_data_r;
  reserve_res_out <= res_addr_0_r;
  
  resource_mem : entity work.alt_mem_dc_dw
  generic map ( DATA_0_WIDTH => RES_DATA_WIDTH + RES_AMOUNT_WIDTH,
                DATA_1_WIDTH => RES_DATA_WIDTH + RES_AMOUNT_WIDTH,
                ADDR_0_WIDTH => RESOURCES_WIDTH,
                ADDR_1_WIDTH => RESOURCES_WIDTH,
                MEM_SIZE   => RESOURCES )
  
  port map ( clk_0 => clk_rsv,
             clk_1 => clk_rls,
             addr_0_in   => res_addr_0_r,
             addr_1_in   => release_res_in,
             wdata_0_in  => res_wdata_0,
             wdata_1_in  => res_wdata_1,
             we_0_in     => res_we_0_r,
             we_1_in     => res_we_1_r,
--             be_0_in     => (others => '1'),
--             be_1_in     => (others => '1'),
             rdata_0_out => res_rdata_0,
             rdata_1_out => res_rdata_1 );
  
end rtl;
