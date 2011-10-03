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
-------------------------------------------------------------------------------
-- Title      : PCIe to HIBI test app
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pcie_to_hibi_test_app.vhd
-- Author     : 
-- Company    : 
-- Last update: 18.01.2011
-- Version    : 0.1
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
--
-------------------------------------------------------------------------------
-- Copyright (c) 2010
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 18.01.2011   0.1     arvio     Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.hibiv3_pkg.all;

-- synthesis translate_off
use std.textio.all;
use work.txt_util.all;
-- synthesis translate_on

entity pcie_to_hibi_test_app is

  generic ( HIBI_DATA_WIDTH       : integer := 32;
            HIBI_ADDR_SPACE_WIDTH : integer := 11;
            HIBI_RW_LENGTH_WIDTH  : integer := 13;
            
            PCIE_DATA_WIDTH       : integer := 128;
            PCIE_ADDR_WIDTH       : integer := 32;
            PCIE_LOWER_ADDR_WIDTH : integer := 7;
            PCIE_RW_LENGTH_WIDTH  : integer := 13;
            PCIE_ID_WIDTH         : integer := 16;
            PCIE_FUNC_WIDTH       : integer := 3;
            PCIE_TAG_WIDTH        : integer := 6;
--            PKT_TAG_WIDTH         : integer := 9;
            PCIE_CRED_WIDTH       : integer := 36;
            
            PCIE_CPL_LENGTH_MIN : integer := 128;
            
            P2H_ADDR_SPACES      : integer := 4;
            P2H_HDMA_ADDR_SPACES : integer := 1;
            
            HIBI_IF_ADDR : std_logic_vector(31 downto 0) := x"10000000";
            
            P2H_ADDR_0_WIDTH     : integer := 16;
            P2H_ADDR_0_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_0_HIBI_BASE : std_logic_vector(31 downto 0) := x"00010000";
            P2H_ADDR_1_WIDTH     : integer := 8;
            P2H_ADDR_1_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000010000";
            P2H_ADDR_1_HIBI_BASE : std_logic_vector(31 downto 0) := x"00020000";
            P2H_ADDR_2_WIDTH     : integer := 8;
            P2H_ADDR_2_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000010100";
            P2H_ADDR_2_HIBI_BASE : std_logic_vector(31 downto 0) := x"00020100";
            P2H_ADDR_3_WIDTH     : integer := 8;
            P2H_ADDR_3_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000010200";
            P2H_ADDR_3_HIBI_BASE : std_logic_vector(31 downto 0) := x"00020200";
            P2H_ADDR_4_WIDTH     : integer := 1;
            P2H_ADDR_4_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_4_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_5_WIDTH     : integer := 1;
            P2H_ADDR_5_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_5_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_6_WIDTH     : integer := 1;
            P2H_ADDR_6_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_6_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_7_WIDTH     : integer := 1;
            P2H_ADDR_7_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_7_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            
            HDMA_REQS_MIN : integer := 2;
            
            H2P_WR_CHANS : integer := 32;
            H2P_RD_CHANS : integer := 128;
            P2H_WR_CHANS : integer := 128;
            P2H_RD_CHANS : integer := 32;
            
            DDR2_ADDR_WIDTH : integer := 14;
            DDR2_DATA_WIDTH : integer := 64;
            DDR2_DQS_WIDTH  : integer := 8;
            DDR2_BA_WIDTH   : integer := 3;
            DDR2_CLK_WIDTH  : integer := 2 );
            

  port (
    
    clk_pcie : in std_logic;
    clk_ref : in std_logic;
    rst_n : in std_logic;
    rst_n_pcie : in std_logic;
    clk_sys_out : out std_logic;
    
    rx_st_data_i   : in std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
    rx_st_valid_i  : in std_logic;
    rx_st_sop_i    : in std_logic;
    rx_st_eop_i    : in std_logic;
    rx_st_empty_i  : in std_logic;
    rx_st_bardec_i : in std_logic_vector(7 downto 0);
--    rx_st_be_i     : in std_logic_vector(15 downto 0);
    rx_st_ready_o  : out std_logic;
    rx_st_mask_o   : out std_logic;
                  
    tx_st_sop_o   : out std_logic;
    tx_st_eop_o   : out std_logic;
    tx_st_empty_o : out std_logic;
    tx_st_valid_o : out std_logic;
    tx_st_data_o  : out std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
    tx_st_ready_i : in std_logic;
    txcred_i      : in std_logic_vector(PCIE_CRED_WIDTH-1 downto 0);
    
    app_msi_req_out : out std_logic;
    app_msi_ack_in  : in  std_logic;
    app_msi_tc_out  : out std_logic_vector(2 downto 0);
    app_msi_num_out : out std_logic_vector(4 downto 0);
    pex_msi_num_out : out std_logic_vector(4 downto 0);
    app_int_sts_out : out std_logic;
    app_int_ack_in  : in  std_logic;

    tl_cfg_add    : in std_logic_vector(3 downto 0);
    tl_cfg_ctl    : in std_logic_vector(31 downto 0);
    tl_cfg_ctl_wr : in  std_logic;
    
    lmi_data_in  : in std_logic_vector(31 downto 0);
    lmi_re_out   : out std_logic;
    lmi_we_out   : out std_logic;
    lmi_ack_in   : in  std_logic;
    lmi_addr_out : out std_logic_vector(11 downto 0);
    lmi_data_out : out std_logic_vector(31 downto 0);
    
    ddr2_clk   : inout std_logic_vector(DDR2_CLK_WIDTH-1 downto 0);
    ddr2_clk_n : inout std_logic_vector(DDR2_CLK_WIDTH-1 downto 0);
    ddr2_odt   : out std_logic;
    ddr2_cs_n  : out std_logic;
    ddr2_cke   : out std_logic;
    ddr2_addr  : out std_logic_vector(DDR2_ADDR_WIDTH-1 downto 0);
    ddr2_ba    : out std_logic_vector(DDR2_BA_WIDTH-1 downto 0);
    ddr2_ras_n : out std_logic;
    ddr2_cas_n : out std_logic;
    ddr2_we_n  : out std_logic;
    ddr2_dm    : out std_logic_vector(DDR2_DQS_WIDTH-1 downto 0);
    ddr2_dq    : inout std_logic_vector(DDR2_DATA_WIDTH-1 downto 0);
    ddr2_dqs   : inout std_logic_vector(DDR2_DQS_WIDTH-1 downto 0);
    ddr2_dqs_n : inout std_logic_vector(DDR2_DQS_WIDTH-1 downto 0);
	 debug_out  : out std_logic );

