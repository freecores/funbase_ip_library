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
-- Title      : PCIe RX
-- Project    : Funbase
-------------------------------------------------------------------------------
-- File       : pcie_rx.vhd
-- Author     : Juha Arvio
-- Company    : TUT
-- Last update: 05.10.2011
-- Version    : 0.91
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
-- converts a PCIe RX interface (Altera PCIe compiler's Avalon ST interface)
-- to a input packet interface
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 13.10.2010   0.1     arvio     Created
-- 05.10.2011   0.91    arvio
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- synthesis translate_off
use std.textio.all;
use work.txt_util.all;
-- synthesis translate_on

entity pcie_rx is

  generic ( HIBI_DATA_WIDTH : integer := 32;
            PCIE_RW_LENGTH_WIDTH  : integer := 13;
            PCIE_ID_WIDTH   : integer := 16;
            PCIE_TAG_WIDTH : integer := 6;
            PKT_TAG_WIDTH  : integer := 8;
            PCIE_RD_LENGTH_WIDTH : integer := 7;
            
            PCIE_DATA_WIDTH : integer := 128;
            PCIE_ADDR_WIDTH : integer := 32 );
  
  port (
    clk_pcie : in std_logic;
    clk : in std_logic;
    rst_n : in std_logic;
    
    pcie_rx_data_in    : in std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
	  pcie_rx_valid_in   : in std_logic;
	  pcie_rx_sop_in     : in std_logic;
	  pcie_rx_eop_in     : in std_logic;
	  pcie_rx_empty_in   : in std_logic;
    pcie_rx_bardec_in  : in std_logic_vector(7 downto 0);
--	  pcie_rx_be_in      : in std_logic_vector(15 downto 0);
	  pcie_rx_ready_out  : out std_logic;
	  pcie_rx_mask_out   : out std_logic;
    
    
    ipkt_is_write_out    : out std_logic;
    ipkt_is_read_req_out : out std_logic;
    ipkt_is_rdata_out    : out std_logic;
--    ipkt_relax_ord_out   : out std_logic;
    ipkt_addr_out        : out std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
--    ipkt_addr_size_out   : out std_logic;
    ipkt_length_out      : out std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
--    ipkt_byte_cnt_out    : out std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
    ipkt_req_id_out      : out std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--    ipkt_cmp_id_out      : out std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
    ipkt_tag_out         : out std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
    ipkt_bar_out         : out std_logic_vector(2 downto 0);
    
    ipkt_valid_out      : out std_logic;
--    ipkt_one_d_out      : out std_logic;
--    ipkt_first_part_out : out std_logic;
--    ipkt_last_part_out  : out std_logic;
    ipkt_re_in          : in std_logic;
    ipkt_data_out       : out std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    
    debug_out           : out std_logic;
    
    tag_release_out : out std_logic;
    tag_release_ready_in : in std_logic;
    tag_release_res_out : out std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
    tag_release_amount_out : out std_logic_vector(PCIE_RD_LENGTH_WIDTH-1 downto 0);
    tag_release_data_in : in std_logic_vector(PKT_TAG_WIDTH-1 downto 0) );

end pcie_rx;

architecture rtl of pcie_rx is

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
  
  constant ENABLE_SIM : integer := 0
  -- synthesis translate_off
--  + 1
  -- synthesis translate_on
  ;
  
  constant HIBI_DATA_BYTE_WIDTH : integer := HIBI_DATA_WIDTH/8;
  constant HIBI_DATA_WORD_ADDR_WIDTH : integer := log2_ceil(HIBI_DATA_BYTE_WIDTH-1);
  constant PCIE_RX_READY_LATENCY : integer := 3;
  
  constant TLP_HEADER_FIFO_SIZE : integer := 256;
  constant TLP_DATA_FIFO_SIZE : integer := 256;
  
  constant TLP_HDR_LENGTH_L : integer := 0;
  constant TLP_HDR_LENGTH_U : integer := TLP_HDR_LENGTH_L + PCIE_RW_LENGTH_WIDTH - 1;
  constant TLP_HDR_TAG_L   : integer := TLP_HDR_LENGTH_U + 1;
  constant TLP_HDR_TAG_U   : integer := TLP_HDR_TAG_L + PCIE_TAG_WIDTH - 1;
  constant TLP_HDR_IS_WRITE_L   : integer := TLP_HDR_TAG_U + 1;
  constant TLP_HDR_IS_WRITE_U   : integer := TLP_HDR_IS_WRITE_L;
  constant TLP_HDR_IS_READ_REQ_L : integer := TLP_HDR_IS_WRITE_U + 1;
  constant TLP_HDR_IS_READ_REQ_U : integer := TLP_HDR_IS_READ_REQ_L;
  constant TLP_HDR_IS_RDATA_L : integer := TLP_HDR_IS_READ_REQ_U + 1;
  constant TLP_HDR_IS_RDATA_U : integer := TLP_HDR_IS_RDATA_L;
--  constant TLP_HDR_RELAX_ORD_L : integer := TLP_HDR_IS_RDATA_U + 1;
--  constant TLP_HDR_RELAX_ORD_U : integer := TLP_HDR_RELAX_ORD_L;
  constant TLP_HDR_ADDR_SIZE_L : integer := TLP_HDR_IS_RDATA_U + 1;
  constant TLP_HDR_ADDR_SIZE_U : integer := TLP_HDR_ADDR_SIZE_L;
  constant TLP_HDR_NOT_QWORD_ALIGNED_L : integer := TLP_HDR_ADDR_SIZE_U + 1;
  constant TLP_HDR_NOT_QWORD_ALIGNED_U : integer := TLP_HDR_NOT_QWORD_ALIGNED_L;
  constant TLP_HDR_REQ_ID_L : integer := TLP_HDR_NOT_QWORD_ALIGNED_U + 1;
  constant TLP_HDR_REQ_ID_U : integer := TLP_HDR_REQ_ID_L + PCIE_ID_WIDTH - 1;
  constant TLP_HDR_BAR_L : integer := TLP_HDR_REQ_ID_U + 1;
  constant TLP_HDR_BAR_U : integer := TLP_HDR_BAR_L + 2;
--  constant TLP_HDR_PCIE_DMA_L : integer := TLP_HDR_REQ_ID_U + 1;
--  constant TLP_HDR_PCIE_DMA_U : integer := TLP_HDR_PCIE_DMA_L;
  constant TLP_HDR_ADDR_L : integer := TLP_HDR_BAR_U + 1;
  constant TLP_HDR_ADDR_U : integer := TLP_HDR_ADDR_L + HIBI_DATA_WIDTH - 1;
  
  
  constant TLP_HEADER_FIFO_DATA_WIDTH : integer := TLP_HDR_ADDR_U + 1;
  constant TLP_HEADER_FIFO_CNT_WIDTH : integer := log2_ceil(TLP_HEADER_FIFO_SIZE);
  constant TLP_DATA_FIFO_CNT_WIDTH : integer := log2_ceil(TLP_DATA_FIFO_SIZE);
  
  constant TLP_DATA_FIFO_RCNT_WIDTH : integer := TLP_DATA_FIFO_CNT_WIDTH + log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH);
  
  
  constant TLP_HEADER_FIFO_CNT_LIMIT : integer := TLP_HEADER_FIFO_SIZE - PCIE_RX_READY_LATENCY;
  constant TLP_DATA_FIFO_CNT_LIMIT : integer := TLP_DATA_FIFO_SIZE - PCIE_RX_READY_LATENCY*(PCIE_DATA_WIDTH/HIBI_DATA_WIDTH);
  
  signal pcie_rx_data : std_logic_vector(127 downto 0);
  signal pcie_rx_data_r : std_logic_vector(63 downto 0);
  
  signal pcie_rx_ready_r : std_logic;
  signal pcie_rx_ready : std_logic;
  signal pcie_rx_ready_half_r : std_logic;
  signal pcie_rx_data_half_r : std_logic;
  signal pcie_rx_valid : std_logic;
  signal pcie_rx_sop_r : std_logic;
  signal pcie_rx_sop : std_logic;
  signal pcie_rx_eop : std_logic;
  
  signal pcie_rx_bar : std_logic_vector(2 downto 0);
  
