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
-- Title      : Testbench for HIBI MEM DMA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : hibi_mem_dma_tb.vhd
-- Author     : jua
-- Created    : 03.06.2010
-- Last update: 09.06.2010
-- Description: 
--
-------------------------------------------------------------------------------
-- Copyright (c) 2010 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 03.06.2010    0.1     jua      Created
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity hibi_mem_dma_tb is
  port (
--    clkin_ref_q1_1_p : in std_logic;     --LVDS    --adj. defaut 100.000 MHz osc
--    clkin_ref_q1_2_p : in std_logic;     --LVDS    --adj. defaut 125.000 MHz osc
--    clkin_ref_q2_p : in std_logic;     --LVDS      --adj. default 125.000 MHz osc
--    clkin_ref_q3_p : in std_logic;     --LVDS      --adj. default 125.000 MHz osc
--    clkin_155_p : in std_logic;	   --LVPECL    --155.520 MHz osc 
    clkin_bot_p : in std_logic;       --LVDS      --ADJ default 100.000 MHz osc or sma in (Requires external termination.)
    clkin_top_p : in std_logic;       --LVDS      --ADJ default 125.000 MHz osc (Requires external termination.)
    clkout_sma : out std_logic;        --1.8V      --PLL CLK sma out

	
----DDR3-SDRAM-PORTS  -> 64Mx16 Interface -----------------------49 pins
--     ddr3_a : out std_logic_vector(14 downto 0);          --SSTL15    --Address (1Gb max)
--     ddr3_ba : out std_logic_vector(2 downto 0);         --SSTL15    --Bank address
--     ddr3_dq : inout std_logic_vector(15 downto 0);         --SSTL15    --Data
--     ddr3_dqs_p : inout std_logic_vector(1 downto 0);      --SSTL15    --Strobe Pos
--     ddr3_dqs_n : inout std_logic_vector(1 downto 0);      --SSTL15    --Strobe Neg
--     ddr3_dm : out std_logic_vector(1 downto 0);         --SSTL15    --Byte write mask
--     ddr3_wen : out std_logic;        --SSTL15    --Write enable
--     ddr3_rasn : out std_logic;       --SSTL15    --Row address select
--     ddr3_casn : out std_logic;       --SSTL15    --Column address select
--     ddr3_ck_p : inout std_logic;       --SSTL15    --System Clock Pos
--     ddr3_ck_n : inout std_logic;       --SSTL15    --System Clock Neg
--     ddr3_cke : out std_logic;        --SSTL15    --Clock Enable
--     ddr3_csn : out std_logic;        --SSTL15    --Chip Select
--     ddr3_resetn : out std_logic;     --SSTL15    --Reset
--     ddr3_odt : out std_logic;        --SSTL15    --On-die termination enable
 
 --DDR2 SDRAM SoDIMM ---------------------------------------x64 -> 117 pins (Default)
	--x64 -> 125 pins
    ddr2_dimm_addr  : out std_logic_vector(15 downto 0);	 --SSTL18 --Address
    ddr2_dimm_ba    : out std_logic_vector(2 downto 0);    --SSTL18 --Bank address
    ddr2_dimm_dq    : inout std_logic_vector(63 downto 0); --SSTL18 --Data x64 SODIMM
    ddr2_dimm_dqs   : inout std_logic_vector(7 downto 0);  --SSTL18 --Strobe Pos
    ddr2_dimm_dqs_n : inout std_logic_vector(7 downto 0);  --SSTL18 --Strobe Neg
    ddr2_dimm_dm    : out std_logic_vector(7 downto 0);    --SSTL18 --Byte write mask
    ddr2_dimm_cke   : out std_logic;                       --SSTL18 --System Clock Enable
    ddr2_dimm_clk   : inout std_logic_vector(1 downto 0);  --SSTL18 --System Clock Pos
    ddr2_dimm_clk_n : inout std_logic_vector(1 downto 0);  --SSTL18 --System Clock Neg
    ddr2_dimm_we_n  : out std_logic;                       --SSTL18 --Write enable
    ddr2_dimm_ras_n : out std_logic;                       --SSTL18 --Row address select
    ddr2_dimm_cas_n : out std_logic;                       --SSTL18 --Column address select
    ddr2_dimm_cs_n : out std_logic;                        --SSTL18 --Chip Select
--    ddr2_dimm_resetn : out std_logic;                    --SSTL18 --Reset
    ddr2_dimm_odt : out std_logic;                         --SSTL18 --On-die termination enable

------------------------------------------------------------------ 
--ETHERNET-10/100/1000-RGMII-----------
    enet_gtx_clk : out std_logic;      --2.5V  --RGMII Transmit Clock
    enet_tx_d : out std_logic_vector(3 downto 0);        --2.5V  --TX to PHY
    enet_rx_d : in std_logic_vector(3 downto 0);        --2.5V  --RX from PHY
    enet_tx_en : out std_logic;       --2.5V  --RGMII Transmit Control
    enet_rx_clk : in std_logic;      --2.5V  --Derived Received Clock
    enet_rx_dv : in std_logic;       --2.5V  --RGMII Receive Control 
    enet_resetn : out std_logic;        --2.5V      --Reset to PHY (TR=0)
    enet_mdc : out std_logic;           --2.5V      --MDIO Control (TR=0)
    enet_mdio : inout std_logic;          --2.5V      --MDIO Data (TR=0)
    enet_intn : in std_logic;           --2.5V      --MDIO Interrupt (TR=0)
------------------------------------------------------------------/

--FLASH-SRAM-MAX-------------FSM-Bus-----90 pins
    fsm_a : out std_logic_vector(25 downto 0);              --2.5V      --FSM Address Bus (1Gb Flash)
    fsm_d : inout std_logic_vector(31 downto 0);              --2.5V      --FSM Data Bus
    flash_clk : out std_logic;          --2.5V  
    flash_cen : out std_logic;          --2.5V  
    flash_oen : out std_logic;          --2.5V
    flash_wen : out std_logic;          --2.5V
    flash_advn : out std_logic;         --2.5V
    flash_rdybsyn : in std_logic;      --2.5V
    flash_resetn : out std_logic;       --2.5V     -- (TR=0)
    sram_clk : out std_logic;           --2.5V
    sram_cen : out std_logic;           --2.5V
    sram_dqp : inout std_logic_vector(3 downto 0);           --2.5V     --Parity bits only go to SRAM
    sram_bwn : out std_logic_vector(3 downto 0);           --2.5V
    sram_gwn : out std_logic;           --2.5V
    sram_bwen : out std_logic;          --2.5V
    sram_oen : out std_logic;           --2.5V
    sram_advn : out std_logic;          --2.5V
    sram_adspn : out std_logic;         --2.5V
    sram_adscn : out std_logic;         --2.5V
    sram_zz : out std_logic;            --2.5V     -- (TR=0)
--     max2_clk : out std_logic;           --1.8V
--     max2_csn : out std_logic;           --1.8V
--     max2_ben : out std_logic_vector(3 downto 0);           --1.8V
--     max2_oen : out std_logic;           --1.8V
--     max2_wen : out std_logic;           --1.8V

----LCD------------------------------------11 pins
    lcd_data : inout std_logic_vector(7 downto 0);           --2.5V
    lcd_d_cn : out std_logic;           --2.5V
    lcd_wen : out std_logic;            --2.5V
    lcd_csn : out std_logic;            --2.5V
--
----User-IO--------------------------------22 pins
    user_dipsw : in std_logic_vector(3 downto 0);         --1.8V/2.5V     -- (TR=0)
--    user_led : out std_logic_vector(7 downto 0);           --2.5V
    user_led : out std_logic_vector(3 downto 0);           --2.5V
    user_pb : in std_logic_vector(1 downto 0);            --1.8V/2.5V     -- (TR=0)
--    user_pb : in std_logic_vector(1 downto 0);            --1.8V/2.5V     -- (TR=0)
    cpu_resetn : in std_logic;         --2.5V (DEV_CLRn)    -- (TR=0)
  
---- --PCI-EXPRESS-EDGE---------------------
--     pcie_refclk_p : in std_logic;      --HCSL
--     pcie_tx_p : out std_logic_vector(3 downto 0);          --1.4V PCML
--     pcie_rx_p : in std_logic_vector(3 downto 0);          --1.4V PCML
--     pcie_smbclk : in std_logic;        --2.5V     -- (TR=0)
--     pcie_smbdat : inout std_logic;        --2.5V     -- (TR=0)
--     pcie_perstn : in std_logic;        --2.5V     -- (TR=0)
--     pcie_waken : out std_logic;         --2.5V     -- (TR=0)
--     pcie_led_x1 : out std_logic;        --2.5V
--     pcie_led_x4 : out std_logic;        --2.5V
--     pcie_led_x8 : out std_logic;        --2.5V
-- --    pcie_led_g2 : out std_logic;        --2.5V
--     cal_blk_clk : in std_logic;         --Virtual Pin
--HIGH-SPEED-MEZZANINE-CARD--------------198 pins (HSMB is only connected on EP2AGX260 devices)
    --Port A -->   single samtec conn  --107 pins  --------------------
--      hsma_tx_p : out std_logic_vector(3 downto 0);    	 --1.4V PCML
--      hsma_rx_p : in std_logic_vector(3 downto 0);    	 --1.4V PCML
      --Enable below for CMOS HSMC     
      --hsma_d : inout std_logic_vector(79 downto 0);           --2.5V
      --Enable below for LVDS HSMC
    hsma_tx_d_p : out std_logic_vector(16 downto 0);        --LVDS  --69 pins
    hsma_rx_d_p : in std_logic_vector(16 downto 0);        --LVDS
    hsma_d : inout std_logic_vector(3 downto 0);             --2.5V
    hsma_clk_in0 : in std_logic;       --2.5V
    hsma_clk_out0 : out std_logic;      --2.5V
    hsma_clk_in_p1 : in std_logic;     --LVDS --Requires external termination  
    hsma_clk_out_p1 : out std_logic;    --LVDS
    hsma_clk_in_p2 : in std_logic;     --LVDS --Requires external termination
    hsma_clk_out_p2 : out std_logic;    --LVDS
    hsma_sda : inout std_logic;           --2.5V     -- (TR=0)
    hsma_scl : out std_logic;           --2.5V     -- (TR=0)
    hsma_tx_led : out std_logic;        --2.5V
    hsma_rx_led : out std_logic;        --2.5V
    hsma_prsntn : in std_logic;       --2.5V     -- (TR=0)
--    --Port B -->   single samtec conn  --107 pins  --------------------
--      --hsmb_tx_p : out std_logic_vector(3 downto 0);    	 --1.4V PCML   
--      --hsmb_rx_p : in std_logic_vector(3 downto 0);    	 --1.4V PCML   
--      --Enable below for CMOS HSMC     
--      --hsmb_d : inout std_logic_vector(79 downto 0);           --2.5V
--      --Enable below for LVDS HSMC  
--    hsmb_tx_d_p : out std_logic_vector(16 downto 0);        --LVDS   
--    hsmb_rx_d_p : in std_logic_vector(16 downto 0);        --LVDS   
--    hsmb_d : inout std_logic_vector(3 downto 0);             --2.5V
    hsmb_clk_in0 : in std_logic );       --2.5V   