end pcie_to_hibi_test_app;

architecture rtl of pcie_to_hibi_test_app is

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
  
  function log2_ceil(N : natural) return positive is
  begin
    if N < 2 then
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
  
  constant MEM_ADDR_WIDTH : integer := 25;
  constant MEM_DATA_WIDTH : integer := 256;
  constant MEM_BE_WIDTH   : integer := MEM_DATA_WIDTH/8;
  
  component a2_ddr2_dimm_1GB
    port (
      local_address : in std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
      local_write_req : in std_logic;
      local_read_req : in std_logic;
      local_burstbegin : in std_logic;
      local_wdata : in std_logic_vector(MEM_DATA_WIDTH-1 downto 0);
      local_be : in std_logic_vector(MEM_BE_WIDTH-1 downto 0);
      local_size : in std_logic_vector(2 downto 0);
      global_reset_n : in std_logic;
      pll_ref_clk : in std_logic;
      soft_reset_n : in std_logic;
      local_ready : out std_logic;
      local_rdata : out std_logic_vector(MEM_DATA_WIDTH-1 downto 0);
      local_rdata_valid : out std_logic;
      reset_request_n : out std_logic;
      mem_odt : out std_logic;
      mem_cs_n : out std_logic;
      mem_cke : out std_logic;
      mem_addr : out std_logic_vector(13 downto 0);
      mem_ba : out std_logic_vector(2 downto 0);
      mem_ras_n : out std_logic;
      mem_cas_n : out std_logic;
      mem_we_n : out std_logic;
      mem_dm : out std_logic_vector(7 downto 0);
      local_refresh_ack : out std_logic;
--      local_wdata_req : out std_logic;
      local_init_done : out std_logic;
      reset_phy_clk_n : out std_logic;
      dll_reference_clk : out std_logic;
      dqs_delay_ctrl_export : out std_logic_vector(5 downto 0);
      phy_clk : out std_logic;
      aux_full_rate_clk : out std_logic;
      aux_half_rate_clk : out std_logic;
      mem_clk : inout std_logic_vector(1 downto 0);
      mem_clk_n : inout std_logic_vector(1 downto 0);
      mem_dq : inout std_logic_vector(63 downto 0);
      mem_dqs : inout std_logic_vector(7 downto 0);
      mem_dqsn : inout std_logic_vector(7 downto 0) );
  end component;
  
  
  
  --synthesis translate_off
  component a2_ddr2_dimm_1GB_full_mem_model
    port (
      global_reset_n : out std_logic;
      mem_dq : inout std_logic_vector(63 downto 0);
      mem_dqs : inout std_logic_vector(7 downto 0);
      mem_dqs_n : inout std_logic_vector(7 downto 0);
      mem_addr : in std_logic_vector(13 downto 0);
      mem_ba : in std_logic_vector(2 downto 0);
      mem_cas_n : in std_logic;
      mem_cke : in std_logic;
      mem_clk : in std_logic;
      mem_clk_n : in std_logic;
      mem_cs_n : in std_logic;
      mem_dm : in std_logic_vector(7 downto 0);
      mem_odt : in std_logic;
      mem_ras_n : in std_logic;
      mem_we_n : in std_logic );
  end component;
  --synthesis translate_on
  
  constant ENABLE_SIM : integer := 0
  -- synthesis translate_off
  + 1
  -- synthesis translate_on
  ;
  
  constant CLK_PERIOD : time := 1*5 ns;
  
  constant HIBI_COM_WIDTH : integer := comm_width_c;
  constant HIBI_COM_FILL   : std_logic_vector(15-HIBI_COM_WIDTH downto 0) := (others => '0');
  
  constant HIBI_COM_WR     : std_logic_vector(15 downto 0) := HIBI_COM_FILL & DATA_WRNP_c;
  constant HIBI_COM_RD     : std_logic_vector(15 downto 0) := HIBI_COM_FILL & DATA_RD_c;
  constant HIBI_COM_MSG_WR : std_logic_vector(15 downto 0) := HIBI_COM_FILL & MSG_WRNP_c;
  constant HIBI_COM_MSG_RD : std_logic_vector(15 downto 0) := HIBI_COM_FILL & MSG_RD_c;
  
  constant HIBI_R3_WRAPPERS : integer := 2;
  
  constant BURST_SIZE_WIDTH : integer := 3;
  
  
  
  