--  signal tag_fifo_re_r : std_logic;
  
  signal tlp_hdri_type : std_logic_vector(4 downto 0);
  signal tlp_hdri_header_length : std_logic;
  signal tlp_hdri_has_data : std_logic;
  
  signal tlp_hdri_is_write : std_logic;
  signal tlp_hdri_is_read_req : std_logic;
  signal tlp_hdri_is_rdata : std_logic;
  signal tlp_hdri_is_other : std_logic;
  signal tlp_hdri_length : std_logic_vector(9 downto 0);
  signal tlp_hdri_length_0 : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal tlp_hdri_length_1 : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal tlp_hdri_byte_cnt : std_logic_vector(11 downto 0);
  signal tlp_hdri_byte_cnt_0 : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal tlp_hdri_tag : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
  signal tlp_hdri_req_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--  signal tlp_hdri_cmp_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal tlp_hdri_addr_size : std_logic;
  signal tlp_hdri_not_qword_aligned : std_logic;
  signal tlp_hdri_not_qword_aligned_0 : std_logic;
--  signal tlp_hdri_pcie_dma : std_logic;
  signal tlp_hdri_first_be : std_logic_vector(3 downto 0);
  signal tlp_hdri_last_be : std_logic_vector(3 downto 0);
  signal tlp_hdri_addr_63_2 : std_logic_vector(61 downto 0);
  signal tlp_hdri_word_addr : std_logic_vector(HIBI_DATA_WIDTH-3 downto 0);
  signal tlp_hdri_addr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal tlp_hdri_lower_addr : std_logic_vector(6 downto 0);
  
  signal tlp_header_fifo_wdata : std_logic_vector(TLP_HEADER_FIFO_DATA_WIDTH-1 downto 0);
  signal tlp_header_fifo_rdata : std_logic_vector(TLP_HEADER_FIFO_DATA_WIDTH-1 downto 0);
  
--  signal tlp_hdri_relax_ord : std_logic;
  
--  signal tlp_hdri_addr_r : std_logic_vector(63 downto 0);
  
  signal tlp_hdri_is_write_r : std_logic;
  signal tlp_hdri_is_read_req_r : std_logic;
  signal tlp_hdri_is_rdata_r : std_logic;
  signal tlp_hdri_is_other_r : std_logic;
  signal tlp_hdri_req_id_r : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal tlp_hdri_length_r : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal tlp_hdri_tag_r : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
  signal tlp_hdri_addr_size_r : std_logic;
  signal tlp_hdri_not_qword_aligned_r : std_logic;
  signal tlp_hdri_bar_r : std_logic_vector(2 downto 0);
--  signal tlp_hdri_pcie_dma_r : std_logic;
--  signal tlp_hdri_relax_ord_r : std_logic;
  
  signal tlp_hdri_addr_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  
  signal tag_release_r : std_logic;
  
  signal tlp_hdro_req_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal tlp_hdro_tag : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
  
  signal tlp_hdro_addr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  
  signal tlp_hdro_has_data : std_logic;
  
  signal tlp_hdro_is_write : std_logic;
  signal tlp_hdro_is_read_req : std_logic;
  signal tlp_hdro_is_rdata : std_logic;
  signal tlp_hdro_length : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal tlp_hdro_addr_size : std_logic;
  signal tlp_hdro_not_qword_aligned : std_logic;
  signal tlp_hdro_bar : std_logic_vector(2 downto 0);