--    hsmb_clk_out0 : out std_logic;      --2.5V   
--    hsmb_clk_out_p1 : out std_logic;    --LVDS   
--    hsmb_clk_out_p2 : out std_logic;    --LVDS   
--    hsmb_sda : inout std_logic;           --2.5V     -- (TR=0)   
--    hsmb_scl : out std_logic;           --2.5V     -- (TR=0)   
--    hsmb_tx_led : out std_logic;        --2.5V                 
--    hsmb_rx_led : out std_logic;        --2.5V                 
--    hsmb_prsntn : in std_logic        --2.5V     -- (TR=0)  
end hibi_mem_dma_tb;



architecture structural of hibi_mem_dma_tb is
  
  constant MEM_ADDR_WIDTH : integer := 25;
  constant MEM_DATA_WIDTH : integer := 256;
  constant MEM_BE_WIDTH   : integer := MEM_DATA_WIDTH/8;
  
  function log2_ceil(N : natural) return positive is
  begin
    if N < 2 then
      return 1;
    else
      return 1 + log2_ceil(N/2);
    end if;
  end;
  
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
      local_wdata_req : out std_logic;
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
  
  constant CLK_PERIOD : time := 1*10 ns;
  
  constant BURST_SIZE_WIDTH : integer := 3;
  
  constant DDR2_ADDR_WIDTH : integer := 14;
  constant DDR2_DATA_WIDTH : integer := 64;
  constant DDR2_DQS_WIDTH  : integer := DDR2_DATA_WIDTH/8;
  constant DDR2_BA_WIDTH   : integer := 3;
  constant DDR2_CLK_WIDTH  : integer := 2;
  
  constant M2H2_TESTERS : integer := 3;
  
  type data_array is array (M2H2_TESTERS-1 downto 0) of std_logic_vector(31 downto 0);
  type comm_array is array (M2H2_TESTERS-1 downto 0) of std_logic_vector(2 downto 0);
  type test_error_array is array (M2H2_TESTERS-1 downto 0) of std_logic_vector(19 downto 0);
  
  signal ref_clk : std_logic := '1';
  signal g_rst_n : std_logic := '0';
  
  
  signal clk  : std_logic;
  signal rst_n   : std_logic;
  
  signal rand : std_logic_vector(3 downto 0);
  
  signal hibi_av_in : std_logic_vector(M2H2_TESTERS-1 downto 0);
  signal hibi_data_in : data_array;
  signal hibi_comm_in : comm_array;
  signal hibi_full_in : std_logic_vector(M2H2_TESTERS-1 downto 0);
  signal hibi_empty_in : std_logic_vector(M2H2_TESTERS-1 downto 0);
  signal hibi_one_p_in : std_logic_vector(M2H2_TESTERS-1 downto 0);
  signal hibi_one_d_in : std_logic_vector(M2H2_TESTERS-1 downto 0);
  
  signal hibi_av_out : std_logic_vector(M2H2_TESTERS-1 downto 0);
  signal hibi_data_out : data_array;
  signal hibi_comm_out : comm_array;
  signal hibi_re_out : std_logic_vector(M2H2_TESTERS-1 downto 0);
  signal hibi_we_out : std_logic_vector(M2H2_TESTERS-1 downto 0);
  
  
  signal hibi_r3_addr_in : std_logic_vector(31 downto 0);
  signal hibi_r3_data_wra_m2h : std_logic_vector(31 downto 0);
  signal hibi_r3_comm_in : std_logic_vector(2 downto 0);
  signal hibi_r3_full_in : std_logic;
