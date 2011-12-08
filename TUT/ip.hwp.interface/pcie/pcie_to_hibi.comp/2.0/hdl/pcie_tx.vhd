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
-- Title      : PCIe TX
-- Project    : Funbase
-------------------------------------------------------------------------------
-- File       : pcie_tx.vhd
-- Author     : Juha Arvio
-- Company    : TUT
-- Last update: 05.10.2011
-- Version    : 0.91
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
-- converts a packet interface into a
-- PCIe TX interface (Altera PCIe compiler's Avalon ST interface)
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 11.11.2010   0.1     arvio     Created
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

entity pcie_tx is

  generic ( HIBI_DATA_WIDTH : integer := 32;
            PCIE_RW_LENGTH_WIDTH  : integer := 13;
            PCIE_ID_WIDTH : integer := 16;
            PCIE_TAG_WIDTH : integer := 6;
            PKT_TAG_WIDTH  : integer := 8;
            PCIE_CRED_WIDTH : integer := 66;
            
            PCIE_DATA_WIDTH : integer := 128;
            PCIE_ADDR_WIDTH : integer := 32;
            PCIE_FORCE_MAX_RW_LENGTH : integer := 0;
            PCIE_MAX_RW_LENGTH : integer := 256;
            PCIE_RD_LENGTH_WIDTH : integer := 9;
            BURST_LATENCY : integer := 2;
            PCIE_IRQ_WIDTH : integer := 5;
            PCIE_TC_WIDTH : integer := 3 );

  port (
    clk_pcie : in std_logic;
    clk : in std_logic;
    rst_n : in std_logic;
    
    pcie_tx_data_out  : out std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
	  pcie_tx_valid_out : out std_logic;
	  pcie_tx_sop_out   : out std_logic;
	  pcie_tx_eop_out   : out std_logic;
	  pcie_tx_empty_out : out std_logic;
    pcie_tx_cred_in   : in std_logic_vector(PCIE_CRED_WIDTH-1 downto 0);
	  pcie_tx_ready_in  : in std_logic;
    
    opkt_is_write_in    : in std_logic;
    opkt_is_read_req_in : in std_logic;
    opkt_is_rdata_in    : in std_logic;
--    opkt_relax_ord_in   : in std_logic;
    opkt_addr_in        : in std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
--    opkt_addr_size_in   : in std_logic;
    opkt_length_in      : in std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
--    opkt_byte_cnt_in    : in std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
    opkt_req_id_in      : in std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--    opkt_cmp_id_in      : in std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
    opkt_tag_in         : in std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
--    opkt_first_be_in    : in std_logic_vector(3 downto 0);
--    opkt_last_be_in     : in std_logic_vector(3 downto 0);
    
--    opkt_wdata_req_out  : out std_logic;
    opkt_ready_out      : out std_logic;
--    opkt_first_part_in : in std_logic;
--    opkt_last_part_in  : in std_logic;
    opkt_we_in         : in std_logic;
    opkt_burst_we_in   : in std_logic;
    opkt_data_in       : in std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    
    pcie_irq_in : in std_logic;
    pcie_irq_number_in : in std_logic_vector(PCIE_IRQ_WIDTH-1 downto 0);
    pcie_irq_tc_in : in std_logic_vector(PCIE_TC_WIDTH-1 downto 0);
    pcie_irq_full_out : out std_logic;
    
    app_msi_req_out : out std_logic;
    app_msi_ack_in  : in  std_logic;
    app_msi_tc_out  : out std_logic_vector(2 downto 0);
    app_msi_num_out : out std_logic_vector(4 downto 0);
--    pex_msi_num_out : out std_logic_vector(4 downto 0);
--    app_int_sts_out : out std_logic;
--    app_int_ack_in  : in  std_logic;

    tl_cfg_add    : in std_logic_vector(3 downto 0);
    tl_cfg_ctl    : in std_logic_vector(31 downto 0);
    tl_cfg_ctl_wr : in  std_logic;
    
    lmi_data_in  : in std_logic_vector(31 downto 0);
    lmi_re_out   : out std_logic;
    lmi_we_out   : out std_logic;
    lmi_ack_in   : in  std_logic;
    lmi_addr_out : out std_logic_vector(11 downto 0);
    lmi_data_out : out std_logic_vector(31 downto 0);
    
    debug_ready_error_out   : out std_logic;
    
    tag_reserve_out : out std_logic;
    tag_reserve_ready_in : in std_logic;
    tag_reserve_res_in : in std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
    tag_reserve_amount_out : out std_logic_vector(PCIE_RD_LENGTH_WIDTH-1 downto 0);
    tag_reserve_data_out : out std_logic_vector(PKT_TAG_WIDTH-1 downto 0) );

end pcie_tx;

architecture rtl of pcie_tx is

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
  constant PCIE_DATA_BYTE_WIDTH : integer := PCIE_DATA_WIDTH/8;
  constant PCIE_DATA_WORD_ADDR_WIDTH : integer := log2_ceil(PCIE_DATA_BYTE_WIDTH-1);
  constant PCIE_TX_VALID_LATENCY : integer := 2; -- 2 for hard ip, 3 for soft ip
  constant PCIE_MAX_RW_LENGTH_WIDTH : integer := log2_ceil(PCIE_MAX_RW_LENGTH-1);
  constant DATA_RATIO : integer := PCIE_DATA_WIDTH/HIBI_DATA_WIDTH;
  
  constant CRED_X8_HDR : integer := 8;
  constant CRED_X8_DATA : integer := 12;
  
  constant TLP_HEADER_FIFO_SIZE : integer := 256;
  constant TLP_DATA_FIFO_SIZE : integer := 256;
  
  constant TLP_HDR_LENGTH_L : integer := 0;
  constant TLP_HDR_LENGTH_U : integer := TLP_HDR_LENGTH_L + PCIE_RW_LENGTH_WIDTH - 1;
  constant TLP_HDR_TAG_L   : integer := TLP_HDR_LENGTH_U + 1;
  constant TLP_HDR_TAG_U   : integer := TLP_HDR_TAG_L + PKT_TAG_WIDTH - 1;
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
  constant TLP_HDR_LAST_PART_HALF_EMPTY_L : integer := TLP_HDR_NOT_QWORD_ALIGNED_U + 1;
  constant TLP_HDR_LAST_PART_HALF_EMPTY_U : integer := TLP_HDR_LAST_PART_HALF_EMPTY_L;
  constant TLP_HDR_REQ_ID_L : integer := TLP_HDR_LAST_PART_HALF_EMPTY_U + 1;
  constant TLP_HDR_REQ_ID_U : integer := TLP_HDR_REQ_ID_L + PCIE_ID_WIDTH - 1;
  constant TLP_HDR_EXTRA_DATA_L : integer := TLP_HDR_REQ_ID_U + 1;
  constant TLP_HDR_EXTRA_DATA_U : integer := TLP_HDR_EXTRA_DATA_L + PCIE_ADDR_WIDTH - 1;
  
  
  constant TLP_HEADER_FIFO_DATA_WIDTH : integer := TLP_HDR_EXTRA_DATA_U + 1;
  constant TLP_HEADER_FIFO_CNT_WIDTH : integer := log2_ceil(TLP_HEADER_FIFO_SIZE);
  constant TLP_DATA_FIFO_CNT_WIDTH : integer := log2_ceil(TLP_DATA_FIFO_SIZE);
  
  constant TLP_DATA_FIFO_RCNT_WIDTH : integer := TLP_DATA_FIFO_CNT_WIDTH - log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH);
  
  
  constant TLP_HEADER_FIFO_CNT_LIMIT : integer := PCIE_TX_VALID_LATENCY;
  constant TLP_DATA_FIFO_CNT_LIMIT : integer := TLP_DATA_FIFO_SIZE - PCIE_TX_VALID_LATENCY*(PCIE_DATA_WIDTH/HIBI_DATA_WIDTH);
  
--  signal pcie_tx_ready_r : std_logic;
  
  signal tlp_hdro_type : std_logic_vector(4 downto 0);
