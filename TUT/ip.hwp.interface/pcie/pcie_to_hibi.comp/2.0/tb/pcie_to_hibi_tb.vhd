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
-- Title      : PCIe to HIBI testbench
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pcie_to_hibi_tb.vhd
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
use ieee.numeric_std.all;
use work.hibiv3_pkg.all;

-- synthesis translate_off
use std.textio.all;
use work.txt_util.all;
-- synthesis translate_on

entity pcie_to_hibi_tb is

  generic ( HIBI_DATA_WIDTH       : integer := 32;
            HIBI_ADDR_SPACE_WIDTH : integer := 11;
            
            PCIE_DATA_WIDTH       : integer := 128;
            PCIE_ADDR_WIDTH       : integer := 32;
            PCIE_LOWER_ADDR_WIDTH : integer := 7;
            PCIE_RW_LENGTH_WIDTH  : integer := 13;
            PCIE_ID_WIDTH         : integer := 16;
            PCIE_FUNC_WIDTH       : integer := 3;
            PCIE_TAG_WIDTH        : integer := 8;
            
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
            P2H_RD_CHANS : integer := 32 );
            

  port (
    
    Rx_St_Data_i   : in std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
    Rx_St_Valid_i  : in std_logic;
    Rx_St_Sop_i    : in std_logic;
    Rx_St_Eop_i    : in std_logic;
    Rx_St_Bardec_i : in std_logic_vector(7 downto 0);
--    Rx_St_Be_i     : in std_logic_vector(15 downto 0);
    Rx_St_Ready_o  : out std_logic;
    Rx_St_Mask_o   : out std_logic;
    
    Tx_St_Sop_o   : out std_logic;
    Tx_St_Eop_o   : out std_logic;
    Tx_St_Valid_o : out std_logic;
    Tx_St_Data_o  : out std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
    Tx_St_Ready_i : in std_logic;
    TxCred_i      : in std_logic_vector(35 downto 0);
    
    app_msi_req_out : out std_logic;
    app_msi_ack_in  : in  std_logic;
    app_msi_tc_out  : out std_logic_vector(2 downto 0);
    app_msi_num_out : out std_logic_vector(4 downto 0);
    pex_msi_num_out : out std_logic_vector(4 downto 0);
    app_int_sts_out : out std_logic;
    app_int_ack_in  : in  std_logic;

    
    lmi_data_in  : in std_logic_vector(31 downto 0);
    lmi_re_out   : out std_logic;
    lmi_we_out   : out std_logic;
    lmi_ack_in   : in  std_logic;
    lmi_addr_out : out std_logic_vector(11 downto 0);
    lmi_data_out : out std_logic_vector(31 downto 0);
    
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
    hsmb_clk_in0 : in std_logic;       --2.5V   
--    hsmb_clk_out0 : out std_logic;      --2.5V   
--    hsmb_clk_out_p1 : out std_logic;    --LVDS   
--    hsmb_clk_out_p2 : out std_logic;    --LVDS   
--    hsmb_sda : inout std_logic;           --2.5V     -- (TR=0)   
--    hsmb_scl : out std_logic;           --2.5V     -- (TR=0)   
--    hsmb_tx_led : out std_logic;        --2.5V                 
--    hsmb_rx_led : out std_logic;        --2.5V                 
--    hsmb_prsntn : in std_logic        --2.5V     -- (TR=0)  
     );

end pcie_to_hibi_tb;

