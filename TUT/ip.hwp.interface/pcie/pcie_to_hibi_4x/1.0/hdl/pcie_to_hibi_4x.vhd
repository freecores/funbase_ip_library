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
-- **************************************************************************
-- File             : pcie_to_hibi_4x.vhd
-- Authors          : Juha Arvio
-- Date             : 30.03.2010
-- Decription       : PCI-E to HIBI
-- Version          : 0.1
-- Version history  : 30.03.2010   jua     Original version
-- **************************************************************************


library ieee;
use ieee.std_logic_1164.all;

entity pcie_to_hibi_4x is
generic(
	HIBI_DATA_WIDTH : integer := 32 );
port(
	rst_n         : in std_logic;
	clk           : in std_logic;

	hibi_comm_in  : in std_logic_vector(2 downto 0);
	hibi_data_in  : in std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
	hibi_av_in    : in std_logic;
	hibi_full_in  : in std_logic;
	hibi_one_p_in : in std_logic;
	hibi_empty_in : in std_logic;
	hibi_one_d_in : in std_logic;

	hibi_comm_out : out std_logic_vector(2 downto 0);
	hibi_data_out : out std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
	hibi_av_out   : out std_logic;
	hibi_we_out   : out std_logic;
	hibi_re_out   : out std_logic;
  
  pcie_rst_n    : in std_logic;
  pcie_ref_clk  : in std_logic;
  pcie_rx       : in std_logic_vector(3 downto 0);
  pcie_tx       : out std_logic_vector(3 downto 0) );
end entity pcie_to_hibi_4x;

architecture struct of pcie_to_hibi_4x is

