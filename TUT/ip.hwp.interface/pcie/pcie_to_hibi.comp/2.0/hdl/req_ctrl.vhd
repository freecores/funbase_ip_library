-------------------------------------------------------------------------------
-- Title      : Generic request controller
-- Project    : 
-------------------------------------------------------------------------------
-- File       : req_ctrl.vhd
-- Author     : 
-- Company    : 
-- Last update: 04.02.2011
-- Version    : 0.6
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
--
-------------------------------------------------------------------------------
-- Copyright (c) 2010
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 20.10.2010   0.1     arvio     Created
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--  This file is a part of a free IP-block: you can redistribute it and/or modify
--  it under the terms of the Lesser GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This IP-block is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  Lesser GNU General Public License for more details.
--
--  You should have received a copy of the Lesser GNU General Public License
--  along with Transaction Generator.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- synthesis translate_off
use std.textio.all;
use work.txt_util.all;
-- synthesis translate_on

entity req_ctrl is

  generic ( COMPONENTS : integer := 4;
            COMPONENTS_WIDTH : integer := 2;
            DATA_WIDTH : integer := 7;
            MIN_COMP_REQS : integer := 4;
            MAX_TOTAL_REQS : integer := 512 );
            

  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    
    init_done_out : out std_logic;
    
    req_re_in : in std_logic;
    req_ready_out : out std_logic;
    req_rcomp_in  : in std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
    req_rdata_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
    
    req_tx_out      : out std_logic;
    req_tx_ready_in : in std_logic;
    req_tx_comp_out : out std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
    
    ack_rx_in       : in std_logic;
    ack_rx_valid_in : in std_logic;
    ack_rx_comp_in  : in std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
    ack_rx_data_in  : in std_logic_vector(DATA_WIDTH-1 downto 0) );

end req_ctrl;

architecture rtl of req_ctrl is

  function maximum (L : integer; R : integer) return integer is
  begin
    if L > R then
      return L;
    else
      return R;
    end if;
  end;
  
  function min (L : integer; R : integer) return integer is
  begin
    if L < R then
      return L;
    else
      return R;
    end if;
  end;
  
  function log2_ceil(N : natural) return integer is
  begin
    if N = 0 then
      return 0;
    elsif N = 1 then
      return 1;
    else
      return 1 + log2_ceil(N/2);
    end if;
  end;
  
  function i2s(value : integer; width : integer) return std_logic_vector is
  begin
    return conv_std_logic_vector(value, width);
  end;
  
  function s2i(value : std_logic_vector) return integer is
  begin
    return conv_integer(value);
  end;
  
  
  constant MIN_COMP_REQS_WIDTH : integer := log2_ceil(MIN_COMP_REQS-1);
--  constant MAX_TOTAL_REQS_WIDTH : integer := log2_ceil(MAX_TOTAL_REQS-1);
  
  constant TOTAL_REQS : integer := min(MAX_TOTAL_REQS, COMPONENTS*MIN_COMP_REQS);
  
  signal req_ready_r : std_logic;
  signal req_ready_p1_r : std_logic;
  signal req_ready_p2_r : std_logic;
  signal req_ready_p3_r : std_logic;
  signal req_rdata_r : std_logic_vector(DATA_WIDTH-1 downto 0);
  
  signal req_tx_r : std_logic;
--  signal req_tx_comp_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal req_tx_done_r : std_logic;
  
  signal req_rcomp_p1_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal req_rcomp_p2_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal req_cnt_we_p3_r : std_logic;
  signal req_cnt_we_p4_r : std_logic;
  signal req_cnt_we_1 : std_logic;
  signal req_cnt_addr_0 : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal req_cnt_addr_1 : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal req_cnt_addr_1_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal req_cnt_wdata_1 : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal req_cnt_p2_r : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
--  signal req_cnt_p2 : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal req_cnt_rdata_p2_0 : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal req_cnt_rdata_p2_0_temp : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
--  signal req_cnt_rdata_p2_0_r : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal req_cnt_rdata_p2_1 : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal req_cnt_rdata_p2_1_temp : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal req_re_p1_r : std_logic;
  signal req_re_p2_r : std_logic;
  
  signal valid_ack_cnt_we_p3_r : std_logic;
  signal valid_ack_cnt_we_p4_r : std_logic;
  signal valid_ack_cnt_we_1 : std_logic;
  signal valid_ack_cnt_addr_1 : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal valid_ack_cnt_wdata_1 : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal valid_ack_cnt_p2_r : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