--  signal hibi_r3_one_p_in : std_logic;
  signal hibi_r3_empty_wra_m2h : std_logic;
--  signal hibi_r3_one_d_wra_m2h : std_logic;
  
  signal hibi_r3_addr_out : std_logic_vector(31 downto 0);
  signal hibi_r3_data_out : std_logic_vector(31 downto 0);
  signal hibi_r3_comm_out : std_logic_vector(2 downto 0);
  signal hibi_r3_re_out : std_logic;
  signal hibi_r3_we_out : std_logic;
  
  signal hibi_msg_r3_addr_in : std_logic_vector(31 downto 0);
  signal hibi_msg_r3_data_in : std_logic_vector(31 downto 0);
  signal hibi_msg_r3_comm_in : std_logic_vector(2 downto 0);
  signal hibi_msg_r3_full_in : std_logic;
  signal hibi_msg_r3_empty_wra_m2h : std_logic;
--  signal hibi_msg_r3_one_p_in : std_logic;
--  signal hibi_msg_r3_one_d_wra_m2h : std_logic;
  
  signal hibi_msg_r3_addr_out : std_logic_vector(31 downto 0);
  signal hibi_msg_r3_data_out : std_logic_vector(31 downto 0);
  signal hibi_msg_r3_comm_out : std_logic_vector(2 downto 0);
  signal hibi_msg_r3_re_out : std_logic;
  signal hibi_msg_r3_we_out : std_logic;
  
  
  signal test_start : std_logic;
  signal test_started : std_logic;
  signal test_done : std_logic_vector(M2H2_TESTERS-1 downto 0);
  signal test_error : test_error_array;
  
  
  
  signal mem_init_done   : std_logic;
  
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
  
  
  signal ddr2_odt    : STD_LOGIC;
  signal ddr2_cs_n  : STD_LOGIC;
  signal ddr2_cke    : STD_LOGIC;
  signal ddr2_addr  : STD_LOGIC_VECTOR (DDR2_ADDR_WIDTH-1 DOWNTO 0);
  signal ddr2_ba    : STD_LOGIC_VECTOR (DDR2_BA_WIDTH-1 DOWNTO 0);
  signal ddr2_ras_n  : STD_LOGIC;
  signal ddr2_cas_n  : STD_LOGIC;
  signal ddr2_we_n  : STD_LOGIC;
  signal ddr2_dm    : STD_LOGIC_VECTOR (DDR2_DQS_WIDTH-1 DOWNTO 0);
  signal ddr2_clk    : STD_LOGIC_VECTOR (DDR2_CLK_WIDTH-1 DOWNTO 0);
  signal ddr2_clk_n  : STD_LOGIC_VECTOR (DDR2_CLK_WIDTH-1 DOWNTO 0);
  signal ddr2_dq    : STD_LOGIC_VECTOR (DDR2_DATA_WIDTH-1 DOWNTO 0);
  signal ddr2_dqs    : STD_LOGIC_VECTOR (DDR2_DQS_WIDTH-1 DOWNTO 0);
  signal ddr2_dqs_n  : STD_LOGIC_VECTOR (DDR2_DQS_WIDTH-1 DOWNTO 0);
  
  
  