component pcie_to_hibi_4x_sopc
        port (
              -- 1) global signals:
                 signal clk : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;

              -- the_a2h
                 signal hibi_av_in_to_the_a2h : IN STD_LOGIC;
                 signal hibi_av_out_from_the_a2h : OUT STD_LOGIC;
                 signal hibi_comm_in_to_the_a2h : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
                 signal hibi_comm_out_from_the_a2h : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
                 signal hibi_data_in_to_the_a2h : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal hibi_data_out_from_the_a2h : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal hibi_empty_in_to_the_a2h : IN STD_LOGIC;
                 signal hibi_full_in_to_the_a2h : IN STD_LOGIC;
                 signal hibi_one_d_in_to_the_a2h : IN STD_LOGIC;
                 signal hibi_one_p_in_to_the_a2h : IN STD_LOGIC;
                 signal hibi_re_out_from_the_a2h : OUT STD_LOGIC;
                 signal hibi_we_out_from_the_a2h : OUT STD_LOGIC;

              -- the_pcie
                 --signal clk125_out_pcie : OUT STD_LOGIC;
                 --signal clk250_out_pcie : OUT STD_LOGIC;
                 --signal clk500_out_pcie : OUT STD_LOGIC;
                 --signal gxb_powerdown_pcie : IN STD_LOGIC;
                 signal pcie_rstn_pcie : IN STD_LOGIC;
                -- signal phystatus_ext_pcie : IN STD_LOGIC;
                 signal pipe_mode_pcie : IN STD_LOGIC;
                 --signal pll_powerdown_pcie : IN STD_LOGIC;
                 --signal powerdown_ext_pcie : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
                 --signal rate_ext_pcie : OUT STD_LOGIC;
                 signal reconfig_clk_pcie : IN STD_LOGIC;
                 --signal reconfig_fromgxb_pcie : OUT STD_LOGIC_VECTOR (16 DOWNTO 0);
                 --signal reconfig_togxb_pcie : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal refclk_pcie : IN STD_LOGIC;
                 signal rx_in0_pcie : IN STD_LOGIC;
                 signal rx_in1_pcie : IN STD_LOGIC;
                 signal rx_in2_pcie : IN STD_LOGIC;
                 signal rx_in3_pcie : IN STD_LOGIC;
                 --signal rxdata0_ext_pcie : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
                 --signal rxdata1_ext_pcie : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
                 --signal rxdata2_ext_pcie : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
                 --signal rxdata3_ext_pcie : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
                 --signal rxdatak0_ext_pcie : IN STD_LOGIC;
                 --signal rxdatak1_ext_pcie : IN STD_LOGIC;
                 --signal rxdatak2_ext_pcie : IN STD_LOGIC;
                 --signal rxdatak3_ext_pcie : IN STD_LOGIC;
                 --signal rxelecidle0_ext_pcie : IN STD_LOGIC;
                 --signal rxelecidle1_ext_pcie : IN STD_LOGIC;
                 --signal rxelecidle2_ext_pcie : IN STD_LOGIC;
                 --signal rxelecidle3_ext_pcie : IN STD_LOGIC;
                 --signal rxpolarity0_ext_pcie : OUT STD_LOGIC;
                 --signal rxpolarity1_ext_pcie : OUT STD_LOGIC;
                 --signal rxpolarity2_ext_pcie : OUT STD_LOGIC;
                 --signal rxpolarity3_ext_pcie : OUT STD_LOGIC;
                 --signal rxstatus0_ext_pcie : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
                 --signal rxstatus1_ext_pcie : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
                 --signal rxstatus2_ext_pcie : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
                 --signal rxstatus3_ext_pcie : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
                 --signal rxvalid0_ext_pcie : IN STD_LOGIC;
                 --signal rxvalid1_ext_pcie : IN STD_LOGIC;
                 --signal rxvalid2_ext_pcie : IN STD_LOGIC;
                 --signal rxvalid3_ext_pcie : IN STD_LOGIC;
                 --signal test_in_pcie : IN STD_LOGIC_VECTOR (39 DOWNTO 0);
                 --signal test_out_pcie : OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
                 signal tx_out0_pcie : OUT STD_LOGIC;
                 signal tx_out1_pcie : OUT STD_LOGIC;
                 signal tx_out2_pcie : OUT STD_LOGIC;
                 signal tx_out3_pcie : OUT STD_LOGIC
                 --signal txcompl0_ext_pcie : OUT STD_LOGIC;
                 --signal txcompl1_ext_pcie : OUT STD_LOGIC;
                 --signal txcompl2_ext_pcie : OUT STD_LOGIC;
                 --signal txcompl3_ext_pcie : OUT STD_LOGIC;
                 --signal txdata0_ext_pcie : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
                 --signal txdata1_ext_pcie : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
                 --signal txdata2_ext_pcie : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
                 --signal txdata3_ext_pcie : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
                 --signal txdatak0_ext_pcie : OUT STD_LOGIC;
                 --signal txdatak1_ext_pcie : OUT STD_LOGIC;
                 --signal txdatak2_ext_pcie : OUT STD_LOGIC;
                 --signal txdatak3_ext_pcie : OUT STD_LOGIC;
                 --signal txdetectrx_ext_pcie : OUT STD_LOGIC;
                 --signal txelecidle0_ext_pcie : OUT STD_LOGIC;
                 --signal txelecidle1_ext_pcie : OUT STD_LOGIC;
                 --signal txelecidle2_ext_pcie : OUT STD_LOGIC;
                 --signal txelecidle3_ext_pcie : OUT STD_LOGIC
              );
end component;

begin