--  signal tlp_hdro_pcie_dma : std_logic;
--  signal tlp_hdro_relax_ord : std_logic;
  signal tlp_hdro_lower_addr : std_logic_vector(6 downto 0);
  
  type tlp_part_state_t is (NO_PACKET, READ_FIRST_EMPTY_PARTS, READ_LAST_EMPTY_PARTS, FIRST_PART, MIDDLE_PART, LAST_PART);
  signal tlp_part_state_r : tlp_part_state_t;
  
  type tag_release_state_t is (WAIT_HEADER, WRITE_TAG, WAIT_HEADER_READ);
  signal tag_release_state_r : tag_release_state_t;
  
  signal tlp_data_part_cnt_r : std_logic_vector(10 downto 0);
  signal tlp_first_empty_part_cnt : std_logic_vector(log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH)-1 downto 0);
  signal tlp_first_empty_part_cnt_r : std_logic_vector(log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH)-1 downto 0);
  signal tlp_last_empty_part_cnt : std_logic_vector(log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH)-1 downto 0);
  signal tlp_last_empty_part_cnt_r : std_logic_vector(log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH)-1 downto 0);
--  signal tlp_first_part_r : std_logic;
  signal tlp_last_part_r : std_logic;
  signal tlp_new_packet_r : std_logic;
  
  signal ipkt_valid_r : std_logic;
  signal ipkt_tag_r : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  signal ipkt_tag : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  
--  signal pcie_dma_valid_r : std_logic;
  
  signal tlp_header_fifo_we_r : std_logic;
  signal tlp_header_fifo_re : std_logic;
  signal tlp_header_fifo_empty : std_logic;
  signal tlp_header_fifo_full : std_logic;
  signal tlp_header_fifo_cnt : std_logic_vector(TLP_DATA_FIFO_CNT_WIDTH-1 downto 0);
  
  signal tlp_data_fifo_section_r : std_logic_vector(1 downto 0);
  signal tlp_data_fifo_section_end_r : std_logic;
  signal tlp_data_fifo_we_r : std_logic;
  signal tlp_data_fifo_re : std_logic;
  signal tlp_data_fifo_re_r : std_logic;
  signal tlp_data_fifo_empty : std_logic;
  signal tlp_data_fifo_full : std_logic;
  signal tlp_data_fifo_one_d : std_logic;
  signal tlp_data_fifo_wdata_r : std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
  signal tlp_data_fifo_rdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal tlp_data_fifo_wcnt : std_logic_vector(TLP_DATA_FIFO_CNT_WIDTH-1 downto 0);
  signal tlp_data_fifo_rcnt : std_logic_vector(TLP_DATA_FIFO_RCNT_WIDTH-1 downto 0);
--  signal ipkt_re_stall_r : std_logic;
  
  signal debug_start_r : std_logic;
  signal debug_started_r : std_logic;
begin
  
  
  tlp_hdri_type          <= pcie_rx_data(28 downto 24);
  tlp_hdri_has_data      <= pcie_rx_data(30);
  tlp_hdri_header_length <= pcie_rx_data(29);
--  tlp_hdri_cmp_id <= pcie_rx_data(63 downto 48);
  
  tlp_hdri_first_be <= pcie_rx_data(35 downto 32);
  tlp_hdri_last_be <= pcie_rx_data(39 downto 36);
  
  tlp_hdri_length <= pcie_rx_data(9 downto 0);
  tlp_hdri_byte_cnt <= pcie_rx_data(43 downto 32);
  tlp_hdri_lower_addr <= pcie_rx_data(70 downto 64);
--  tlp_hdri_relax_ord <= pcie_rx_data(13);
  tlp_hdri_addr_size <= (tlp_hdri_is_write or tlp_hdri_is_read_req) and tlp_hdri_header_length;
  