architecture rtl of pcie_to_hibi_tb is

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
  
  constant ENABLE_SIM : integer := 0
  -- synthesis translate_off
  + 1
  -- synthesis translate_on
  ;
  
  constant CLK_PERIOD : time := 1*10 ns;
  
  constant HIBI_COM_WIDTH : integer := comm_width_c;
  constant HIBI_COM_WR     : std_logic_vector(15 downto 0) := DATA_WRNP_c;
  constant HIBI_COM_RD     : std_logic_vector(15 downto 0) := DATA_RD_c;
  constant HIBI_COM_MSG_WR : std_logic_vector(15 downto 0) := MSG_WRNP_c;
  constant HIBI_COM_MSG_RD : std_logic_vector(15 downto 0) := MSG_RD_c;
  
  constant HIBI_R3_WRAPPERS : integer := 2;
  
  constant BURST_SIZE_WIDTH : integer := 3;
  
  constant DDR2_ADDR_WIDTH : integer := 14;
  constant DDR2_DATA_WIDTH : integer := 64;
  constant DDR2_DQS_WIDTH  : integer := DDR2_DATA_WIDTH/8;
  constant DDR2_BA_WIDTH   : integer := 3;
  constant DDR2_CLK_WIDTH  : integer := 2;
  
  constant MEM_ADDR_WIDTH : integer := 25;
  constant MEM_DATA_WIDTH : integer := 256;
  constant MEM_BE_WIDTH   : integer := MEM_DATA_WIDTH/8;
  
  
  signal ref_clk : std_logic := '1';
  signal g_rst_n : std_logic := '0';
  
  signal clk  : std_logic;
  signal rst_n   : std_logic;
  
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
  signal hibi_full  : std_logic(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_empty : std_logic(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_raddr : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_rdata : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_rcom  : std_logic_vector(HIBI_COM_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_re    : std_logic(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_we    : std_logic(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_waddr : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_wdata : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_wcom  : std_logic_vector(HIBI_COM_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_full  : std_logic(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_empty : std_logic(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_raddr : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_rdata : std_logic_vector(HIBI_DATA_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_rcom  : std_logic_vector(HIBI_COM_WIDTH*HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_re    : std_logic(HIBI_R3_WRAPPERS-1 downto 0);
  signal hibi_msg_we    : std_logic(HIBI_R3_WRAPPERS-1 downto 0);
  
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
  
  gen_0 : if ENABLE_SIM = 0 generate
  ref_clk <= clkin_bot_p;
  rst_n <= user_pb(0);
  g_rst_n <= rst_n;
  end generate;
  
  --synthesis translate_off
  ref_clk <= not ref_clk after CLK_PERIOD/2;
  g_rst_n <= '0', '1' after 4.6 * CLK_PERIOD;
  --synthesis translate_on
  
  
  pcie_to_hibi_0 : entity work.pcie_to_hibi
  generic map ( HIBI_DATA_WIDTH => HIBI_DATA_WIDTH,
                HIBI_COM_WIDTH  => HIBI_COM_WIDTH,
                HIBI_COM_WR     => HIBI_COM_WR,
                HIBI_COM_RD     => HIBI_COM_RD,
                HIBI_COM_MSG_WR => HIBI_COM_MSG_WR,
                HIBI_COM_MSG_RD => HIBI_COM_MSG_RD,
                
                HIBI_ADDR_SPACE_WIDTH => HIBI_ADDR_SPACE_WIDTH,
                
                PCIE_DATA_WIDTH       => PCIE_DATA_WIDTH,
                PCIE_ADDR_WIDTH       => PCIE_ADDR_WIDTH,
                PCIE_LOWER_ADDR_WIDTH => PCIE_LOWER_ADDR_WIDTH,
                PCIE_RW_LENGTH_WIDTH  => PCIE_RW_LENGTH_WIDTH,
                PCIE_ID_WIDTH         => PCIE_ID_WIDTH,
                PCIE_FUNC_WIDTH       => PCIE_FUNC_WIDTH,
                PCIE_TAG_WIDTH        => PCIE_TAG_WIDTH,
                
                PCIE_CPL_LENGTH_MIN => PCIE_CPL_LENGTH_MIN,
                
                HIBI_DMA_CHANS_ADDR_SPACE_WIDTH => HIBI_DMA_CHANS_ADDR_SPACE_WIDTH,
                
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
                P2H_RD_CHANS => P2H_RD_CHANS );
  
  port map (
    clk   => clk,
    rst_n => rst_n,
    
    clk_pcie => clk_pcie,
    
    Rx_St_Data_i   => Rx_St_Data_i,
    Rx_St_Valid_i  => Rx_St_Valid_i,
    Rx_St_Sop_i    => Rx_St_Sop_i,
    Rx_St_Eop_i    => Rx_St_Eop_i,
    Rx_St_Bardec_i => Rx_St_Bardec_i,
    Rx_St_Ready_o  => Rx_St_Ready_o,
    Rx_St_Mask_o   => Rx_St_Mask_o,
    
    Tx_St_Sop_o   => Tx_St_Sop_o,
    Tx_St_Eop_o   => Tx_St_Eop_o,
    Tx_St_Valid_o => Tx_St_Valid_o,
    Tx_St_Data_o  => Tx_St_Data_o,
    Tx_St_Ready_i => Tx_St_Ready_i,
    TxCred_i      => TxCred_i,
    
    app_msi_req_out => app_msi_req_out,
    app_msi_ack_in  => app_msi_ack_in,
    app_msi_tc_out  => app_msi_tc_out,
    app_msi_num_out => app_msi_num_out,
    pex_msi_num_out => pex_msi_num_out,
    app_int_sts_out => app_int_sts_out,
    app_int_ack_in  => app_int_ack_in,

    
    lmi_data_in  => lmi_data_in,
    lmi_re_out   => lmi_re_out,
    lmi_we_out   => lmi_we_out,
    lmi_ack_in   => lmi_ack_in,
    lmi_addr_out => lmi_addr_out,
    lmi_data_out => lmi_data_out,

    hibi_addr_in => hibi_addr_in,
    hibi_data_in => hibi_data_in,
    hibi_comm_in => hibi_comm_in,
    hibi_empty_in => hibi_empty_in,
    hibi_re_out => hibi_re_out,

    hibi_addr_out => hibi_addr_out,
    hibi_data_out => hibi_data_out,
    hibi_comm_out => hibi_comm_out,
    hibi_full_in => hibi_full_in,
    hibi_we_out => hibi_we_out,

    hibi_msg_addr_in => hibi_msg_addr_in,
    hibi_msg_data_in => hibi_msg_data_in,
    hibi_msg_comm_in => hibi_msg_comm_in,
    hibi_msg_empty_in => hibi_msg_empty_in,
    hibi_msg_re_out => hibi_msg_re_out,

    hibi_msg_data_out => hibi_msg_data_out,
    hibi_msg_addr_out => hibi_msg_addr_out,
    hibi_msg_comm_out => hibi_msg_comm_out,
    hibi_msg_full_in => hibi_msg_full_in,
    hibi_msg_we_out => hibi_msg_we_out );
  
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
  
  hibi_seg_0 : entity work.hibiv3_r3
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
    separate_addr_g => 0 );

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
  
end rtl;