pcie_to_hibi_4x_sopc_inst : pcie_to_hibi_4x_sopc
port map(
  clk => clk,
  reset_n => rst_n,
  
  hibi_av_out_from_the_a2h => hibi_av_out,
  hibi_comm_out_from_the_a2h => hibi_comm_out,
  hibi_data_out_from_the_a2h => hibi_data_out,
  hibi_re_out_from_the_a2h => hibi_re_out,
  hibi_we_out_from_the_a2h => hibi_we_out,
  
  hibi_av_in_to_the_a2h => hibi_av_in,
  hibi_comm_in_to_the_a2h => hibi_comm_in,
  hibi_data_in_to_the_a2h => hibi_data_in,
  hibi_empty_in_to_the_a2h => hibi_empty_in,
  hibi_full_in_to_the_a2h => hibi_full_in,
  hibi_one_d_in_to_the_a2h => hibi_one_d_in,
  hibi_one_p_in_to_the_a2h => hibi_one_p_in,
  
  rx_in0_pcie => pcie_rx(0),
  rx_in1_pcie => pcie_rx(1),
  rx_in2_pcie => pcie_rx(2),
  rx_in3_pcie => pcie_rx(3),
  
  tx_out0_pcie => pcie_tx(0),
  tx_out1_pcie => pcie_tx(1),
  tx_out2_pcie => pcie_tx(2),
  tx_out3_pcie => pcie_tx(3),
  
  pcie_rstn_pcie => pcie_rst_n,
  refclk_pcie => pcie_ref_clk,
  
  pipe_mode_pcie => '0',
  reconfig_clk_pcie => '0'
  --reconfig_togxb_pcie => "010",
  
--  clk125_out_pcie => clk125_out_pcie,
--  clk250_out_pcie => clk250_out_pcie,
--  clk500_out_pcie => clk500_out_pcie,
--   powerdown_ext_pcie => powerdown_ext_pcie,
--   rate_ext_pcie => rate_ext_pcie,
--   reconfig_fromgxb_pcie => reconfig_fromgxb_pcie,
--   rxpolarity0_ext_pcie => rxpolarity0_ext_pcie,
--   rxpolarity1_ext_pcie => rxpolarity1_ext_pcie,
--   rxpolarity2_ext_pcie => rxpolarity2_ext_pcie,
--   rxpolarity3_ext_pcie => rxpolarity3_ext_pcie,
--   test_out_pcie => test_out_pcie,
--   txcompl0_ext_pcie => txcompl0_ext_pcie,
--   txcompl1_ext_pcie => txcompl1_ext_pcie,
--   txcompl2_ext_pcie => txcompl2_ext_pcie,
--   txcompl3_ext_pcie => txcompl3_ext_pcie,
--   txdata0_ext_pcie => txdata0_ext_pcie,
--   txdata1_ext_pcie => txdata1_ext_pcie,
--   txdata2_ext_pcie => txdata2_ext_pcie,
--   txdata3_ext_pcie => txdata3_ext_pcie,
--   txdatak0_ext_pcie => txdatak0_ext_pcie,
--   txdatak1_ext_pcie => txdatak1_ext_pcie,
--   txdatak2_ext_pcie => txdatak2_ext_pcie,
--   txdatak3_ext_pcie => txdatak3_ext_pcie,
--   txdetectrx_ext_pcie => txdetectrx_ext_pcie,
--   txelecidle0_ext_pcie => txelecidle0_ext_pcie,
--   txelecidle1_ext_pcie => txelecidle1_ext_pcie,
--   txelecidle2_ext_pcie => txelecidle2_ext_pcie,
--   txelecidle3_ext_pcie => txelecidle3_ext_pcie,
--   gxb_powerdown_pcie => gxb_powerdown_pcie,
--   phystatus_ext_pcie => phystatus_ext_pcie,
--   pll_powerdown_pcie => pll_powerdown_pcie,
--   rxdata0_ext_pcie => rxdata0_ext_pcie,
--   rxdata1_ext_pcie => rxdata1_ext_pcie,
--   rxdata2_ext_pcie => rxdata2_ext_pcie,
--   rxdata3_ext_pcie => rxdata3_ext_pcie,
--   rxdatak0_ext_pcie => rxdatak0_ext_pcie,
--   rxdatak1_ext_pcie => rxdatak1_ext_pcie,
--   rxdatak2_ext_pcie => rxdatak2_ext_pcie,
--   rxdatak3_ext_pcie => rxdatak3_ext_pcie,
--   rxelecidle0_ext_pcie => rxelecidle0_ext_pcie,
--   rxelecidle1_ext_pcie => rxelecidle1_ext_pcie,
--   rxelecidle2_ext_pcie => rxelecidle2_ext_pcie,
--   rxelecidle3_ext_pcie => rxelecidle3_ext_pcie,
--   rxstatus0_ext_pcie => rxstatus0_ext_pcie,
--   rxstatus1_ext_pcie => rxstatus1_ext_pcie,
--   rxstatus2_ext_pcie => rxstatus2_ext_pcie,
--   rxstatus3_ext_pcie => rxstatus3_ext_pcie,
--   rxvalid0_ext_pcie => rxvalid0_ext_pcie,
--   rxvalid1_ext_pcie => rxvalid1_ext_pcie,
--   rxvalid2_ext_pcie => rxvalid2_ext_pcie,
--   rxvalid3_ext_pcie => rxvalid3_ext_pcie,
--   test_in_pcie => test_in_pcie
);

end architecture struct;