--  signal tlp_hdro_header_length : std_logic;
  signal tlp_hdro_has_data : std_logic;
  
  signal tlp_hdro_is_write : std_logic;
  signal tlp_hdro_is_read_req : std_logic;
  signal tlp_hdro_is_rdata : std_logic;
  signal tlp_hdro_length : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal tlp_hdro_word_length : std_logic_vector(PCIE_RW_LENGTH_WIDTH-3 downto 0);
  signal tlp_hdro_byte_cnt : std_logic_vector(11 downto 0);
  signal tlp_hdro_tag : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  signal tlp_hdro_req_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--  signal tlp_hdro_cmp_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal tlp_hdro_addr_size : std_logic;
  signal tlp_hdro_not_qword_aligned : std_logic;
  signal tlp_hdro_first_be : std_logic_vector(3 downto 0);
  signal tlp_hdro_last_be : std_logic_vector(3 downto 0);
  signal tlp_hdro_last_part_half_empty : std_logic;
  signal tlp_hdro_relax_ord : std_logic;
  signal tlp_hdro_extra_data : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  
  signal tlp_hdri_extra_data : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal tlp_hdri_has_data : std_logic;
  signal tlp_hdri_addr_size : std_logic;
  signal tlp_hdri_addr_size_r : std_logic;
  signal tlp_hdri_not_qword_aligned : std_logic;
  signal tlp_hdri_not_qword_aligned_r : std_logic;
  signal tlp_hdri_tag_r : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  signal tlp_hdri_req_id_r : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal tlp_hdri_is_write_r : std_logic;
  signal tlp_hdri_is_read_req_r : std_logic;
  signal tlp_hdri_is_rdata_r : std_logic;
  
  signal tl_cfg_ctl_wr_d1_r : std_logic;
  signal tl_cfg_ctl_wr_d1_0_r : std_logic;
  signal tl_cfg_ctl_wr_d2_0_r : std_logic;
  
  signal tlp_header_fifo_wdata : std_logic_vector(TLP_HEADER_FIFO_DATA_WIDTH-1 downto 0);
  signal tlp_header_fifo_rdata : std_logic_vector(TLP_HEADER_FIFO_DATA_WIDTH-1 downto 0);
  
  type hdr_wr_state_t is (WAIT_HDR, WAIT_DATA_WRITE, HDR_IS_RDATA, HDR_IS_RW_REQ);
  signal hdr_wr_state_r : hdr_wr_state_t;
  signal hdr_wr_return_state_r : hdr_wr_state_t;
  
  type tlp_part_state_t is (WAIT_OPKT, BURST_DELAY, WRITE_FIRST_EMPTY_PARTS, WRITE_LAST_EMPTY_PARTS, FIRST_PART, MIDDLE_PART, LAST_PART);
  signal tlp_part_state_r : tlp_part_state_t;
  
  type pcie_tx_state_t is (WAIT_TX, READ_REQ, WRITE_TX_DATA);
  signal pcie_tx_state_r : pcie_tx_state_t;
  
  type pcie_irq_state_t is (WAIT_IRQ, WAIT_ACK, IRQ_FIFO_DELAY);
  signal pcie_irq_state_r : pcie_irq_state_t;
  
  signal pcie_length_r : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal pcie_addr_r : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal pcie_packet_cnt_r : std_logic_vector(PCIE_RW_LENGTH_WIDTH-PCIE_MAX_RW_LENGTH_WIDTH-1 downto 0);
  signal pcie_data_part_cnt_r : std_logic_vector(PCIE_MAX_RW_LENGTH_WIDTH-1 downto 0);
  signal pcie_byte_cnt_r : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal pcie_id_r : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--  signal pcie_req_id_r : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal pcie_max_rd_size_r : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal pcie_max_payload_size_r : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal pcie_relax_ord_possible_r : std_logic;
  signal pcie_is_write_r : std_logic;
  signal pcie_is_read_req_r : std_logic;
  signal pcie_is_rdata_r : std_logic;
  signal pcie_not_qword_aligned_r : std_logic;
  signal pcie_tx_valid_r : std_logic;
  signal pcie_tx_sop_r : std_logic;
  signal pcie_tx_eop_r : std_logic;
  signal pcie_tx_empty_r : std_logic;
--  signal tag_fifo_we_r : std_logic;
  
  signal pcie_tag : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
--  signal pcie_wr_req_tag_r : std_logic_vector(PCIE_TAG_WIDTH-3 downto 0);
  signal pcie_rd_req_tag_r : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
--  signal pcie_rd_cpl_tag_r : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
  
  signal pcie_tx_ready : std_logic;
  signal pcie_tx_data_half_r : std_logic;
  signal pcie_tx_data : std_logic_vector(127 downto 0);
  
  
  signal app_msi_req_r : std_logic;
  signal pcie_irq_re_r : std_logic;
  signal pcie_irq_empty : std_logic;
  signal irq_wdata : std_logic_vector(PCIE_IRQ_WIDTH+PCIE_TC_WIDTH-1 downto 0);
  signal irq_rdata : std_logic_vector(PCIE_IRQ_WIDTH+PCIE_TC_WIDTH-1 downto 0);
  
  signal cred_cpl_data : std_logic_vector(11 downto 0);
  signal cred_cpl_hdr : std_logic_vector(2 downto 0);
  signal cred_np_data : std_logic_vector(2 downto 0);
  signal cred_np_hdr : std_logic_vector(2 downto 0);
  signal cred_p_data : std_logic_vector(11 downto 0);
  signal cred_p_hdr : std_logic_vector(2 downto 0);
  
--  signal cred_inf_cpl_data : std_logic;
--  signal cred_inf_cpl_hdr : std_logic;
--  signal cred_inf_np_data : std_logic;
--  signal cred_inf_np_hdr : std_logic;
--  signal cred_inf_p_data : std_logic;
--  signal cred_inf_p_hdr : std_logic;
  
  signal tlp_data_fifo_burst_we_r : std_logic_vector(BURST_LATENCY-1 downto 0);
  signal opkt_wdata_req_r : std_logic;
  signal opkt_ready_r : std_logic;
  signal opkt_ready_d1_r : std_logic;
  signal opkt_ready_0 : std_logic;
  signal opkt_length_r : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal opkt_addr_r : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal opkt_length_left_r : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  
--  type empty_part_cnt_t is array (2 downto 0) of std_logic_vector(log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH)-1 downto 0);
  signal tlp_data_part_cnt_r : std_logic_vector(12 downto 0);
  signal tlp_empty_part_cnt_r : std_logic_vector(log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH)-1 downto 0);
--  signal tlp_first_empty_part_cnt_r : empty_part_cnt_t;
--  signal tlp_last_empty_part_cnt : std_logic_vector(log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH)-1 downto 0);
--  signal tlp_last_empty_part_cnt_r : empty_part_cnt_t;
--  signal tlp_first_part_r : std_logic;
--  signal tlp_last_part_r : std_logic;
  signal tlp_new_packet_r : std_logic;
  signal tlp_last_part_half_empty_r : std_logic;
--  signal first_pkt_part_r : std_logic;
--  type pkt_part_cnt_t is array (2 downto 0) of std_logic_vector(7 downto 0);
--  signal pkt_part_cnt_r : pkt_part_cnt_t;
--  signal pkt_part_r : std_logic_vector(1 downto 0);
--  signal pkt_rpart_r : std_logic_vector(1 downto 0);
  
--  signal ipkt_valid_r : std_logic;
  
  signal tlp_header_fifo_we_r : std_logic;
  signal tlp_header_fifo_re_r : std_logic;
  signal tlp_header_fifo_empty : std_logic;
  signal tlp_header_fifo_two_d : std_logic;
  signal tlp_header_fifo_empty_d1_r : std_logic;
  signal tlp_header_fifo_full : std_logic;
  signal tlp_header_fifo_cnt : std_logic_vector(TLP_DATA_FIFO_CNT_WIDTH-1 downto 0);
  
  signal tlp_data_fifo_we_r : std_logic;
  signal tlp_data_fifo_we : std_logic;
  signal tlp_data_fifo_re_r : std_logic;
  signal tlp_data_fifo_empty : std_logic;
  signal tlp_data_fifo_full : std_logic;
  signal tlp_data_fifo_one_d : std_logic;
--  signal tlp_data_fifo_wdata_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal tlp_data_fifo_rdata : std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
  signal tlp_data_fifo_wcnt : std_logic_vector(TLP_DATA_FIFO_CNT_WIDTH-1 downto 0);
  signal tlp_data_fifo_rcnt : std_logic_vector(TLP_DATA_FIFO_RCNT_WIDTH-1 downto 0);
  
  signal addr_to_limit_r : std_logic_vector(12 downto 0);
  signal hdr_done_r : std_logic;
  signal data_done_r : std_logic;
  
  signal tag_reserve_r : std_logic;
  signal tag_reserve_ready_r : std_logic;
  
--  signal debug_0_r : std_logic_vector(7 downto 0);
--  signal debug_1_r : std_logic;
  
  signal debug_ready_cnt_r : std_logic_vector(6 downto 0);
  signal debug_ready_error_r : std_logic;
begin
  tlp_hdri_has_data <= opkt_is_write_in or opkt_is_rdata_in;
  tlp_hdro_has_data <= tlp_hdro_is_write or tlp_hdro_is_rdata;
  
  tlp_hdro_relax_ord <= '0';
  
  cred_cpl_data <= pcie_tx_cred_in(35 downto 24);
  cred_cpl_hdr <= pcie_tx_cred_in(23 downto 21);
  cred_np_data <= pcie_tx_cred_in(20 downto 18);
  cred_np_hdr <= pcie_tx_cred_in(17 downto 15);
  cred_p_data <= pcie_tx_cred_in(14 downto 3);
  cred_p_hdr <= pcie_tx_cred_in(2 downto 0);
  
--  cred_inf_cpl_data <= pcie_tx_cred_in(65);
--  cred_inf_cpl_hdr <= pcie_tx_cred_in(64);
--  cred_inf_np_data <= pcie_tx_cred_in(63);
--  cred_inf_np_hdr <= pcie_tx_cred_in(62);
--  cred_inf_p_data <= pcie_tx_cred_in(61);
--  cred_inf_p_hdr <= pcie_tx_cred_in(60);
  
  pcie_tx_empty_out <= pcie_tx_empty_r;
  pcie_tx_valid_out <= pcie_tx_valid_r;
  
