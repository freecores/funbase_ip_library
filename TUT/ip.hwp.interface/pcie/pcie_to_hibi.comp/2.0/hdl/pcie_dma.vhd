-------------------------------------------------------------------------------
-- Title      : PCIe DMA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pcie_dma.vhd
-- Author     : 
-- Company    : 
-- Last update: 07.02.2011
-- Version    : 0.1
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
--
-------------------------------------------------------------------------------
-- Copyright (c) 2011
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 07.02.2010   0.1     arvio     Created
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

entity pcie_dma is

  generic ( HIBI_DATA_WIDTH : integer := 32;
            HIBI_RW_LENGTH_WIDTH  : integer := 16;
            PCIE_RW_LENGTH_WIDTH  : integer := 13;
            PCIE_ID_WIDTH   : integer := 16;
--            PKT_TAG_WIDTH  : integer := 9;
            PCIE_TAG_WIDTH : integer := 6;
            
            PCIE_DATA_WIDTH : integer := 128;
            PCIE_ADDR_WIDTH : integer := 32;
            PCIE_LOWER_ADDR_WIDTH : integer := 7;
            DMA_BAR : integer := 2;
            BURST_LATENCY : integer := 2;
            
            ADDR_TO_LIMIT_WIDTH : integer := 12;
            IRQ_WIDTH : integer := 5;
            INFO_WIDTH : integer := 3 ); -- traffic class number width on pcie
  
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    
    ipkt_is_write_in    : in std_logic;
    ipkt_is_read_req_in : in std_logic;
    ipkt_is_rdata_in    : in std_logic;
    ipkt_valid_in       : in std_logic;
    ipkt_addr_in        : in std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    ipkt_data_in        : in std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
--    ipkt_addr_size_in   : in std_logic;
    ipkt_length_in      : in std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
    ipkt_req_id_in      : in std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
    ipkt_tag_in         : in std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
    ipkt_bar_in      : in std_logic_vector(2 downto 0);
    
    ipkt_re_out         : out std_logic;
    
    ipkt_is_write_out    : out std_logic;
    ipkt_is_read_req_out : out std_logic;
    ipkt_is_rdata_out    : out std_logic;
    ipkt_valid_out       : out std_logic;
    ipkt_addr_out        : out std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    ipkt_addr_to_limit_out : out std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
    ipkt_data_out        : out std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
--    ipkt_addr_size_out   : out std_logic;
    ipkt_length_out      : out std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
    ipkt_req_id_out      : out std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
    ipkt_tag_out         : out std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
--    ipkt_bardec_out      : out std_logic_vector(7 downto 0);
    
    ipkt_re_in           : in std_logic;
    
    opkt_is_write_in    : in std_logic;
    opkt_is_read_req_in : in std_logic;
    opkt_is_rdata_in    : in std_logic;
--    opkt_wdata_req_out  : out std_logic;
    opkt_ready_out      : out std_logic;
    opkt_addr_in        : in std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
    opkt_data_in        : in std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
--    opkt_addr_size_in   : in std_logic;
    opkt_length_in      : in std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
    opkt_req_id_in      : in std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
    opkt_tag_in         : in std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
    
    opkt_we_in          : in std_logic;
    opkt_burst_we_in    : in std_logic;
    
    opkt_is_write_out    : out std_logic;
    opkt_is_read_req_out : out std_logic;
    opkt_is_rdata_out    : out std_logic;
--    opkt_wdata_req_in    : in std_logic;
    opkt_ready_in        : in std_logic;
    opkt_addr_out        : out std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
    opkt_data_out        : out std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
--    opkt_addr_size_out   : out std_logic;
    opkt_length_out      : out std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
    opkt_req_id_out      : out std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
    opkt_tag_out         : out std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
    
    opkt_we_out          : out std_logic;
    opkt_burst_we_out    : out std_logic;
    
    irq_in : in std_logic;
    dma_irq_out : out std_logic;
    dma_irq_number_out : out std_logic_vector(IRQ_WIDTH-1 downto 0);
    dma_irq_info_out : out std_logic_vector(INFO_WIDTH-1 downto 0);
    irq_full_in : in std_logic;
    dma_irq_full_out : out std_logic;
    
    debug_out           : out std_logic );

end pcie_dma;

architecture rtl of pcie_dma is

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
  
  function log2(X : natural; Y : natural) return integer is
  begin
    if (X >= Y) then
      return log2_ceil((X/Y)-1);
    else
      return 0 - log2_ceil((Y/X)-1);
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
  
  constant ENABLE_SIM : integer := 0
  -- synthesis translate_off
  + 1
  -- synthesis translate_on
  ;
  
  constant HIBI_DATA_BYTE_WIDTH : integer := HIBI_DATA_WIDTH/8;
  constant HIBI_DATA_WORD_ADDR_WIDTH : integer := log2_ceil(HIBI_DATA_BYTE_WIDTH-1);
  constant PCIE_RX_READY_LATENCY : integer := 3;
  constant BURST_LATENCY_WIDTH : integer := log2_ceil(BURST_LATENCY-1);
  
  constant DMA_VERSION : std_logic_vector(3 downto 0) := x"0";
  constant DMA_CORE_TYPE : std_logic_vector(1 downto 0) := "00";
  constant WDMA_MAX_PAYLOAD_SIZE : std_logic_vector(2 downto 0) := "001"; -- 256 bytes
  
  constant BOARD_ID : std_logic_vector(6 downto 0) := "0000010"; -- Altera Stratix II GX x8
  constant PCIE_LINK_WIDTH : std_logic_vector(3 downto 0) := x"8";
  constant RDMA_MAX_READ_SIZE : std_logic_vector(2 downto 0) := "001"; -- 256 bytes
  
  constant DMA_DESC_OFFSET_WIDTH : integer := 4;
  constant DMA_DESC_EPLAST_OFFSET : std_logic_vector(DMA_DESC_OFFSET_WIDTH downto 0) := "01100";
  constant DMA_DESC_0_OFFSET : std_logic_vector(DMA_DESC_OFFSET_WIDTH downto 0) := "10000";
  constant DMA_DESC_LENGTH : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0) := "0000100000000";
  constant DMA_DESC_WORD_CNT_WIDTH : integer := DMA_DESC_OFFSET_WIDTH-2;
  constant DMA_DESC_RW_LENGTH_WORD : std_logic_vector(1 downto 0) := "00";
  constant DMA_DESC_EP_ADDR_WORD : std_logic_vector(1 downto 0) := "01";
  constant DMA_DESC_RC_UPPER_ADDR_WORD : std_logic_vector(1 downto 0) := "10";
  constant DMA_DESC_RC_LOWER_ADDR_WORD : std_logic_vector(1 downto 0) := "11";
  
  constant ONCHIP_MEM_SIZE : integer := 8192;
  constant DMA_DESC_FIFO_LENGTH : integer := ONCHIP_MEM_SIZE/HIBI_DATA_WIDTH;
  constant DMA_DESC_FIFO_LENGTH_WIDTH : integer := log2_ceil(ONCHIP_MEM_SIZE/HIBI_DATA_WIDTH);
  constant DMA_DESC_FIFO_MAX_DESCS : integer := DMA_DESC_FIFO_LENGTH/4;
  constant DMA_DESC_FIFO_MAX_DESCS_WIDTH : integer := log2_ceil(DMA_DESC_FIFO_MAX_DESCS);
  