--  signal valid_ack_cnt_p2 : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal valid_ack_cnt_rdata_p2_0 : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal valid_ack_cnt_rdata_p2_0_temp : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  signal valid_ack_cnt_rdata_p2_1 : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
  
  signal req_ack_cnt_waddr_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal req_ack_cnt_waddr_d1_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  
  signal ack_rx_p1_r : std_logic;
  signal ack_rx_p2_r : std_logic;
  signal ack_rx_valid_p1_r : std_logic;
  signal ack_rx_valid_p2_r : std_logic;
  signal ack_rx_comp_p1_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal ack_rx_comp_p2_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal ack_rx_comp_p3_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal ack_rx_comp_p4_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal ack_rx_data_p1_r : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ack_rx_data_p2_r : std_logic_vector(DATA_WIDTH-1 downto 0);
  
  signal valid_ack_we_1 : std_logic;
  signal valid_ack_data_addr_0 : std_logic_vector(COMPONENTS_WIDTH+MIN_COMP_REQS_WIDTH-1 downto 0);
  signal valid_ack_data_addr_1 : std_logic_vector(COMPONENTS_WIDTH+MIN_COMP_REQS_WIDTH-1 downto 0);
  signal valid_ack_rdata_p2 : std_logic_vector(DATA_WIDTH-1 downto 0);
  
  signal mem_init_done_r : std_logic;
  signal mem_init_ptr_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  
  signal valid_ack_release_r : std_logic;
  signal valid_ack_release_store_r : std_logic;
  
  signal valid_ack_release_we_r : std_logic;
  signal valid_ack_release_re_r : std_logic;
  signal valid_ack_release_empty : std_logic;
--  signal valid_ack_release_empty_d1_r : std_logic;
  signal valid_ack_release_full : std_logic;
  signal valid_ack_release_one_p : std_logic;
  signal valid_ack_release_wdata_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal valid_ack_release_rdata : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  signal valid_ack_release_rdata_r : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
  
  signal valid_ack_cnt_rdata_p2_0_src : std_logic;
  signal valid_ack_cnt_rdata_p2_0_src_r : std_logic;
  
begin
  
  req_ready_out <= req_ready_p1_r;
  req_rdata_out <= valid_ack_rdata_p2;
  
  req_tx_out <= req_tx_r;
  req_tx_comp_out <= valid_ack_release_rdata_r;
  
  
  init_done_out <= mem_init_done_r;
  
--  valid_ack_we <= ack_rx_in and ack_rx_valid_in;
--  valid_ack_wdata <= ack_rx_comp_in & ack_rx_data_in;
  
  process (req_cnt_we_p3_r, req_ack_cnt_waddr_r, req_rcomp_in, valid_ack_release_rdata_r, req_cnt_p2_r, req_cnt_rdata_p2_0, req_cnt_rdata_p2_1, valid_ack_cnt_we_p3_r, valid_ack_cnt_p2_r,
           valid_ack_cnt_rdata_p2_0, ack_rx_comp_p2_r, ack_rx_p2_r, valid_ack_cnt_rdata_p2_0_src, valid_ack_cnt_rdata_p2_0_src_r)
  begin
    if ( (req_cnt_we_p3_r = '1') and ((req_ack_cnt_waddr_r = req_rcomp_in) or ((ack_rx_p2_r = '1') and (req_ack_cnt_waddr_r = ack_rx_comp_p2_r))) ) then
      req_cnt_rdata_p2_0_temp <= req_cnt_p2_r;
    else
      req_cnt_rdata_p2_0_temp <= req_cnt_rdata_p2_0;
    end if;
    
    if ((valid_ack_cnt_we_p3_r = '1') and (req_ack_cnt_waddr_r = ack_rx_comp_p2_r)) then
      valid_ack_cnt_rdata_p2_0_src <= '1';
    else
      valid_ack_cnt_rdata_p2_0_src <= '0';
    end if;
    
    if ((valid_ack_cnt_rdata_p2_0_src = '1') or (valid_ack_cnt_rdata_p2_0_src_r = '1')) then
      valid_ack_cnt_rdata_p2_0_temp <= valid_ack_cnt_p2_r;
    else
      valid_ack_cnt_rdata_p2_0_temp <= valid_ack_cnt_rdata_p2_0;
    end if;
    
    if ((req_cnt_we_p3_r = '1') and (req_ack_cnt_waddr_r = valid_ack_release_rdata_r)) then
      req_cnt_rdata_p2_1_temp <= req_cnt_p2_r;
    else
      req_cnt_rdata_p2_1_temp <= req_cnt_rdata_p2_1;
    end if;
  end process;
  
  process (clk, rst_n)
    variable req_cnt_p2_v : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
    variable valid_ack_cnt_p2_v : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