begin  -- structural
  
  
  gen_0 : if ENABLE_SIM = 0 generate
  ref_clk <= clkin_bot_p;
  rst_n <= user_pb(0);
  g_rst_n <= rst_n;
  end generate;
  
  --synthesis translate_off
  ref_clk <= not ref_clk after CLK_PERIOD/2;
  g_rst_n <= '0', '1' after 4.6 * CLK_PERIOD;
  --synthesis translate_on
  
  
  
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      test_start <= '0';
      test_started <= '0';
    elsif (clk'event and clk = '1') then
      test_start <= '0';
      
      if ((test_started = '0') and (mem_init_done = '1')) then
        test_start <= '1';
        test_started <= '1';
      end if;
    end if;
  end process;
  
  pseudo_rand_gen_r2_0 : entity work.pseudo_rand_gen_r2
  generic map (
    RAND_START_0 => x"4",
    RAND_START_1 => x"0" )
  port map (
    clk   => clk,
    rst_n => rst_n,
    
    rand_out => rand);
  
  hibi_mem_dma_tester_0 : entity work.hibi_mem_dma_tester
  generic map (
    TESTER_HIBI_BASE => x"01",
    M2H2_HIBI_BASE => x"29",
    MEM_ADDR_WIDTH => 20,
    
    TEST_DATA_UPPER_BITS => x"0",
    
    DELAY_ENABLE => 1 )
    
    
  port map (
    clk   => clk,
    rst_n => rst_n,
    
    hibi_comm_in  => hibi_comm_in(0),
    hibi_data_in  => hibi_data_in(0),
    hibi_av_in    => hibi_av_in(0),
    hibi_full_in  => hibi_full_in(0),
    hibi_one_p_in  => hibi_one_p_in(0),
    hibi_empty_in  => hibi_empty_in(0),
    hibi_one_d_in  => hibi_one_d_in(0),

    hibi_comm_out  => hibi_comm_out(0),
    hibi_data_out  => hibi_data_out(0),
    hibi_av_out    => hibi_av_out(0),
    hibi_we_out    => hibi_we_out(0),
    hibi_re_out    => hibi_re_out(0),
    
    mem_rw_addr_in => x"00000",
    mem_rw_block_length_min_in => x"00001",
    mem_rw_block_length_max_in => x"00100",
    mem_rw_block_inc_in        => x"00001",
    mem_rw_blocks_in => x"00040",
    
    test_start_in => test_start,
    test_cfg_delay_in => rand,
    
    test_done_out => test_done(0),
    test_error_out => test_error(0) );
  
  hibi_mem_dma_tester_1 : entity work.hibi_mem_dma_tester
  generic map (
    TESTER_HIBI_BASE => x"03",
    M2H2_HIBI_BASE => x"29",
    MEM_ADDR_WIDTH => 20,
    
    TEST_DATA_UPPER_BITS => x"1",
    
    DELAY_ENABLE => 1 )
    
    
  port map (
    clk   => clk,
    rst_n => rst_n,
    
    hibi_comm_in  => hibi_comm_in(1),
    hibi_data_in  => hibi_data_in(1),
    hibi_av_in    => hibi_av_in(1),
    hibi_full_in  => hibi_full_in(1),
    hibi_one_p_in  => hibi_one_p_in(1),
    hibi_empty_in  => hibi_empty_in(1),
    hibi_one_d_in  => hibi_one_d_in(1),

    hibi_comm_out  => hibi_comm_out(1),
    hibi_data_out  => hibi_data_out(1),
    hibi_av_out    => hibi_av_out(1),
    hibi_we_out    => hibi_we_out(1),
    hibi_re_out    => hibi_re_out(1),
    
    mem_rw_addr_in => x"40000",
    mem_rw_block_length_min_in => x"00001",
    mem_rw_block_length_max_in => x"00020",
    mem_rw_block_inc_in        => x"00001",
    mem_rw_blocks_in => x"00040",
    
    test_start_in => test_start,
    test_cfg_delay_in => rand,
    
    test_done_out => test_done(1),
    test_error_out => test_error(1) );
  
  hibi_mem_dma_tester_2 : entity work.hibi_mem_dma_tester
  generic map (
    TESTER_HIBI_BASE => x"05",
    M2H2_HIBI_BASE => x"29",
    MEM_ADDR_WIDTH => 20,
    
    TEST_DATA_UPPER_BITS => x"2",
    
    DELAY_ENABLE => 1 )
  
  port map (
    clk   => clk,
    rst_n => rst_n,
    
    hibi_comm_in  => hibi_comm_in(2),
    hibi_data_in  => hibi_data_in(2),
    hibi_av_in    => hibi_av_in(2),
    hibi_full_in  => hibi_full_in(2),
    hibi_one_p_in  => hibi_one_p_in(2),
    hibi_empty_in  => hibi_empty_in(2),
    hibi_one_d_in  => hibi_one_d_in(2),

    hibi_comm_out  => hibi_comm_out(2),
    hibi_data_out  => hibi_data_out(2),
    hibi_av_out    => hibi_av_out(2),
    hibi_we_out    => hibi_we_out(2),
    hibi_re_out    => hibi_re_out(2),
    
    mem_rw_addr_in => x"20000",
    mem_rw_block_length_min_in => x"00001",
    mem_rw_block_length_max_in => x"00000",
    mem_rw_block_inc_in        => x"00000",
    mem_rw_blocks_in => x"00200",
    
    test_start_in => test_start,
    test_cfg_delay_in => rand,
    
    test_done_out => test_done(2),
    test_error_out => test_error(2) );

  hibi_mem_dma_0 : entity work.hibi_mem_dma
  generic map (
    HIBI_DATA_WIDTH => 32,
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

    hibi_addr_in      => hibi_r3_addr_in,
    hibi_data_in      => hibi_r3_data_wra_m2h,
    hibi_comm_in      => hibi_r3_comm_in,
    hibi_empty_in     => hibi_r3_empty_wra_m2h,
--    hibi_one_d_in     => hibi_r3_one_d_wra_m2h,
    hibi_re_out       => hibi_r3_re_out,
    hibi_addr_out     => hibi_r3_addr_out,
    hibi_data_out     => hibi_r3_data_out,
    hibi_comm_out     => hibi_r3_comm_out,
    hibi_full_in      => hibi_r3_full_in,
--    hibi_one_p_in     => hibi_r3_one_p_in,
    hibi_we_out       => hibi_r3_we_out,
    
    hibi_msg_addr_in  => hibi_msg_r3_addr_in,
    hibi_msg_data_in  => hibi_msg_r3_data_in,
    hibi_msg_comm_in  => hibi_msg_r3_comm_in,
    hibi_msg_empty_in => hibi_msg_r3_empty_wra_m2h,
--    hibi_msg_one_d_in => hibi_msg_r3_one_d_wra_m2h,
    hibi_msg_re_out   => hibi_msg_r3_re_out,
    hibi_msg_data_out => hibi_msg_r3_data_out,
    hibi_msg_addr_out => hibi_msg_r3_addr_out,
    hibi_msg_comm_out => hibi_msg_r3_comm_out,
    hibi_msg_full_in  => hibi_msg_r3_full_in,
--    hibi_msg_one_p_in => hibi_msg_r3_one_p_in,
    hibi_msg_we_out   => hibi_msg_r3_we_out,
    
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
  mem_be(MEM_BE_WIDTH-1 downto 4) <= (others => '0');
  
  
  process (mem_wdata(15 downto 0), mem_addr(15 downto 0), mem_wr_req)
  begin
    if ((mem_wr_req = '1') and (mem_wdata(15 downto 0) /= mem_addr(15 downto 0))) then
      debug_wdata_error <= '1';

    else
      debug_wdata_error <= '0';
    end if;
  end process;
  
  gen_1 : if ENABLE_SIM = 1 generate
  
  mem_ctrl : a2_ddr2_dimm_1GB
  port map (
    pll_ref_clk  => ref_clk,
    phy_clk      => clk,
    
    global_reset_n => g_rst_n,
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
  
  gen_2 : if ENABLE_SIM = 0 generate
  mem_ctrl : a2_ddr2_dimm_1GB
  port map (
    pll_ref_clk  => ref_clk,
    phy_clk      => clk,
    
    global_reset_n => g_rst_n,
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
    
    mem_clk   => ddr2_dimm_clk,
    mem_clk_n => ddr2_dimm_clk_n,
    mem_odt   => ddr2_dimm_odt,
    mem_cs_n  => ddr2_dimm_cs_n,
    mem_cke   => ddr2_dimm_cke,
    mem_addr  => ddr2_dimm_addr(13 downto 0),
    mem_ba    => ddr2_dimm_ba,
    mem_ras_n => ddr2_dimm_ras_n,
    mem_cas_n => ddr2_dimm_cas_n,
    mem_we_n  => ddr2_dimm_we_n,
    mem_dm    => ddr2_dimm_dm,
    mem_dq    => ddr2_dimm_dq,
    mem_dqs   => ddr2_dimm_dqs,
    mem_dqsn  => ddr2_dimm_dqs_n );
  end generate;
  
  --synthesis translate_off
  a2_ddr2_dimm_1GB_0 : a2_ddr2_dimm_1GB_full_mem_model
  port map (
    mem_clk   => ddr2_clk(0),
    mem_clk_n => ddr2_clk_n(0),
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
    mem_dqs_n  => ddr2_dqs_n,
    
    global_reset_n => rst_n );  
  --synthesis translate_on
  
hibi_seg : entity work.hibi_seg
  generic map (
    number_of_r4_agents_g => M2H2_TESTERS,   -- 1-16
    number_of_r3_agents_g => 1    -- 0-1
  )
  port map (
    clk  => clk,
    rst_n  => rst_n,
    
    agent_av_in_1  => hibi_av_out(0),
    agent_av_out_1  => hibi_av_in(0),
    agent_comm_in_1  => hibi_comm_out(0),
    agent_comm_out_1  => hibi_comm_in(0),
    agent_data_in_1  => hibi_data_out(0),
    agent_data_out_1  => hibi_data_in(0),
    agent_empty_out_1  => hibi_empty_in(0),
    agent_full_out_1  => hibi_full_in(0),
    agent_one_p_out_1  => hibi_one_p_in(0),
    agent_one_d_out_1 => hibi_one_d_in(0),
    agent_re_in_1  => hibi_re_out(0),
    agent_we_in_1  => hibi_we_out(0),
    
    agent_av_in_2  => hibi_av_out(1),
    agent_av_out_2  => hibi_av_in(1),
    agent_comm_in_2  => hibi_comm_out(1),
    agent_comm_out_2  => hibi_comm_in(1),
    agent_data_in_2  => hibi_data_out(1),
    agent_data_out_2  => hibi_data_in(1),
    agent_empty_out_2  => hibi_empty_in(1),
    agent_full_out_2  => hibi_full_in(1),
    agent_one_p_out_2  => hibi_one_p_in(1),
    agent_one_d_out_2  => hibi_one_d_in(1),
    agent_re_in_2  => hibi_re_out(1),
    agent_we_in_2  => hibi_we_out(1),
    
    agent_av_in_3  => hibi_av_out(2),
    agent_av_out_3  => hibi_av_in(2),
    agent_comm_in_3  => hibi_comm_out(2),
    agent_comm_out_3  => hibi_comm_in(2),
    agent_data_in_3  => hibi_data_out(2),
    agent_data_out_3  => hibi_data_in(2),
    agent_empty_out_3  => hibi_empty_in(2),
    agent_full_out_3  => hibi_full_in(2),
    agent_one_p_out_3  => hibi_one_p_in(2),
    agent_one_d_out_3  => hibi_one_d_in(2),
    agent_re_in_3  => hibi_re_out(2),
    agent_we_in_3  => hibi_we_out(2),
    
    agent_data_in_4  => (others => '0'),
    agent_comm_in_4  => (others => '0'),
    agent_av_in_4  => '0',
    agent_we_in_4  => '0',
    agent_re_in_4  => '0',
    
    agent_data_in_5  => (others => '0'),
    agent_comm_in_5  => (others => '0'),
    agent_av_in_5  => '0',
    agent_we_in_5  => '0',
    agent_re_in_5  => '0',
    
    agent_data_in_6  => (others => '0'),
    agent_comm_in_6  => (others => '0'),
    agent_av_in_6  => '0',
    agent_we_in_6  => '0',
    agent_re_in_6  => '0',
    
    agent_data_in_7  => (others => '0'),
    agent_comm_in_7  => (others => '0'),
    agent_av_in_7  => '0',
    agent_we_in_7  => '0',
    agent_re_in_7  => '0',
    
    agent_data_in_8  => (others => '0'),
    agent_comm_in_8  => (others => '0'),
    agent_av_in_8  => '0',
    agent_we_in_8  => '0',
    agent_re_in_8  => '0',
    
    agent_data_in_9  => (others => '0'),
    agent_comm_in_9  => (others => '0'),
    agent_av_in_9  => '0',
    agent_we_in_9  => '0',
    agent_re_in_9  => '0',
    
    agent_data_in_10  => (others => '0'),
    agent_comm_in_10  => (others => '0'),
    agent_av_in_10  => '0',
    agent_we_in_10  => '0',
    agent_re_in_10  => '0',
    
    agent_data_in_11  => (others => '0'),
    agent_comm_in_11  => (others => '0'),
    agent_av_in_11  => '0',
    agent_we_in_11  => '0',
    agent_re_in_11  => '0',
    
    agent_data_in_12  => (others => '0'),
    agent_comm_in_12  => (others => '0'),
    agent_av_in_12  => '0',
    agent_we_in_12  => '0',
    agent_re_in_12  => '0',
    
    agent_data_in_13  => (others => '0'),
    agent_comm_in_13  => (others => '0'),
    agent_av_in_13  => '0',
    agent_we_in_13  => '0',
    agent_re_in_13  => '0',
    
    agent_data_in_14  => (others => '0'),
    agent_comm_in_14  => (others => '0'),
    agent_av_in_14  => '0',
    agent_we_in_14  => '0',
    agent_re_in_14  => '0',
    
    agent_data_in_15  => (others => '0'),
    agent_comm_in_15  => (others => '0'),
    agent_av_in_15  => '0',
    agent_we_in_15  => '0',
    agent_re_in_15  => '0',
    
    agent_data_in_16  => (others => '0'),
    agent_comm_in_16  => (others => '0'),
    agent_av_in_16  => '0',
    agent_we_in_16  => '0',
    agent_re_in_16  => '0',
    
    agent_comm_in_17  => hibi_r3_comm_out,
    agent_comm_out_17  => hibi_r3_comm_in,
    agent_addr_in_17  => hibi_r3_addr_out,
    agent_data_in_17  => hibi_r3_data_out,
    agent_addr_out_17  => hibi_r3_addr_in,
    agent_data_out_17  => hibi_r3_data_wra_m2h,
    agent_empty_out_17  => hibi_r3_empty_wra_m2h,
--    agent_one_d_out_17  => hibi_r3_one_d_wra_m2h,
    agent_full_out_17  => hibi_r3_full_in,
--    agent_one_p_out_17  => hibi_r3_one_p_in,
    agent_re_in_17  => hibi_r3_re_out,
    agent_we_in_17  => hibi_r3_we_out,
    
    agent_msg_comm_in_17  => hibi_msg_r3_comm_out,
    agent_msg_comm_out_17  => hibi_msg_r3_comm_in,
    agent_msg_addr_in_17  => hibi_msg_r3_addr_out,
    agent_msg_data_in_17  => hibi_msg_r3_data_out,
    agent_msg_addr_out_17  => hibi_msg_r3_addr_in,
    agent_msg_data_out_17  => hibi_msg_r3_data_in,
    agent_msg_empty_out_17  => hibi_msg_r3_empty_wra_m2h,
--    agent_msg_one_d_out_17  => hibi_msg_r3_one_d_wra_m2h,
    agent_msg_full_out_17  => hibi_msg_r3_full_in,
--    agent_msg_one_p_out_17  => hibi_msg_r3_one_p_in,
    agent_msg_re_in_17  => hibi_msg_r3_re_out,
    agent_msg_we_in_17  => hibi_msg_r3_we_out );


--    assert (hibi_r3_one_d_wra_m2h and hibi_r3_empty_wra_m2h)='0' report "One_d and empty malfunction" severity warning; 
--    assert (hibi_msg_r3_one_d_wra_m2h and hibi_msg_r3_empty_wra_m2h)='0' report "msg_one_d and msg_empty malfunction" severity warning; 


end structural;