--  tag_fifo_we_out <= tag_fifo_we_r;
--  tag_fifo_data_out <= tlp_hdro_tag;
  
  opkt_ready_out <= opkt_ready_0;
  
--  opkt_wdata_req_out <= opkt_wdata_req_r or opkt_ready_0;
  
  app_msi_req_out <= app_msi_req_r;
--  pcie_irq_ack_out <= app_msi_ack_in;
--  app_msi_tc_out <= app_msi_tc_r;
--  app_msi_num_out <= app_msi_num_r;
--  pex_msi_num_out <= (others => '0');
--  app_int_sts_out <= '0';
  
  lmi_re_out <= '0';
  lmi_we_out  <= '0';
  lmi_addr_out <= (others => '0');
  lmi_data_out <= (others => '0');
  
  tag_reserve_out <= tag_reserve_r;
  tag_reserve_amount_out <= tlp_hdro_length(PCIE_RD_LENGTH_WIDTH-1 downto 0);
  tag_reserve_data_out <= tlp_hdro_tag;
--  tag_reserve_res_out <= tlp_hdro_tag(PCIE_TAG_WIDTH-1 downto PCIE_TAG_WIDTH-2) & pcie_rd_req_tag_r;
  
  debug_ready_error_out <= debug_ready_error_r;
  
  process (clk_pcie, rst_n)
  begin
    if (rst_n = '0') then
      debug_ready_cnt_r <= (others => '0');
      debug_ready_error_r <= '0';
      
    elsif (clk_pcie'event and clk_pcie = '1') then
      if (pcie_tx_ready_in = '0') then
        debug_ready_cnt_r <= debug_ready_cnt_r + 1;
      else
        debug_ready_cnt_r <= (others => '0');
      end if;
      
      if (debug_ready_cnt_r > 64) then
        debug_ready_error_r <= '1';
      else
        debug_ready_error_r <= '0';
      end if;
    end if;
  end process;
  
  
  pcie_data_128 : if (PCIE_DATA_WIDTH = 128) generate
  process (pcie_tx_data, pcie_tx_ready_in, pcie_tx_sop_r, pcie_tx_eop_r) --, debug_1_r)
  begin
    pcie_tx_data_out <= pcie_tx_data;
    pcie_tx_ready <= pcie_tx_ready_in; -- and debug_1_r;
    pcie_tx_sop_out <= pcie_tx_sop_r;
    pcie_tx_eop_out <= pcie_tx_eop_r;
  end process;
  