--    variable req_cnt_rdata_p2_0_v : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
--    variable req_cnt_rdata_p2_1_v : std_logic_vector(MIN_COMP_REQS_WIDTH downto 0);
    variable valid_ack_release_rdata_v : std_logic_vector(COMPONENTS_WIDTH-1 downto 0);
    variable req_tx_v : std_logic;
    variable req_re_v : std_logic;
  begin
    if (rst_n = '0') then
      req_ready_r <= '0';
      req_rdata_r <= (others => '0');
      req_tx_r <= '0';
--      req_tx_comp_r <= (others => '0');
      
      req_cnt_p2_r <= (others => '0');
      req_rcomp_p1_r <= (others => '0');
      req_rcomp_p2_r <= (others => '0');
      req_cnt_we_p3_r <= '0';
      req_cnt_we_p4_r <= '0';
      req_re_p1_r <= '0';
      req_re_p2_r <= '0';
      req_cnt_addr_1_r <= (others => '0');
      
--      req_cnt_rdata_p2_0_r <= (others => '0');
      
      req_tx_done_r <= '0';
      
      ack_rx_p1_r <= '0';
      ack_rx_p2_r <= '0';
      ack_rx_valid_p1_r <= '0';
      ack_rx_valid_p2_r <= '0';
      ack_rx_comp_p1_r <= (others => '0');
      ack_rx_comp_p2_r <= (others => '0');
      ack_rx_comp_p3_r <= (others => '0');
      ack_rx_comp_p4_r <= (others => '0');
      ack_rx_data_p1_r <= (others => '0');
      ack_rx_data_p2_r <= (others => '0');
      
      mem_init_done_r <= '0';
      mem_init_ptr_r <= (others => '0');
      
      valid_ack_cnt_p2_r <= (others => '0');
      valid_ack_cnt_we_p3_r <= '0';
      valid_ack_cnt_we_p4_r <= '0';
      
      req_ack_cnt_waddr_r <= (others => '0');
      req_ack_cnt_waddr_d1_r <= (others => '0');
      
      valid_ack_release_r <= '0';
      valid_ack_release_store_r <= '0';
      
      valid_ack_release_we_r <= '0';
      valid_ack_release_re_r <= '0';
      valid_ack_release_wdata_r <= (others => '0');