--  signal ref_clk : std_logic
  --synthesis translate_off
--  := '1'
  --synthesis translate_on
--  ;
  
--  signal g_rst_n : std_logic
  --synthesis translate_off
--  := '0'
  --synthesis translate_on
--  ;
  
  signal clk  : std_logic;
--  signal rst_n   : std_logic;
  
  signal mem_init_done   : std_logic;
  signal p2h_init_done   : std_logic;
  
  signal mem_wr_req      : std_logic;
  signal mem_rd_req      : std_logic;
  signal mem_addr        : std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
  signal mem_ready       : std_logic;
  signal mem_rdata_valid : std_logic;

  signal mem_wdata       : std_logic_vector(MEM_DATA_WIDTH-1 downto 0);
  signal mem_rdata       : std_logic_vector(MEM_DATA_WIDTH-1 downto 0);
    
  signal mem_be          : std_logic_vector(MEM_BE_WIDTH-1 downto 0);
    
  signal mem_burst_begin : std_logic;
  signal mem_burst_size  : std_logic_vector(BURST_SIZE_WIDTH-1 downto 0);
  
  
  signal debug_wdata_error : std_logic;
  
  
  signal ddr2_odt_0   : std_logic;
  signal ddr2_cs_n_0  : std_logic;
  signal ddr2_cke_0   : std_logic;
  signal ddr2_addr_0  : std_logic_vector(DDR2_ADDR_WIDTH-1 downto 0);
  signal ddr2_ba_0    : std_logic_vector(DDR2_BA_WIDTH-1 downto 0);
  signal ddr2_ras_n_0 : std_logic;
  signal ddr2_cas_n_0 : std_logic;
  signal ddr2_we_n_0  : std_logic;
  signal ddr2_dm_0    : std_logic_vector(DDR2_DQS_WIDTH-1 downto 0);
  signal ddr2_clk_0   : std_logic_vector(DDR2_CLK_WIDTH-1 downto 0);
  signal ddr2_clk_n_0 : std_logic_vector(DDR2_CLK_WIDTH-1 downto 0);
  signal ddr2_dq_0    : std_logic_vector(DDR2_DATA_WIDTH-1 downto 0);
  signal ddr2_dqs_0   : std_logic_vector(DDR2_DQS_WIDTH-1 downto 0);
  signal ddr2_dqs_n_0 : std_logic_vector(DDR2_DQS_WIDTH-1 downto 0);
  
  signal p2h_hibi_waddr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal p2h_hibi_wdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal p2h_hibi_wcom  : std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
  signal p2h_hibi_full  : std_logic;
  signal p2h_hibi_empty : std_logic;
  signal p2h_hibi_raddr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal p2h_hibi_rdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal p2h_hibi_rcom  : std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
  signal p2h_hibi_re    : std_logic;
  signal p2h_hibi_we    : std_logic;
  signal p2h_hibi_msg_waddr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal p2h_hibi_msg_wdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal p2h_hibi_msg_wcom  : std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
  signal p2h_hibi_msg_full  : std_logic;
  signal p2h_hibi_msg_empty : std_logic;
  signal p2h_hibi_msg_raddr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal p2h_hibi_msg_rdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal p2h_hibi_msg_rcom  : std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
  signal p2h_hibi_msg_re    : std_logic;
  signal p2h_hibi_msg_we    : std_logic;
  
  signal hibi_mem_dma_hibi_waddr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_wdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_wcom  : std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_full  : std_logic;
  signal hibi_mem_dma_hibi_empty : std_logic;
  signal hibi_mem_dma_hibi_raddr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_rdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_rcom  : std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_re    : std_logic;
  signal hibi_mem_dma_hibi_we    : std_logic;
  signal hibi_mem_dma_hibi_msg_waddr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_msg_wdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_msg_wcom  : std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_msg_full  : std_logic;
  signal hibi_mem_dma_hibi_msg_empty : std_logic;
  signal hibi_mem_dma_hibi_msg_raddr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_msg_rdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_msg_rcom  : std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
  signal hibi_mem_dma_hibi_msg_re    : std_logic;
  signal hibi_mem_dma_hibi_msg_we    : std_logic;
  
  signal hibi_waddr : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_wdata : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_wcom  : std_logic_vector(HIBI_COM_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_full  : std_logic_vector(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_empty : std_logic_vector(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_raddr : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_rdata : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_rcom  : std_logic_vector(HIBI_COM_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_re    : std_logic_vector(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_we    : std_logic_vector(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_waddr : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_wdata : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_wcom  : std_logic_vector(HIBI_COM_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_full  : std_logic_vector(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_empty : std_logic_vector(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_raddr : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_rdata : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_rcom  : std_logic_vector(HIBI_COM_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_re    : std_logic_vector(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_we    : std_logic_vector(HIBI_R3_WRAPPERS-1 downto 0);
  
begin
  
  --synthesis translate_off
--   debug_gen_0 : if DEBUG = 1 generate
--   process
--   begin
--     report "---------------------------------------------------";
--     report "";
--     report "WRITE_CHANNELS_WIDTH: " & str(WRITE_CHANNELS_WIDTH);
--     report "READ_CHANNELS_WIDTH: " & str(READ_CHANNELS_WIDTH);
--     report "maximum(WRITE_CHANNELS, READ_CHANNELS)*2: " & str(maximum(WRITE_CHANNELS, READ_CHANNELS)*2);
--     report "---------------------------------------------------";
--     wait until DEBUG = 0;
--   end process;
--   end generate;
  --synthesis translate_on
  
--   gen_0 : if ENABLE_SIM = 0 generate
--   ref_clk <= clk_ref;
--   rst_n <= rst_g_n;
--   g_rst_n <= rst_n;
--   end generate;
  
  --synthesis translate_off
--  ref_clk <= not ref_clk after CLK_PERIOD/2;
--  g_rst_n <= '0', '1' after 4.6 * CLK_PERIOD;
  --synthesis translate_on
  
  clk_sys_out <= clk;
  
--  app_msi_num_out <= (others => '0');
  pex_msi_num_out <= (others => '0');
  
  pcie_to_hibi_0 : entity work.pcie_to_hibi
  generic map ( HIBI_DATA_WIDTH => HIBI_DATA_WIDTH,
                HIBI_COM_WIDTH  => HIBI_COM_WIDTH,
                HIBI_COM_WR     => HIBI_COM_WR,
                HIBI_COM_RD     => HIBI_COM_RD,
                HIBI_COM_MSG_WR => HIBI_COM_MSG_WR,
--                HIBI_COM_MSG_RD => HIBI_COM_MSG_RD,
                
                HIBI_ADDR_SPACE_WIDTH => HIBI_ADDR_SPACE_WIDTH,
                HIBI_RW_LENGTH_WIDTH => HIBI_RW_LENGTH_WIDTH,
                
                PCIE_DATA_WIDTH       => PCIE_DATA_WIDTH,
                PCIE_ADDR_WIDTH       => PCIE_ADDR_WIDTH,
                PCIE_LOWER_ADDR_WIDTH => PCIE_LOWER_ADDR_WIDTH,
                PCIE_RW_LENGTH_WIDTH  => PCIE_RW_LENGTH_WIDTH,
                PCIE_ID_WIDTH         => PCIE_ID_WIDTH,
                PCIE_FUNC_WIDTH       => PCIE_FUNC_WIDTH,
                PCIE_TAG_WIDTH        => PCIE_TAG_WIDTH,
--                PKT_TAG_WIDTH         => PKT_TAG_WIDTH,
                PCIE_CRED_WIDTH       => PCIE_CRED_WIDTH,
                
                PCIE_CPL_LENGTH_MIN => PCIE_CPL_LENGTH_MIN,
                
                PCIE_MAX_RW_LENGTH => 128,
                PCIE_FORCE_MAX_RW_LENGTH => 0, --ENABLE_SIM,
                
                P2H_ADDR_SPACES => P2H_ADDR_SPACES,
                P2H_HDMA_ADDR_SPACES => P2H_HDMA_ADDR_SPACES,
                
                HIBI_IF_ADDR => HIBI_IF_ADDR,
                
                P2H_ADDR_0_WIDTH => P2H_ADDR_0_WIDTH,
                P2H_ADDR_0_PCIE_BASE => P2H_ADDR_0_PCIE_BASE,
                P2H_ADDR_0_HIBI_BASE => P2H_ADDR_0_HIBI_BASE,
                P2H_ADDR_1_WIDTH => P2H_ADDR_1_WIDTH,
                P2H_ADDR_1_PCIE_BASE => P2H_ADDR_1_PCIE_BASE,
                P2H_ADDR_1_HIBI_BASE => P2H_ADDR_1_HIBI_BASE,
                P2H_ADDR_2_WIDTH => P2H_ADDR_2_WIDTH,
                P2H_ADDR_2_PCIE_BASE => P2H_ADDR_2_PCIE_BASE,
                P2H_ADDR_2_HIBI_BASE => P2H_ADDR_2_HIBI_BASE,
                P2H_ADDR_3_WIDTH => P2H_ADDR_3_WIDTH,
                P2H_ADDR_3_PCIE_BASE => P2H_ADDR_3_PCIE_BASE,
                P2H_ADDR_3_HIBI_BASE => P2H_ADDR_3_HIBI_BASE,
                P2H_ADDR_4_WIDTH => P2H_ADDR_4_WIDTH,
                P2H_ADDR_4_PCIE_BASE => P2H_ADDR_4_PCIE_BASE,
                P2H_ADDR_4_HIBI_BASE => P2H_ADDR_4_HIBI_BASE,
                P2H_ADDR_5_WIDTH => P2H_ADDR_5_WIDTH,
                P2H_ADDR_5_PCIE_BASE => P2H_ADDR_5_PCIE_BASE,
                P2H_ADDR_5_HIBI_BASE => P2H_ADDR_5_HIBI_BASE,
                P2H_ADDR_6_WIDTH => P2H_ADDR_6_WIDTH,
                P2H_ADDR_6_PCIE_BASE => P2H_ADDR_6_PCIE_BASE,
                P2H_ADDR_6_HIBI_BASE => P2H_ADDR_6_HIBI_BASE,
                P2H_ADDR_7_WIDTH => P2H_ADDR_7_WIDTH,
                P2H_ADDR_7_PCIE_BASE => P2H_ADDR_7_PCIE_BASE,
                P2H_ADDR_7_HIBI_BASE => P2H_ADDR_7_HIBI_BASE,
                
                HDMA_REQS_MIN => HDMA_REQS_MIN,
            
                H2P_WR_CHANS => H2P_WR_CHANS,
                H2P_RD_CHANS => H2P_RD_CHANS,
                P2H_WR_CHANS => P2H_WR_CHANS,
                P2H_RD_CHANS => P2H_RD_CHANS )
  
  port map (
    clk   => clk,
    rst_n => rst_n,
    
    clk_pcie => clk_pcie,
    
    init_done_out => p2h_init_done,
    
    
    rx_st_data_i   => rx_st_data_i,
    rx_st_valid_i  => rx_st_valid_i,
    rx_st_sop_i    => rx_st_sop_i,
    rx_st_eop_i    => rx_st_eop_i,
    rx_st_empty_i  => rx_st_empty_i,
    rx_st_bardec_i => rx_st_bardec_i,
    rx_st_ready_o  => rx_st_ready_o,
    rx_st_mask_o   => rx_st_mask_o,
    
    tx_st_sop_o   => tx_st_sop_o,
    tx_st_eop_o   => tx_st_eop_o,
    tx_st_empty_o => tx_st_empty_o,
    tx_st_valid_o => tx_st_valid_o,
    tx_st_data_o  => tx_st_data_o,
    tx_st_ready_i => tx_st_ready_i,
    txcred_i      => txcred_i,
    
    app_msi_req_out => app_msi_req_out,
    app_msi_ack_in  => app_msi_ack_in,
    app_msi_tc_out  => app_msi_tc_out,
    app_msi_num_out => app_msi_num_out,
--    pex_msi_num_out => pex_msi_num_out,
--    app_int_sts_out => app_int_sts_out,
--    app_int_ack_in  => app_int_ack_in,

    tl_cfg_add => tl_cfg_add,
    tl_cfg_ctl => tl_cfg_ctl,
    tl_cfg_ctl_wr => tl_cfg_ctl_wr,
    
    lmi_data_in  => lmi_data_in,
    lmi_re_out   => lmi_re_out,
    lmi_we_out   => lmi_we_out,
    lmi_ack_in   => lmi_ack_in,
    lmi_addr_out => lmi_addr_out,
    lmi_data_out => lmi_data_out,

    hibi_addr_in  => p2h_hibi_raddr,
    hibi_data_in  => p2h_hibi_rdata,
    hibi_comm_in  => p2h_hibi_rcom,
    hibi_empty_in => p2h_hibi_empty,
    hibi_re_out   => p2h_hibi_re,

    hibi_addr_out => p2h_hibi_waddr,
    hibi_data_out => p2h_hibi_wdata,
    hibi_comm_out => p2h_hibi_wcom,
    hibi_full_in  => p2h_hibi_full,
    hibi_we_out   => p2h_hibi_we,

    hibi_msg_addr_in  => p2h_hibi_msg_raddr,
    hibi_msg_data_in  => p2h_hibi_msg_rdata,
    hibi_msg_comm_in  => p2h_hibi_msg_rcom, 
    hibi_msg_empty_in => p2h_hibi_msg_empty,
    hibi_msg_re_out   => p2h_hibi_msg_re,   
                                        
    hibi_msg_data_out => p2h_hibi_msg_wdata,
    hibi_msg_addr_out => p2h_hibi_msg_waddr,
    hibi_msg_comm_out => p2h_hibi_msg_wcom, 
    hibi_msg_full_in  => p2h_hibi_msg_full, 
    hibi_msg_we_out   => p2h_hibi_msg_we,
	
    debug_out => debug_out	);   
  
  
  hibi_mem_dma_0 : entity work.hibi_mem_dma
  generic map (
    HIBI_DATA_WIDTH => HIBI_DATA_WIDTH,
    HIBI_COM_WIDTH  => HIBI_COM_WIDTH,
    HIBI_COM_WR     => HIBI_COM_WR,
    HIBI_COM_RD     => HIBI_COM_RD,
    HIBI_COM_MSG_WR => HIBI_COM_MSG_WR,
--    HIBI_COM_MSG_RD => HIBI_COM_MSG_RD,
    
    
    MEM_DATA_WIDTH => 32, --MEM_DATA_WIDTH,
    MEM_ADDR_WIDTH => MEM_ADDR_WIDTH,
    MEM_BE_WIDTH => 4, --MEM_BE_WIDTH,
    
    BURST_SIZE_WIDTH => BURST_SIZE_WIDTH,
    
    READ_CHANNELS => 32,
    WRITE_CHANNELS => 32,
    
    RW_AMOUNT_WIDTH => 20,
    RW_ADDR_INC_WIDTH => 14,
    RW_ADDR_INTERVAL_WIDTH => 14,
    RW_ADDR_INTERVAL_INC_WIDTH => 14,
    DEBUG => 1 )
  
  port map (
    clk => clk,
    rst_n => rst_n,

    hibi_addr_in      => hibi_mem_dma_hibi_raddr,
    hibi_data_in      => hibi_mem_dma_hibi_rdata,
    hibi_comm_in      => hibi_mem_dma_hibi_rcom,
    hibi_empty_in     => hibi_mem_dma_hibi_empty,
    hibi_re_out       => hibi_mem_dma_hibi_re,
    hibi_addr_out     => hibi_mem_dma_hibi_waddr,
    hibi_data_out     => hibi_mem_dma_hibi_wdata,
    hibi_comm_out     => hibi_mem_dma_hibi_wcom,
    hibi_full_in      => hibi_mem_dma_hibi_full,
    hibi_we_out       => hibi_mem_dma_hibi_we,
    
    hibi_msg_addr_in      => hibi_mem_dma_hibi_msg_raddr,
    hibi_msg_data_in      => hibi_mem_dma_hibi_msg_rdata,
    hibi_msg_comm_in      => hibi_mem_dma_hibi_msg_rcom,
    hibi_msg_empty_in     => hibi_mem_dma_hibi_msg_empty,
    hibi_msg_re_out       => hibi_mem_dma_hibi_msg_re,
    hibi_msg_addr_out     => hibi_mem_dma_hibi_msg_waddr,
    hibi_msg_data_out     => hibi_mem_dma_hibi_msg_wdata,
    hibi_msg_comm_out     => hibi_mem_dma_hibi_msg_wcom,
    hibi_msg_full_in      => hibi_mem_dma_hibi_msg_full,
    hibi_msg_we_out       => hibi_mem_dma_hibi_msg_we,
    
    mem_init_done_in  => mem_init_done,
    
    mem_wr_req_out    => mem_wr_req,
    mem_rd_req_out    => mem_rd_req,
    mem_addr_out      => mem_addr,
    mem_ready_in      => mem_ready,
    mem_rdata_valid_in => mem_rdata_valid,
    
    mem_wdata_out      => mem_wdata(31 downto 0),
    mem_rdata_in       => mem_rdata(31 downto 0),
    
    mem_be_out         => mem_be(3 downto 0),
    
    mem_burst_begin_out => mem_burst_begin,
    mem_burst_size_out  => mem_burst_size );
  
  mem_wdata(MEM_DATA_WIDTH-1 downto 32) <= (others => '0');
  mem_be(MEM_BE_WIDTH-1 downto 4) <= (others => '1');
  
  gen_1 : if ENABLE_SIM = 1 generate
  mem_ctrl : a2_ddr2_dimm_1GB
  port map (
    pll_ref_clk  => clk_ref,
    phy_clk      => clk,
    
    global_reset_n => rst_n,
    soft_reset_n   => '1',
    
    local_init_done    => mem_init_done,
    local_address      => mem_addr,
    local_write_req    => mem_wr_req,
    local_read_req    => mem_rd_req,
    local_wdata        => mem_wdata,
    local_be          => mem_be,
    local_ready        => mem_ready,
    local_rdata        => mem_rdata,
    local_rdata_valid  => mem_rdata_valid,
    
    local_burstbegin  => mem_burst_begin,
    local_size        => mem_burst_size,
    
    mem_clk   => ddr2_clk_0,
    mem_clk_n => ddr2_clk_n_0,
    mem_odt   => ddr2_odt_0,
    mem_cs_n  => ddr2_cs_n_0,
    mem_cke   => ddr2_cke_0,
    mem_addr  => ddr2_addr_0,
    mem_ba    => ddr2_ba_0,
    mem_ras_n => ddr2_ras_n_0,
    mem_cas_n => ddr2_cas_n_0,
    mem_we_n  => ddr2_we_n_0,
    mem_dm    => ddr2_dm_0,
    mem_dq    => ddr2_dq_0,
    mem_dqs   => ddr2_dqs_0,
    mem_dqsn  => ddr2_dqs_n_0 );
  end generate;
  
  gen_2 : if ENABLE_SIM = 0 generate
  mem_ctrl : a2_ddr2_dimm_1GB
  port map (
    pll_ref_clk  => clk_ref,
    phy_clk      => clk,
    
    global_reset_n => rst_n,
    soft_reset_n   => '1',
    
    local_init_done    => mem_init_done,
    local_address      => mem_addr,
    local_write_req    => mem_wr_req,
    local_read_req    => mem_rd_req,
    local_wdata        => mem_wdata,
    local_be          => mem_be,
    local_ready        => mem_ready,
    local_rdata        => mem_rdata,
    local_rdata_valid  => mem_rdata_valid,
    local_burstbegin  => mem_burst_begin,
    local_size        => mem_burst_size,
    
    mem_clk   => ddr2_clk,
    mem_clk_n => ddr2_clk_n,
    mem_odt   => ddr2_odt,
    mem_cs_n  => ddr2_cs_n,
    mem_cke   => ddr2_cke,
    mem_addr  => ddr2_addr,
    mem_ba    => ddr2_ba,
    mem_ras_n => ddr2_ras_n,
    mem_cas_n => ddr2_cas_n,
    mem_we_n  => ddr2_we_n,
    mem_dm    => ddr2_dm,
    mem_dq    => ddr2_dq,
    mem_dqs   => ddr2_dqs,
    mem_dqsn  => ddr2_dqs_n );
  end generate;
  
  --synthesis translate_off
  a2_ddr2_dimm_1GB_0 : a2_ddr2_dimm_1GB_full_mem_model
  port map (
    mem_clk   => ddr2_clk_0(0),
    mem_clk_n => ddr2_clk_n_0(0),
    mem_odt   => ddr2_odt_0,
    mem_cs_n  => ddr2_cs_n_0,
    mem_cke   => ddr2_cke_0,
    mem_addr  => ddr2_addr_0,
    mem_ba    => ddr2_ba_0,
    mem_ras_n => ddr2_ras_n_0,
    mem_cas_n => ddr2_cas_n_0,
    mem_we_n  => ddr2_we_n_0,
    mem_dm    => ddr2_dm_0,
    mem_dq    => ddr2_dq_0,
    mem_dqs   => ddr2_dqs_0,
    mem_dqs_n  => ddr2_dqs_n_0 );
    
--    global_reset_n => rst_n );  
  --synthesis translate_on
  
  hibi_seg_0 : entity work.hibiv3_seg_r3
  generic map (
    -- HIBI generics
--    id_width_g          => 4,
    addr_width_g        => HIBI_DATA_WIDTH,
    data_width_g        => HIBI_DATA_WIDTH,
    comm_width_g        => comm_width_c,
--    counter_width_g     => 8,
--    rel_agent_freq_g    => 1,
--    rel_bus_freq_g      => 1,
--    arb_type_g          => 3,
--    fifo_sel_g          => 0,
--    rx_fifo_depth_g     => 4,
--    rx_msg_fifo_depth_g => 4,
--    tx_fifo_depth_g     => 4,
--    tx_msg_fifo_depth_g => 4,
--    max_send_g          => 20,
--    n_cfg_pages_g       => 1,
--    n_time_slots_g      => 0,
--    keep_slot_g         => 0,
--    n_extra_params_g    => 1,

--    cfg_re_g            => 1,
--    cfg_we_g            => 1,
--    debug_width_g       => 0,
    n_agents_g   => HIBI_R3_WRAPPERS,
    n_segments_g => 1,
    separate_addr_g => 0,
    addr_space_width_g => HIBI_DATA_WIDTH-4 )

  port map (
    clk_ip  => clk,
    clk_noc => clk,
    rst_n   => rst_n,

    agent_comm_in   => hibi_wcom,
    agent_data_in   => hibi_wdata,
    agent_addr_in   => hibi_waddr,
    agent_we_in     => hibi_we,
    agent_re_in     => hibi_re,
    agent_comm_out  => hibi_rcom,
    agent_data_out  => hibi_rdata,
    agent_addr_out  => hibi_raddr,
    agent_full_out  => hibi_full,
--    agent_one_p_out => hibi_one_p,
    agent_empty_out => hibi_empty,
--    agent_one_d_out => hibi_one_d,
    
    agent_msg_comm_in   => hibi_msg_wcom,
    agent_msg_data_in   => hibi_msg_wdata,
    agent_msg_addr_in   => hibi_msg_waddr,
    agent_msg_we_in     => hibi_msg_we,
    agent_msg_re_in     => hibi_msg_re,
    agent_msg_comm_out  => hibi_msg_rcom,
    agent_msg_data_out  => hibi_msg_rdata,
    agent_msg_addr_out  => hibi_msg_raddr,
    agent_msg_full_out  => hibi_msg_full,
--    agent_msg_one_p_out => hibi_msg_one_p,
    agent_msg_empty_out => hibi_msg_empty
--    agent_msg_one_d_out => hibi_msg_one_d,
    );
  
  hibi_waddr <= p2h_hibi_waddr & hibi_mem_dma_hibi_waddr;
  hibi_wdata <= p2h_hibi_wdata & hibi_mem_dma_hibi_wdata;
  hibi_wcom <= p2h_hibi_wcom & hibi_mem_dma_hibi_wcom;
  hibi_re <= p2h_hibi_re & hibi_mem_dma_hibi_re;
  hibi_we <= p2h_hibi_we & hibi_mem_dma_hibi_we;
  
  hibi_msg_waddr <= p2h_hibi_msg_waddr & hibi_mem_dma_hibi_msg_waddr;
  hibi_msg_wdata <= p2h_hibi_msg_wdata & hibi_mem_dma_hibi_msg_wdata;
  hibi_msg_wcom <= p2h_hibi_msg_wcom & hibi_mem_dma_hibi_msg_wcom;
  hibi_msg_re <= p2h_hibi_msg_re & hibi_mem_dma_hibi_msg_re;
  hibi_msg_we <= p2h_hibi_msg_we & hibi_mem_dma_hibi_msg_we;
  
  p2h_hibi_full <= hibi_full(1);
  p2h_hibi_empty <= hibi_empty(1);
  p2h_hibi_raddr <= hibi_raddr(HIBI_DATA_WIDTH*2-1 downto HIBI_DATA_WIDTH);
  p2h_hibi_rdata <= hibi_rdata(HIBI_DATA_WIDTH*2-1 downto HIBI_DATA_WIDTH);
  p2h_hibi_rcom <= hibi_rcom(HIBI_COM_WIDTH*2-1 downto HIBI_COM_WIDTH);
  p2h_hibi_msg_full <= hibi_msg_full(1);
  p2h_hibi_msg_empty <= hibi_msg_empty(1);
  p2h_hibi_msg_raddr <= hibi_msg_raddr(HIBI_DATA_WIDTH*2-1 downto HIBI_DATA_WIDTH);
  p2h_hibi_msg_rdata <= hibi_msg_rdata(HIBI_DATA_WIDTH*2-1 downto HIBI_DATA_WIDTH);
  p2h_hibi_msg_rcom <= hibi_msg_rcom(HIBI_COM_WIDTH*2-1 downto HIBI_COM_WIDTH);
  
  hibi_mem_dma_hibi_full <= hibi_full(0);
  hibi_mem_dma_hibi_empty <= hibi_empty(0);
  hibi_mem_dma_hibi_raddr <= hibi_raddr(HIBI_DATA_WIDTH-1 downto 0);
  hibi_mem_dma_hibi_rdata <= hibi_rdata(HIBI_DATA_WIDTH-1 downto 0);
  hibi_mem_dma_hibi_rcom <= hibi_rcom(HIBI_COM_WIDTH-1 downto 0);
  hibi_mem_dma_hibi_msg_full <= hibi_msg_full(0);
  hibi_mem_dma_hibi_msg_empty <= hibi_msg_empty(0);
  hibi_mem_dma_hibi_msg_raddr <= hibi_msg_raddr(HIBI_DATA_WIDTH-1 downto 0);
  hibi_mem_dma_hibi_msg_rdata <= hibi_msg_rdata(HIBI_DATA_WIDTH-1 downto 0);
  hibi_mem_dma_hibi_msg_rcom <= hibi_msg_rcom(HIBI_COM_WIDTH-1 downto 0);
  
  
  
end rtl;
  