--   process (clk_pcie, rst_n)
--   begin
--     if (rst_n = '0') then
--       debug_0_r <= (others => '0');
--       debug_1_r <= '0';
--       
--     elsif (clk_pcie'event and clk_pcie = '1') then
--       if (debug_0_r = 15) then
--         debug_0_r <= (others => '0');
--         debug_1_r <= '1';
--       else
--         debug_0_r <= debug_0_r + 1;
--         debug_1_r <= '0';
--       end if;
--     end if;
--   end process;
  end generate;
  
  pcie_data_64 : if (PCIE_DATA_WIDTH = 64) generate
  process (pcie_tx_data, pcie_tx_data_half_r, pcie_tx_ready_in, pcie_tx_sop_r, pcie_tx_eop_r, pcie_data_part_cnt_r)
  begin
    if (pcie_tx_data_half_r = '0') then
      pcie_tx_data_out <= pcie_tx_data(63 downto 0);
    else
      pcie_tx_data_out <= pcie_tx_data(127 downto 64);
    end if;
    
    if ( (pcie_tx_ready_in = '1') and ((pcie_tx_data_half_r = '1') or ((pcie_tx_eop_r = '1') and (pcie_data_part_cnt_r <= PCIE_DATA_BYTE_WIDTH))) ) then
      pcie_tx_ready <= '1';
    else
      pcie_tx_ready <= '0';
    end if;
    
    if ((pcie_tx_eop_r = '1') and (pcie_data_part_cnt_r <= PCIE_DATA_BYTE_WIDTH)) then
      pcie_tx_eop_out <= '1';
    else
      pcie_tx_eop_out <= '0';
    end if;
    
    pcie_tx_sop_out <= pcie_tx_sop_r and not(pcie_tx_data_half_r);
  end process;
  
  process (clk_pcie, rst_n)
  begin
    if (rst_n = '0') then
      pcie_tx_data_half_r <= '0';
      
    elsif (clk_pcie'event and clk_pcie = '1') then
      if ((pcie_tx_valid_r = '1') and (pcie_tx_ready_in = '1')) then
        if ((pcie_tx_sop_r = '0') and (pcie_data_part_cnt_r <= PCIE_DATA_BYTE_WIDTH)) then
          pcie_tx_data_half_r <= '0';
        else
          pcie_tx_data_half_r <= not pcie_tx_data_half_r;
        end if;
      end if;
    end if;
  end process;
  end generate;
  
  process (opkt_addr_in, tlp_data_fifo_rdata, tlp_hdro_length, tlp_hdro_extra_data, tlp_hdro_type, tlp_hdro_addr_size, tlp_hdro_has_data, pcie_id_r, tlp_hdro_is_rdata,
           tlp_hdro_first_be, tlp_hdro_last_be, tlp_hdro_tag, tlp_hdro_req_id, pcie_tx_sop_r, tlp_hdro_not_qword_aligned, opkt_length_left_r, tlp_hdro_word_length, opkt_addr_r,
           opkt_is_rdata_in, opkt_is_read_req_in, opkt_ready_r, opkt_ready_d1_r, opkt_burst_we_in, tlp_data_fifo_we_r, tlp_data_fifo_burst_we_r, pcie_rd_req_tag_r,
           tlp_hdro_is_write, tlp_hdro_is_read_req, pcie_tag)
  begin
    if (tlp_hdro_length = 0) then
      tlp_hdro_first_be <= "0000";
      tlp_hdro_last_be <= "0000";
    else
      case tlp_hdro_length(1 downto 0) is
        when "00" =>
          if (tlp_hdro_length >= 5) then
            tlp_hdro_first_be <= "1111";
            case tlp_hdro_length(1 downto 0) is
              when "00" =>
                tlp_hdro_last_be <= "1111";
              when "01" =>
                tlp_hdro_last_be <= "1000";
              when "10" =>
                tlp_hdro_last_be <= "1100";
              when others => --"11" =>
                tlp_hdro_last_be <= "1110";
            end case;
          elsif (tlp_hdro_length = 4) then
            tlp_hdro_first_be <= "1111";
            tlp_hdro_last_be <= "0000";
          else
            case tlp_hdro_length(1 downto 0) is
              when "01" =>
                tlp_hdro_first_be <= "1000";
              when "10" =>
                tlp_hdro_first_be <= "1100";
              when others => --"11" =>
                tlp_hdro_first_be <= "1110";
            end case;
            tlp_hdro_last_be <= "0000";
          end if;
        
        when "01" =>
          if (tlp_hdro_length >= 4) then
            tlp_hdro_first_be <= "0111";
            case tlp_hdro_length(1 downto 0) is
              when "00" =>
                tlp_hdro_last_be <= "1000";
              when "01" =>
                tlp_hdro_last_be <= "1100";
              when "10" =>
                tlp_hdro_last_be <= "1110";
              when others => --"11" =>
                tlp_hdro_last_be <= "1111";
            end case;
          elsif (tlp_hdro_length = 3) then
            tlp_hdro_first_be <= "0111";
            tlp_hdro_last_be <= "0000";
          else
            case tlp_hdro_length(1 downto 0) is
              when "01" =>
                tlp_hdro_first_be <= "0100";
              when others => --"10" =>
                tlp_hdro_first_be <= "0110";
            end case;
            tlp_hdro_last_be <= "0000";
          end if;
        
        when "10" =>
          if (tlp_hdro_length >= 3) then
            tlp_hdro_first_be <= "0011";
            case tlp_hdro_length(1 downto 0) is
              when "00" =>
                tlp_hdro_last_be <= "1100";
              when "01" =>
                tlp_hdro_last_be <= "1110";
              when "10" =>
                tlp_hdro_last_be <= "1111";
              when others => --"11" =>
                tlp_hdro_last_be <= "1000";
            end case;
          elsif (tlp_hdro_length = 2) then
            tlp_hdro_first_be <= "0011";
            tlp_hdro_last_be <= "0000";
          else
            tlp_hdro_first_be <= "0010";
            tlp_hdro_last_be <= "0000";
          end if;
        when others => --"11" =>
          tlp_hdro_first_be <= "0001";
          if (tlp_hdro_length >= 2) then
            case tlp_hdro_length(1 downto 0) is
              when "00" =>
                tlp_hdro_last_be <= "1110";
              when "01" =>
                tlp_hdro_last_be <= "1111";
              when "10" =>
                tlp_hdro_last_be <= "1000";
              when others => --"11" =>
                tlp_hdro_last_be <= "1100";
            end case;
          else
            tlp_hdro_last_be <= "0000";
          end if;
      end case;
    end if;
    
    pcie_tx_data <= (others => '0');
    tlp_hdro_type <= "00000";
    
    if (pcie_tx_sop_r = '0') then
      pcie_tx_data <= tlp_data_fifo_rdata;
    
    else
      pcie_tx_data(9 downto 0) <= tlp_hdro_word_length(9 downto 0);
      pcie_tx_data(11 downto 10) <= "00";
      pcie_tx_data(12) <= '0'; -- no snoop
      pcie_tx_data(13) <= '0'; --tlp_hdro_relax_ord;
      pcie_tx_data(14) <= '0'; -- ep
      pcie_tx_data(19 downto 16) <= "0000";
      pcie_tx_data(22 downto 20) <= "000"; -- traffic class
      pcie_tx_data(23) <= '0';
      pcie_tx_data(28 downto 24) <= tlp_hdro_type;
      pcie_tx_data(29) <= tlp_hdro_addr_size;
      pcie_tx_data(30) <= tlp_hdro_has_data;
      pcie_tx_data(31) <= '0';
      pcie_tx_data(63 downto 48) <= pcie_id_r;
      
      if (tlp_hdro_is_rdata = '0') then
--        tlp_hdro_type <= "00000";
        pcie_tx_data(35 downto 32) <= tlp_hdro_first_be;
        pcie_tx_data(39 downto 36) <= tlp_hdro_last_be;
        pcie_tx_data(47 downto 40) <= (others => '0');
        pcie_tx_data(39 + PCIE_TAG_WIDTH downto 40) <= pcie_tag;
        if (tlp_hdro_addr_size = '0') then
          pcie_tx_data(95 downto 64) <= tlp_hdro_extra_data(31 downto 2) & "00";
          if ((tlp_hdro_has_data = '1') and (tlp_hdro_not_qword_aligned = '1')) then
            pcie_tx_data(127 downto 96) <= tlp_data_fifo_rdata(127 downto 96);
          else
            pcie_tx_data(127 downto 96) <= (others => '0');
          end if;
        else
          pcie_tx_data(127 downto 96) <= tlp_hdro_extra_data(31 downto 2) & "00";
          pcie_tx_data(95 downto 64) <= tlp_hdro_extra_data(63 downto 32);
        end if;
      else
        tlp_hdro_type <= "01010";
        pcie_tx_data(43 downto 32) <= tlp_hdro_extra_data(18 downto 7);
        pcie_tx_data(47 downto 44) <= "0000"; -- completion status and BCM
        pcie_tx_data(70 downto 64) <= tlp_hdro_extra_data(6 downto 0);
        pcie_tx_data(79 downto 72) <= (others => '0');
        pcie_tx_data(71+PCIE_TAG_WIDTH downto 72) <= tlp_hdro_tag(PCIE_TAG_WIDTH-1 downto 0);
        pcie_tx_data(95 downto 80) <= tlp_hdro_req_id;
        pcie_tx_data(127 downto 96) <= tlp_data_fifo_rdata(127 downto 96);
      end if;
    end if;
    
    if (tlp_hdro_length(1 downto 0) = 0) then
      tlp_hdro_word_length <= tlp_hdro_length(PCIE_RW_LENGTH_WIDTH-1 downto 2);
    else
      tlp_hdro_word_length <= tlp_hdro_length(PCIE_RW_LENGTH_WIDTH-1 downto 2) + 1;
    end if;
    
    
    if (opkt_addr_in(2 downto 0) /= "000") then
      tlp_hdri_not_qword_aligned <= '1';
    else
      tlp_hdri_not_qword_aligned <= '0';
    end if;
    
    tlp_hdri_extra_data <= opkt_addr_r;
    
    if (opkt_is_rdata_in = '1') then
      if (opkt_length_left_r >= 256) then
        tlp_hdri_extra_data(18 downto 7) <= x"100";
      else
        tlp_hdri_extra_data(18 downto 7) <= opkt_length_left_r(11 downto 0);
      end if;
    end if;
    
    if ((opkt_burst_we_in = '0') and (tlp_data_fifo_burst_we_r(BURST_LATENCY-1) = '0')) then
      tlp_data_fifo_we <= tlp_data_fifo_we_r;
    else
      tlp_data_fifo_we <= tlp_data_fifo_burst_we_r(BURST_LATENCY-1);
    end if;
    
    if (opkt_is_read_req_in = '0') then
      opkt_ready_0 <= opkt_ready_d1_r;
    else
      opkt_ready_0 <= opkt_ready_r;
    end if;
    
--    if (tlp_hdro_is_write = '1') then
--      pcie_tag <= pcie_wr_req_tag_r;
    if (tlp_hdro_is_read_req = '1') then
      pcie_tag <= pcie_rd_req_tag_r;
    else
      pcie_tag <= (others => '0');
    end if;
    
  end process;
  
  gen_0 : if (PCIE_ADDR_WIDTH = 32) generate
  tlp_hdri_addr_size <= '0';
  end generate;
  
  gen_1 : if (PCIE_ADDR_WIDTH = 64) generate
  process (opkt_addr_in(63 downto 32))
  begin
    if (opkt_addr_in(63 downto 32) = 0) then
      tlp_hdri_addr_size <= '0';
    else
      tlp_hdri_addr_size <= '1';
    end if;
  end process;
  end generate;
  
--   gen_2 : if (HIBI_DATA_WIDTH = 32) generate
--   process (opkt_length_in(3 downto 0), tlp_hdri_not_qword_aligned, opkt_is_rdata_in, tlp_hdri_addr_size)
--   begin
--     if (tlp_hdri_not_qword_aligned = '0') then
--       if ((tlp_hdri_addr_size = '0') or (opkt_is_rdata_in = '1')) then
--         tlp_first_empty_part_cnt <= "11";
--       
--         if (opkt_length_in(1 downto 0) = 0) then
--           case opkt_length_in(3 downto 2) is
--             when "00" =>
--               tlp_last_empty_part_cnt <= "01";
--             when "01" =>
--               tlp_last_empty_part_cnt <= "00";
--             when "10" =>
--               tlp_last_empty_part_cnt <= "11";
--             when others => --"11" =>
--               tlp_last_empty_part_cnt <= "10";
--           end case;
--         else
--           case opkt_length_in(3 downto 2) is
--             when "00" =>
--               tlp_last_empty_part_cnt <= "00";
--             when "01" =>
--               tlp_last_empty_part_cnt <= "11";
--             when "10" =>
--               tlp_last_empty_part_cnt <= "10";
--             when others => --"11" =>
--               tlp_last_empty_part_cnt <= "01";
--           end case;
--         end if;
--       else
--         tlp_first_empty_part_cnt <= "01";
--       
--         if (opkt_length_in(1 downto 0) = 0) then
--           case opkt_length_in(3 downto 2) is
--             when "00" =>
--               tlp_last_empty_part_cnt <= "11";
--             when "01" =>
--               tlp_last_empty_part_cnt <= "10";
--             when "10" =>
--               tlp_last_empty_part_cnt <= "01";
--             when others => --"11" =>
--               tlp_last_empty_part_cnt <= "00";
--           end case;
--         else
--           case opkt_length_in(3 downto 2) is
--             when "00" =>
--               tlp_last_empty_part_cnt <= "10";
--             when "01" =>
--               tlp_last_empty_part_cnt <= "01";
--             when "10" =>
--               tlp_last_empty_part_cnt <= "00";
--             when others => --"11" =>
--               tlp_last_empty_part_cnt <= "11";
--           end case;
--         end if;
--       end if;
--     
--     else
--       tlp_first_empty_part_cnt <= "00";
--       
--       if (opkt_length_in(1 downto 0) = 0) then
--         case opkt_length_in(3 downto 2) is
--           when "00" =>
--             tlp_last_empty_part_cnt <= "00";
--           when "01" =>
--             tlp_last_empty_part_cnt <= "11";
--           when "10" =>
--             tlp_last_empty_part_cnt <= "10";
--           when others => --"11" =>
--             tlp_last_empty_part_cnt <= "01";
--          end case;
--       else
--         case opkt_length_in(3 downto 2) is
--           when "00" =>
--             tlp_last_empty_part_cnt <= "11";
--           when "01" =>
--             tlp_last_empty_part_cnt <= "10";
--           when "10" =>
--             tlp_last_empty_part_cnt <= "01";
--           when others => --"11" =>
--             tlp_last_empty_part_cnt <= "00";
--         end case;
--       end if;
--     end if;
--     
--   end process;
--   end generate;
  
  
  
  process (clk_pcie, rst_n)
  begin
    if (rst_n = '0') then
      pcie_id_r <= (others => '0');
      tl_cfg_ctl_wr_d1_0_r <= '0';
      tl_cfg_ctl_wr_d2_0_r <= '0';
      app_msi_req_r <= '0';
      pcie_irq_re_r <= '0';
      pcie_irq_state_r <= WAIT_IRQ;
      
    elsif (clk_pcie'event and clk_pcie = '1') then
      tl_cfg_ctl_wr_d1_0_r <= tl_cfg_ctl_wr;
      tl_cfg_ctl_wr_d2_0_r <= tl_cfg_ctl_wr_d1_0_r;
      
      if (tl_cfg_ctl_wr_d2_0_r /= tl_cfg_ctl_wr_d1_0_r) then
        if (tl_cfg_add = 15) then
          pcie_id_r <= tl_cfg_ctl(12 downto 0) & "000";
        end if;
      end if;
      
      case pcie_irq_state_r is
        when WAIT_IRQ =>
--          pcie_irq_re_r <= '0';
          if (pcie_irq_empty = '0') then
            app_msi_req_r <= '1';
            pcie_irq_state_r <= WAIT_ACK;
          end if;
        when WAIT_ACK =>
          if (app_msi_ack_in = '1') then
            pcie_irq_re_r <= '1';
            app_msi_req_r <= '0';
            pcie_irq_state_r <= IRQ_FIFO_DELAY;
          end if;
        when IRQ_FIFO_DELAY =>
          pcie_irq_re_r <= '0';
          pcie_irq_state_r <= WAIT_IRQ;
      end case;
      
--       if (app_msi_req_t_d1_r /= app_msi_req_t_r) then
--         app_msi_req_r <= '1';
--         app_msi_tc_r <= pcie_irq_tc_in;
--         app_msi_num_r <= pcie_irq_number_in;
--       elsif (app_msi_ack_in = '1') then
--         app_msi_req_r <= '0';
--         app_msi_tc_r <= app_msi_tc_r;
--         app_msi_num_r <= app_msi_num_r;
--       else
--         app_msi_req_r <= app_msi_req_r;
--         app_msi_tc_r <= app_msi_tc_r;
--         app_msi_num_r <= app_msi_num_r;
--       end if;
--       
--       app_msi_req_t_d1_r <= app_msi_req_t_r;
-- --      app_msi_req_t_d2_r <= app_msi_req_t_d1_r;
--       
--       if (app_msi_ack_in = '1') then
--         app_msi_ack_t_r <= not app_msi_ack_t_r;
--       end if;
    end if;
  end process;
  
--   process (clk, rst_n)
--   begin
--     if (rst_n = '0') then
--       pcie_irq_ack_out <= '0';
--       app_msi_ack_t_d1_r <= '0';
-- --      app_msi_ack_t_d2_r <= '0';
--       app_msi_req_t_r <= '0';
--     elsif (clk'event and clk = '1') then
--       if (pcie_irq_in = '1') then
--         app_msi_req_t_r <= not app_msi_req_t_r;
--       end if;
--       
--       app_msi_ack_t_d1_r <= app_msi_ack_t_r;
-- --      app_msi_ack_t_d2_r <= app_msi_ack_t_d1_r;
--       
--       if (app_msi_ack_t_d1_r /= app_msi_ack_t_r) then
--         pcie_irq_ack_out <= '1';
--       else
--         pcie_irq_ack_out <= '0';
--       end if;
--     end if;
--   end process;
  
  process (clk_pcie, rst_n)
  begin
    if (rst_n = '0') then
      pcie_tx_valid_r <= '0';
      tlp_header_fifo_re_r <= '0';
      tlp_data_fifo_re_r <= '0';
      pcie_tx_state_r <= WAIT_TX;
      pcie_addr_r <= (others => '0');
      pcie_is_write_r <= '0';
      pcie_is_read_req_r <= '0';
      pcie_is_rdata_r <= '0';
--      pcie_req_id_r <= (others => '0');
      pcie_not_qword_aligned_r <= '0';
      pcie_length_r <= (others => '0');
      pcie_packet_cnt_r <= (others => '0');
      pcie_data_part_cnt_r <= (others => '0');
      pcie_tx_sop_r <= '0';
      pcie_tx_eop_r <= '0';
      pcie_tx_empty_r <= '0';
--      tag_fifo_we_r <= '0';
      
--      pcie_wr_req_tag_r <= (others => '0');
      pcie_rd_req_tag_r <= (others => '0');
--      pcie_rd_cpl_tag_r <= (others => '0');
      
      tag_reserve_r <= '0';
      tag_reserve_ready_r <= '0';
      
    elsif (clk_pcie'event and clk_pcie = '1') then
      pcie_tx_valid_r <= '0';
      tlp_header_fifo_re_r <= '0';
      tlp_data_fifo_re_r <= '0';
--      tag_fifo_we_r <= '0';
      
--      pcie_tx_sop_r <= '0';
--      pcie_tx_eop_r <= '0';
      
      tlp_header_fifo_empty_d1_r <= tlp_header_fifo_empty;
      
      pcie_tx_empty_r <= '0';
      
      case pcie_tx_state_r is
        when WAIT_TX =>
          if ( not((tlp_header_fifo_two_d = '1') and (tlp_header_fifo_re_r = '1')) and (tlp_header_fifo_re_r = '0') ) then
            if ((tlp_header_fifo_empty = '0') and (tlp_hdro_is_read_req = '1')) then --tlp_hdro_length) ) then
              tag_reserve_r <= '1';
              pcie_tx_state_r <= READ_REQ;
            
            elsif ( (pcie_tx_ready = '1') and (tlp_header_fifo_empty = '0') and (tlp_data_fifo_empty = '0') and not((tlp_data_fifo_rcnt <= 2) and (tlp_data_fifo_re_r = '1'))
                    and ( ((tlp_hdro_is_rdata = '1') and (cred_cpl_data >= tlp_hdro_word_length)) or ((tlp_hdro_is_write = '1') and (cred_p_data >= tlp_hdro_word_length)) )
                    and ( (tlp_data_fifo_rcnt > tlp_hdro_word_length(PCIE_RW_LENGTH_WIDTH-3 downto 2)) or
                          ((tlp_data_fifo_rcnt = tlp_hdro_word_length(PCIE_RW_LENGTH_WIDTH-3 downto 2)) and (tlp_hdro_word_length(1 downto 0) = "00")) ) ) then
              pcie_tx_sop_r <= '1';
              pcie_tx_eop_r <= '0';
              pcie_tx_valid_r <= '1';
              
--              if (tlp_hdro_is_rdata = '1') then
--                pcie_rd_cpl_tag_r <= pcie_rd_cpl_tag_r + 1;
--              else
--                pcie_wr_req_tag_r <= pcie_wr_req_tag_r + 1;
--              end if;
              
              if (tlp_hdro_not_qword_aligned = '1') then
                tlp_data_fifo_re_r <= '1';
              end if;
              
              pcie_packet_cnt_r <= tlp_hdro_length(PCIE_RW_LENGTH_WIDTH-1 downto PCIE_MAX_RW_LENGTH_WIDTH);
              pcie_data_part_cnt_r <= tlp_hdro_length(PCIE_MAX_RW_LENGTH_WIDTH-1 downto 0);
              
              if ((tlp_hdro_length <= PCIE_DATA_BYTE_WIDTH) and (tlp_hdro_not_qword_aligned = '1') and (tlp_hdro_addr_size = '0')) then
                pcie_tx_eop_r <= '1';
              else
                pcie_tx_state_r <= WRITE_TX_DATA;
              end if;
              
              tlp_header_fifo_re_r <= '1';
            end if;
          end if;
         
         when READ_REQ =>
           if (tag_reserve_ready_in = '1') then
             pcie_rd_req_tag_r <= tag_reserve_res_in;
             tag_reserve_r <= '0';
             tag_reserve_ready_r <= '1';
           end if;
           
           if ( ((tag_reserve_ready_in = '1') or (tag_reserve_ready_r = '1')) and ((pcie_tx_ready = '1') and (cred_np_hdr >= 1)) ) then
             tlp_header_fifo_re_r <= '1';
             tag_reserve_ready_r <= '0';
             pcie_tx_sop_r <= '1';
             pcie_tx_eop_r <= '1';
             pcie_tx_valid_r <= '1';
             
--             pcie_rd_req_tag_r <= pcie_rd_req_tag_r + 1;
             pcie_tx_state_r <= WAIT_TX;
           end if;
          
        when WRITE_TX_DATA =>
          pcie_tx_sop_r <= '0';
          
          if ((pcie_tx_ready = '1') and (tlp_data_fifo_empty = '0') and not((tlp_data_fifo_one_d = '1') and (tlp_data_fifo_re_r = '1'))) then
            pcie_tx_valid_r <= '1';
            tlp_data_fifo_re_r <= '1';
            
            if ( ((pcie_tx_sop_r = '1') and (tlp_hdro_word_length <= 2)) or (((pcie_tx_sop_r = '0')) and (pcie_data_part_cnt_r <= (PCIE_DATA_BYTE_WIDTH/2))) ) then
              pcie_tx_empty_r <= '1';
            end if;
            
            if (pcie_data_part_cnt_r <= PCIE_DATA_BYTE_WIDTH) then
              pcie_packet_cnt_r <= pcie_packet_cnt_r - 1;
              
              if (pcie_packet_cnt_r = 0) then
                pcie_tx_eop_r <= '1';
                pcie_tx_state_r <= WAIT_TX;
              end if;
            end if;
            
            pcie_data_part_cnt_r <= pcie_data_part_cnt_r - PCIE_DATA_BYTE_WIDTH;
         end if;
      end case;
      
    end if;
  end process;
  
  
  
  
  process (clk, rst_n)
    variable pcie_max_size_v : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
    variable opkt_length_v : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
    variable tlp_first_empty_part_cnt_v : std_logic_vector(log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH)-1 downto 0);
    variable tlp_last_empty_part_cnt_v : std_logic_vector(log2(PCIE_DATA_WIDTH, HIBI_DATA_WIDTH)-1 downto 0);
    variable tlp_hdri_not_qword_aligned_v : std_logic;
    variable hdr_done_v : std_logic;
    variable data_done_v : std_logic;
    variable i_v : integer;
--    variable add_pkt_parts_first_v : std_logic;
--    variable add_pkt_parts_v : std_logic;
--    variable pkt_part_cnt_first_inc_v : std_logic;
--    variable pkt_part_cnt_inc_v : std_logic;
  begin
    if (rst_n = '0') then
      tlp_header_fifo_we_r <= '0';
      tlp_data_fifo_we_r <= '0';
      opkt_wdata_req_r <= '0';
      opkt_ready_r <= '0';
      opkt_ready_d1_r <= '0';
      tlp_data_fifo_burst_we_r <= (others => '0');
      tlp_part_state_r <= WAIT_OPKT;
      tlp_data_part_cnt_r <= (others => '0');
      tlp_empty_part_cnt_r <= (others => '0');
--      tlp_last_empty_part_cnt_r <= (others => '0');
      tlp_last_part_half_empty_r <= '0';
      tlp_new_packet_r <= '0';
      addr_to_limit_r <= (others => '0');
--      first_pkt_part_r <= '0';
      hdr_wr_state_r <= WAIT_HDR;
      hdr_wr_return_state_r <= WAIT_HDR;
      hdr_done_r <= '0';
      opkt_length_r <= (others => '0');
      opkt_length_left_r <= (others => '0');
      opkt_addr_r <= (others => '0');
--      pkt_part_r <= (others => '0');
--      pkt_rpart_r <= (others => '0');
      data_done_r <= '1';
      tlp_hdri_not_qword_aligned_r <= '0';
      tlp_hdri_is_write_r <= '0';
      tlp_hdri_is_read_req_r <= '0';
      tlp_hdri_is_rdata_r <= '0';
      tlp_hdri_req_id_r <= (others => '0');
      tlp_hdri_tag_r <= (others => '0');
      tlp_hdri_addr_size_r <= '0';
      tl_cfg_ctl_wr_d1_r <= '0';
      pcie_relax_ord_possible_r <= '0';
      pcie_max_payload_size_r <= (others => '0');
      pcie_max_rd_size_r <= (others => '0');
      
    elsif (clk'event and clk = '1') then
      tlp_header_fifo_we_r <= '0';
      tlp_data_fifo_we_r <= '0';
      
      tlp_last_part_half_empty_r <= '0';
      
      opkt_wdata_req_r <= '0';
      opkt_ready_r <= '0';
      opkt_ready_d1_r <= opkt_ready_r;
      
      tl_cfg_ctl_wr_d1_r <= tl_cfg_ctl_wr;
      
      if ((tl_cfg_ctl_wr_d1_r /= tl_cfg_ctl_wr) and (tl_cfg_add = 0)) then
        pcie_relax_ord_possible_r <= tl_cfg_ctl(20);
        
        case tl_cfg_ctl(23 downto 21) is
          when "000" =>
            pcie_max_payload_size_r <= "0000010000000"; -- 128 bytes, 32 dwords
          when "001" =>
            pcie_max_payload_size_r <= "0000100000000"; -- 256 bytes, 64 dwords
          when "010" =>
            pcie_max_payload_size_r <= "0001000000000"; -- 512 bytes, 128 dwords
          when "011" =>
            pcie_max_payload_size_r <= "0010000000000"; -- 1024 bytes, 256 dwords
          when others => --"100" =>
            pcie_max_payload_size_r <= "0100000000000"; -- 2048 bytes, 512 dwords (pcie spec says 101 => 4096 bytes, but altera pcie controller reference implementation has 100 => 2048 as the max)
        end case;
        
        case tl_cfg_ctl(30 downto 28) is
          when "000" =>
            pcie_max_rd_size_r <= "0000010000000"; -- 128 bytes, 32 dwords
          when "001" =>
            pcie_max_rd_size_r <= "0000100000000"; -- 256 bytes, 64 dwords
          when "010" =>
            pcie_max_rd_size_r <= "0001000000000"; -- 512 bytes, 128 dwords
          when "011" =>
            pcie_max_rd_size_r <= "0010000000000"; -- 1024 bytes, 256 dwords
          when others => --"100" =>
            pcie_max_rd_size_r <= "0100000000000"; -- 2048 bytes, 512 dwords (pcie spec says 101 => 4096 bytes, but altera pcie controller reference implementation has 100 => 2048 as the max)
        end case;
      end if;
      
      tlp_data_fifo_burst_we_r(0) <= tlp_data_fifo_we_r and opkt_burst_we_in;
      for i_v in 0 to BURST_LATENCY-2 loop
        tlp_data_fifo_burst_we_r(i_v+1) <= tlp_data_fifo_burst_we_r(i_v);
      end loop;
      
      if (PCIE_FORCE_MAX_RW_LENGTH = 1) then
        pcie_max_size_v := i2s(PCIE_MAX_RW_LENGTH, PCIE_RW_LENGTH_WIDTH);
      else
        if (opkt_is_write_in = '1') then
          pcie_max_size_v := pcie_max_payload_size_r;
        else
          pcie_max_size_v := pcie_max_rd_size_r;
        end if;
      end if;
      
--      pkt_part_cnt_first_inc_v := '0';
--      pkt_part_cnt_inc_v := '0';
      
      opkt_length_v := opkt_length_r;
      tlp_hdri_not_qword_aligned_v := tlp_hdri_not_qword_aligned_r;
      
      hdr_done_v := hdr_done_r;
      case hdr_wr_state_r is
        when WAIT_HDR =>
          if (((opkt_we_in = '1') or (opkt_burst_we_in = '1')) and (hdr_done_r = '0') and (opkt_ready_r = '0')) then
            opkt_addr_r <= opkt_addr_in;
            opkt_length_left_r <= opkt_length_in;
            tlp_hdri_not_qword_aligned_v := tlp_hdri_not_qword_aligned;
            
            if (tlp_hdri_not_qword_aligned = '0') then
              opkt_wdata_req_r <= '1';
            end if;
            
            if (opkt_is_rdata_in = '0') then
              addr_to_limit_r <= "1000000000000" - opkt_addr_in(11 downto 0); -- 4kb boundary
              hdr_wr_state_r <= HDR_IS_RW_REQ;
            else
              addr_to_limit_r <= "0000010000000" - opkt_addr_in(6 downto 0); -- read completion boundary
--              first_pkt_part_r <= '1';
              data_done_r <= '0';
              hdr_wr_state_r <= HDR_IS_RDATA;
            end if;
            
            tlp_hdri_is_write_r <= opkt_is_write_in;
            tlp_hdri_is_read_req_r <= opkt_is_read_req_in;
            tlp_hdri_is_rdata_r <= opkt_is_rdata_in;
            tlp_hdri_req_id_r <= opkt_req_id_in;
            tlp_hdri_tag_r <= opkt_tag_in;
            tlp_hdri_addr_size_r <= tlp_hdri_addr_size;
          end if;
--          hdr_done_v := '0';
          tlp_new_packet_r <= '1';
          
        when HDR_IS_RDATA =>
          if (tlp_header_fifo_full = '0') then
            if (opkt_length_left_r > addr_to_limit_r) then
              opkt_length_v := addr_to_limit_r;
              opkt_length_left_r <= opkt_length_left_r - addr_to_limit_r;
              
              if (tlp_header_fifo_we_r = '1') then
                opkt_addr_r <= opkt_addr_r + addr_to_limit_r;
              end if;
              
              addr_to_limit_r <= pcie_max_payload_size_r;
              
--               if (first_pkt_part_r = '1') then
--                 pkt_part_cnt_first_inc_v := '1';
--                 add_pkt_parts_first_v := '1';
--               else
--                 pkt_part_cnt_inc_v := '1';
--               end if;
              
--              first_pkt_part_r <= '0';
              tlp_header_fifo_we_r <= '1';
              hdr_done_v := '1';
              hdr_wr_state_r <= WAIT_DATA_WRITE;
              hdr_wr_return_state_r <= HDR_IS_RDATA;
            else
--              add_pkt_parts_v := '1';
              opkt_length_v := opkt_length_left_r;
              tlp_header_fifo_we_r <= '1';
              hdr_done_v := '1';
              hdr_wr_state_r <= WAIT_HDR;
            end if;
          end if;
        
        when WAIT_DATA_WRITE =>
          if (data_done_r = '1') then
            data_done_r <= '0';
            tlp_hdri_not_qword_aligned_v := tlp_hdri_not_qword_aligned;
            hdr_wr_state_r <= hdr_wr_return_state_r;
          end if;
          
--         when HDR_IS_RW_REQ_0 =>
--           if (opkt_length_left_r > addr_to_limit_r) then
--             hdr_wr_state_r <= HDR_IS_RW_REQ_1;
--           else
--             hdr_wr_state_r <= HDR_IS_RW_REQ_2;
--           end if;
        
        when HDR_IS_RW_REQ =>
          if (tlp_header_fifo_full = '0') then
            if ((opkt_length_left_r > addr_to_limit_r) or (opkt_length_left_r > pcie_max_size_v)) then
              if ((pcie_max_size_v <= addr_to_limit_r) or (addr_to_limit_r = 0)) then
                opkt_length_v := pcie_max_size_v;
                opkt_length_left_r <= opkt_length_left_r - pcie_max_size_v;
                if (tlp_header_fifo_we_r = '1') then
                  opkt_addr_r <= opkt_addr_r + pcie_max_size_v;
                end if;
                if (addr_to_limit_r = 0) then
                  addr_to_limit_r <= "1000000000000";
                else
                  addr_to_limit_r <= addr_to_limit_r - pcie_max_size_v;
                end if;
              else
                opkt_length_v := addr_to_limit_r;
                opkt_length_left_r <= opkt_length_left_r - addr_to_limit_r;
                addr_to_limit_r <= "1000000000000";
                if (tlp_header_fifo_we_r = '1') then
                  opkt_addr_r <= opkt_addr_r + addr_to_limit_r;
                end if;
              end if;
              
              if (opkt_is_write_in = '1') then
                data_done_r <= '0';
                hdr_wr_state_r <= WAIT_DATA_WRITE;
                hdr_wr_return_state_r <= HDR_IS_RW_REQ;
              end if;
            else
              hdr_wr_state_r <= WAIT_HDR;
              opkt_length_v := opkt_length_left_r;
--              if (tlp_new_packet_r = '0') then
--                opkt_addr_r <= opkt_addr_r + opkt_length_r;
--              end if;
--              if (opkt_is_read_req_in = '1') then
--                opkt_ready_r <= '1';
--              end if;
              hdr_done_v := '1';
            end if;
            
            if (tlp_new_packet_r = '0') then
              if (addr_to_limit_r < opkt_length_r) then
                addr_to_limit_r <= "1000000000000";
              else
                addr_to_limit_r <= addr_to_limit_r - opkt_length_r;
              end if;
              
              opkt_length_left_r <= opkt_length_left_r - opkt_length_r;
              opkt_addr_r <= opkt_addr_r + opkt_length_r;
            end if;
            
            if (opkt_is_read_req_in = '0') then
              hdr_done_v := '1';
            end if;
            
            tlp_header_fifo_we_r <= '1';
            tlp_new_packet_r <= '0';
          end if;
        
--         when HDR_IS_RW_REQ_1 =>
--           if (tlp_header_fifo_full = '0') then
--             if (opkt_length_left_r > pcie_max_size_v) then
--               opkt_length_v := pcie_max_size_v;
--               opkt_length_left_r <= opkt_length_left_r - pcie_max_size_v;
--               opkt_addr_r <= opkt_addr_r + pcie_max_size_v;
--               tlp_header_fifo_we_r <= '1';
--             else
--               opkt_length_v := opkt_length_left_r;
--               tlp_header_fifo_we_r <= '1';
--               hdr_done_v := '1';
--               hdr_done_r <= '1';
--               hdr_wr_state_r <= WAIT_HDR;
--             end if;
--           end if;
      end case;
      
      hdr_done_r <= hdr_done_v;
      opkt_length_r <= opkt_length_v;
      tlp_hdri_not_qword_aligned_r <= tlp_hdri_not_qword_aligned_v;
      
      if (tlp_hdri_not_qword_aligned_v = '1') then
        if ((tlp_hdri_addr_size = '0') or (opkt_is_rdata_in = '1')) then
          tlp_first_empty_part_cnt_v := "11";
        
          if (opkt_length_v(1 downto 0) = 0) then
            case opkt_length_v(3 downto 2) is
              when "00" =>
                tlp_last_empty_part_cnt_v := "01";
              when "01" =>
                tlp_last_empty_part_cnt_v := "00";
              when "10" =>
                tlp_last_empty_part_cnt_v := "11";
              when others => --"11" =>
                tlp_last_empty_part_cnt_v := "10";
            end case;
          else
            case opkt_length_v(3 downto 2) is
              when "00" =>
                tlp_last_empty_part_cnt_v := "00";
              when "01" =>
                tlp_last_empty_part_cnt_v := "11";
              when "10" =>
                tlp_last_empty_part_cnt_v := "10";
              when others => --"11" =>
                tlp_last_empty_part_cnt_v := "01";
            end case;
          end if;
        else
          tlp_first_empty_part_cnt_v := "01";
        
          if (opkt_length_v(1 downto 0) = 0) then
            case opkt_length_v(3 downto 2) is
              when "00" =>
                tlp_last_empty_part_cnt_v := "11";
              when "01" =>
                tlp_last_empty_part_cnt_v := "10";
              when "10" =>
                tlp_last_empty_part_cnt_v := "01";
              when others => --"11" =>
                tlp_last_empty_part_cnt_v := "00";
            end case;
          else
            case opkt_length_v(3 downto 2) is
              when "00" =>
                tlp_last_empty_part_cnt_v := "10";
              when "01" =>
                tlp_last_empty_part_cnt_v := "01";
              when "10" =>
                tlp_last_empty_part_cnt_v := "00";
              when others => --"11" =>
                tlp_last_empty_part_cnt_v := "11";
            end case;
          end if;
        end if;
      
      else
        tlp_first_empty_part_cnt_v := "00";
        
        if (opkt_length_v(1 downto 0) = 0) then
          case opkt_length_v(3 downto 2) is
            when "00" =>
              tlp_last_empty_part_cnt_v := "00";
            when "01" =>
              tlp_last_empty_part_cnt_v := "11";
            when "10" =>
              tlp_last_empty_part_cnt_v := "10";
            when others => --"11" =>
              tlp_last_empty_part_cnt_v := "01";
           end case;
        else
          case opkt_length_v(3 downto 2) is
            when "00" =>
              tlp_last_empty_part_cnt_v := "11";
            when "01" =>
              tlp_last_empty_part_cnt_v := "10";
            when "10" =>
              tlp_last_empty_part_cnt_v := "01";
            when others => --"11" =>
              tlp_last_empty_part_cnt_v := "00";
          end case;
        end if;
      end if;      
      
--       if (pkt_part_cnt_first_inc_v = '1') then
--         if (add_pkt_parts_first_v = '1') then
--           pkt_part_cnt_r(0) <= x"01";
--         else
--           pkt_part_cnt_r(s2i(pkt_part_r)) <= x"01";
--         end if;
--       elsif (pkt_part_cnt_inc_v = '1') then
--         pkt_part_cnt_r(s2i(pkt_part_r)) <= pkt_part_cnt_r(s2i(pkt_part_r)) + 1;
--       end if;
      
--       if (add_pkt_parts_first_v = '1') then
--         tlp_first_empty_part_cnt_r(0) <= tlp_first_empty_part_cnt_v;
--         tlp_last_empty_part_cnt_r(0) <= tlp_last_empty_part_cnt_v;
--         pkt_part_r <= "01";
--       elsif (add_pkt_parts_v = '1') then
--         tlp_first_empty_part_cnt_r(s2i(pkt_part_r)) <= tlp_first_empty_part_cnt_v;
--         tlp_last_empty_part_cnt_r(s2i(pkt_part_r)) <= tlp_last_empty_part_cnt_v;
--         pkt_part_r <= pkt_part_r + 1;
--       end if;
      
      data_done_v := '0';
      
      case tlp_part_state_r is
        when WAIT_OPKT =>
          if ((hdr_done_v = '1') and (opkt_is_read_req_in = '0')) then
            if (tlp_data_fifo_full = '0') then
              if (tlp_first_empty_part_cnt_v > 0) then
                tlp_part_state_r <= WRITE_FIRST_EMPTY_PARTS;
                tlp_data_fifo_we_r <= '1';
                tlp_empty_part_cnt_r <= tlp_first_empty_part_cnt_v;
                if (tlp_first_empty_part_cnt_v >= 2) then
                  tlp_last_part_half_empty_r <= '1';
                end if;
              else
                if (opkt_length_v <= HIBI_DATA_BYTE_WIDTH) then
                  tlp_part_state_r <= LAST_PART;
                else
                  tlp_part_state_r <= FIRST_PART;
                end if;
                tlp_data_part_cnt_r <= opkt_length_v - HIBI_DATA_BYTE_WIDTH;
                opkt_ready_r <= '1';
              end if;
            end if;
          end if;
        
        when BURST_DELAY =>
          if (tlp_data_fifo_burst_we_r(BURST_LATENCY-2) = '0') then
            tlp_part_state_r <= WRITE_LAST_EMPTY_PARTS;
          end if;
        
        when WRITE_FIRST_EMPTY_PARTS =>
          if (tlp_empty_part_cnt_r = 1) then
            if (opkt_length_v <= HIBI_DATA_BYTE_WIDTH) then
              tlp_part_state_r <= LAST_PART;
            else
              tlp_part_state_r <= FIRST_PART;
            end if;
            tlp_data_part_cnt_r <= opkt_length_v - HIBI_DATA_BYTE_WIDTH;
          else
            tlp_data_fifo_we_r <= '1';
          end if;
          tlp_empty_part_cnt_r <= tlp_empty_part_cnt_r - 1;
          
        when WRITE_LAST_EMPTY_PARTS =>
          if (tlp_empty_part_cnt_r = 0) then
            tlp_part_state_r <= WAIT_OPKT;
          else
            tlp_data_fifo_we_r <= '1';
          end if;
          tlp_empty_part_cnt_r <= tlp_empty_part_cnt_r - 1;
        
        when FIRST_PART =>
          if (((opkt_we_in = '1') or (opkt_burst_we_in = '1')) and (opkt_ready_r = '1')) then
            tlp_data_fifo_we_r <= '1';
            
            if (tlp_data_part_cnt_r <= HIBI_DATA_BYTE_WIDTH) then
              tlp_part_state_r <= LAST_PART;
            else
              tlp_part_state_r <= MIDDLE_PART;
            end if;
            
            tlp_data_part_cnt_r <= tlp_data_part_cnt_r - HIBI_DATA_BYTE_WIDTH;
          end if;
          opkt_ready_r <= '1';
        
        when MIDDLE_PART =>
          if (((opkt_we_in = '1') or (opkt_burst_we_in = '1')) and (opkt_ready_r = '1')) then
            tlp_data_fifo_we_r <= '1';
            
            if (tlp_data_part_cnt_r <= HIBI_DATA_BYTE_WIDTH) then
              tlp_part_state_r <= LAST_PART;
            end if;
            
            tlp_data_part_cnt_r <= tlp_data_part_cnt_r - HIBI_DATA_BYTE_WIDTH;
          end if;
          opkt_ready_r <= '1';
          
        when LAST_PART =>
          if (((opkt_we_in = '1') or (opkt_burst_we_in = '1')) and (opkt_ready_r = '1')) then
            tlp_data_fifo_we_r <= '1';
            
            if (tlp_last_empty_part_cnt_v > 0) then
              tlp_empty_part_cnt_r <= tlp_last_empty_part_cnt_v;
              if (opkt_burst_we_in = '0') then
                tlp_part_state_r <= WRITE_LAST_EMPTY_PARTS;
              else
                tlp_part_state_r <= BURST_DELAY;
              end if;
            else
              tlp_part_state_r <= WAIT_OPKT;
            end if;
            data_done_v := '1';
          else
            opkt_ready_r <= '1';
          end if;
      end case;
      
      if (hdr_done_v = '1') then
        if (opkt_is_read_req_in = '1') then
          hdr_done_r <= '0';
          opkt_ready_r <= '1';
        elsif (data_done_v = '1') then
          hdr_done_r <= '0';
          opkt_ready_r <= '1';
        end if;
      end if;
    end if;
  end process;
  
  irq_fifo : entity work.alt_fifo_dc_dw
	generic map ( DATA_WIDTH => PCIE_IRQ_WIDTH+PCIE_TC_WIDTH,
                FIFO_LENGTH => 2,
                CNT_WIDTH => 1,
                
                RDATA_WIDTH => PCIE_IRQ_WIDTH+PCIE_TC_WIDTH,
                RCNT_WIDTH => 1 )
  
  port map (
		rclk => clk_pcie,
		wclk => clk,
    rst_n => rst_n,
    
    wdata_in	=> irq_wdata,
		re_in	=> pcie_irq_re_r,
		we_in	=> pcie_irq_in,
		rempty_out => pcie_irq_empty,
		wfull_out	=> pcie_irq_full_out,
		rdata_out => irq_rdata );
  
  irq_wdata(PCIE_IRQ_WIDTH-1 downto 0) <= pcie_irq_number_in;
  irq_wdata(PCIE_IRQ_WIDTH+PCIE_TC_WIDTH-1 downto PCIE_IRQ_WIDTH) <= pcie_irq_tc_in;
  
  app_msi_num_out <= irq_rdata(PCIE_IRQ_WIDTH-1 downto 0);
  app_msi_tc_out <= irq_rdata(PCIE_IRQ_WIDTH+PCIE_TC_WIDTH-1 downto PCIE_IRQ_WIDTH);
  
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
		rclk => clk_pcie,
		wclk => clk,
    rst_n => rst_n,
    
    wdata_in	=> tlp_header_fifo_wdata,
		re_in	=> tlp_header_fifo_re_r,
		we_in	=> tlp_header_fifo_we_r,
		rempty_out => tlp_header_fifo_empty,
		wfull_out	=> tlp_header_fifo_full,
		rdata_out => tlp_header_fifo_rdata,
		two_d_out => tlp_header_fifo_two_d,
    wcount_out => tlp_header_fifo_cnt );
  
  tlp_header_fifo_wdata(TLP_HDR_LENGTH_U downto TLP_HDR_LENGTH_L) <= opkt_length_r;
  tlp_header_fifo_wdata(TLP_HDR_TAG_U downto TLP_HDR_TAG_L) <= tlp_hdri_tag_r;
  tlp_header_fifo_wdata(TLP_HDR_IS_WRITE_U) <= tlp_hdri_is_write_r;
  tlp_header_fifo_wdata(TLP_HDR_IS_READ_REQ_U) <= tlp_hdri_is_read_req_r;
  tlp_header_fifo_wdata(TLP_HDR_IS_RDATA_U) <= tlp_hdri_is_rdata_r;
--  tlp_header_fifo_wdata(TLP_HDR_RELAX_ORD_U) <= opkt_relax_ord_in;
  tlp_header_fifo_wdata(TLP_HDR_ADDR_SIZE_U) <= tlp_hdri_addr_size_r;
  tlp_header_fifo_wdata(TLP_HDR_NOT_QWORD_ALIGNED_U) <= tlp_hdri_not_qword_aligned;
  tlp_header_fifo_wdata(TLP_HDR_LAST_PART_HALF_EMPTY_U) <= tlp_last_part_half_empty_r;
  tlp_header_fifo_wdata(TLP_HDR_REQ_ID_U downto TLP_HDR_REQ_ID_L) <= tlp_hdri_req_id_r;
  tlp_header_fifo_wdata(TLP_HDR_EXTRA_DATA_U downto TLP_HDR_EXTRA_DATA_L) <= tlp_hdri_extra_data;
  
  tlp_hdro_length <= tlp_header_fifo_rdata(TLP_HDR_LENGTH_U downto TLP_HDR_LENGTH_L);
  tlp_hdro_tag <= tlp_header_fifo_rdata(TLP_HDR_TAG_U downto TLP_HDR_TAG_L);
  tlp_hdro_is_write <= tlp_header_fifo_rdata(TLP_HDR_IS_WRITE_U);
  tlp_hdro_is_read_req <= tlp_header_fifo_rdata(TLP_HDR_IS_READ_REQ_U);
  tlp_hdro_is_rdata <= tlp_header_fifo_rdata(TLP_HDR_IS_RDATA_U);
--  tlp_hdro_relax_ord <= tlp_header_fifo_rdata(TLP_HDR_RELAX_ORD_U);
  tlp_hdro_addr_size <= tlp_header_fifo_rdata(TLP_HDR_ADDR_SIZE_U);
  tlp_hdro_not_qword_aligned <= tlp_header_fifo_rdata(TLP_HDR_NOT_QWORD_ALIGNED_U);
  tlp_hdro_last_part_half_empty <= tlp_header_fifo_rdata(TLP_HDR_LAST_PART_HALF_EMPTY_U);
  tlp_hdro_req_id <= tlp_header_fifo_rdata(TLP_HDR_REQ_ID_U downto TLP_HDR_REQ_ID_L);
  tlp_hdro_extra_data <= tlp_header_fifo_rdata(TLP_HDR_EXTRA_DATA_U downto TLP_HDR_EXTRA_DATA_L);
  
  -----------------------------------------------------------------------------------------
  -- TLP data fifo
  -----------------------------------------------------------------------------------------
  -- input data:  pcie_rx_data_in
  -- input write: tlp_header_fifo_we
  -- output data: tlp_header_fifo_rdata
  -- output read: tlp_header_fifo_re
  -----------------------------------------------------------------------------------------
  
  tlp_data_fifo : entity work.alt_fifo_dc_dw
	generic map ( DATA_WIDTH => HIBI_DATA_WIDTH,
                FIFO_LENGTH => TLP_DATA_FIFO_SIZE,
                CNT_WIDTH => TLP_DATA_FIFO_CNT_WIDTH,
                
                RDATA_WIDTH => PCIE_DATA_WIDTH,
                RCNT_WIDTH => TLP_DATA_FIFO_RCNT_WIDTH )
  
  port map (
		rclk => clk_pcie,
		wclk => clk,
    rst_n => rst_n,
    wdata_in => opkt_data_in, --tlp_data_fifo_wdata_r,
		re_in	=> tlp_data_fifo_re_r,
		we_in	=> tlp_data_fifo_we,
		rempty_out => tlp_data_fifo_empty,
		one_d_out => tlp_data_fifo_one_d,
    wfull_out	=> tlp_data_fifo_full,
		rdata_out => tlp_data_fifo_rdata,
		wcount_out => tlp_data_fifo_wcnt,
    rcount_out => tlp_data_fifo_rcnt );
  
  
end rtl;