--  constant DMA_TAG : std_logic_vector(PKT_TAG_WIDTH-PCIE_LOWER_TAG_WIDTH downto 0) := i2s(1, PKT_TAG_WIDTH-PCIE_LOWER_TAG_WIDTH+1);
  constant DMA_DESC_TAG : std_logic_vector(1 downto 0) := (others => '0');
  constant DMA_RDATA_TAG : std_logic_vector(1 downto 0) := DMA_DESC_TAG + 1;
  constant DMA_P2H_RDATA_TAG : std_logic_vector(1 downto 0) := DMA_RDATA_TAG + 1;
  constant H2P_RDATA_TAG : std_logic_vector(1 downto 0) := DMA_P2H_RDATA_TAG + 1;
  
  type dma_state_t is (DMA_WAIT, DMA_DESC_WAIT, DMA_DELAY, DMA_WAIT_EPLAST, DMA_SEND_EPLAST, DMA_SEND_IRQ, DMA_WRITE, DMA_WDATA_WAIT, DMA_READ, DMA_RDATA_WAIT);
  signal dma_state_r : dma_state_t;
  
  type dma_cfg_rd_state_t is (DMA_CFG_READ_WAIT, DMA_CFG_READ);
  signal dma_cfg_rd_state_r : dma_cfg_rd_state_t;
  
  type dma_desc_rd_state_t is (DMA_RW_START_WAIT, DMA_READ_DESC_WAIT, DMA_READ_DESC_SEND);
  signal dma_desc_rd_state_r : dma_desc_rd_state_t;
  
  signal rdma_desc_addr_r   : std_logic_vector(PCIE_ADDR_WIDTH-DMA_DESC_OFFSET_WIDTH-2 downto 0);
  signal rdma_desc_amount_r : std_logic_vector(15 downto 0);
  signal rdma_desc_last_r   : std_logic_vector(15 downto 0);
  
  signal rdma_msi_ena_r    : std_logic;
  signal rdma_eplast_ena_r : std_logic;
  signal rdma_eplast_r : std_logic_vector(15 downto 0);
  signal rdma_msi_number_r : std_logic_vector(4 downto 0);
  signal rdma_msi_tc_r     : std_logic_vector(2 downto 0);
  signal rdma_last_sync_r  : std_logic;
  signal rdma_start_r  : std_logic;
  
--  signal rdma_version_r   : std_logic_vector(3 downto 0);
  
  signal wdma_desc_addr_r   : std_logic_vector(PCIE_ADDR_WIDTH-DMA_DESC_OFFSET_WIDTH-2 downto 0);
  signal wdma_desc_amount_r : std_logic_vector(15 downto 0);
  signal wdma_desc_last_r   : std_logic_vector(15 downto 0);
  
  signal wdma_msi_ena_r    : std_logic;
  signal wdma_eplast_ena_r : std_logic;
  signal wdma_eplast_r : std_logic_vector(15 downto 0);
  signal wdma_msi_number_r : std_logic_vector(4 downto 0);
  signal wdma_msi_tc_r     : std_logic_vector(2 downto 0);
  signal wdma_last_sync_r  : std_logic;
  signal wdma_start_r  : std_logic;
  
  signal wdma_started_r  : std_logic;
  signal rdma_started_r  : std_logic;
  
  signal dma_desc_re_r : std_logic;
  signal dma_desc_rd_ready : std_logic;
  signal dma_desc_we_r : std_logic;
  signal dma_desc_wr_ready : std_logic;
  signal dma_desc_addr_r : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal dma_desc_length_r : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal dma_desc_fetch_amount_r : std_logic_vector(15 downto 0);
  signal dma_h2p_re_r : std_logic;
  signal dma_h2p_rd_ready : std_logic;
  signal dma_p2h_re_r : std_logic;
  signal dma_p2h_rd_ready : std_logic;
  signal dma_cfg_rd_ready : std_logic;
  signal dma_cfg_raddr_r : std_logic_vector(4 downto 0);
  signal dma_cfg_rdata : std_logic_vector(31 downto 0);
  signal dma_cfg_req_id_r : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal dma_cfg_tag_r : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
  signal dma_ep_addr_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal dma_rc_addr_r : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal dma_rw_length_r : std_logic_vector(15 downto 0);
  signal dma_msi_ena_r : std_logic;
  signal dma_eplast_ena_r : std_logic;
  signal dma_delay_r : std_logic_vector(BURST_LATENCY_WIDTH-1 downto 0);
  
  signal addr_to_limit_r : std_logic_vector(ADDR_TO_LIMIT_WIDTH downto 0);
  
  signal dma_desc_cnt_r : std_logic_vector(15 downto 0);
  signal dma_word_cnt_r : std_logic_vector(DMA_DESC_WORD_CNT_WIDTH-1 downto 0);
  
  signal ipkt_re_r : std_logic;
  signal ipkt_is_dma_cfg_wr : std_logic;
  signal ipkt_is_dma_cfg_rd : std_logic;
  signal ipkt_is_dma_cfg_rdata : std_logic;
  signal ipkt_is_dma_rdata : std_logic;
  signal is_dma_bar : std_logic;
  signal is_dma_desc_tag : std_logic;
  signal is_dma_rdata_tag : std_logic;
  signal is_h2p_rdata_tag : std_logic;
  
  signal opkt_is_dma_rdata : std_logic;
  
  signal dma_desc_fifo_we_r : std_logic;
  signal dma_desc_fifo_re_r : std_logic;
  signal dma_desc_fifo_wdata_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal dma_desc_fifo_rdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal dma_desc_fifo_full : std_logic;
  signal dma_desc_fifo_empty : std_logic;