--  tag_fifo_re_out <= tag_fifo_re_r;
  
  tag_release_out <= tag_release_r;
  tag_release_res_out <= tlp_hdro_tag;
  tag_release_amount_out <= tlp_hdro_length(PCIE_RD_LENGTH_WIDTH-1 downto 0);
  
  pcie_rx_eop <= pcie_rx_eop_in;
  
  debug_out <= debug_start_r;
  
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      debug_start_r <= '0';
      debug_started_r <= '0';
      
    elsif (clk'event and clk = '1') then
      debug_start_r <= '0';
      
      if ((pcie_rx_valid_in = '1') and (pcie_rx_ready = '1')) then
        debug_started_r <= '1';
        
        if (debug_started_r = '0') then
          debug_start_r <= '1';
        end if;
      end if;
    end if;
  end process;
  
  pcie_data_128 : if (PCIE_DATA_WIDTH = 128) generate
  process (pcie_rx_data_in, pcie_rx_valid_in, pcie_rx_ready_r, pcie_rx_sop_in)
  begin
    pcie_rx_data <= pcie_rx_data_in;
    pcie_rx_valid <= pcie_rx_valid_in;
    pcie_rx_ready <= pcie_rx_ready_r;
    pcie_rx_sop <= pcie_rx_sop_in;
  end process;
  
  pcie_rx_data_half_r <= '0';
  pcie_rx_ready_half_r <= '0';
  pcie_rx_sop_r <= '0';
  end generate;
  
  pcie_data_64 : if (PCIE_DATA_WIDTH = 64) generate
  process (pcie_rx_data_in, pcie_rx_data_half_r, pcie_rx_ready_r, pcie_rx_ready_half_r, pcie_rx_sop_r, pcie_rx_eop_in, pcie_rx_data_r, pcie_rx_valid_in)
  begin
    if ((pcie_rx_data_half_r = '0') and (pcie_rx_eop_in = '1')) then
      pcie_rx_data <= x"0000000000000000" & pcie_rx_data_in;
      pcie_rx_valid <= '1';
    else
      pcie_rx_data <= pcie_rx_data_in & pcie_rx_data_r;
      pcie_rx_valid <= pcie_rx_valid_in and pcie_rx_data_half_r; 
    end if;
    
    pcie_rx_ready <= pcie_rx_ready_r or pcie_rx_ready_half_r;
    pcie_rx_sop <= pcie_rx_sop_r;
  end process;
  
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      pcie_rx_data_r <= (others => '0');
      pcie_rx_data_half_r <= '0';
      pcie_rx_ready_half_r <= '0';
      pcie_rx_sop_r <= '0';
      
    elsif (clk'event and clk = '1') then
      if ((pcie_rx_valid_in = '1') and (pcie_rx_ready = '1')) then
        pcie_rx_sop_r <= pcie_rx_sop_in;
        
        if (pcie_rx_eop_in = '1') then
          pcie_rx_data_half_r <= '0';
        else
          pcie_rx_data_half_r <= not pcie_rx_data_half_r;
        end if;
      end if;
      
      if ((pcie_rx_data_half_r = '0') and (pcie_rx_valid_in = '1')) then
        pcie_rx_ready_half_r <= '1';
      else
        pcie_rx_ready_half_r <= '0';
      end if;
    end if;
  end process;
  end generate;
  
  process (pcie_rx_data, tlp_hdri_has_data, tlp_hdri_type, tlp_hdri_addr_size, tlp_hdri_addr_63_2, tlp_hdri_length, tlp_hdri_word_addr, tlp_hdri_first_be, tlp_hdri_last_be,
           tlp_hdri_length_0, pcie_rx_bardec_in, tlp_hdri_byte_cnt, pcie_rx_sop, tlp_hdri_not_qword_aligned_r, tlp_hdri_not_qword_aligned, tlp_hdri_is_rdata, tlp_hdri_tag,
           ipkt_re_in, ipkt_valid_r, tlp_hdro_has_data, tlp_data_fifo_re, tlp_data_fifo_section_end_r, tlp_last_part_r, tag_release_state_r, tlp_hdro_tag, ipkt_tag_r,
           tlp_hdro_is_rdata)
  begin
    tlp_hdri_is_write <= '0';
    tlp_hdri_is_read_req <= '0';
    tlp_hdri_is_rdata <= '0';
    tlp_hdri_is_other <= '0';
    tlp_hdri_req_id <= pcie_rx_data(63 downto 48);
    tlp_hdri_tag <= pcie_rx_data(45 downto 40);
    
    if (pcie_rx_bardec_in(0) = '1') then
      pcie_rx_bar <= "000";
    elsif (pcie_rx_bardec_in(1) = '1') then
      pcie_rx_bar <= "001";
    elsif (pcie_rx_bardec_in(2) = '1') then
      pcie_rx_bar <= "010";
    elsif (pcie_rx_bardec_in(3) = '1') then
      pcie_rx_bar <= "011";
    elsif (pcie_rx_bardec_in(4) = '1') then
      pcie_rx_bar <= "100";
    elsif (pcie_rx_bardec_in(5) = '1') then
      pcie_rx_bar <= "101";
    elsif (pcie_rx_bardec_in(6) = '1') then
      pcie_rx_bar <= "110";
    else
      pcie_rx_bar <= "111";
    end if;
    
    if (tlp_hdri_has_data = '1') then
      if (tlp_hdri_type = "00000") then
        tlp_hdri_is_write <= '1';
      elsif (tlp_hdri_type = "01010") then
        tlp_hdri_is_rdata <= '1';
        tlp_hdri_req_id <= pcie_rx_data(95 downto 80);
        tlp_hdri_tag <= pcie_rx_data(77 downto 72);
      else
        tlp_hdri_is_other <= '1';
      end if;
    elsif (tlp_hdri_type = "00000") then
      tlp_hdri_is_read_req <= '1';
    else
      tlp_hdri_is_other <= '1';
    end if;
    
    if (tlp_hdri_addr_size = '0') then
      tlp_hdri_addr_63_2 <= x"00000000" & pcie_rx_data(95 downto 66);
      tlp_hdri_not_qword_aligned <= pcie_rx_data(66);
    else
      tlp_hdri_addr_63_2 <= pcie_rx_data(95 downto 64) & pcie_rx_data(127 downto 98);
      tlp_hdri_not_qword_aligned <= pcie_rx_data(98);
    end if;
    
    if (pcie_rx_sop = '0') then
      tlp_hdri_not_qword_aligned_0 <= tlp_hdri_not_qword_aligned_r;
    else
      tlp_hdri_not_qword_aligned_0 <= tlp_hdri_not_qword_aligned;
    end if;
    
    tlp_hdri_word_addr <= tlp_hdri_addr_63_2(HIBI_DATA_WIDTH-3 downto 0);
    
    if (tlp_hdri_length = 0) then
      tlp_hdri_length_0 <= "1000000000000";
    else
      tlp_hdri_length_0 <= '0' & tlp_hdri_length & "00";
    end if;
    
    if (tlp_hdri_byte_cnt = 0) then
      tlp_hdri_byte_cnt_0 <= "1000000000000";
    else
      tlp_hdri_byte_cnt_0 <= '0' & tlp_hdri_byte_cnt;
    end if;
    
    if (tlp_hdri_is_rdata = '0') then
      if (tlp_hdri_first_be(0) = '1') then
        tlp_hdri_addr <= tlp_hdri_word_addr & "00";
        
        if (tlp_hdri_last_be(3 downto 2) = "01") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 1;
        elsif (tlp_hdri_last_be(3 downto 1) = "001") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 2;
        elsif (tlp_hdri_last_be(3 downto 0) = "0001") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 3;
        else
          tlp_hdri_length_1 <= tlp_hdri_length_0;
        end if;
        
      elsif (tlp_hdri_first_be(1 downto 0) = "10") then
        tlp_hdri_addr <= tlp_hdri_word_addr & "01";
        
        if (tlp_hdri_last_be(3 downto 2) = "01") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 2;
        elsif (tlp_hdri_last_be(3 downto 1) = "001") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 3;
        elsif (tlp_hdri_last_be(3 downto 0) = "0001") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 4;
        else
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 1;
        end if;
        
      elsif (tlp_hdri_first_be(2 downto 0) = "100") then
        tlp_hdri_addr <= tlp_hdri_word_addr & "10";
        
        if (tlp_hdri_last_be(3 downto 2) = "01") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 3;
        elsif (tlp_hdri_last_be(3 downto 1) = "001") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 4;
        elsif (tlp_hdri_last_be(3 downto 0) = "0001") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 5;
        else
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 2;
        end if;
        
      else --elsif ((tlp_hdri_first_be = "1000") and (tlp_hdri_last_be(3) = '1')) then
        tlp_hdri_addr <= tlp_hdri_word_addr & "11";
        
        if (tlp_hdri_last_be(3 downto 2) = "01") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 4;
        elsif (tlp_hdri_last_be(3 downto 1) = "001") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 5;
        elsif (tlp_hdri_last_be(3 downto 0) = "0001") then
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 6;
        else
          tlp_hdri_length_1 <= tlp_hdri_length_0 - 3;
        end if;
      end if;
    else
      tlp_hdri_addr <= tlp_hdri_word_addr & "00";
      tlp_hdri_length_1 <= tlp_hdri_length_0;
    end if;
    
    if ( ((ipkt_re_in = '1') and (ipkt_valid_r = '1') and (tlp_hdro_has_data = '0')) 
        or ((tlp_data_fifo_re = '1') and (tlp_data_fifo_section_end_r = '1') and (tlp_last_part_r = '1')
        and not((tag_release_state_r = WAIT_HEADER) and (tlp_hdro_is_rdata = '1'))) ) then
      tlp_header_fifo_re <= '1';
    else
      tlp_header_fifo_re <= '0';
    end if;
    
    if (tlp_hdro_is_rdata = '0') then
      ipkt_tag <= (others => '0');
      ipkt_tag(PCIE_TAG_WIDTH-1 downto 0) <= tlp_hdro_tag;
    else
      ipkt_tag <= ipkt_tag_r;
    end if;
  end process;
  
  tlp_hdro_has_data <= tlp_hdro_is_write or tlp_hdro_is_rdata;
  
  pcie_rx_ready_out <= pcie_rx_ready;
  pcie_rx_mask_out <= '0';
  
  ipkt_is_write_out <= tlp_hdro_is_write;
  ipkt_is_read_req_out <= tlp_hdro_is_read_req;
  ipkt_is_rdata_out <= tlp_hdro_is_rdata;
  ipkt_length_out <= tlp_hdro_length;
  ipkt_req_id_out <= tlp_hdro_req_id;
  ipkt_tag_out <= ipkt_tag; --tlp_hdro_tag;
  ipkt_bar_out <= tlp_hdro_bar;
  
  ipkt_addr_out <= tlp_hdro_addr;
  
--  ipkt_cmp_id_out <= tlp_hdro_extra_data(PCIE_RW_LENGTH_WIDTH+PCIE_ID_WIDTH-1 downto PCIE_RW_LENGTH_WIDTH);
--  ipkt_byte_cnt_out <= tlp_hdro_extra_data(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  
  ipkt_valid_out <= ipkt_valid_r;
  ipkt_data_out <= tlp_data_fifo_rdata;
  
  process (clk_pcie, rst_n)
  begin
    if (rst_n = '0') then
      pcie_rx_ready_r <= '0';
      tlp_header_fifo_we_r <= '0';
      tlp_data_fifo_we_r <= '0';
      tlp_data_fifo_wdata_r <= (others => '0');
      tlp_hdri_length_r <= (others => '0');
      tlp_hdri_req_id_r <= (others => '0');
      tlp_hdri_tag_r <= (others => '0');
      tlp_hdri_is_write_r <= '0';
      tlp_hdri_is_read_req_r <= '0';
      tlp_hdri_is_rdata_r <= '0';
      tlp_hdri_is_other_r <= '0';
      tlp_hdri_addr_size_r <= '0';
      tlp_hdri_not_qword_aligned_r <= '0';
      tlp_hdri_addr_r <= (others => '0');
      
    elsif (clk_pcie'event and clk_pcie = '1') then
      
      if ( (tlp_hdri_is_other = '1') or (tlp_hdri_is_other_r = '1') or ((tlp_header_fifo_cnt <= TLP_HEADER_FIFO_CNT_LIMIT)
          and (tlp_data_fifo_wcnt <= TLP_DATA_FIFO_CNT_LIMIT)) ) then
        pcie_rx_ready_r <= '1';
      else
        pcie_rx_ready_r <= '0';
      end if;
      
      tlp_data_fifo_wdata_r <= pcie_rx_data;
      
      tlp_header_fifo_we_r <= '0';
      
      if ((pcie_rx_valid = '1') and (pcie_rx_sop = '1') and (tlp_hdri_is_other = '0')) then
        tlp_header_fifo_we_r <= '1';
        tlp_hdri_not_qword_aligned_r <= tlp_hdri_not_qword_aligned;
      end if;
      
      if ( (pcie_rx_valid = '1') and ( (pcie_rx_sop = '0') or ((tlp_hdri_has_data and pcie_rx_sop and tlp_hdri_not_qword_aligned) = '1') )
           and not((pcie_rx_sop = '0') and (tlp_hdri_is_other_r = '1')) and not((pcie_rx_sop = '1') and (tlp_hdri_is_other = '1')) ) then
        tlp_data_fifo_we_r <= '1';
      else
        tlp_data_fifo_we_r <= '0';
      end if;
      
      if ((pcie_rx_sop = '1') or (ENABLE_SIM = 0)) then
          tlp_hdri_length_r <= tlp_hdri_length_1;
      end if;
      
      tlp_hdri_addr_r <= tlp_hdri_addr;
      tlp_hdri_req_id_r <= tlp_hdri_req_id;
      tlp_hdri_tag_r <= tlp_hdri_tag;
      tlp_hdri_bar_r <= pcie_rx_bar;
      
      if (pcie_rx_sop = '1') then
        tlp_hdri_is_write_r <= tlp_hdri_is_write;
        tlp_hdri_is_read_req_r <= tlp_hdri_is_read_req;
        tlp_hdri_is_rdata_r <= tlp_hdri_is_rdata;
        tlp_hdri_is_other_r <= tlp_hdri_is_other;
        tlp_hdri_addr_size_r <= tlp_hdri_addr_size;
      end if;
      
    end if;
  end process;
  
  gen_0 : if (HIBI_DATA_WIDTH = 32) generate
  process (tlp_hdro_length(3 downto 0), tlp_hdro_not_qword_aligned, tlp_hdro_addr_size, tlp_hdro_is_rdata)
  begin
    if ((tlp_hdro_not_qword_aligned = '0') or (tlp_hdro_is_rdata = '1')) then
      tlp_first_empty_part_cnt <= "00";
      
      if (tlp_hdro_length(1 downto 0) = 0) then
        case tlp_hdro_length(3 downto 2) is
          when "00" =>
            tlp_last_empty_part_cnt <= "00";
          when "01" =>
            tlp_last_empty_part_cnt <= "11";
          when "10" =>
            tlp_last_empty_part_cnt <= "10";
          when others => --"11" =>
            tlp_last_empty_part_cnt <= "01";
        end case;
      else
        case tlp_hdro_length(3 downto 2) is
          when "00" =>
            tlp_last_empty_part_cnt <= "11";
          when "01" =>
            tlp_last_empty_part_cnt <= "10";
          when "10" =>
            tlp_last_empty_part_cnt <= "01";
          when others => --"11" =>
            tlp_last_empty_part_cnt <= "00";
        end case;
      end if;
      
    else
      if (tlp_hdro_addr_size = '0') then
        tlp_first_empty_part_cnt <= "11";
        
        if (tlp_hdro_length(1 downto 0) = 0) then
          case tlp_hdro_length(3 downto 2) is
            when "00" =>
              tlp_last_empty_part_cnt <= "01";
            when "01" =>
              tlp_last_empty_part_cnt <= "00";
            when "10" =>
              tlp_last_empty_part_cnt <= "11";
            when others => --"11" =>
              tlp_last_empty_part_cnt <= "10";
           end case;
        else
          case tlp_hdro_length(3 downto 2) is
            when "00" =>
              tlp_last_empty_part_cnt <= "00";
            when "01" =>
              tlp_last_empty_part_cnt <= "11";
            when "10" =>
              tlp_last_empty_part_cnt <= "10";
            when others => --"11" =>
              tlp_last_empty_part_cnt <= "01";
          end case;
        end if;
      
      else
        tlp_first_empty_part_cnt <= "01";
        
        if (tlp_hdro_length(1 downto 0) = 0) then
          case tlp_hdro_length(3 downto 2) is
            when "00" =>
              tlp_last_empty_part_cnt <= "11";
            when "01" =>
              tlp_last_empty_part_cnt <= "10";
            when "10" =>
              tlp_last_empty_part_cnt <= "01";
            when others => --"11" =>
              tlp_last_empty_part_cnt <= "00";
           end case;
        else
          case tlp_hdro_length(3 downto 2) is
            when "00" =>
              tlp_last_empty_part_cnt <= "10";
            when "01" =>
              tlp_last_empty_part_cnt <= "01";
            when "10" =>
              tlp_last_empty_part_cnt <= "00";
            when others => --"11" =>
              tlp_last_empty_part_cnt <= "11";
          end case;
        end if;
      end if;
    end if;
    
  end process;
  end generate;
  
  gen_1 : if (HIBI_DATA_WIDTH = 64) generate
  process (tlp_hdro_length(1 downto 0))
  begin
    if (tlp_hdro_length(0) = '0') then
      case tlp_hdro_length(0) is
        when '0' =>
          tlp_last_empty_part_cnt <= "0";
        when others => --'1' =>
          tlp_last_empty_part_cnt <= "1";
      end case;
    else
      case tlp_hdro_length(0) is
        when '0' =>
          tlp_last_empty_part_cnt <= "1";
        when others => --'1' =>
          tlp_last_empty_part_cnt <= "0";
      end case;
    end if;
  end process;
  end generate;
  
  
  process (clk, rst_n)
    variable ipkt_valid_v : std_logic;
  begin
    if (rst_n = '0') then
      tlp_data_part_cnt_r <= (others => '0');
      tlp_first_empty_part_cnt_r <= (others => '0');
      tlp_last_empty_part_cnt_r <= (others => '0');
      tlp_last_part_r <= '0';
      tlp_data_fifo_section_r <= (others => '0');
      tlp_data_fifo_section_end_r <= '0';
      tlp_data_fifo_re_r <= '0';
      tlp_new_packet_r <= '0';
      ipkt_valid_r <= '0';
--      ipkt_re_stall_r <= '0';
      
      tlp_part_state_r <= NO_PACKET;
      tag_release_state_r <= WAIT_HEADER;
      tag_release_r <= '0';
      ipkt_tag_r <= (others => '0');
      
    elsif (clk'event and clk = '1') then
      tlp_last_part_r <= tlp_last_part_r;
      tlp_data_fifo_re_r <= '0';
      
      if ( (tlp_header_fifo_empty = '0') and (tlp_data_fifo_empty = '0') and not((tlp_data_fifo_one_d = '1') and (tlp_data_fifo_re_r = '1')) ) then
        ipkt_valid_v := '1';
      else
        ipkt_valid_v := '0';
      end if;
      
      ipkt_valid_r <= '0';
      
      case tlp_part_state_r is
        when NO_PACKET =>
          if ((tlp_header_fifo_empty = '0') and (tlp_hdro_has_data = '0')) then
            tlp_new_packet_r <= '0';
            tlp_last_part_r <= '1';
            tlp_part_state_r <= LAST_PART;
            ipkt_valid_r <= '1';
          
          elsif ( (tlp_header_fifo_empty = '0') and (tlp_data_fifo_empty = '0') and not((tag_release_state_r = WAIT_HEADER) and (tlp_hdro_is_rdata = '1')) ) then
            tlp_new_packet_r <= '0';
            
            if ((tlp_first_empty_part_cnt > 0) and (tlp_new_packet_r = '1')) then
              tlp_last_part_r <= '0';
              tlp_part_state_r <= READ_FIRST_EMPTY_PARTS;
              tlp_first_empty_part_cnt_r <= tlp_first_empty_part_cnt;
              tlp_data_fifo_re_r <= '1';
            else
              if (tlp_hdro_length(HIBI_DATA_WORD_ADDR_WIDTH-1 downto 0) = 0) then
                tlp_data_part_cnt_r <= tlp_hdro_length(PCIE_RW_LENGTH_WIDTH-1 downto HIBI_DATA_WORD_ADDR_WIDTH);
              else
                tlp_data_part_cnt_r <= tlp_hdro_length(PCIE_RW_LENGTH_WIDTH-1 downto HIBI_DATA_WORD_ADDR_WIDTH) + 1; -- this addition isn't needed and can be optimized
              end if;
              
              tlp_last_empty_part_cnt_r <= tlp_last_empty_part_cnt;
              
              if (tlp_hdro_length <= HIBI_DATA_BYTE_WIDTH) then
                tlp_last_part_r <= '1';
                tlp_part_state_r <= LAST_PART;
              else
                tlp_last_part_r <= '0';
                tlp_part_state_r <= FIRST_PART;
              end if;
              
              ipkt_valid_r <= '1';
            end if;
          else
            tlp_new_packet_r <= '1';
          end if;
        
        when READ_FIRST_EMPTY_PARTS =>
          if (tlp_first_empty_part_cnt_r = 1) then
            tlp_part_state_r <= NO_PACKET;
          else
            tlp_data_fifo_re_r <= '1';
          end if;
          tlp_first_empty_part_cnt_r <= tlp_first_empty_part_cnt_r - 1;
          
        when READ_LAST_EMPTY_PARTS =>
          if (tlp_last_empty_part_cnt_r = 0) then
            tlp_part_state_r <= NO_PACKET;
          else
            tlp_data_fifo_re_r <= '1';
          end if;
          tlp_last_empty_part_cnt_r <= tlp_last_empty_part_cnt_r - 1;
        
        when FIRST_PART =>
          if ((ipkt_re_in = '1') and (ipkt_valid_r = '1')) then
            if (tlp_data_part_cnt_r = 2) then
              tlp_last_part_r <= '1';
              tlp_part_state_r <= LAST_PART;
            else
              tlp_part_state_r <= MIDDLE_PART;
            end if;
            tlp_data_part_cnt_r <= tlp_data_part_cnt_r - 1;
          end if;
          ipkt_valid_r <= ipkt_valid_v;
        
        when MIDDLE_PART =>
          if ((ipkt_re_in = '1') and (ipkt_valid_r = '1')) then
            if (tlp_data_part_cnt_r = 2) then
              tlp_last_part_r <= '1';
              tlp_part_state_r <= LAST_PART;
            end if;
            tlp_data_part_cnt_r <= tlp_data_part_cnt_r - 1;
          end if;
          ipkt_valid_r <= ipkt_valid_v;
          
        when LAST_PART =>
          tlp_new_packet_r <= '1';
          if ((ipkt_re_in = '1') and (ipkt_valid_r = '1')) then
            if ((tlp_last_empty_part_cnt_r > 0) and (tlp_hdro_has_data = '1')) then
              tlp_part_state_r <= READ_LAST_EMPTY_PARTS;
            else
              tlp_part_state_r <= NO_PACKET;
            end if;
          else
            ipkt_valid_r <= '1';
          end if;
      end case;
      
      if (tlp_data_fifo_re = '1') then
        tlp_data_fifo_section_r <= tlp_data_fifo_section_r + 1;
        if (tlp_data_fifo_section_r = 2) then
          tlp_data_fifo_section_end_r <= '1';
        else
          tlp_data_fifo_section_end_r <= '0';
        end if;
      end if;
      
      tag_release_r <= '0';
      
      case tag_release_state_r is
        when WAIT_HEADER =>
          if ((tlp_header_fifo_empty = '0') and (tlp_hdro_is_rdata = '1') and (tag_release_ready_in = '1')) then
            tag_release_r <= '1';
            tag_release_state_r <= WRITE_TAG;
          end if;
        
        when WRITE_TAG =>
          ipkt_tag_r <= tag_release_data_in;
          tag_release_state_r <= WAIT_HEADER_READ;
        
        when WAIT_HEADER_READ =>
          if (tlp_header_fifo_re = '1') then
            tag_release_state_r <= WAIT_HEADER;
          end if;
      end case;
      
    end if;
  end process;
  
  
  
  -----------------------------------------------------------------------------------------
  -- TLP header fifo
  -----------------------------------------------------------------------------------------
  -- input data:  pcie_rx_data_in
  -- input write: tlp_header_fifo_we
  -- output data: tlp_header_fifo_rdata
  -- output read: tlp_header_fifo_re
  -----------------------------------------------------------------------------------------
  
  tlp_header_fifo : entity work.alt_fifo_dc_dw
	generic map ( DATA_WIDTH => TLP_HEADER_FIFO_DATA_WIDTH,
                FIFO_LENGTH => TLP_HEADER_FIFO_SIZE,
                CNT_WIDTH => TLP_HEADER_FIFO_CNT_WIDTH,
                
                RDATA_WIDTH => TLP_HEADER_FIFO_DATA_WIDTH,
                RCNT_WIDTH => TLP_HEADER_FIFO_CNT_WIDTH )
  
  port map (
		rclk => clk,
		wclk => clk_pcie,
    rst_n => rst_n,
    
    wdata_in	=> tlp_header_fifo_wdata,
		re_in	=> tlp_header_fifo_re,
		we_in	=> tlp_header_fifo_we_r,
		rempty_out => tlp_header_fifo_empty,
		wfull_out	=> tlp_header_fifo_full,
		rdata_out => tlp_header_fifo_rdata,
		wcount_out => tlp_header_fifo_cnt );
  
--  tlp_header_fifo_re <= (ipkt_re_in and ipkt_valid_r and not(tlp_hdro_has_data)) or (tlp_data_fifo_re and tlp_data_fifo_section_end_r and tlp_last_part_r);
  
  tlp_header_fifo_wdata(TLP_HDR_LENGTH_U downto TLP_HDR_LENGTH_L) <= tlp_hdri_length_r;
  tlp_header_fifo_wdata(TLP_HDR_TAG_U downto TLP_HDR_TAG_L) <= tlp_hdri_tag_r;
  tlp_header_fifo_wdata(TLP_HDR_IS_WRITE_U) <= tlp_hdri_is_write_r;
  tlp_header_fifo_wdata(TLP_HDR_IS_READ_REQ_U) <= tlp_hdri_is_read_req_r;
  tlp_header_fifo_wdata(TLP_HDR_IS_RDATA_U) <= tlp_hdri_is_rdata_r;
--  tlp_header_fifo_wdata(TLP_HDR_RELAX_ORD_U) <= tlp_hdri_relax_ord_r;
  tlp_header_fifo_wdata(TLP_HDR_ADDR_SIZE_U) <= tlp_hdri_addr_size_r;
  tlp_header_fifo_wdata(TLP_HDR_NOT_QWORD_ALIGNED_U) <= tlp_hdri_not_qword_aligned_r;
  tlp_header_fifo_wdata(TLP_HDR_REQ_ID_U downto TLP_HDR_REQ_ID_L) <= tlp_hdri_req_id_r;
  tlp_header_fifo_wdata(TLP_HDR_BAR_U downto TLP_HDR_BAR_L) <= tlp_hdri_bar_r;
--  tlp_header_fifo_wdata(TLP_HDR_PCIE_DMA_U) <= tlp_hdri_pcie_dma_r;
  tlp_header_fifo_wdata(TLP_HDR_ADDR_U downto TLP_HDR_ADDR_L) <= tlp_hdri_addr_r;
  
  tlp_hdro_length <= tlp_header_fifo_rdata(TLP_HDR_LENGTH_U downto TLP_HDR_LENGTH_L);
  tlp_hdro_tag <= tlp_header_fifo_rdata(TLP_HDR_TAG_U downto TLP_HDR_TAG_L);
  tlp_hdro_is_write <= tlp_header_fifo_rdata(TLP_HDR_IS_WRITE_U);
  tlp_hdro_is_read_req <= tlp_header_fifo_rdata(TLP_HDR_IS_READ_REQ_U);
  tlp_hdro_is_rdata <= tlp_header_fifo_rdata(TLP_HDR_IS_RDATA_U);
--  tlp_hdro_relax_ord <= tlp_header_fifo_rdata(TLP_HDR_RELAX_ORD_U);
  tlp_hdro_addr_size <=  tlp_header_fifo_rdata(TLP_HDR_ADDR_SIZE_U);
  tlp_hdro_not_qword_aligned <=  tlp_header_fifo_rdata(TLP_HDR_NOT_QWORD_ALIGNED_U);
--  tlp_hdro_pcie_dma <=  tlp_header_fifo_rdata(TLP_HDR_PCIE_DMA_U);
  tlp_hdro_req_id <= tlp_header_fifo_rdata(TLP_HDR_REQ_ID_U downto TLP_HDR_REQ_ID_L);
  tlp_hdro_bar <= tlp_header_fifo_rdata(TLP_HDR_BAR_U downto TLP_HDR_BAR_L);
  tlp_hdro_addr <= tlp_header_fifo_rdata(TLP_HDR_ADDR_U downto TLP_HDR_ADDR_L);
  
  tlp_hdro_lower_addr <= tlp_hdro_addr(6 downto 0);
  
  -----------------------------------------------------------------------------------------
  -- TLP data fifo
  -----------------------------------------------------------------------------------------
  -- input data:  pcie_rx_data_in
  -- input write: tlp_header_fifo_we
  -- output data: tlp_header_fifo_rdata
  -- output read: tlp_header_fifo_re
  -----------------------------------------------------------------------------------------
  
  tlp_data_fifo : entity work.alt_fifo_dc_dw
	generic map ( DATA_WIDTH => PCIE_DATA_WIDTH,
                FIFO_LENGTH => TLP_DATA_FIFO_SIZE,
                CNT_WIDTH => TLP_DATA_FIFO_CNT_WIDTH,
                
                RDATA_WIDTH => HIBI_DATA_WIDTH,
                RCNT_WIDTH => TLP_DATA_FIFO_RCNT_WIDTH )
  
  port map (
		rclk => clk,
		wclk => clk_pcie,
    rst_n => rst_n,
    wdata_in => tlp_data_fifo_wdata_r,
		re_in	=> tlp_data_fifo_re,
		we_in	=> tlp_data_fifo_we_r,
		rempty_out => tlp_data_fifo_empty,
		one_d_out => tlp_data_fifo_one_d,
    wfull_out	=> tlp_data_fifo_full,
		rdata_out => tlp_data_fifo_rdata,
		wcount_out => tlp_data_fifo_wcnt,
    rcount_out => tlp_data_fifo_rcnt );
    
    tlp_data_fifo_re <= (ipkt_re_in and ipkt_valid_r and tlp_hdro_has_data) or tlp_data_fifo_re_r;
  
end rtl;