--      valid_ack_release_empty_d1_r <= '0';
      valid_ack_release_rdata_r <= (others => '0');
      
      req_ready_p1_r <= '0';
      req_ready_p2_r <= '0';
      req_ready_p3_r <= '0';
      
      valid_ack_cnt_rdata_p2_0_src_r <= '0';
      
    elsif (clk'event and clk = '1') then
--      valid_ack_release_empty_d1_r <= valid_ack_release_empty;
      
      req_ready_r <= '0';
      valid_ack_release_we_r <= '0';
      
      valid_ack_cnt_rdata_p2_0_src_r <= valid_ack_cnt_rdata_p2_0_src;
      
      if (mem_init_done_r = '0') then
        valid_ack_release_we_r <= '1';
        
        if (valid_ack_release_wdata_r = (COMPONENTS - 1)) then
          valid_ack_release_wdata_r <= (others => '0');
        else
          valid_ack_release_wdata_r <= valid_ack_release_wdata_r + 1;
        end if;
          
        mem_init_ptr_r <= mem_init_ptr_r + 1;
        
        if (valid_ack_release_one_p = '1') then
          mem_init_done_r <= '1';
        end if;
      end if;
      
      ack_rx_p1_r <= ack_rx_in;
      ack_rx_p2_r <= ack_rx_p1_r;
      ack_rx_valid_p1_r <= ack_rx_valid_in;
      ack_rx_valid_p2_r <= ack_rx_valid_p1_r;
      ack_rx_comp_p1_r <= ack_rx_comp_in;
      ack_rx_comp_p2_r <= ack_rx_comp_p1_r;
      ack_rx_comp_p3_r <= ack_rx_comp_p2_r;
      ack_rx_comp_p4_r <= ack_rx_comp_p3_r;
      ack_rx_data_p1_r <= ack_rx_data_in;
      ack_rx_data_p2_r <= ack_rx_data_p1_r;
      
      req_ack_cnt_waddr_d1_r <= req_ack_cnt_waddr_r;
      
      req_ready_p1_r <= req_ready_r;
      req_ready_p2_r <= req_ready_p1_r;
      req_ready_p3_r <= req_ready_p2_r;
      
      req_re_p1_r <= req_re_in;
--      req_re_p2_r <= req_re_p1_r;
      req_rcomp_p1_r <= req_rcomp_in;
--      req_rcomp_p2_r <= req_rcomp_p1_r;
      
--      if (ack_rx_comp_p2_r /= ack_rx_comp_p3_r) then
--        req_cnt_p2_v := req_cnt_rdata_p2_0;
--        valid_ack_cnt_p2_v := valid_ack_cnt_rdata_p2_0;
--      else
--        req_cnt_p2_v := req_cnt_p2_r;
--        valid_ack_cnt_p2_v := valid_ack_cnt_p2_r;
--      end if;
      
      if ((mem_init_done_r = '1') and (valid_ack_release_empty = '0') and (ack_rx_comp_p1_r = ack_rx_comp_p2_r) and (valid_ack_release_r = '0')) then
        valid_ack_release_rdata_r <= valid_ack_release_rdata;
        valid_ack_release_re_r <= '1';
        valid_ack_release_r <= '1';
        valid_ack_release_store_r <= '1';
      else
        valid_ack_release_re_r <= '0';
        valid_ack_release_store_r <= '0';
      end if;
      
--       if ((req_cnt_we_p3_r = '1') and (req_ack_cnt_waddr_r = req_rcomp_in)) then
--         req_cnt_rdata_p2_0_v := req_cnt_p2_r;
--       else
--         req_cnt_rdata_p2_0_v := req_cnt_rdata_p2_0;
--       end if;
--       
--       if ((req_cnt_we_p3_r = '1') and (req_ack_cnt_waddr_r = valid_ack_release_rdata_r)) then
--         req_cnt_rdata_p2_1_v := req_cnt_p2_r;
--       else
--         req_cnt_rdata_p2_1_v := req_cnt_rdata_p2_1;
--       end if;
      
--       if ((valid_ack_release_r = '1') and (req_ack_cnt_waddr_r = valid_ack_release_rdata_r) and (req_cnt_we_p3_r = '1')) then
--         req_cnt_rdata_p2_0_v := req_cnt_p2_r;
--       end if;
      
      req_cnt_we_p3_r <= '0';
      valid_ack_cnt_we_p3_r <= '0';
      
      req_cnt_we_p4_r <= req_cnt_we_p3_r;
      valid_ack_cnt_we_p4_r <= valid_ack_cnt_we_p3_r;
      
      req_tx_v := '0';
      
      if (ack_rx_p2_r = '1') then
        req_ack_cnt_waddr_r <= ack_rx_comp_p2_r;
        if (ack_rx_valid_p2_r = '0') then
          req_cnt_p2_r <= req_cnt_rdata_p2_0_temp - 1;
          req_cnt_we_p3_r <= '1';
        else
          valid_ack_cnt_p2_r <= valid_ack_cnt_rdata_p2_0_temp + 1;
          valid_ack_cnt_we_p3_r <= '1';
        end if;
      elsif ((req_cnt_we_p4_r = '0') and (valid_ack_cnt_we_p4_r = '0') and (req_re_p1_r = '1') and (req_ready_r = '0') and (req_ready_p1_r = '0') and (req_ready_p2_r = '0')
             and (valid_ack_cnt_rdata_p2_1 /= 0)) then
        req_cnt_p2_r <= req_cnt_rdata_p2_1_temp - 1;
        valid_ack_cnt_p2_r <= valid_ack_cnt_rdata_p2_1 - 1;
        req_cnt_we_p3_r <= '1';
        valid_ack_cnt_we_p3_r <= '1';
        req_ack_cnt_waddr_r <= req_rcomp_in;
        
        valid_ack_release_wdata_r <= req_rcomp_in;
        
        valid_ack_release_we_r <= '1';
        
        req_ready_r <= '1';
      elsif (req_tx_done_r = '1') then
        req_tx_done_r <= '0';
        
        valid_ack_release_r <= '0';
        
        req_cnt_p2_r <= req_cnt_rdata_p2_0_temp + 1;
        req_ack_cnt_waddr_r <= valid_ack_release_rdata_r;
        req_cnt_we_p3_r <= '1';
      end if;
      
      if ((valid_ack_release_r = '1') and (req_tx_done_r = '0')) then
        req_tx_r <= '1';
--        req_tx_comp_r <= valid_ack_release_rdata_r;
      end if;
      
      if ((req_tx_r = '1') and (req_tx_ready_in = '1')) then
        req_tx_r <= '0';
        req_tx_done_r <= '1';
      end if;
      
--      if ((valid_ack_release_store_r = '1') or (req_tx_v = '1')) then
--        req_cnt_rdata_p2_0_r <= req_cnt_rdata_p2_0_v;
--      end if;
      
      
    end if;
  end process;
  
  process (mem_init_done_r, mem_init_ptr_r, req_cnt_we_p3_r, req_cnt_p2_r, valid_ack_cnt_p2_r, valid_ack_cnt_we_p3_r, req_cnt_rdata_p2_0, valid_ack_cnt_rdata_p2_0,
           ack_rx_comp_p1_r, ack_rx_comp_p2_r, ack_rx_comp_p3_r, ack_rx_comp_p4_r, valid_ack_release_rdata_r, req_ack_cnt_waddr_r, req_rcomp_in)
  begin
    if (mem_init_done_r = '0') then
      req_cnt_addr_1 <= mem_init_ptr_r;
      req_cnt_wdata_1 <= (others => '0');
      req_cnt_we_1 <= '1';
      valid_ack_cnt_addr_1 <= mem_init_ptr_r;
      valid_ack_cnt_wdata_1 <= (others => '0');
      valid_ack_cnt_we_1 <= '1';
    else
      req_cnt_wdata_1 <= req_cnt_p2_r;
      req_cnt_we_1 <= req_cnt_we_p3_r;
      valid_ack_cnt_wdata_1 <= valid_ack_cnt_p2_r;
      valid_ack_cnt_we_1 <= valid_ack_cnt_we_p3_r;
      
      if ((req_cnt_we_p3_r = '1') or (valid_ack_cnt_we_p3_r = '1')) then
        req_cnt_addr_1 <= req_ack_cnt_waddr_r;
        valid_ack_cnt_addr_1 <= req_ack_cnt_waddr_r;
      else
        req_cnt_addr_1 <= req_rcomp_in;
        valid_ack_cnt_addr_1 <= req_rcomp_in;
      end if;
    end if;
    
    if (ack_rx_comp_p1_r /= ack_rx_comp_p2_r) then
      req_cnt_addr_0 <= ack_rx_comp_p1_r;
    else
      req_cnt_addr_0 <= valid_ack_release_rdata_r;
    end if;
    
--     if (ack_rx_comp_p3_r /= ack_rx_comp_p4_r) then
--       req_cnt_p2 <= req_cnt_rdata_p2_0;
--       valid_ack_cnt_p2 <= valid_ack_cnt_rdata_p2_0;
--     else
--       req_cnt_p2 <= req_cnt_p2_r;
--       valid_ack_cnt_p2 <= valid_ack_cnt_p2_r;
--     end if;
    
  end process;
  
------------------------------------------------------------------------------------------
-- Req count memory
------------------------------------------------------------------------------------------
-- port 0:
--  - use 0: read req count for the corresponding received ack
--  - use 1: read req count for the corresponding released ack
--
-- port 1:
--  - init: initialize counts to zero
--  - normal operation:
--    - use switch: req_cnt_we_p3_r (only addr has to be switched)
--    - use 0: read req count for the corresponding req read
--    - use 1: write req count
--      - write enable: req_cnt_we_p3_r

  req_cnt_mem : entity work.onchip_mem_sc
  generic map ( DATA_WIDTH => MIN_COMP_REQS_WIDTH+1,
                ADDR_WIDTH => COMPONENTS_WIDTH,
                MEM_SIZE   => COMPONENTS )
  
  port map ( clk         => clk,
             addr_0_in   => req_cnt_addr_0,
             addr_1_in   => req_cnt_addr_1,
             wdata_0_in  => (others => '0'),
             wdata_1_in  => req_cnt_p2_r,
             we_0_in     => '0',
             we_1_in     => req_cnt_we_1,
             be_0_in     => (others => '0'),
             be_1_in     => (others => '1'),
             rdata_0_out => req_cnt_rdata_p2_0,
             rdata_1_out => req_cnt_rdata_p2_1 );


------------------------------------------------------------------------------------------
-- Valid ack count memory
------------------------------------------------------------------------------------------
-- port 0:
--  - use 0: read valid ack count for the corresponding received ack
--  - use 1: read valid ack count for the corresponding released ack
--
-- port 1:
--  - use switch: req_cnt_we_p3_r (only addr has to be switched)
--  - use 0: read valid ack count for the corresponding req read
--  - use 1: write valid ack count for the corresponding released ack
--    - write enable: req_cnt_we_p3_r

  valid_ack_cnt_mem : entity work.onchip_mem_sc
  generic map ( DATA_WIDTH => MIN_COMP_REQS_WIDTH+1,
                ADDR_WIDTH => COMPONENTS_WIDTH,
                MEM_SIZE   => COMPONENTS )
  
  port map ( clk         => clk,
             addr_0_in   => ack_rx_comp_p1_r,
             addr_1_in   => valid_ack_cnt_addr_1,
             wdata_0_in  => (others => '0'),
             wdata_1_in  => valid_ack_cnt_wdata_1,
             we_0_in     => '0',
             we_1_in     => valid_ack_cnt_we_1,
             be_0_in     => (others => '0'),
             be_1_in     => (others => '1'),
             rdata_0_out => valid_ack_cnt_rdata_p2_0,
             rdata_1_out => valid_ack_cnt_rdata_p2_1 );
  
  
------------------------------------------------------------------------------------------
-- Valid ack data memory
------------------------------------------------------------------------------------------
  valid_ack_data_addr_0 <= req_rcomp_p1_r & valid_ack_cnt_p2_r(MIN_COMP_REQS_WIDTH-1 downto 0); -- part of address directly from other memory
  valid_ack_data_addr_1 <= ack_rx_comp_p2_r & valid_ack_cnt_p2_r(MIN_COMP_REQS_WIDTH-1 downto 0);
  valid_ack_we_1 <= ack_rx_valid_p2_r and ack_rx_p2_r;
  
  valid_ack_data_mem : entity work.onchip_mem_sc
  generic map ( DATA_WIDTH => DATA_WIDTH,
                ADDR_WIDTH => COMPONENTS_WIDTH + MIN_COMP_REQS_WIDTH,
                MEM_SIZE   => COMPONENTS*MIN_COMP_REQS )
  
  port map ( clk         => clk,
             addr_0_in   => valid_ack_data_addr_0,
             addr_1_in   => valid_ack_data_addr_1,
             wdata_0_in  => (others => '0'),
             wdata_1_in  => ack_rx_data_p2_r,
             we_0_in     => '0',
             we_1_in     => valid_ack_we_1,
             be_0_in     => (others => '0'),
             be_1_in     => (others => '1'),
             rdata_0_out => valid_ack_rdata_p2 );
--             rdata_1_out => req_cnt_rdata_p2_1 );
  
  
  valid_ack_release_fifo : entity work.fifo_sc
	generic map ( DATA_WIDTH => COMPONENTS_WIDTH,
                FIFO_LENGTH => TOTAL_REQS,
                CNT_WIDTH => log2_ceil(TOTAL_REQS-1) )
            
  port map ( clk => clk,
		         rst_n => rst_n,
             wdata_in => valid_ack_release_wdata_r,
		         rdata_out => valid_ack_release_rdata,
             re_in => valid_ack_release_re_r,
		         we_in => valid_ack_release_we_r,
		         empty_out => valid_ack_release_empty,
             full_out => valid_ack_release_full,
             one_p_out => valid_ack_release_one_p );
             
  
end rtl;