--  signal dma_desc_fifo_amount : std_logic_vector(log2_ceil(DMA_DESC_FIFO_LENGTH)-1 downto 0);
  
  signal dma_desc_req_free_amount_r : std_logic_vector(DMA_DESC_FIFO_MAX_DESCS_WIDTH-1 downto 0);
  
  signal ipkt_valid : std_logic;
  signal ipkt_valid_no_dma : std_logic;
  signal ipkt_re_stall : std_logic;
  
  signal opkt_dma_cfg_rdata_r : std_logic;
  
  signal dma_irq_r : std_logic;
  
  signal burst_active_r : std_logic;
  signal burst_active : std_logic;
  signal burst_deactivate_r : std_logic_vector(BURST_LATENCY-1 downto 0);
  
--  signal opkt_burst_we_r : std_logic_vector(BURST_LATENCY-1 downto 0);
  signal opkt_is_write_r : std_logic;
  signal opkt_is_dma_rdata_r : std_logic;
--  signal opkt_burst_we : std_logic;
  signal opkt_is_write : std_logic;
  signal opkt_is_dma_rdata_0 : std_logic;
  
  signal debug_start_r : std_logic;
  signal debug_started_r : std_logic;
begin
  
  debug_out <= debug_start_r;
  
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      debug_start_r <= '0';
      debug_started_r <= '0';
      
    elsif (clk'event and clk = '1') then
      debug_start_r <= '0';
      
      if (ipkt_valid_in = '1') then
        debug_started_r <= '1';
        
        if (debug_started_r = '0') then
          debug_start_r <= '1';
        end if;
      end if;
    end if;
  end process;
  
  dma_cfg_rd_ready  <= opkt_ready_in and not(burst_active);
  dma_desc_rd_ready <= dma_cfg_rd_ready  and not(opkt_dma_cfg_rdata_r);
  dma_desc_wr_ready <= dma_desc_rd_ready and not(dma_desc_re_r);
  dma_h2p_rd_ready  <= dma_desc_wr_ready and not(dma_desc_we_r);
  
  opkt_ready_out    <= opkt_ready_in and not(opkt_dma_cfg_rdata_r) and not(dma_desc_re_r) and not(dma_desc_we_r) and not(dma_p2h_re_r);
  
  ipkt_is_dma_cfg_wr <= ipkt_is_write_in and is_dma_bar;
  ipkt_is_dma_cfg_rd <= ipkt_is_read_req_in and is_dma_bar;
  ipkt_is_dma_cfg_rdata <= ipkt_is_rdata_in and is_dma_desc_tag;
  ipkt_is_dma_rdata <= ipkt_is_rdata_in and is_dma_rdata_tag;
  ipkt_valid_no_dma <= ipkt_valid_in and not(ipkt_is_dma_cfg_wr) and not(ipkt_is_dma_cfg_rd) and not(ipkt_is_dma_cfg_rdata) and not(ipkt_is_dma_rdata);
  
  ipkt_re_stall <= ipkt_is_dma_cfg_rd and ipkt_valid_in and opkt_dma_cfg_rdata_r;
  
  dma_p2h_rd_ready <= ipkt_re_in;
--  opkt_wdata_req_out <= opkt_wdata_req_in;
  
--  ipkt_re_out <= ipkt_re_in and not(ipkt_re_stall);
  ipkt_valid_out <= ipkt_valid or dma_p2h_re_r;
  
  opkt_we_out <= not(burst_active) and (opkt_we_in or opkt_dma_cfg_rdata_r or dma_desc_re_r or dma_desc_we_r or dma_h2p_re_r);
  opkt_burst_we_out <= opkt_burst_we_in;
  
  ipkt_addr_to_limit_out <= addr_to_limit_r(ADDR_TO_LIMIT_WIDTH-1 downto 0);
  
  dma_irq_out <= dma_irq_r or irq_in;
  dma_irq_full_out <= irq_full_in;
  
  process (dma_cfg_raddr_r, rdma_desc_amount_r, rdma_msi_ena_r, rdma_eplast_ena_r, rdma_eplast_r, rdma_msi_number_r, rdma_msi_tc_r, rdma_last_sync_r, rdma_desc_addr_r,
           wdma_desc_amount_r, wdma_msi_ena_r, wdma_eplast_ena_r, wdma_eplast_r, wdma_msi_number_r, wdma_msi_tc_r, wdma_last_sync_r, wdma_desc_addr_r, wdma_desc_last_r,
           rdma_start_r, wdma_started_r, opkt_data_in, opkt_addr_in, opkt_req_id_in, opkt_is_write_in, opkt_is_read_req_in, opkt_is_rdata_in, opkt_length_in, opkt_tag_in,
           dma_cfg_rdata, dma_cfg_req_id_r, dma_cfg_tag_r, dma_desc_re_r, dma_desc_addr_r, dma_desc_length_r, ipkt_data_in, ipkt_re_in, ipkt_is_write_in, dma_h2p_re_r,
           ipkt_is_read_req_in, ipkt_is_rdata_in, ipkt_addr_in, ipkt_length_in, ipkt_req_id_in, ipkt_tag_in, ipkt_is_dma_cfg_rdata, ipkt_valid_in, dma_p2h_re_r, ipkt_bar_in,
           dma_rw_length_r, dma_rc_addr_r, is_dma_bar, ipkt_re_r, opkt_is_dma_rdata, dma_desc_we_r, dma_desc_cnt_r, ipkt_is_dma_rdata, wdma_start_r, opkt_burst_we_in,
           opkt_dma_cfg_rdata_r, rdma_desc_last_r, dma_ep_addr_r, opkt_is_write_r, opkt_is_dma_rdata_r, opkt_is_dma_rdata_0, burst_active_r)
--     variable opkt_burst_we_v : std_logic;
--     variable opkt_is_write_v : std_logic;
--     variable opkt_is_dma_rdata_v : std_logic;
  begin
    if (wdma_started_r = '0') then
      dma_irq_number_out <= rdma_msi_number_r;
      dma_irq_info_out <= rdma_msi_tc_r;
    else
      dma_irq_number_out <= wdma_msi_number_r;
      dma_irq_info_out <= wdma_msi_tc_r;
    end if;
    
    dma_cfg_rdata <= (others => '0');
    
    case dma_cfg_raddr_r(3 downto 0) is
      when x"0" =>
        dma_cfg_rdata(15 downto 0) <= rdma_desc_amount_r;
        dma_cfg_rdata(17) <= rdma_msi_ena_r;
        dma_cfg_rdata(18) <= rdma_eplast_ena_r;
        dma_cfg_rdata(24 downto 20) <= rdma_msi_number_r;
        dma_cfg_rdata(30 downto 28) <= rdma_msi_tc_r;
        dma_cfg_rdata(31) <= rdma_last_sync_r;
      when x"1" =>
        dma_cfg_rdata <= rdma_desc_addr_r(58 downto 27);
      when x"2" =>
        dma_cfg_rdata <= rdma_desc_addr_r(26 downto 0) & "00000";
      when x"3" =>
        dma_cfg_rdata(15 downto 0) <= rdma_desc_last_r;
      
      when x"4" =>
        dma_cfg_rdata(15 downto 0) <= wdma_desc_amount_r;
        dma_cfg_rdata(17) <= wdma_msi_ena_r;
        dma_cfg_rdata(18) <= wdma_eplast_ena_r;
        dma_cfg_rdata(24 downto 20) <= wdma_msi_number_r;
        dma_cfg_rdata(30 downto 28) <= wdma_msi_tc_r;
        dma_cfg_rdata(31) <= wdma_last_sync_r;
      when x"5" =>
        dma_cfg_rdata <= wdma_desc_addr_r(58 downto 27);
      when x"6" =>
        dma_cfg_rdata <= wdma_desc_addr_r(26 downto 0) & "00000";
      when x"7" =>
        dma_cfg_rdata(15 downto 0) <= wdma_desc_last_r;
      
      when x"8" =>
        dma_cfg_rdata(15 downto 0) <= rdma_eplast_r;
        dma_cfg_rdata(16) <= not(rdma_start_r);
        dma_cfg_rdata(20 downto 17) <= (others => '0');
        dma_cfg_rdata(23 downto 21) <= WDMA_MAX_PAYLOAD_SIZE;
        dma_cfg_rdata(25 downto 24) <= (others => '0');
        dma_cfg_rdata(27 downto 26) <= DMA_CORE_TYPE;
        dma_cfg_rdata(31 downto 28) <= DMA_VERSION;
      when x"9" =>
        dma_cfg_rdata(23 downto 0) <= (others => '0'); -- rdma performance counter
        dma_cfg_rdata(31 downto 24) <= i2s(HIBI_DATA_WIDTH, 8);
      when x"A" =>
        dma_cfg_rdata(15 downto 0) <= wdma_eplast_r;
        dma_cfg_rdata(16) <= not(wdma_start_r);
        dma_cfg_rdata(20 downto 17) <= PCIE_LINK_WIDTH;
        dma_cfg_rdata(23 downto 21) <= RDMA_MAX_READ_SIZE;
        dma_cfg_rdata(24) <= '0';
        dma_cfg_rdata(31 downto 25) <= BOARD_ID;
      when x"B" =>
        dma_cfg_rdata(23 downto 0) <= (others => '0'); -- wdma performance counter
        dma_cfg_rdata(31 downto 24) <= i2s(32, 8);
      when others => --x"C" =>
        dma_cfg_rdata(15 downto 0) <= (others => '0'); -- error counter
        dma_cfg_rdata(31 downto 0) <= (others => '0');
    end case;
    
    opkt_is_write_out <= opkt_is_write_in;
    opkt_is_read_req_out <= opkt_is_read_req_in;
    opkt_is_rdata_out <= opkt_is_rdata_in;
    opkt_length_out <= opkt_length_in;
    opkt_tag_out <= opkt_tag_in(PCIE_TAG_WIDTH-1 downto 0);
    opkt_data_out <= opkt_data_in;
    opkt_addr_out <= opkt_addr_in;
    opkt_req_id_out <= opkt_req_id_in;
    
    if (opkt_is_dma_rdata_0 = '1') then
      opkt_is_write_out <= '1';
      opkt_is_read_req_out <= '0';
      opkt_is_rdata_out <= '0';
      opkt_addr_out <= dma_rc_addr_r;
      
    elsif (opkt_dma_cfg_rdata_r = '1') then
      opkt_is_write_out <= '0';
      opkt_is_read_req_out <= '0';
      opkt_is_rdata_out <= '1';
      opkt_data_out <= dma_cfg_rdata;
      opkt_addr_out(PCIE_LOWER_ADDR_WIDTH-1 downto 0) <= dma_cfg_raddr_r & "00";
      opkt_length_out <= (others => '0');
      opkt_length_out(HIBI_DATA_WORD_ADDR_WIDTH) <= '1';
      opkt_req_id_out <= dma_cfg_req_id_r;
      opkt_tag_out <= dma_cfg_tag_r;
      
    elsif (dma_desc_re_r = '1') then
      opkt_is_write_out <= '0';
      opkt_is_read_req_out <= '1';
      opkt_is_rdata_out <= '0';
      opkt_addr_out <= dma_desc_addr_r;
      opkt_length_out <= dma_desc_length_r;
      opkt_tag_out <= DMA_DESC_TAG & "0000";
    
    elsif (dma_desc_we_r = '1') then
      opkt_is_write_out <= '1';
      opkt_is_read_req_out <= '0';
      opkt_is_rdata_out <= '0';
      opkt_data_out <= "0000000000000000" & dma_desc_cnt_r;
      if (wdma_started_r = '0') then
        opkt_addr_out <= rdma_desc_addr_r & "01100";
      else
        opkt_addr_out <= wdma_desc_addr_r & "01100";
      end if;
      
      opkt_length_out <= "0000000000100";
--      opkt_tag_out <= '1' & DMA_DESC_TAG;
    
    elsif (dma_h2p_re_r = '1') then
      opkt_is_write_out <= '0';
      opkt_is_read_req_out <= '1';
      opkt_is_rdata_out <= '0';
      opkt_addr_out <= dma_rc_addr_r;
      opkt_length_out <= dma_rw_length_r(PCIE_RW_LENGTH_WIDTH-3 downto 0) & "00";
      opkt_tag_out <= DMA_RDATA_TAG & "0000";
    end if;
    
    ipkt_data_out <= ipkt_data_in;
    ipkt_is_write_out <= ipkt_is_write_in;
    ipkt_is_read_req_out <= ipkt_is_read_req_in;
    ipkt_is_rdata_out <= ipkt_is_rdata_in;
    ipkt_addr_out <= ipkt_addr_in;
    ipkt_length_out <= ipkt_length_in;
    ipkt_req_id_out <= ipkt_req_id_in;
    ipkt_tag_out <= ipkt_tag_in;
    ipkt_valid <= ipkt_valid_in;
    ipkt_re_out <= ipkt_re_in or ipkt_re_r;
    
    if (dma_p2h_re_r = '1') then
      ipkt_is_write_out <= '0';
      ipkt_is_read_req_out <= '1';
      ipkt_is_rdata_out <= '0';
      ipkt_addr_out <= dma_ep_addr_r; --(HIBI_DATA_WIDTH-3 downto 0) & "00";
      ipkt_length_out <= dma_rw_length_r(HIBI_RW_LENGTH_WIDTH-3 downto 0) & "00";
      ipkt_tag_out <= DMA_P2H_RDATA_TAG & "0000";
      ipkt_valid <= '1';
      ipkt_re_out <= '0';
    
    elsif (ipkt_valid_in = '1') then
      if (ipkt_is_dma_cfg_rdata = '1') then
        ipkt_valid <= '0';
      elsif (ipkt_is_dma_rdata = '1') then
        ipkt_is_write_out <= '1';
        ipkt_is_read_req_out <= '0';
        ipkt_is_rdata_out <= '0';
        ipkt_addr_out <= dma_ep_addr_r; --(HIBI_DATA_WIDTH-3 downto 0) & "00";
        ipkt_length_out <= dma_rw_length_r(HIBI_RW_LENGTH_WIDTH-3 downto 0) & "00";
      elsif (is_dma_bar = '1') then
        ipkt_valid <= '0';
      end if;
    end if;
    
    if (ipkt_bar_in = DMA_BAR) then
      is_dma_bar <= '1';
    else
      is_dma_bar <= '0';
    end if;
    
    if (ipkt_tag_in(PCIE_TAG_WIDTH-1 downto PCIE_TAG_WIDTH-2) = DMA_DESC_TAG) then
      is_dma_desc_tag <= '1';
      is_dma_rdata_tag <= '0';
      is_h2p_rdata_tag <= '0';
    elsif (ipkt_tag_in(PCIE_TAG_WIDTH-1 downto PCIE_TAG_WIDTH-2) = DMA_RDATA_TAG) then
      is_dma_desc_tag <= '0';
      is_dma_rdata_tag <= '1';
      is_h2p_rdata_tag <= '0';
    else
      is_dma_desc_tag <= '0';
      is_dma_rdata_tag <= '0';
      is_h2p_rdata_tag <= '1';
    end if;
    
    if ((opkt_tag_in(PCIE_TAG_WIDTH-1) = '1') and (opkt_is_rdata_in = '1')) then
      opkt_is_dma_rdata <= '1';
    else
      opkt_is_dma_rdata <= '0';
    end if;
    
    burst_active <= burst_active_r or opkt_burst_we_in;
    opkt_is_write <= opkt_is_write_r or opkt_is_write_in;
    opkt_is_dma_rdata_0 <= opkt_is_dma_rdata_r or opkt_is_dma_rdata;
    
--     opkt_burst_we_v := opkt_burst_we_in;
--     opkt_is_write_v := opkt_is_write_in;
--     opkt_is_dma_rdata_v := opkt_is_dma_rdata;
--     for i in 0 to (BURST_LATENCY-1) loop
--       opkt_burst_we_v := opkt_burst_we_v or opkt_burst_we_r(i);
--       opkt_is_write_v := opkt_is_write_v or opkt_is_write_r(i);
--       opkt_is_dma_rdata_v := opkt_is_dma_rdata_v or opkt_is_dma_rdata_r(i);
--     end loop;
--     opkt_burst_we <= opkt_burst_we_v;
--     opkt_is_write <= opkt_is_write_v;
--     opkt_is_dma_rdata_0 <= opkt_is_dma_rdata_v;
  end process;
  
  process (clk, rst_n)
    variable dma_desc_req_free_inc_v : std_logic;
    variable dma_desc_req_free_dec_v : std_logic;
    variable dma_desc_req_free_dec_amount_v : std_logic_vector(DMA_DESC_FIFO_MAX_DESCS_WIDTH-1 downto 0);
  begin
    if (rst_n = '0') then
      dma_state_r <= DMA_WAIT;
      rdma_desc_amount_r <= (others => '0');
      rdma_msi_ena_r <= '0';
      rdma_eplast_ena_r <= '0';
      rdma_msi_number_r <= (others => '0');
      rdma_msi_tc_r <= (others => '0');
      rdma_last_sync_r <= '0';
      rdma_start_r <= '0';
      
      rdma_desc_addr_r <= (others => '0');
      rdma_desc_last_r <= (others => '0');
      rdma_eplast_r <= (others => '0');
      
      wdma_desc_amount_r <= (others => '0');
      wdma_msi_ena_r <= '0';
      wdma_eplast_ena_r <= '0';
      wdma_msi_number_r <= (others => '0');
      wdma_msi_tc_r <= (others => '0');
      wdma_last_sync_r <= '0';
      wdma_start_r <= '0';
      
      wdma_desc_addr_r <= (others => '0');
      wdma_desc_last_r <= (others => '0');
      wdma_eplast_r <= (others => '0');
      
      wdma_started_r <= '0';
      rdma_started_r <= '0';
      
      dma_cfg_raddr_r <= (others => '0');
      dma_cfg_req_id_r <= (others => '0');
      dma_desc_re_r <= '0';
      dma_desc_we_r <= '0';
      dma_desc_addr_r <= (others => '0');
      dma_desc_length_r <= (others => '0');
      dma_desc_fetch_amount_r <= (others => '0');
      dma_ep_addr_r <= (others => '0');
      dma_rc_addr_r <= (others => '0');
      dma_rw_length_r <= (others => '0');
      dma_msi_ena_r <= '0';
      dma_eplast_ena_r <= '0';
      dma_desc_cnt_r <= (others => '0');
      dma_cfg_tag_r <= (others => '0');
      dma_word_cnt_r <= (others => '0');
      dma_h2p_re_r <= '0';
      dma_p2h_re_r <= '0';
      dma_desc_fifo_we_r <= '0';
      opkt_dma_cfg_rdata_r <= '0';
      addr_to_limit_r <= (others => '0');
      
      dma_desc_req_free_amount_r <= i2s(DMA_DESC_FIFO_MAX_DESCS, DMA_DESC_FIFO_MAX_DESCS_WIDTH);
      
      dma_desc_fifo_wdata_r <= (others => '0');
      dma_desc_fifo_re_r <= '0';
      
      ipkt_re_r <= '0';
      dma_irq_r <= '0';
      opkt_is_write_r <= '0';
      opkt_is_dma_rdata_r <= '0';
      
      burst_active_r <= '0';
      burst_deactivate_r <= (others => '0');
      
    elsif (clk'event and clk = '1') then
      ipkt_re_r <= '0';
      
      if ((ipkt_is_dma_cfg_wr = '1') and (ipkt_valid_in = '1')) then
        case ipkt_addr_in(5 downto 2) is
          when x"0" =>
            rdma_desc_amount_r <= ipkt_data_in(15 downto 0);
            rdma_msi_ena_r <= ipkt_data_in(17);
            rdma_eplast_ena_r <= ipkt_data_in(18);
            rdma_msi_number_r <= ipkt_data_in(24 downto 20);
            rdma_msi_tc_r <= ipkt_data_in(30 downto 28);
            rdma_last_sync_r <= ipkt_data_in(31);
          when x"1" =>
            rdma_desc_addr_r(62-DMA_DESC_OFFSET_WIDTH downto 31-DMA_DESC_OFFSET_WIDTH) <= ipkt_data_in;
          when x"2" =>
            rdma_desc_addr_r(30-DMA_DESC_OFFSET_WIDTH downto 0) <= ipkt_data_in(31 downto DMA_DESC_OFFSET_WIDTH+1);
          when x"3" =>
            rdma_desc_last_r <= ipkt_data_in(15 downto 0);
            dma_desc_fetch_amount_r <= ipkt_data_in(15 downto 0) + 1;
            rdma_start_r <= '1';
            
          when x"4" =>
            wdma_desc_amount_r <= ipkt_data_in(15 downto 0);
            wdma_msi_ena_r <= ipkt_data_in(17);
            wdma_eplast_ena_r <= ipkt_data_in(18);
            wdma_msi_number_r <= ipkt_data_in(24 downto 20);
            wdma_msi_tc_r <= ipkt_data_in(30 downto 28);
            wdma_last_sync_r <= ipkt_data_in(31);
          when x"5" =>
            wdma_desc_addr_r(62-DMA_DESC_OFFSET_WIDTH downto 31-DMA_DESC_OFFSET_WIDTH) <= ipkt_data_in;
          when x"6" =>
            wdma_desc_addr_r(30-DMA_DESC_OFFSET_WIDTH downto 0) <= ipkt_data_in(31 downto DMA_DESC_OFFSET_WIDTH+1);
          when others => --x"7" =>
            wdma_desc_last_r <= ipkt_data_in(15 downto 0);
            dma_desc_fetch_amount_r <= ipkt_data_in(15 downto 0) + 1;
            wdma_start_r <= '1';
        end case;
        
        ipkt_re_r <= '1';
      end if;
      
      case dma_cfg_rd_state_r is
        when DMA_CFG_READ_WAIT =>
          if ((ipkt_is_dma_cfg_rd = '1') and (ipkt_valid_in = '1')) then
            dma_cfg_raddr_r <= ipkt_addr_in(PCIE_LOWER_ADDR_WIDTH-1 downto 2);
            dma_cfg_req_id_r <= ipkt_req_id_in;
            dma_cfg_tag_r <= ipkt_tag_in;
            ipkt_re_r <= '1';
            
            opkt_dma_cfg_rdata_r <= '1';
            dma_cfg_rd_state_r <= DMA_CFG_READ;
          end if;
          
        when DMA_CFG_READ =>
          if (dma_cfg_rd_ready = '1') then
            opkt_dma_cfg_rdata_r <= '0';
            dma_cfg_rd_state_r <= DMA_CFG_READ_WAIT;
          end if;
      end case;
      
      dma_desc_req_free_inc_v := '0';
      dma_desc_req_free_dec_v := '0';
      
      case dma_desc_rd_state_r is
        when DMA_RW_START_WAIT =>
          if (wdma_start_r = '1') then
            dma_desc_addr_r <= wdma_desc_addr_r & DMA_DESC_0_OFFSET;
            dma_desc_rd_state_r <= DMA_READ_DESC_WAIT;
          elsif (rdma_start_r = '1') then
            dma_desc_addr_r <= rdma_desc_addr_r & DMA_DESC_0_OFFSET;
            dma_desc_rd_state_r <= DMA_READ_DESC_WAIT;
          end if;
          
        when DMA_READ_DESC_WAIT =>
          if (dma_desc_fetch_amount_r > 0) then
            if (dma_desc_req_free_amount_r > 0) then
              dma_desc_re_r <= '1';
              
              if (dma_desc_fetch_amount_r > dma_desc_req_free_amount_r) then
                dma_desc_length_r <= i2s(0, PCIE_RW_LENGTH_WIDTH-DMA_DESC_FIFO_MAX_DESCS_WIDTH-DMA_DESC_OFFSET_WIDTH)
                                     & dma_desc_req_free_amount_r & i2s(0, DMA_DESC_OFFSET_WIDTH);
                dma_desc_req_free_dec_v := '1';
                dma_desc_req_free_dec_amount_v := dma_desc_req_free_amount_r(DMA_DESC_FIFO_MAX_DESCS_WIDTH-1 downto 0);
                dma_desc_fetch_amount_r <= dma_desc_fetch_amount_r - dma_desc_req_free_amount_r;
              else
                dma_desc_length_r <= i2s(0, PCIE_RW_LENGTH_WIDTH-DMA_DESC_FIFO_MAX_DESCS_WIDTH-DMA_DESC_OFFSET_WIDTH)
                                     & dma_desc_fetch_amount_r(DMA_DESC_FIFO_MAX_DESCS_WIDTH-1 downto 0) & i2s(0, DMA_DESC_OFFSET_WIDTH);
                dma_desc_req_free_dec_v := '1';
                dma_desc_req_free_dec_amount_v := dma_desc_fetch_amount_r(DMA_DESC_FIFO_MAX_DESCS_WIDTH-1 downto 0);
                dma_desc_fetch_amount_r <= (others => '0');
              end if;
              dma_desc_rd_state_r <= DMA_READ_DESC_SEND;
            end if;
          else
            dma_desc_rd_state_r <= DMA_RW_START_WAIT;
          end if;
          
        when DMA_READ_DESC_SEND =>
          if (dma_desc_rd_ready = '1') then
            dma_desc_re_r <= '0';
            
            dma_desc_addr_r <= dma_desc_addr_r + dma_desc_length_r;
            
            dma_desc_rd_state_r <= DMA_READ_DESC_WAIT;
          end if;
      end case;
      
      dma_desc_fifo_we_r <= '0';
      dma_desc_fifo_wdata_r <= ipkt_data_in;
      
      if ((ipkt_is_dma_cfg_rdata = '1') and (ipkt_valid_in = '1') and (ipkt_valid = '0')) then
        ipkt_re_r <= '1';
        if (ipkt_re_r = '1') then
          dma_desc_fifo_we_r <= '1';
        end if;
      end if;
      
      dma_desc_fifo_re_r <= '0';
      
--      dma_irq_r <= '0';
      
      case dma_state_r is
        when DMA_WAIT =>
          dma_word_cnt_r <= (others => '0');
          dma_desc_cnt_r <= (others => '0');
          if ((wdma_start_r = '1') or (rdma_start_r = '1')) then
            wdma_started_r <= wdma_start_r;
            rdma_started_r <= rdma_start_r;
            wdma_start_r <= '0';
            rdma_start_r <= '0';
            dma_state_r <= DMA_DESC_WAIT;
          end if;
        
        when DMA_DESC_WAIT =>
          if (((wdma_started_r = '1') and (dma_desc_cnt_r > wdma_desc_last_r)) or ((rdma_started_r = '1') and (dma_desc_cnt_r > rdma_desc_last_r))) then
--            wdma_start_r <= wdma_start_r and not(wdma_started_r);
--            rdma_start_r <= rdma_start_r and not(rdma_started_r);
            dma_state_r <= DMA_WAIT;
          else
            if (dma_desc_fifo_empty = '0') then
              dma_desc_fifo_re_r <= '1';
            end if;
            
            if (dma_desc_fifo_re_r = '1') then
              case dma_word_cnt_r is
                when DMA_DESC_RW_LENGTH_WORD =>
                  dma_rw_length_r <= dma_desc_fifo_rdata(15 downto 0);
                  dma_msi_ena_r <= dma_desc_fifo_rdata(16);
                  dma_eplast_ena_r <= dma_desc_fifo_rdata(17);
                when DMA_DESC_EP_ADDR_WORD =>
                  dma_ep_addr_r <= dma_desc_fifo_rdata;
                when DMA_DESC_RC_UPPER_ADDR_WORD =>
                  dma_rc_addr_r(63 downto 32) <= dma_desc_fifo_rdata;
                when others => --DMA_DESC_RC_LOWER_ADDR_WORD =>
                  dma_rc_addr_r(31 downto 0) <= dma_desc_fifo_rdata;
                  addr_to_limit_r <= "1000000000000" - dma_desc_fifo_rdata(11 downto 0);
                  if (wdma_started_r = '1') then
                    dma_desc_req_free_inc_v := '1';
                    dma_h2p_re_r <= '1';
                    dma_state_r <= DMA_WRITE;
                  else
                    dma_p2h_re_r <= '1';
                    dma_state_r <= DMA_READ;
                  end if;
                  
                  dma_desc_fifo_re_r <= '0';
              end case;
              
              dma_word_cnt_r <= dma_word_cnt_r + 1;
            end if;
          end if;
        
        when DMA_DELAY =>
          if (dma_delay_r = (BURST_LATENCY-1)) then
            dma_desc_we_r <= '1';
            dma_state_r <= DMA_SEND_EPLAST;
          end if;
          dma_delay_r <= dma_delay_r + 1;
        
        when DMA_WAIT_EPLAST =>
          if (burst_active = '0') then
            dma_desc_we_r <= '1';
            dma_state_r <= DMA_SEND_EPLAST;
          end if;
        
        when DMA_SEND_EPLAST =>
          if (dma_desc_wr_ready = '1') then
            dma_desc_cnt_r <= dma_desc_cnt_r + 1;
            dma_desc_we_r <= '0';
            if (dma_msi_ena_r = '0') then
              dma_state_r <= DMA_DESC_WAIT;
            else
--              if (irq_full_in = '0') then
                dma_irq_r <= '1';
                dma_state_r <= DMA_SEND_IRQ;
--              end if;
            end if;
          end if;
        
        when DMA_SEND_IRQ =>
          if (irq_full_in = '0') then
            dma_irq_r <= '0';
            dma_state_r <= DMA_DESC_WAIT;
          end if;
        
        when DMA_WRITE =>
          if (dma_h2p_rd_ready = '1') then
            dma_h2p_re_r <= '0';
            dma_state_r <= DMA_WDATA_WAIT;
          end if;
        
        when DMA_WDATA_WAIT =>
          if ((ipkt_is_dma_rdata = '1') and (ipkt_valid_in = '1') and (ipkt_re_in = '1')) then
            if (dma_rw_length_r = 1) then
              if ((dma_eplast_ena_r = '1') or (wdma_eplast_ena_r = '1')) then
                dma_desc_we_r <= '1';
                dma_state_r <= DMA_SEND_EPLAST;
              elsif ((dma_msi_ena_r = '1') or (wdma_msi_ena_r = '1')) then
                dma_desc_cnt_r <= dma_desc_cnt_r + 1;
                dma_irq_r <= '1';
                dma_state_r <= DMA_SEND_IRQ;
              else
                dma_desc_cnt_r <= dma_desc_cnt_r + 1;
                dma_state_r <= DMA_DESC_WAIT;
              end if;
              wdma_eplast_r <= dma_desc_cnt_r;
            end if;
            dma_ep_addr_r <= dma_ep_addr_r + 4;
            dma_rw_length_r <= dma_rw_length_r - 1;
          end if;
        
--        when CALC_ADDR_TO_LIMIT =>
          
        when DMA_READ =>
          if (dma_p2h_rd_ready = '1') then
            dma_p2h_re_r <= '0';
            dma_state_r <= DMA_RDATA_WAIT;
          end if;
        
        when DMA_RDATA_WAIT =>
          if ((opkt_is_dma_rdata_0 = '1') and (opkt_ready_in = '1') and (opkt_burst_we_in = '1')) then
            if (dma_rw_length_r = 1) then
              if ((dma_eplast_ena_r = '1') or (rdma_eplast_ena_r = '1')) then
                dma_desc_we_r <= '1';
                dma_state_r <= DMA_WAIT_EPLAST;
              elsif ((dma_msi_ena_r = '1') or (rdma_msi_ena_r = '1')) then
                dma_desc_cnt_r <= dma_desc_cnt_r + 1;
                dma_irq_r <= '1';
                dma_state_r <= DMA_SEND_IRQ;
              else
                dma_desc_cnt_r <= dma_desc_cnt_r + 1;
                dma_state_r <= DMA_DESC_WAIT;
              end if;
              rdma_eplast_r <= dma_desc_cnt_r;
            end if;
            dma_rw_length_r <= dma_rw_length_r - 1;
            dma_rc_addr_r <= dma_rc_addr_r + HIBI_DATA_BYTE_WIDTH;
          end if;
      end case;
      
      if ((dma_desc_req_free_inc_v = '1') and (dma_desc_req_free_dec_v = '1')) then
        dma_desc_req_free_amount_r <= dma_desc_req_free_amount_r - dma_desc_req_free_dec_amount_v + 1;
      elsif (dma_desc_req_free_inc_v = '1') then
        dma_desc_req_free_amount_r <= dma_desc_req_free_amount_r + 1;
      elsif (dma_desc_req_free_dec_v = '1') then
        dma_desc_req_free_amount_r <= dma_desc_req_free_amount_r - dma_desc_req_free_dec_amount_v;
      else
        dma_desc_req_free_amount_r <= dma_desc_req_free_amount_r;
      end if;
      
      if ((opkt_burst_we_in = '1') and (burst_active_r = '0')) then
        burst_active_r <= '1';
        opkt_is_write_r <= opkt_is_write_in;
        opkt_is_dma_rdata_r <= opkt_is_dma_rdata;
      elsif (burst_deactivate_r(BURST_LATENCY-1) = '1') then
        burst_active_r <= '0';
        opkt_is_write_r <= '0';
        opkt_is_dma_rdata_r <= '0';
      end if;
      
      if ((opkt_burst_we_in = '1') and (opkt_length_in <= HIBI_DATA_BYTE_WIDTH)) then
        burst_deactivate_r(0) <= '1';
      else
        burst_deactivate_r(0) <= '0';
      end if;
      
      for i in 1 to (BURST_LATENCY-1) loop
       burst_deactivate_r(i) <= burst_deactivate_r(i-1);
      end loop;
      
--       opkt_burst_we_r(0) <= opkt_burst_we_in;
--       opkt_is_write_r(0) <= opkt_is_write_in;
--       opkt_is_dma_rdata_r(0) <= opkt_is_dma_rdata;
--       
--       for i in 1 to (BURST_LATENCY-1) loop
--         opkt_burst_we_r(i) <= opkt_burst_we_r(i-1);
--         opkt_is_write_r(i) <= opkt_is_write_r(i-1);
--         opkt_is_dma_rdata_r(i) <= opkt_is_dma_rdata_r(i-1);
--       end loop;
    end if;
  end process;
  
  dma_desc_fifo : entity work.fifo_sc
	generic map ( DATA_WIDTH => HIBI_DATA_WIDTH,
                FIFO_LENGTH => DMA_DESC_FIFO_LENGTH,
                CNT_WIDTH => log2_ceil(DMA_DESC_FIFO_LENGTH-1) )
            
  port map ( clk => clk,
		         rst_n => rst_n,
             wdata_in => dma_desc_fifo_wdata_r,
		         rdata_out => dma_desc_fifo_rdata,
             re_in => dma_desc_fifo_re_r,
		         we_in => dma_desc_fifo_we_r,
		         empty_out => dma_desc_fifo_empty );
    
  
end rtl;
