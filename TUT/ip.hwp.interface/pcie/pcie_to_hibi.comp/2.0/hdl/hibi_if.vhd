-------------------------------------------------------------------------------
-- Title      : HIBI interface
-- Project    : Funbase
-------------------------------------------------------------------------------
-- File       : hibi_if.vhd
-- Author     : Juha Arvio
-- Company    : TTY
-- Last update: 27.05.2011
-- Version    : 0.9
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: a HIBI interface for PCIE to HIBI adapter
--
-------------------------------------------------------------------------------
-- Copyright (c) 2011
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 15.10.2010   0.1     arvio     Created
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

entity hibi_if is

  generic ( HIBI_DATA_WIDTH       : integer := 32;
            HIBI_COM_WIDTH : integer := 3;
            HIBI_COM_WR     : std_logic_vector(15 downto 0) := x"0000";
            HIBI_COM_RD     : std_logic_vector(15 downto 0) := x"0000";
            HIBI_COM_MSG_WR : std_logic_vector(15 downto 0) := x"0000";
--            HIBI_COM_MSG_RD : std_logic_vector(15 downto 0) := x"0000";
            
            HIBI_ADDR_SPACE_WIDTH : integer := 11;
            HIBI_RW_LENGTH_WIDTH  : integer := 16;
            
            PCIE_DATA_WIDTH       : integer := 128;
            PCIE_ADDR_WIDTH       : integer := 32;
            PCIE_LOWER_ADDR_WIDTH : integer := 7;
            PCIE_RW_LENGTH_WIDTH  : integer := 13;
            PCIE_ID_WIDTH         : integer := 16;
            PCIE_FUNC_WIDTH       : integer := 3;
--            PKT_TAG_WIDTH         : integer := 9;
            PCIE_TAG_WIDTH  : integer := 6;
            ADDR_TO_LIMIT_WIDTH : integer := 12;
            
            PCIE_CPL_LENGTH_MIN : integer := 128;
            
--            HDMA_CHANS_ADDR_SPACE_WIDTH : integer := 7;
            
            P2H_ADDR_SPACES      : integer := 4;
            P2H_HDMA_ADDR_SPACES : integer := 2;
            
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
            
            H2P_WR_CHANS : integer := 16;
            H2P_RD_CHANS : integer := 16;
            P2H_WR_CHANS : integer := 128;
            P2H_RD_CHANS : integer := 32 );
    
  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    
    init_done_out : out std_logic;
    
    ipkt_is_write_in     : in std_logic;
    ipkt_is_read_req_in  : in std_logic;
    ipkt_is_rdata_in     : in std_logic;
--    ipkt_relax_ord_in    : in std_logic;
    ipkt_addr_in         : in std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    ipkt_addr_to_limit_in : in std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
--    ipkt_addr_size_in    : in std_logic;
    ipkt_length_in      : in std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
--    ipkt_byte_cnt_in    : in std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
    ipkt_req_id_in      : in std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--    ipkt_cmp_id_in      : in std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
    ipkt_tag_in         : in std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
    
    ipkt_valid_in      : in std_logic;
--    ipkt_one_d_in      : in std_logic;
--    ipkt_first_part_in : in std_logic;
--    ipkt_last_part_in  : in std_logic;
    ipkt_re_out        : out std_logic;
    ipkt_data_in       : in std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    
    opkt_is_write_out    : out std_logic;
    opkt_is_read_req_out : out std_logic;
    opkt_is_rdata_out    : out std_logic;
--    opkt_relax_ord_out   : out std_logic;
    opkt_addr_out        : out std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
--    opkt_addr_size_out   : out std_logic;
    opkt_length_out      : out std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
--    opkt_byte_cnt_out    : out std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
    opkt_req_id_out      : out std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--    opkt_cmp_id_out      : out std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--    opkt_func_id_out     : out std_logic_vector(PCIE_FUNC_WIDTH-1 downto 0);
    opkt_tag_out         : out std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
    
--    opkt_wdata_req_in    : in std_logic;
    
    opkt_ready_in       : in std_logic;
--    opkt_first_part_out : out std_logic;
    opkt_we_out         : out std_logic;
    opkt_burst_we_out   : out std_logic;
    opkt_data_out       : out std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    
    irq_out : out std_logic;
    irq_ack_in : in std_logic;
    
    hibi_addr_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_data_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_comm_in  : in  std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_empty_in : in  std_logic;
    hibi_re_out   : out std_logic;

    hibi_addr_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_data_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_comm_out : out std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_full_in  : in  std_logic;
    hibi_we_out   : out std_logic;

    hibi_msg_addr_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_data_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_comm_in  : in  std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_msg_empty_in : in  std_logic;
    hibi_msg_re_out   : out std_logic;

    hibi_msg_data_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_addr_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_comm_out : out std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_msg_full_in  : in  std_logic;
    hibi_msg_we_out   : out std_logic );

end hibi_if;

architecture rtl of hibi_if is

  function max(L : integer; R : integer) return integer is
  begin
    if L > R then
      return L;
    else
      return R;
    end if;
  end;
  
  function min(L : integer; R : integer) return integer is
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
  
  constant HCOM_WR : std_logic_vector(HIBI_COM_WIDTH-1 downto 0) := HIBI_COM_WR(HIBI_COM_WIDTH-1 downto 0);
  constant HCOM_RD : std_logic_vector(HIBI_COM_WIDTH-1 downto 0) := HIBI_COM_RD(HIBI_COM_WIDTH-1 downto 0);
  constant HCOM_MSG_WR : std_logic_vector(HIBI_COM_WIDTH-1 downto 0) := HIBI_COM_MSG_WR(HIBI_COM_WIDTH-1 downto 0);
--  constant HCOM_MSG_RD : std_logic_vector(HIBI_COM_WIDTH-1 downto 0) := HIBI_COM_MSG_RD(HIBI_COM_WIDTH-1 downto 0);
  
  constant HIBI_LOWER_ADDR_RANGE : integer := 8;
  
  constant HDMA_WR_REQ_OFFSET : std_logic_vector(7 downto 0) := x"22";
  constant HDMA_RD_REQ_OFFSET : std_logic_vector(7 downto 0) := x"21";
--  constant HDMA_WR_CONF_OFFSET : std_logic_vector(1 downto 0) := "10";
--  constant HDMA_RD_CONF_OFFSET : std_logic_vector(1 downto 0) := "01";
  
  constant HDMA_RW_AMOUNT_WIDTH : integer := 20;
  constant HIBI_DATA_BYTE_WIDTH : integer := HIBI_DATA_WIDTH/8;
  
  constant HDMA_CHANNELS_WIDTH : integer := 8;
  constant HDMA_CONF_OFFSET_WIDTH : integer := HDMA_CHANNELS_WIDTH + 2;
  constant HDMA_BASE_ADDR_WIDTH : integer := HIBI_DATA_WIDTH - HDMA_CONF_OFFSET_WIDTH;
  
  
  constant P2H_ADDR_SPACES_WIDTH : integer := log2_ceil(P2H_ADDR_SPACES-1);
  constant P2H_HDMA_ADDR_SPACES_WIDTH : integer := log2_ceil(P2H_HDMA_ADDR_SPACES-1);
  
  constant PCIE_CPL_LENGTH_MIN_WIDTH : integer := log2_ceil(PCIE_CPL_LENGTH_MIN-1);
  constant PCIE_CPL_DW_LENGTH_MIN : integer := PCIE_CPL_LENGTH_MIN/4;
  constant PCIE_CPL_HIBI_LENGTH_MIN : integer := PCIE_CPL_LENGTH_MIN/(HIBI_DATA_WIDTH/8);
  constant PCIE_CPL_HIBI_LENGTH_MIN_WIDTH : integer := log2_ceil(PCIE_CPL_HIBI_LENGTH_MIN-1);
  constant PCIE_CPL_PCIE_LENGTH_MIN : integer := PCIE_CPL_LENGTH_MIN/(PCIE_DATA_WIDTH/8);
  constant PCIE_CPL_PCIE_LENGTH_MIN_WIDTH : integer := log2_ceil(PCIE_CPL_PCIE_LENGTH_MIN-1);
  
  constant PCIE_PACKETS_WIDTH : integer := PCIE_RW_LENGTH_WIDTH - PCIE_CPL_LENGTH_MIN_WIDTH;
  
  constant OPKT_BUFFERS : integer := max(H2P_WR_CHANS, P2H_RD_CHANS);
  constant OPKT_BUFFERS_WIDTH : integer := log2_ceil(OPKT_BUFFERS-1);
  constant OPKT_BUF_PARTS : integer := 2;
  
  constant OPKT_BUF_PARTS_WIDTH : integer := log2_ceil(OPKT_BUF_PARTS-1);
  constant OPKT_BUF_WIDTH : integer := log2_ceil(PCIE_CPL_HIBI_LENGTH_MIN*OPKT_BUF_PARTS-1);
  
  constant OPKT_TYPES_WIDTH : integer := 1;
  constant OPKT_P2H_TYPE : std_logic_vector(OPKT_TYPES_WIDTH-1 downto 0) := "0";
  constant OPKT_H2P_TYPE : std_logic_vector(OPKT_TYPES_WIDTH-1 downto 0) := "1";
  
  constant GEN_CONF_BASE_OFFSET        : std_logic_vector(63 downto 0) := x"0000000000000000";
  constant H2P_RD_CONF_BASE_OFFSET     : std_logic_vector(63 downto 0) := x"0000000000000100";
  constant H2P_WR_CONF_BASE_OFFSET     : std_logic_vector(63 downto 0) := x"0000000000000200";
  constant P2H_ACK_BASE_OFFSET         : std_logic_vector(63 downto 0) := x"0000000000000300";
  constant P2H_RD_RET_ADDR_BASE_OFFSET : std_logic_vector(63 downto 0) := x"0000000000000400";
  
  constant H2P_WR_CHANS_WIDTH : integer := log2_ceil(H2P_WR_CHANS-1);
  constant H2P_RD_CHANS_WIDTH : integer := log2_ceil(H2P_RD_CHANS-1);
  constant H2P_CHANS : integer := max(H2P_WR_CHANS, H2P_RD_CHANS);
  constant H2P_CHANS_WIDTH : integer := log2_ceil(H2P_CHANS-1);
  
  constant HDMA_REQ_CNT_WIDTH : integer := log2_ceil(HDMA_REQS_MIN);
  
  constant HDMA_CHAN_OFFSET_WIDTH : integer := 7;
  
  constant HDMA_ACK_BASE_OFFSET : std_logic_vector(1 downto 0) := "11";
  
  constant P2H_RD_CHANS_WIDTH : integer := log2_ceil(P2H_RD_CHANS-1);
  
  constant P2H_LOWER_ADDR_L : integer := 0;
  constant P2H_LOWER_ADDR_U : integer := P2H_LOWER_ADDR_L + PCIE_LOWER_ADDR_WIDTH - 1;
--  constant P2H_ADDR_L : integer := P2H_LOWER_ADDR_L;
--  constant P2H_ADDR_U : integer := P2H_ADDR_L + HIBI_DATA_WIDTH - 1;
  constant P2H_TOTAL_AMOUNT_L : integer := P2H_LOWER_ADDR_U + 1;
  constant P2H_TOTAL_AMOUNT_U : integer := P2H_TOTAL_AMOUNT_L + HIBI_RW_LENGTH_WIDTH - 1;
  constant P2H_PARTS_LEFT_L : integer := P2H_TOTAL_AMOUNT_U + 1;
  constant P2H_PARTS_LEFT_U : integer := P2H_PARTS_LEFT_L + HIBI_RW_LENGTH_WIDTH - PCIE_LOWER_ADDR_WIDTH - 1;
  constant P2H_REQ_ID_L : integer := P2H_PARTS_LEFT_U + 1;
  constant P2H_REQ_ID_U : integer := P2H_REQ_ID_L + PCIE_ID_WIDTH - 1;
  constant P2H_TAG_L : integer := P2H_REQ_ID_U + 1;
  constant P2H_TAG_U : integer := P2H_TAG_L + PCIE_TAG_WIDTH - 1;
  
  constant P2H_RCONF_WIDTH : integer := P2H_TAG_U+1;
  
  constant H2P_CONF_STATE_WIDTH : integer := 2;
  
--  constant H2P_ADDR_WIDTH : integer := 32;
--  constant H2P_RW_AMOUNT_WIDTH : integer := 16;
  
  constant H2P_ADDR_L : integer := 0;
  constant H2P_ADDR_U : integer := H2P_ADDR_L + PCIE_ADDR_WIDTH - 1;
  constant H2P_TOTAL_AMOUNT_L   : integer := H2P_ADDR_U + 1;
  constant H2P_TOTAL_AMOUNT_U   : integer := H2P_TOTAL_AMOUNT_L + HIBI_RW_LENGTH_WIDTH - 1;
  constant H2P_CONF_STARTED_L : integer := H2P_TOTAL_AMOUNT_U + 1;
  constant H2P_CONF_STARTED_U : integer := H2P_CONF_STARTED_L;
  constant H2P_CONF_DONE_L : integer := H2P_CONF_STARTED_U + 1;
  constant H2P_CONF_DONE_U : integer := H2P_CONF_DONE_L;
  constant H2P_PARTS_LEFT_L : integer := H2P_CONF_DONE_U + 1;
  constant H2P_PARTS_LEFT_U : integer := H2P_PARTS_LEFT_L + HIBI_RW_LENGTH_WIDTH - PCIE_LOWER_ADDR_WIDTH - 1;
  constant H2P_RET_ADDR_L : integer := H2P_CONF_DONE_U + 1;
  constant H2P_RET_ADDR_U : integer := H2P_RET_ADDR_L + HIBI_DATA_WIDTH - 1;
  
  constant H2P_WCONF_WIDTH : integer := H2P_PARTS_LEFT_U + 1;
  constant H2P_RCONF_WIDTH : integer := H2P_RET_ADDR_U + 1;
  constant H2P_CONF_WIDTH : integer := max(H2P_WCONF_WIDTH, H2P_RCONF_WIDTH);
  
  signal hibi_wdata_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_false_wdata_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_waddr_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_comm_r : std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
  signal hibi_we_r : std_logic;
  signal hibi_re_r : std_logic;
  signal hibi_false_wr_r : std_logic;
  signal hibi_false_wr_type_r : std_logic;
  
  signal hibi_msg_wdata_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_msg_waddr_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_msg_we_r : std_logic;
  signal hibi_msg_rdata_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_msg_raddr_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_msg_empty_r : std_logic;
  signal hibi_msg_re_r : std_logic;
  
  signal hibi_msg_re_stall_r : std_logic;
  signal hibi_msg_re : std_logic;
  
  signal p2h_req_tx_we_r : std_logic;
  signal p2h_req_tx_wdata_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal p2h_req_tx_waddr_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  
  signal hibi_wr_length_r : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
  
  signal hdma_wr_r : std_logic;
  signal hibi_single_read_r : std_logic;
  
  
  type hibi_tx_state_t is (WAIT_PACKET, P2H_REQ_WAIT, OPKT_BUF_WAIT_CONF, HDMA_WR_CONF_TX, HDMA_RD_CONF_TX, HIBI_WR_END_0, HIBI_WR_END_1, HIBI_WR);
  signal hibi_tx_state_r : hibi_tx_state_t;
  
  signal hdma_conf_sub_state_r : std_logic_vector(1 downto 0);
  
  type hibi_rdata_state_t is (WAIT_CONF, HIBI_SIMPLE_DMA_WR_CONF_RX, HIBI_SIMPLE_DMA_RD_CONF_RX);
  signal hibi_rdata_state_r : hibi_rdata_state_t;
  
  type h2p_req_state_t is (WAIT_H2P_REQ, WAIT_OPKT_BUF_RESERVE, WAIT_H2P_ACK_TX);
  signal h2p_req_state_r : h2p_req_state_t;
  
  type opkt_tx_state_t is (WAIT_OPKT_BUF, WAIT_FILLED_READ, OPKT_TX_DELAY, LOAD_OPKT_CONF, OPKT_TX);
  signal opkt_tx_state_r : opkt_tx_state_t;
  
  signal ipkt_re_r : std_logic;
  signal ipkt_valid_r : std_logic;
  
  signal p2h_req_init_done : std_logic;
  signal p2h_req_re_r : std_logic;
  signal p2h_req_ready : std_logic;
  signal p2h_req_rcomp_r : std_logic_vector(P2H_HDMA_ADDR_SPACES_WIDTH downto 0);
  signal p2h_req_offset : std_logic_vector(HDMA_CHANNELS_WIDTH-1 downto 0);
  signal p2h_req_tx : std_logic;
  signal p2h_req_tx_ready : std_logic;
  signal p2h_req_tx_hibi_dma_comp : std_logic_vector(P2H_HDMA_ADDR_SPACES_WIDTH downto 0);
  signal p2h_ack_rx : std_logic;
  signal p2h_ack_rx_valid : std_logic;
  signal p2h_ack_rx_hibi_dma_comp : std_logic_vector(P2H_HDMA_ADDR_SPACES_WIDTH downto 0);
  signal p2h_ack_rx_hibi_dma_offset : std_logic_vector(HDMA_CHANNELS_WIDTH-1 downto 0);
  
  
  signal opkt_buf_init_done : std_logic;
  
  signal opkt_buf_reserve : std_logic;
  signal opkt_buf_reserve_ready : std_logic;
  signal opkt_buf_reserve_index : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);

  signal p2h_buf_reserve_r : std_logic;
  signal h2p_buf_reserve_r : std_logic;
  signal p2h_buf_reserve_ready : std_logic;
  signal h2p_buf_reserve_ready : std_logic;
  
  signal opkt_tx_buf_done_r : std_logic;
--  signal opkt_tx_buf_done_index : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
  
  signal opkt_buf_conf_we : std_logic;
  signal opkt_buf_conf_ready : std_logic;
  signal opkt_buf_conf_type : std_logic_vector(OPKT_TYPES_WIDTH-1 downto 0);
  signal opkt_buf_conf_amount : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
  signal opkt_buf_conf_addr_to_limit : std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
  signal opkt_buf_conf_index : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
  
  signal buf_windex : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
  signal buf_windex_r : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
  
  signal p2h_buf_conf_we_r : std_logic;
  signal p2h_buf_conf_ready : std_logic;
  signal p2h_buf_conf_type_r : std_logic_vector(OPKT_TYPES_WIDTH-1 downto 0);
  signal p2h_buf_conf_amount_r : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
  signal p2h_buf_index_r : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
  
  signal h2p_buf_conf_we_r : std_logic;
  signal h2p_buf_conf_ready : std_logic;
  signal h2p_buf_conf_type_r : std_logic_vector(OPKT_TYPES_WIDTH-1 downto 0);
  signal h2p_buf_conf_amount_r : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
  signal h2p_buf_conf_addr_to_limit_r : std_logic_vector(ADDR_TO_LIMIT_WIDTH downto 0);
  signal h2p_buf_index_r : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
  
  
  signal opkt_buf_filled_re_r : std_logic;
  signal opkt_buf_filled_empty : std_logic;
  signal opkt_buf_filled_size : std_logic_vector(PCIE_CPL_HIBI_LENGTH_MIN_WIDTH downto 0);
  signal opkt_buf_filled_index : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
  signal opkt_buf_filled_amount : std_logic_vector(OPKT_BUF_PARTS_WIDTH downto 0);
  signal opkt_buf_filled_type : std_logic_vector(OPKT_TYPES_WIDTH-1 downto 0);
  
  
--  signal p2h_opkt_tx_buf_done_r : std_logic;
--  signal h2p_opkt_tx_buf_done_r : std_logic;
--  signal h2p_opkt_tx_buf_done_ready : std_logic;
  signal opkt_buf_index_r : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
--  signal h2p_opkt_tx_buf_done_index_r : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
  
  signal opkt_buf_we : std_logic;
  signal opkt_buf_wr_stall : std_logic;
  
  signal h2p_wconf_we_r : std_logic;
  signal h2p_wconf_we : std_logic;
  signal h2p_wconf_addr : std_logic_vector(H2P_WR_CHANS_WIDTH-1 downto 0);
  signal h2p_wconf_wdata : std_logic_vector(H2P_WCONF_WIDTH-1 downto 0);
  signal h2p_wconf_rdata : std_logic_vector(H2P_WCONF_WIDTH-1 downto 0);
  signal h2p_wconf_upd_we_r : std_logic;
  signal h2p_wconf_upd_wdata : std_logic_vector(H2P_WCONF_WIDTH-1 downto 0);
  signal h2p_wconf_upd_rdata : std_logic_vector(H2P_WCONF_WIDTH-1 downto 0);
  
  signal h2p_wconf_addr_rv : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal h2p_wconf_length_total_rv : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
  signal h2p_wconf_packets_left_rv : std_logic_vector(HIBI_RW_LENGTH_WIDTH-PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  signal h2p_wconf_started_rv : std_logic;
  signal h2p_wconf_done_rv : std_logic;
  
  signal h2p_rconf_we_r : std_logic;
  signal h2p_rconf_we : std_logic;
  signal h2p_rconf_addr : std_logic_vector(H2P_RD_CHANS_WIDTH-1 downto 0);
  signal h2p_rconf_wdata : std_logic_vector(H2P_RCONF_WIDTH-1 downto 0);
  signal h2p_rconf_rdata : std_logic_vector(H2P_RCONF_WIDTH-1 downto 0);
  signal h2p_rconf_upd_we_r : std_logic;
  signal h2p_rconf_upd_wdata : std_logic_vector(H2P_RCONF_WIDTH-1 downto 0);
  signal h2p_rconf_upd_rdata : std_logic_vector(H2P_RCONF_WIDTH-1 downto 0);
  
  signal h2p_rconf_addr_rv : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal h2p_rconf_total_amount_rv : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
  signal h2p_rconf_ret_addr_rv : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal h2p_rconf_started_rv : std_logic;
  signal h2p_rconf_done_rv : std_logic;
  
  signal h2p_rd_last_part_r : std_logic;
  
  signal h2p_wr_req_r : std_logic;
  signal h2p_rd_req_r : std_logic;
  signal hibi_msg_ret_addr_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal h2p_nack_r : std_logic;
  
  signal load_h2p_conf_state_r : std_logic;
  signal load_h2p_conf_state_d1_r : std_logic;
  signal h2p_conf_state_r : std_logic_vector(H2P_CONF_STATE_WIDTH-1 downto 0);
  signal h2p_conf_load_data_r : std_logic_vector(H2P_CONF_WIDTH-1 downto 0);
  signal h2p_conf_state_windex_r : std_logic_vector(H2P_CHANS_WIDTH downto 0);
  signal h2p_conf_state_wdata : std_logic_vector(H2P_CONF_STATE_WIDTH-1 downto 0);
  signal h2p_conf_state_we : std_logic;
  signal h2p_conf_state_we_r : std_logic;
  signal h2p_conf_state_rindex : std_logic_vector(H2P_CHANS_WIDTH downto 0);
  signal h2p_conf_state_rdata : std_logic_vector(H2P_CONF_STATE_WIDTH-1 downto 0);
  signal cur_h2p_chan_rd_r : std_logic;
  signal cur_h2p_chan_wr_r : std_logic;
  signal cur_h2p_chan_r : std_logic_vector(H2P_CHANS_WIDTH-1 downto 0);
  signal h2p_conf_state_init_done_r : std_logic;
  
  signal cur_h2p_rd_chan_r : std_logic_vector(H2P_CHANS_WIDTH-1 downto 0);
  
  
  signal h2p_ack_tx_we_r : std_logic;
  signal h2p_ack_tx_wdata : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal h2p_ack_tx_waddr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal h2p_req_ready_r : std_logic;
  
  signal opkt_buf_start_r : std_logic;
  signal opkt_buf_ready : std_logic;
  signal opkt_buf_re_r : std_logic;
  signal opkt_buf_rindex_r : std_logic_vector(OPKT_BUFFERS_WIDTH-1 downto 0);
  
  signal opkt_type_r : std_logic_vector(OPKT_TYPES_WIDTH-1 downto 0);
--  signal opkt_first_part_r : std_logic;
  signal opkt_tx_length_r : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
  signal opkt_tx_addr_r : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal opkt_tx_hibi_ret_addr_r : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
--  signal opkt_tx_lower_addr_r : std_logic_vector(PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  signal opkt_tx_length_total_r : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
  signal opkt_tx_packets_left_r : std_logic_vector(HIBI_RW_LENGTH_WIDTH-PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  signal opkt_tx_req_id_r : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--  signal opkt_tx_cpl_id_r : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal opkt_tx_tag_r : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
  
  signal opkt_tx_is_write_r : std_logic;
  signal opkt_tx_is_read_req_r : std_logic;
  signal opkt_tx_is_rdata_r : std_logic;
  signal opkt_tx_we_r : std_logic;
  
  signal h2p_rd_res_init_done_r : std_logic;
  signal h2p_rd_res_empty : std_logic;
  signal h2p_rd_res_re_r : std_logic;
  signal h2p_rd_res_we_r : std_logic;
  signal h2p_rd_res_we : std_logic;
  signal h2p_rd_res_rdata : std_logic_vector(H2P_RD_CHANS_WIDTH-1 downto 0);
  signal h2p_rd_res_wdata : std_logic_vector(H2P_RD_CHANS_WIDTH-1 downto 0);
  
  signal h2p_rd_cfg_empty : std_logic;
  signal h2p_rd_cfg_re_r : std_logic;
  signal h2p_rd_cfg_we_r : std_logic;
  signal h2p_rd_cfg_rdata : std_logic_vector(H2P_RD_CHANS_WIDTH-1 downto 0);
  signal h2p_rd_cfg_wdata : std_logic_vector(H2P_RD_CHANS_WIDTH-1 downto 0);
  
  signal p2h_rconf_lower_addr_rv : std_logic_vector(PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  signal p2h_rconf_total_amount_rv : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
  signal p2h_rconf_packets_left_rv : std_logic_vector(HIBI_RW_LENGTH_WIDTH-PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  signal p2h_rconf_req_id_rv : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal p2h_rconf_tag_rv : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
  
  signal p2h_rconf_upd_we_r : std_logic;
  
  signal p2h_rconf_wdata : std_logic_vector(P2H_RCONF_WIDTH-1 downto 0);
  signal p2h_rconf_upd_wdata : std_logic_vector(P2H_RCONF_WIDTH-1 downto 0);
  signal p2h_rconf_upd_rdata : std_logic_vector(P2H_RCONF_WIDTH-1 downto 0);
  
--   signal p2h_tx_lower_addr : std_logic_vector(PCIE_LOWER_ADDR_WIDTH-1 downto 0);
--   signal p2h_tx_length_total : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
--   signal p2h_tx_packets_left : std_logic_vector(HIBI_RW_LENGTH_WIDTH-PCIE_LOWER_ADDR_WIDTH-1 downto 0);
--   signal p2h_tx_req_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
--   signal p2h_tx_tag : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
--   
--   signal h2p_tx_dst_addr : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
--   signal h2p_tx_length_total : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
--   signal h2p_tx_packets_left : std_logic_vector(HIBI_RW_LENGTH_WIDTH-PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  
  signal p2h_rconf_we_r : std_logic;
--  signal p2h_opkt_conf_wdata_0 : std_logic_vector(PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  
  signal init_done : std_logic;
  
begin
  init_done <= h2p_conf_state_init_done_r and p2h_req_init_done and opkt_buf_init_done;
  init_done_out <= init_done;
  
  ipkt_re_out <= ipkt_re_r;
  
  opkt_is_write_out <= opkt_tx_is_write_r;
  opkt_is_read_req_out <= opkt_tx_is_read_req_r;
  opkt_is_rdata_out <= opkt_tx_is_rdata_r;
  opkt_addr_out <= opkt_tx_addr_r;
  opkt_length_out <= opkt_tx_length_r;
  opkt_req_id_out <= opkt_tx_req_id_r;
  opkt_tag_out <= opkt_tx_tag_r;
  opkt_we_out <= '0'; --opkt_tx_we_r;
  opkt_burst_we_out <= opkt_tx_we_r;
  
  irq_out <= '0';
  
  hibi_addr_out <= hibi_waddr_r;
  hibi_comm_out <= hibi_comm_r;
  hibi_we_out <= hibi_we_r;
  hibi_re_out <= init_done and not(opkt_buf_wr_stall);
  
  hibi_msg_re <= hibi_msg_re_r and not(hibi_msg_re_stall_r);
  hibi_msg_re_out <= hibi_msg_re;
  
  -- HIBI message write interface is shared between three blocks
  hibi_msg_comm_out <= HCOM_MSG_WR;
  hibi_msg_we_out <= hibi_msg_we_r or p2h_req_tx_we_r or h2p_ack_tx_we_r;
  
  process (hibi_msg_we_r, hibi_msg_wdata_r, hibi_msg_waddr_r, p2h_req_tx_we_r, p2h_req_tx_wdata_r, p2h_req_tx_waddr_r, h2p_ack_tx_wdata, h2p_ack_tx_waddr, hibi_false_wr_r,
           ipkt_data_in, hibi_wdata_r, hibi_empty_in, hibi_addr_in, buf_windex_r, hibi_false_wdata_r)
  begin
    if (hibi_msg_we_r = '1') then
      hibi_msg_data_out <= hibi_msg_wdata_r;
      hibi_msg_addr_out <= hibi_msg_waddr_r;
    elsif (p2h_req_tx_we_r = '1') then
      hibi_msg_data_out <= p2h_req_tx_wdata_r;
      hibi_msg_addr_out <= p2h_req_tx_waddr_r;
    else
      hibi_msg_data_out <= h2p_ack_tx_wdata;
      hibi_msg_addr_out <= h2p_ack_tx_waddr;
    end if;
    
    if (hibi_false_wr_r = '0') then
      hibi_data_out <= hibi_wdata_r;
    else
      hibi_data_out <= hibi_false_wdata_r;
    end if;
    
    if (hibi_empty_in = '0') then
      buf_windex <= hibi_addr_in(OPKT_BUFFERS_WIDTH-1 downto 0);
    else
      buf_windex <= buf_windex_r;
    end if;
  end process;
  
  process (clk, rst_n)
    variable ipkt_p2h_addr_space_v : std_logic_vector(P2H_ADDR_SPACES_WIDTH-1 downto 0);
    variable p2h_addr_space_v : std_logic_vector(P2H_ADDR_SPACES_WIDTH-1 downto 0);
    variable direct_addr_v : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    variable hibi_addr_v : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    variable hibi_base_addr_v : std_logic_vector(HDMA_BASE_ADDR_WIDTH-1 downto 0);
    variable hibi_type_v : std_logic;
    variable hibi_tx_state_0_v : std_logic;
    variable hibi_false_wr_v : std_logic;
    variable p2h_addr_space_valid_v : std_logic;
  begin
    if (rst_n = '0') then
      ipkt_re_r <= '0';
      ipkt_valid_r <= '0';
      hibi_we_r <= '0';
      hibi_comm_r <= (others => '0');
      hibi_waddr_r <= (others => '0');
      hibi_wdata_r <= (others => '0');
      hibi_false_wdata_r <= (others => '0');
      hibi_msg_we_r <= '0';
      hibi_msg_waddr_r <= (others => '0');
      hibi_msg_wdata_r <= (others => '0');
      hibi_wr_length_r <= (others => '0');
      hibi_tx_state_r <= WAIT_PACKET;
      hdma_conf_sub_state_r <= (others => '0');
      hdma_wr_r <= '0';
      hibi_single_read_r <= '0';
      p2h_buf_reserve_r <= '0';
      p2h_req_re_r <= '0';
      p2h_req_rcomp_r <= (others => '0');
      p2h_rconf_we_r <= '0';
      p2h_buf_conf_we_r <= '0';
      p2h_buf_index_r <= (others => '0');
      p2h_buf_conf_type_r <= (others => '0');
      p2h_buf_conf_amount_r <= (others => '0');
      h2p_rconf_upd_we_r <= '0';
      h2p_rd_last_part_r <= '0';
      hibi_false_wr_r <= '0';
      hibi_false_wr_type_r <= '0';
      
    elsif (clk'event and clk = '1') then
      hibi_we_r <= '0';
      ipkt_re_r <= '0';
      h2p_rconf_upd_we_r <= '0';
      
      direct_addr_v := ipkt_addr_in;
      p2h_addr_space_valid_v := '1';
      
      if (ipkt_addr_in(HIBI_DATA_WIDTH-1 downto P2H_ADDR_0_WIDTH) = P2H_ADDR_0_PCIE_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_0_WIDTH)) then
        p2h_addr_space_v := i2s(0, P2H_ADDR_SPACES_WIDTH);
      elsif ((ipkt_addr_in(HIBI_DATA_WIDTH-1 downto P2H_ADDR_1_WIDTH) = P2H_ADDR_1_PCIE_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_1_WIDTH)) and (P2H_ADDR_SPACES > 1)) then
        p2h_addr_space_v := i2s(1, P2H_ADDR_SPACES_WIDTH);
      elsif ((ipkt_addr_in(HIBI_DATA_WIDTH-1 downto P2H_ADDR_2_WIDTH) = P2H_ADDR_2_PCIE_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_2_WIDTH)) and (P2H_ADDR_SPACES > 2)) then
        p2h_addr_space_v := i2s(2, P2H_ADDR_SPACES_WIDTH);
      elsif ((ipkt_addr_in(HIBI_DATA_WIDTH-1 downto P2H_ADDR_3_WIDTH) = P2H_ADDR_3_PCIE_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_3_WIDTH)) and (P2H_ADDR_SPACES > 3)) then
        p2h_addr_space_v := i2s(3, P2H_ADDR_SPACES_WIDTH);
      elsif ((ipkt_addr_in(HIBI_DATA_WIDTH-1 downto P2H_ADDR_4_WIDTH) = P2H_ADDR_4_PCIE_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_4_WIDTH)) and (P2H_ADDR_SPACES > 4)) then
        p2h_addr_space_v := i2s(4, P2H_ADDR_SPACES_WIDTH);
      elsif ((ipkt_addr_in(HIBI_DATA_WIDTH-1 downto P2H_ADDR_5_WIDTH) = P2H_ADDR_5_PCIE_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_5_WIDTH)) and (P2H_ADDR_SPACES > 5)) then
        p2h_addr_space_v := i2s(5, P2H_ADDR_SPACES_WIDTH);
      elsif ((ipkt_addr_in(HIBI_DATA_WIDTH-1 downto P2H_ADDR_6_WIDTH) = P2H_ADDR_6_PCIE_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_6_WIDTH)) and (P2H_ADDR_SPACES > 6)) then
        p2h_addr_space_v := i2s(6, P2H_ADDR_SPACES_WIDTH);
      elsif ((ipkt_addr_in(HIBI_DATA_WIDTH-1 downto P2H_ADDR_7_WIDTH) = P2H_ADDR_7_PCIE_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_7_WIDTH)) and (P2H_ADDR_SPACES > 7)) then
        p2h_addr_space_v := i2s(7, P2H_ADDR_SPACES_WIDTH);
      else
        p2h_addr_space_valid_v := '0';
      end if;
      
      
      if (p2h_addr_space_v = 0) then
        if (P2H_HDMA_ADDR_SPACES > 0) then
          hibi_base_addr_v := P2H_ADDR_0_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CONF_OFFSET_WIDTH);
        end if;
        hibi_addr_v := P2H_ADDR_0_HIBI_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_0_WIDTH) & direct_addr_v(P2H_ADDR_0_WIDTH-1 downto 0);
      
      elsif (p2h_addr_space_v = 1) then
        if (P2H_HDMA_ADDR_SPACES > 1) then
          hibi_base_addr_v := P2H_ADDR_1_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CONF_OFFSET_WIDTH);
        end if;
        hibi_addr_v := P2H_ADDR_1_HIBI_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_1_WIDTH) & direct_addr_v(P2H_ADDR_1_WIDTH-1 downto 0);
      
      elsif (p2h_addr_space_v = 2) then
        if (P2H_HDMA_ADDR_SPACES > 2) then
          hibi_base_addr_v := P2H_ADDR_2_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CONF_OFFSET_WIDTH);
        end if;
        hibi_addr_v := P2H_ADDR_2_HIBI_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_2_WIDTH) & direct_addr_v(P2H_ADDR_2_WIDTH-1 downto 0);
      
      elsif (p2h_addr_space_v = 3) then
        if (P2H_HDMA_ADDR_SPACES > 3) then
          hibi_base_addr_v := P2H_ADDR_3_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CONF_OFFSET_WIDTH);
        end if;
        hibi_addr_v := P2H_ADDR_3_HIBI_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_3_WIDTH) & direct_addr_v(P2H_ADDR_3_WIDTH-1 downto 0);
      
      elsif (p2h_addr_space_v = 4) then
        if (P2H_HDMA_ADDR_SPACES > 4) then
          hibi_base_addr_v := P2H_ADDR_4_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CONF_OFFSET_WIDTH);
        end if;
        hibi_addr_v := P2H_ADDR_4_HIBI_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_4_WIDTH) & direct_addr_v(P2H_ADDR_4_WIDTH-1 downto 0);
      
      elsif (p2h_addr_space_v = 5) then
        if (P2H_HDMA_ADDR_SPACES > 5) then
          hibi_base_addr_v := P2H_ADDR_5_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CONF_OFFSET_WIDTH);
        end if;
        hibi_addr_v := P2H_ADDR_5_HIBI_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_5_WIDTH) & direct_addr_v(P2H_ADDR_5_WIDTH-1 downto 0);
      
      elsif (p2h_addr_space_v = 6) then
        if (P2H_HDMA_ADDR_SPACES > 6) then
          hibi_base_addr_v := P2H_ADDR_6_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CONF_OFFSET_WIDTH);
        end if;
        hibi_addr_v := P2H_ADDR_6_HIBI_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_6_WIDTH) & direct_addr_v(P2H_ADDR_6_WIDTH-1 downto 0);
      
      elsif (p2h_addr_space_v = 7) then
        if (P2H_HDMA_ADDR_SPACES > 7) then
          hibi_base_addr_v := P2H_ADDR_7_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CONF_OFFSET_WIDTH);
        end if;
        hibi_addr_v := P2H_ADDR_7_HIBI_BASE(HIBI_DATA_WIDTH-1 downto P2H_ADDR_7_WIDTH) & direct_addr_v(P2H_ADDR_7_WIDTH-1 downto 0);
      end if;
      
      
      if (p2h_addr_space_v < P2H_HDMA_ADDR_SPACES) then
        hibi_type_v := '1';
      else
        hibi_type_v := '0';
      end if;
      
      p2h_req_rcomp_r <= p2h_addr_space_v(P2H_HDMA_ADDR_SPACES_WIDTH-1 downto 0) & ipkt_is_write_in;
      
      
--       if ((hibi_msg_full_in = '1') and (hibi_msg_we_r = '1')) then
--         hibi_msg_stall_r <= '1';
--         hibi_msg_stall_v := '1';
--       else
--         hibi_msg_stall_r <= '0';
--         hibi_msg_stall_v := hibi_msg_stall_r;
--       end if;
      
      ipkt_valid_r <= ipkt_valid_in;
      
      if (hibi_we_r = '1') then
        if (hibi_full_in = '1') then
          hibi_false_wr_v := '1';
          if (ipkt_valid_in = '1') then
            hibi_false_wr_type_r <= '0';
          else
            hibi_false_wr_type_r <= '1';
          end if;
        else
          hibi_false_wr_v := '0';
        end if;
      else
        hibi_false_wr_v := hibi_false_wr_r;
      end if;
      
      hibi_false_wr_r <= hibi_false_wr_v;
      
      hibi_tx_state_0_v := '0';
      
      p2h_rconf_we_r <= '0';
      p2h_buf_reserve_r <= '0';
      
      case hibi_tx_state_r is
        when WAIT_PACKET =>
          if ((ipkt_valid_in = '1') and (ipkt_re_r = '0')) then
            hibi_tx_state_0_v := '1';
          end if;
        
        when P2H_REQ_WAIT =>
          if (p2h_req_ready = '1') then
            hdma_conf_sub_state_r <= "00";
            
            hibi_waddr_r <= hibi_base_addr_v & ipkt_is_write_in & ipkt_is_read_req_in & p2h_req_offset;
            
            p2h_req_re_r <= '0';
            
            if (p2h_addr_space_valid_v = '1') then
              if (ipkt_is_write_in = '0') then
                p2h_buf_conf_we_r <= '1';
                hibi_tx_state_r <= OPKT_BUF_WAIT_CONF;
              else
                hibi_msg_we_r <= '1';
                hibi_msg_waddr_r <= hibi_base_addr_v & ipkt_is_write_in & ipkt_is_read_req_in & p2h_req_offset;
                hibi_msg_wdata_r <= hibi_addr_v;
                hibi_tx_state_r <= HDMA_WR_CONF_TX;
              end if;
            end if;
          end if;
        
--         when OPKT_BUF_WAIT_RESERVE =>
--           if (hibi_msg_full_in = '0') then
--             hibi_msg_we_r <= '0';
--           end if;
--           
--           if (p2h_buf_reserve_ready = '1') then
-- --            p2h_buf_reserve_r <= '0';
--             
--             p2h_rconf_we_r <= '1';
--             
-- --            p2h_buf_index_r <= opkt_buf_reserve_index;
--             p2h_buf_conf_we_r <= '1';
--             
--             hibi_tx_state_r <= OPKT_BUF_WAIT_CONF;
--           end if;
       
       when OPKT_BUF_WAIT_CONF =>
          if (hibi_msg_full_in = '0') then
            hibi_msg_we_r <= '0';
          end if;
          
          if (p2h_buf_conf_ready = '1') then
            p2h_buf_conf_we_r <= '0';
            
            if (hibi_type_v = '0') then
              hibi_comm_r <= HCOM_RD;
              hibi_wdata_r <= HIBI_IF_ADDR(HIBI_DATA_WIDTH-1 downto HIBI_ADDR_SPACE_WIDTH) & P2H_RD_RET_ADDR_BASE_OFFSET(HIBI_ADDR_SPACE_WIDTH-1 downto OPKT_BUFFERS_WIDTH) & p2h_buf_index_r;
              hibi_tx_state_r <= HIBI_WR;
              hibi_single_read_r <= '1';
            else
              hibi_msg_waddr_r <= hibi_base_addr_v & ipkt_is_write_in & ipkt_is_read_req_in & p2h_req_offset;
              hibi_msg_wdata_r <= hibi_addr_v;
              hibi_msg_we_r <= '1';
              hibi_tx_state_r <= HDMA_RD_CONF_TX;
              hibi_single_read_r <= '0';
            end if;
          end if;
        
        when HDMA_WR_CONF_TX =>
          if (hibi_msg_full_in = '0') then
            hdma_conf_sub_state_r <= hdma_conf_sub_state_r + 1;
            case hdma_conf_sub_state_r is
              when "00" =>
                hibi_msg_wdata_r <= (others => '0');
                hibi_msg_wdata_r(HIBI_RW_LENGTH_WIDTH-1 downto 0) <= ipkt_length_in;
                hibi_msg_wdata_r(HIBI_DATA_BYTE_WIDTH+HDMA_RW_AMOUNT_WIDTH-1  downto HDMA_RW_AMOUNT_WIDTH) <= (others => '1');
                hibi_wr_length_r <= ipkt_length_in;
              when "01" =>
                hibi_msg_wdata_r(HIBI_DATA_WIDTH-1 downto 1) <= (others => '0');
                hibi_msg_wdata_r(0) <= '1';
              when others => --"10" =>
                hibi_msg_we_r <= '0';
                hibi_tx_state_r <= HIBI_WR;
                hdma_wr_r <= '1';
            end case;
          end if;
        
        when HDMA_RD_CONF_TX =>
          if (hibi_msg_full_in = '0') then
            hdma_conf_sub_state_r <= hdma_conf_sub_state_r + 1;
            case hdma_conf_sub_state_r is
              when "00" =>
                hibi_msg_wdata_r <= (others => '0');
                hibi_msg_wdata_r(HIBI_RW_LENGTH_WIDTH-1 downto 0) <= ipkt_length_in;
                hibi_msg_wdata_r(HIBI_DATA_BYTE_WIDTH+HDMA_RW_AMOUNT_WIDTH-1 downto HDMA_RW_AMOUNT_WIDTH) <= (others => '1');
              when "01" =>
                hibi_msg_wdata_r <= HIBI_IF_ADDR(HIBI_DATA_WIDTH-1 downto HIBI_ADDR_SPACE_WIDTH) & P2H_RD_RET_ADDR_BASE_OFFSET(HIBI_ADDR_SPACE_WIDTH-1 downto OPKT_BUFFERS_WIDTH) & p2h_buf_index_r;
              when "10" =>
                hibi_msg_wdata_r(HIBI_DATA_WIDTH-1 downto 1) <= (others => '0');
                hibi_msg_wdata_r(0) <= '1';
              when others => -- "11" =>
                ipkt_re_r <= '1';
                hibi_msg_we_r <= '0';
                hibi_tx_state_r <= WAIT_PACKET;
            end case;
          end if;
        
        when HIBI_WR =>
          if ((hibi_full_in = '0') and (ipkt_valid_in = '1') and (hibi_false_wr_v = '0')) then
            ipkt_re_r <= '1';
          end if;
          
          if ( (hibi_full_in = '0') and (((ipkt_re_r = '1') and (ipkt_valid_in = '1'))
              or ((hibi_false_wr_r = '1') and ((hibi_false_wr_type_r = '0') or (hibi_false_wr_v = '1')))) ) then
--            if (hibi_wr_length_r <= (HIBI_DATA_WIDTH/8)) then
--              hibi_tx_state_r <= HIBI_WR_END_0;
--              hibi_tx_state_0_v := '1';
--            else
              hibi_we_r <= '1';
--            end if;
          end if;
          
          if ((hibi_we_r = '1') and (hibi_false_wr_v = '0')) then
            hibi_wr_length_r <= hibi_wr_length_r - (HIBI_DATA_WIDTH/8);
            if (hdma_wr_r = '0') then
              hibi_waddr_r <= hibi_waddr_r + (HIBI_DATA_WIDTH/8);
            end if;
            
            if (hibi_wr_length_r <= (HIBI_DATA_WIDTH/8)) then
              if (ipkt_is_rdata_in = '1') then
                h2p_rconf_upd_we_r <= '1';
              end if;
              hibi_tx_state_r <= HIBI_WR_END_0;
            end if;
          end if;
          
          if ((ipkt_re_r = '1') and (hibi_single_read_r = '0')) then
            hibi_wdata_r <= ipkt_data_in;
          end if;
          
          if ((hibi_single_read_r = '0') and (hibi_false_wr_v = '1') and (hibi_false_wr_r = '0')) then
            hibi_false_wdata_r <= hibi_wdata_r;
          end if;
        
        when HIBI_WR_END_0 =>
          if (hibi_false_wr_v = '1') then
            hibi_tx_state_r <= HIBI_WR_END_1;
          else
            hibi_tx_state_r <= WAIT_PACKET;
          end if;
        
        when HIBI_WR_END_1 =>
          if (hibi_full_in = '0') then
            hibi_we_r <= '1';
            hibi_tx_state_r <= WAIT_PACKET;
          end if;
      end case;
      
      if (hibi_tx_state_0_v = '1') then
        hibi_we_r <= '0';
        hibi_comm_r <= HCOM_WR;
        hibi_waddr_r <= hibi_addr_v;
        hibi_wdata_r <= ipkt_data_in;
        hibi_wr_length_r <= ipkt_length_in;
        
        if (p2h_addr_space_valid_v = '0') then
          ipkt_re_r <= '1';
--          hibi_tx_state_r <= WAIT_PACKET;
        elsif (ipkt_is_write_in = '1') then
          if (hibi_type_v = '0') then -- if the target hibi component doesn't support DMA
            hibi_we_r <= '1';
            ipkt_re_r <= '1';
            hibi_tx_state_r <= HIBI_WR;
            p2h_req_re_r <= '0';
          else
            hibi_waddr_r <= hibi_msg_waddr_r;
            hibi_tx_state_r <= P2H_REQ_WAIT;
            p2h_req_re_r <= '1';
          end if;
        elsif (ipkt_is_read_req_in = '1') then
          if (p2h_buf_reserve_ready = '1') then
            p2h_buf_reserve_r <= '1';
            p2h_rconf_we_r <= '1';
            p2h_buf_index_r <= opkt_buf_reserve_index;
            
            if (hibi_type_v = '0') then
              p2h_buf_conf_we_r <= '1';
              hibi_tx_state_r <= OPKT_BUF_WAIT_CONF;
              p2h_req_re_r <= '0';
            else
              hibi_tx_state_r <= P2H_REQ_WAIT;
              p2h_req_re_r <= '1';
            end if;
          end if;
        elsif (ipkt_is_rdata_in = '1') then
          hibi_we_r <= '1';
          ipkt_re_r <= '1';
          hibi_waddr_r <= h2p_rconf_ret_addr_rv;
          
          if (ipkt_length_in >= h2p_rconf_total_amount_rv) then
            h2p_rd_last_part_r <= '1';
          else
            h2p_rd_last_part_r <= '0';
          end if;
          
          hdma_wr_r <= '1';
          
          hibi_tx_state_r <= HIBI_WR;
          p2h_req_re_r <= '0';
          
        else
          hibi_we_r <= '0';
          ipkt_re_r <= '0';
          hibi_tx_state_r <= WAIT_PACKET;
          p2h_req_re_r <= '0';
        end if;
      end if;
      
    end if;
  end process;


-----------------------------------------------------------------------------------------
-- HIBI message reader:
-----------------------------------------------------------------------------------------
-- initialization:
-- --------------
-- increment h2p_conf_state_windex_r from zero until it reaches H2P_CHANS*2 - 1
-- set h2p_conf_state_init_done_r <= '1' after reaching maximum
--
-- normal operation:
-- ----------------
-- Pass read and write channel requests to the channel request processer
-- Write read and write channel configurations to read or write configure memory
-----------------------------------------------------------------------------------------
  process (clk, rst_n)
    variable hibi_msg_raddr_v : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    variable hibi_msg_rdata_v : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
    variable hibi_msg_empty_v : std_logic;
    variable h2p_conf_state_v : std_logic_vector(H2P_CONF_STATE_WIDTH-1 downto 0);
    variable h2p_conf_done_v : std_logic;
    variable h2p_conf_load_data_v : std_logic_vector(H2P_RCONF_WIDTH-1 downto 0);
    variable h2p_conf_load_v : std_logic;
  begin
    if (rst_n = '0') then
      hibi_msg_re_r <= '0';
      hibi_msg_raddr_r <= (others => '0');
      hibi_msg_rdata_r <= (others => '0');
      hibi_msg_empty_r <= '0';
      hibi_msg_re_stall_r <= '0';
      hibi_msg_ret_addr_r <= (others => '0');
      load_h2p_conf_state_r <= '0';
      load_h2p_conf_state_d1_r <= '0';
      h2p_conf_state_r <= (others => '0');
      h2p_conf_load_data_r <= (others => '0');
      h2p_conf_state_windex_r <= (others => '0');
      h2p_conf_state_we_r <= '0';
      cur_h2p_chan_rd_r <= '0';
      cur_h2p_chan_wr_r <= '0';
      cur_h2p_chan_r <= (others => '0');
      h2p_conf_state_init_done_r <= '0';
      h2p_rd_res_init_done_r <= '0';
      h2p_wconf_we_r <= '0';
      h2p_rconf_we_r <= '0';
      h2p_wr_req_r <= '0';
      h2p_rd_req_r <= '0';
      h2p_buf_conf_we_r <= '0';
      h2p_buf_conf_type_r <= (others => '0');
      h2p_buf_conf_amount_r <= (others => '0');
      h2p_buf_index_r <= (others => '0');
      h2p_rd_cfg_we_r <= '0';
      
    elsif (clk'event and clk = '1') then
      hibi_msg_re_r <= '0';
      
      h2p_conf_state_we_r <= '0';
      load_h2p_conf_state_r <= '0';
      load_h2p_conf_state_d1_r <= load_h2p_conf_state_r;
      h2p_conf_load_v := '0';
      h2p_conf_done_v := '0';
      
      h2p_wconf_we_r <= '0';
      h2p_rconf_we_r <= '0';
      h2p_rd_cfg_we_r <= '0';
      
      -- increment h2p_conf_state_mem_waddr_r until it reaches H2P_CHANS*2 - 1
      if (h2p_conf_state_init_done_r = '0') then
        if (h2p_conf_state_windex_r = (H2P_CHANS*2 - 1)) then
          h2p_conf_state_init_done_r <= '1';
        end if;
        if (h2p_conf_state_windex_r = (H2P_RD_CHANS - 1)) then
          h2p_rd_res_init_done_r <= '1';
        end if;
        h2p_conf_state_windex_r <= h2p_conf_state_windex_r + 1;
      end if;
      
      -- if a hibi message read stall is occurring route the stored value of the HIBI address, data and empty to the next block
      if (hibi_msg_re_stall_r = '0') then
        hibi_msg_raddr_v := hibi_msg_addr_in;
        hibi_msg_rdata_v := hibi_msg_data_in;
        hibi_msg_empty_v := hibi_msg_empty_in;
      else
        hibi_msg_raddr_v := hibi_msg_raddr_r;
        hibi_msg_rdata_v := hibi_msg_rdata_r;
        hibi_msg_empty_v := hibi_msg_empty_r;
      end if;
      
      hibi_msg_raddr_r <= hibi_msg_raddr_v;
      hibi_msg_rdata_r <= hibi_msg_rdata_v;
      hibi_msg_empty_r <= hibi_msg_empty_v;
      
      if (h2p_req_ready_r = '1') then
        h2p_wr_req_r <= '0';
        h2p_rd_req_r <= '0';
      end if;
      
      ------------------------------------------------------------------------------------
      -- HIBI read message address demux:
      ------------------------------------------------------------------------------------
      if (opkt_buf_init_done = '1') then
        if ((hibi_msg_re_r = '1') and (hibi_msg_empty_v = '0')) then
          if (hibi_msg_raddr_v(HIBI_ADDR_SPACE_WIDTH-1 downto 8) = 0) then
            case hibi_msg_raddr_v(HIBI_LOWER_ADDR_RANGE-1 downto 0) is
              when HDMA_WR_REQ_OFFSET =>
                if ((h2p_wr_req_r = '1') or (h2p_rd_req_r = '1')) then
                  hibi_msg_re_stall_r <= '1';
                else
                  hibi_msg_re_stall_r <= '0';
                  hibi_msg_ret_addr_r <= hibi_msg_rdata_v;
                  h2p_wr_req_r <= '1';
                end if;
              when HDMA_RD_REQ_OFFSET =>
                if ((h2p_wr_req_r = '1') or (h2p_rd_req_r = '1')) then
                  hibi_msg_re_stall_r <= '1';
                else
                  hibi_msg_re_stall_r <= '0';
                  hibi_msg_ret_addr_r <= hibi_msg_rdata_v;
                  h2p_rd_req_r <= '1';
                end if;
              when others =>
--                h2p_wr_req_r <= '0';
            end case;

          elsif ( (hibi_msg_raddr_v(HIBI_ADDR_SPACE_WIDTH-1 downto 8) = 1) or (hibi_msg_raddr_v(HIBI_ADDR_SPACE_WIDTH-1 downto 8) = 2) ) then
            if ( ((cur_h2p_chan_wr_r & cur_h2p_chan_rd_r) /= hibi_msg_raddr_v(9 downto 8)) or  (cur_h2p_chan_r /= hibi_msg_raddr_v(H2P_CHANS_WIDTH-1 downto 0)) ) then
              load_h2p_conf_state_r <= '1';
              
              cur_h2p_chan_rd_r <= hibi_msg_raddr_v(8);
              cur_h2p_chan_wr_r <= hibi_msg_raddr_v(9);
              cur_h2p_chan_r <= hibi_msg_raddr_v(H2P_CHANS_WIDTH-1 downto 0);
              
              hibi_msg_re_stall_r <= '1';
            elsif (hibi_msg_re_stall_r = '0') then
              h2p_conf_load_v := '1';
            end if;
          end if;
        end if;
        
        if (hibi_msg_empty_v = '0') then
          hibi_msg_re_r <= '1';
        end if;
        
        if (load_h2p_conf_state_d1_r = '1') then
          h2p_conf_load_v := '1';
          h2p_conf_state_v := h2p_conf_state_rdata;
          h2p_conf_state_r <= h2p_conf_state_rdata;
          if (h2p_conf_state_v /= 0) then
            if (cur_h2p_chan_wr_r = '1') then
              h2p_conf_load_data_v(H2P_RCONF_WIDTH-1 downto H2P_WCONF_WIDTH) := (others => '0');
              h2p_conf_load_data_v(H2P_WCONF_WIDTH-1 downto 0) := h2p_wconf_rdata;
            else
              h2p_conf_load_data_v := h2p_rconf_rdata;
            end if;
          else
            h2p_conf_load_data_v := (others => '0');
            h2p_conf_load_data_v(H2P_CONF_STARTED_L) := '1';
          end if;
          hibi_msg_re_stall_r <= '0';
        else
          h2p_conf_state_v := h2p_conf_state_r;
          h2p_conf_load_data_v := h2p_conf_load_data_r;
        end if;
        
        ------------------------------------------------------------------------------------
        -- R/W configuration processer:
        ------------------------------------------------------------------------------------
        if (h2p_conf_load_v = '1') then
          h2p_conf_load_data_r <= h2p_conf_load_data_v;
          if (cur_h2p_chan_wr_r = '1') then
            case h2p_conf_state_v is
              when "00" =>
                h2p_conf_load_data_r(H2P_ADDR_L+HIBI_DATA_WIDTH-1 downto H2P_ADDR_L) <= hibi_msg_rdata_v;
                h2p_conf_load_data_r(H2P_CONF_STARTED_L) <= '1';
              when others => --"01" =>
                h2p_conf_load_data_r(H2P_TOTAL_AMOUNT_U downto H2P_TOTAL_AMOUNT_L) <= hibi_msg_rdata_v(HIBI_RW_LENGTH_WIDTH-1 downto 0);
                h2p_conf_load_data_r(H2P_CONF_DONE_L) <= '1';
                h2p_conf_done_v := '1';
            end case;
          else
            case h2p_conf_state_v is
              when "00" =>
                h2p_conf_load_data_r(H2P_ADDR_L+HIBI_DATA_WIDTH-1 downto H2P_ADDR_L) <= hibi_msg_rdata_v;
                h2p_conf_load_data_r(H2P_CONF_STARTED_L) <= '1';
              when "01" =>
                h2p_conf_load_data_r(H2P_TOTAL_AMOUNT_U downto H2P_TOTAL_AMOUNT_L) <= hibi_msg_rdata_v(HIBI_RW_LENGTH_WIDTH-1 downto 0);
              when others => --"10" =>
                h2p_conf_load_data_r(H2P_RET_ADDR_U downto H2P_RET_ADDR_L) <= hibi_msg_rdata_v(HIBI_DATA_WIDTH-1 downto 0);
                h2p_conf_load_data_r(H2P_CONF_DONE_L) <= '1';
                h2p_rd_cfg_we_r <= '1';
                h2p_conf_done_v := '1';
            end case;
          end if;
          
          h2p_wconf_we_r <= cur_h2p_chan_wr_r;
          h2p_rconf_we_r <= cur_h2p_chan_rd_r;
          
          h2p_conf_state_windex_r <= cur_h2p_chan_wr_r & cur_h2p_chan_r;
          h2p_conf_state_we_r <= '1';
          
          if (h2p_conf_done_v = '0') then
            h2p_conf_state_r <= h2p_conf_state_v + 1;
          else
            if (h2p_buf_conf_ready = '0') then
              hibi_msg_re_stall_r <= '1';
            else
              hibi_msg_re_stall_r <= '0';
              h2p_conf_state_r <= (others => '0');
            end if;
          end if;
        end if;
      end if;
      
      if ((h2p_conf_done_v = '1') and (cur_h2p_chan_wr_r = '1')) then
        h2p_buf_conf_we_r <= '1';
        h2p_buf_conf_amount_r <= hibi_msg_rdata_v(HIBI_RW_LENGTH_WIDTH-1 downto 0);
        h2p_buf_index_r <= hibi_msg_raddr_v(H2P_CHANS_WIDTH-1 downto 0);
--        h2p_buf_conf_addr_r <= h2p_conf_load_data_v(H2P_ADDR_L+HIBI_DATA_WIDTH-1 downto H2P_ADDR_L);
        h2p_buf_conf_addr_to_limit_r <= "1000000000000" - h2p_conf_load_data_v(H2P_ADDR_L+ADDR_TO_LIMIT_WIDTH-1 downto H2P_ADDR_L);
      end if;
      
      if ((h2p_buf_conf_we_r = '1') and (h2p_buf_conf_ready = '1')) then
        h2p_buf_conf_we_r <= '0';
      end if;
    end if;
  end process;
  
  
-----------------------------------------------------------------------------------------
-- HIBI to PCIE channel request processer:
-----------------------------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      h2p_ack_tx_we_r <= '0';
      h2p_req_ready_r <= '0';
      h2p_req_state_r <= WAIT_H2P_REQ;
      h2p_buf_reserve_r <= '0';
      h2p_rd_res_re_r <= '0';
      h2p_nack_r <= '0';
      
    elsif (clk'event and clk = '1') then
      h2p_req_ready_r <= '0';
      h2p_ack_tx_we_r <= '0';
      h2p_rd_res_re_r <= '0';
      
      case h2p_req_state_r is
        when WAIT_H2P_REQ =>
          if (h2p_wr_req_r = '1') then
            h2p_buf_reserve_r <= '1';
            h2p_req_state_r <= WAIT_OPKT_BUF_RESERVE;
          
          elsif ((h2p_rd_req_r = '1') and (h2p_rd_res_empty = '0')) then
            if (h2p_rd_res_empty = '0') then
              h2p_ack_tx_we_r <= '1';
              h2p_req_state_r <= WAIT_H2P_ACK_TX;
            else
              h2p_nack_r <= '1';
              h2p_ack_tx_we_r <= '1';
              h2p_req_state_r <= WAIT_H2P_ACK_TX;
            end if;
          end if;
        
        when WAIT_OPKT_BUF_RESERVE =>
          if (h2p_buf_reserve_r = '1') then
            if (h2p_buf_reserve_ready = '1') then
              h2p_buf_reserve_r <= '0';
              h2p_ack_tx_we_r <= '1';
              h2p_req_state_r <= WAIT_H2P_ACK_TX;
            end if;
          end if;
        
        when WAIT_H2P_ACK_TX =>
          if ((h2p_ack_tx_we_r = '1') and (hibi_msg_we_r = '0') and (p2h_req_tx = '0') and (hibi_msg_full_in = '0')) then
            if (h2p_rd_req_r = '1') then
              h2p_rd_res_re_r <= '1';
            end if;
            h2p_nack_r <= '0';
            h2p_ack_tx_we_r <= '0';
            h2p_req_ready_r <= '1';
            h2p_req_state_r <= WAIT_H2P_REQ;
          end if;
      end case;
    end if;
  end process;
  
  h2p_ack_tx_waddr <= hibi_msg_ret_addr_r;
  h2p_ack_tx_wdata(HIBI_DATA_WIDTH-1 downto HDMA_CONF_OFFSET_WIDTH) <= (others => '0');
  
  process (h2p_buf_reserve_r, opkt_buf_reserve_index, h2p_rd_res_rdata, h2p_nack_r)
  begin
    if (h2p_nack_r = '1') then
      h2p_ack_tx_wdata(HDMA_CONF_OFFSET_WIDTH-1 downto 0) <= (others => '0');
    elsif (h2p_buf_reserve_r = '1') then
      h2p_ack_tx_wdata(HDMA_CONF_OFFSET_WIDTH-1 downto OPKT_BUFFERS_WIDTH) <= H2P_WR_CONF_BASE_OFFSET(HDMA_CONF_OFFSET_WIDTH-1 downto OPKT_BUFFERS_WIDTH);
      h2p_ack_tx_wdata(OPKT_BUFFERS_WIDTH-1 downto 0) <= opkt_buf_reserve_index;
    else
      h2p_ack_tx_wdata(HDMA_CONF_OFFSET_WIDTH-1 downto H2P_RD_CHANS_WIDTH) <= H2P_RD_CONF_BASE_OFFSET(HDMA_CONF_OFFSET_WIDTH-1 downto H2P_RD_CHANS_WIDTH);
      h2p_ack_tx_wdata(H2P_RD_CHANS_WIDTH-1 downto 0) <= h2p_rd_res_rdata;
    end if;
  end process;
  
-----------------------------------------------------------------------------------------
-- OPKT TX:
-----------------------------------------------------------------------------------------
  process (clk, rst_n)
    variable opkt_tx_length_total_v : std_logic_vector(HIBI_RW_LENGTH_WIDTH-1 downto 0);
    variable opkt_tx_packets_left_v : std_logic_vector(HIBI_RW_LENGTH_WIDTH-PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  begin
    if (rst_n = '0') then
      opkt_tx_state_r <= WAIT_OPKT_BUF;
      opkt_buf_index_r <= (others => '0');
      opkt_type_r <= "0";
--      opkt_first_part_r <= '0';
      opkt_tx_length_r <= (others => '0');
      opkt_tx_addr_r <= (others => '0');
--      opkt_tx_lower_addr_r <= (others => '0');
      opkt_tx_length_total_r <= (others => '0');
      opkt_tx_packets_left_r <= (others => '0');
      opkt_tx_req_id_r <= (others => '0');
      opkt_tx_tag_r <= (others => '0');
      p2h_rconf_upd_we_r <= '0';
      h2p_wconf_upd_we_r <= '0';
      opkt_tx_buf_done_r <= '0';
      opkt_buf_filled_re_r <= '0';
      opkt_buf_re_r <= '0';
      opkt_buf_rindex_r <= (others => '0');
      opkt_tx_hibi_ret_addr_r <= (others => '0');
      opkt_buf_start_r <= '0';
      cur_h2p_rd_chan_r <= (others => '0');
      opkt_tx_we_r <= '0';
--      h2p_rd_res_re_r <= '0';
      opkt_tx_is_write_r <= '0';
      opkt_tx_is_read_req_r <= '0';
      opkt_tx_is_rdata_r <= '0';
      hibi_re_r <= '0';
      h2p_rd_cfg_re_r <= '0';
      buf_windex_r <= (others => '0');
      
    elsif (clk'event and clk = '1') then
      p2h_rconf_upd_we_r <= '0';
      h2p_wconf_upd_we_r <= '0';
      
--      h2p_rd_res_re_r <= '0';
--      opkt_buf_filled_re_r <= '0';
      opkt_buf_re_r <= '0';
      
      if (opkt_buf_ready = '1') then
        opkt_buf_start_r <= '0';
      end if;
      
      if ((opkt_buf_filled_re_r = '1') and (opkt_buf_ready = '1')) then
        opkt_buf_filled_re_r <= '0';
      end if;
      
      if (hibi_empty_in = '0') then
        buf_windex_r <= hibi_addr_in(OPKT_BUFFERS_WIDTH-1 downto 0);
      end if;
      
      case opkt_tx_state_r is
        when WAIT_OPKT_BUF =>
          opkt_tx_buf_done_r <= '0';
          if (h2p_rd_cfg_empty = '0') then
            opkt_tx_is_read_req_r <= '1';
            
            opkt_tx_addr_r <= h2p_rconf_addr_rv;
            opkt_tx_length_r <= h2p_rconf_total_amount_rv;
            opkt_tx_tag_r(PCIE_TAG_WIDTH-1 downto H2P_RD_CHANS_WIDTH) <= (others => '0');
            opkt_tx_tag_r(H2P_RD_CHANS_WIDTH-1 downto 0) <= h2p_rd_res_rdata;
            opkt_tx_state_r <= OPKT_TX;
            
          elsif ( (opkt_buf_filled_empty = '0') and ( (opkt_buf_filled_re_r = '0') or ((opkt_buf_filled_re_r = '1') and (opkt_buf_ready = '1')) ) ) then
            opkt_buf_index_r <= opkt_buf_filled_index;
            opkt_type_r <= opkt_buf_filled_type;
            opkt_tx_length_r <= "00000" & opkt_buf_filled_size & "00";
            opkt_buf_start_r <= '1'; -- start buffer read initiation at this stage to ensure no waiting
            opkt_tx_state_r <= OPKT_TX_DELAY;
          end if;
        
        when WAIT_FILLED_READ =>
          if (opkt_buf_ready = '1') then
            opkt_tx_state_r <= WAIT_OPKT_BUF;
          end if;
        
        when OPKT_TX_DELAY =>
          opkt_tx_state_r <= LOAD_OPKT_CONF;
          
        when LOAD_OPKT_CONF =>
          if (opkt_type_r = OPKT_P2H_TYPE) then
            opkt_tx_addr_r(PCIE_LOWER_ADDR_WIDTH-1 downto 0) <= p2h_rconf_lower_addr_rv;
            opkt_tx_length_total_v := p2h_rconf_total_amount_rv;
            opkt_tx_packets_left_v := p2h_rconf_packets_left_rv;
            opkt_tx_tag_r <= p2h_rconf_tag_rv;
            opkt_tx_is_rdata_r <= '1';
            
          else
            opkt_tx_addr_r <= h2p_wconf_addr_rv;
            opkt_tx_length_total_v := h2p_wconf_length_total_rv;
            opkt_tx_packets_left_v := h2p_wconf_packets_left_rv;
            opkt_tx_is_write_r <= '1';
          end if;
          
          opkt_tx_req_id_r <= p2h_rconf_req_id_rv;
          
--           if (opkt_tx_packets_left_v = 0) then
--             opkt_tx_length_r <= (others => '0');
--             opkt_tx_length_r(PCIE_CPL_LENGTH_MIN_WIDTH-1 downto 0) <= opkt_tx_length_total_v(PCIE_CPL_LENGTH_MIN_WIDTH-1 downto 0);
--           else
--             opkt_tx_length_r <= i2s(PCIE_CPL_LENGTH_MIN, HIBI_RW_LENGTH_WIDTH);
--           end if;
          
          opkt_tx_length_total_r <= opkt_tx_length_total_v;
          opkt_tx_packets_left_r <= opkt_tx_packets_left_v;
--          opkt_tx_tag_r <= p2h_tx_tag;
--          opkt_first_part_r <= '1';
          opkt_tx_we_r <= '1';
          opkt_tx_state_r <= OPKT_TX;
          
        when OPKT_TX =>
          if ((opkt_ready_in = '1') and ( ((opkt_buf_ready = '1') and (opkt_buf_start_r = '1')) or (opkt_buf_start_r = '0') ) ) then
--            opkt_first_part_r <= '0';
            opkt_buf_re_r <= '1';
            
            if (opkt_tx_length_r <= HIBI_DATA_BYTE_WIDTH) then
              opkt_tx_state_r <= WAIT_FILLED_READ; --WAIT_OPKT_BUF;
              
              opkt_buf_filled_re_r <= '1';
              
              opkt_tx_we_r <= '0';
              opkt_tx_is_write_r <= '0';
              opkt_tx_is_read_req_r <= '0';
              opkt_tx_is_rdata_r <= '0';
              
              if (opkt_tx_packets_left_r = 0) then
                opkt_tx_buf_done_r <= '1';
              end if;
              
              opkt_tx_packets_left_r <= opkt_tx_packets_left_r - 1;
              
              if (opkt_type_r = OPKT_P2H_TYPE) then
                p2h_rconf_upd_we_r <= '1';
              else
                h2p_wconf_upd_we_r <= '1';
              end if;
            end if;
            
            opkt_tx_length_r <= opkt_tx_length_r - HIBI_DATA_BYTE_WIDTH;
          end if;
      end case;
      
    end if;
  end process;
  
-----------------------------------------------------------------------------------------
-- HIBI to PC read/write configuration state memory port router:
-----------------------------------------------------------------------------------------
-- initialization:
-- --------------
-- (others => '0') => h2p_conf_state_mem_wdata
-- '1'             => h2p_conf_state_mem_we
--
-- normal operation:
-- ----------------
-- rw_chan_conf_index_r   => h2p_conf_state_mem_wdata
-- h2p_conf_state_mem_we_r => h2p_conf_state_mem_we
-----------------------------------------------------------------------------------------
  process (h2p_conf_state_init_done_r, h2p_conf_state_r, h2p_conf_state_we_r, hibi_msg_re_stall_r, hibi_msg_addr_in, hibi_msg_raddr_r)
  begin
    if (h2p_conf_state_init_done_r = '0') then
      h2p_conf_state_wdata <= (others => '0');
      h2p_conf_state_we <= '1';
    else
      h2p_conf_state_wdata <= h2p_conf_state_r;
      h2p_conf_state_we <= h2p_conf_state_we_r;
    end if;
    
    if (hibi_msg_re_stall_r = '0') then
      h2p_conf_state_rindex <= hibi_msg_addr_in(H2P_CHANS_WIDTH downto 0);
    else
      h2p_conf_state_rindex <= hibi_msg_raddr_r(H2P_CHANS_WIDTH downto 0);
    end if;
  end process;
  
------------------------------------------------------------------------------------------
-- H2P read/write configuration state memory
------------------------------------------------------------------------------------------
  h2p_conf_state_mem : entity work.onchip_mem_sc
  generic map ( DATA_WIDTH => H2P_CONF_STATE_WIDTH,
                ADDR_WIDTH => H2P_CHANS_WIDTH + 1,
                MEM_SIZE   => H2P_CHANS*2 )
  
  port map ( clk         => clk,
             addr_0_in   => h2p_conf_state_rindex,
             addr_1_in   => h2p_conf_state_windex_r,
             wdata_0_in  => (others => '0'),
             wdata_1_in  => h2p_conf_state_wdata,
             we_0_in     => '0',
             we_1_in     => h2p_conf_state_we,
             be_0_in     => (others => '0'),
             be_1_in     => (others => '1'),
             rdata_0_out => h2p_conf_state_rdata );
--             rdata_1_out => p2h_opkt_conf_rdata_1 );
  
  
  
------------------------------------------------------------------------------------------
-- HDMA request control
------------------------------------------------------------------------------------------
  req_ctrl : entity work.req_ctrl
  generic map ( COMPONENTS => P2H_HDMA_ADDR_SPACES*2,
                COMPONENTS_WIDTH => P2H_HDMA_ADDR_SPACES_WIDTH+1,
                DATA_WIDTH => HDMA_CHANNELS_WIDTH,
                MIN_COMP_REQS => HDMA_REQS_MIN )

  port map (
    clk   => clk,
    rst_n => rst_n,
    
    init_done_out => p2h_req_init_done,
    
    req_re_in => p2h_req_re_r,
    req_ready_out => p2h_req_ready,
    req_rcomp_in  => p2h_req_rcomp_r,
    req_rdata_out => p2h_req_offset,
    
    req_tx_out      => p2h_req_tx,
    req_tx_ready_in => p2h_req_tx_ready,
    req_tx_comp_out => p2h_req_tx_hibi_dma_comp,
    
    ack_rx_in       => p2h_ack_rx,
    ack_rx_valid_in => p2h_ack_rx_valid,
    ack_rx_comp_in  => p2h_ack_rx_hibi_dma_comp,
    ack_rx_data_in  => p2h_ack_rx_hibi_dma_offset );
  
  process (clk, rst_n)
    variable p2h_req_base_addr_v : std_logic_vector(HIBI_DATA_WIDTH-HDMA_CHANNELS_WIDTH-1 downto 0);
  begin
    if (rst_n = '0') then
      p2h_req_tx_we_r <= '0';
      p2h_req_tx_wdata_r <= (others => '0');
      p2h_req_tx_waddr_r <= (others => '0');
    
    elsif (clk'event and clk = '1') then
      p2h_req_tx_wdata_r(HIBI_DATA_WIDTH-1 downto HIBI_LOWER_ADDR_RANGE+3) <= HIBI_IF_ADDR(HIBI_DATA_WIDTH-1 downto HIBI_LOWER_ADDR_RANGE+3);
      
      if (p2h_req_tx = '1') then
        p2h_req_tx_we_r <= '1';
        p2h_req_tx_wdata_r(HIBI_LOWER_ADDR_RANGE+2 downto 0) <= P2H_ACK_BASE_OFFSET(HIBI_LOWER_ADDR_RANGE+2 downto P2H_HDMA_ADDR_SPACES_WIDTH+1) & p2h_req_tx_hibi_dma_comp;
        
        if ((P2H_HDMA_ADDR_SPACES = 1) or ( (P2H_HDMA_ADDR_SPACES > 0) and (p2h_req_tx_hibi_dma_comp(P2H_HDMA_ADDR_SPACES_WIDTH downto 1) = 0)) ) then
          p2h_req_base_addr_v := P2H_ADDR_0_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CHANNELS_WIDTH);
        elsif ((P2H_HDMA_ADDR_SPACES > 1) and (p2h_req_tx_hibi_dma_comp(P2H_HDMA_ADDR_SPACES_WIDTH downto 1) = 1)) then
          p2h_req_base_addr_v := P2H_ADDR_1_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CHANNELS_WIDTH);
        elsif ((P2H_HDMA_ADDR_SPACES > 2) and (p2h_req_tx_hibi_dma_comp(P2H_HDMA_ADDR_SPACES_WIDTH downto 1) = 2)) then
          p2h_req_base_addr_v := P2H_ADDR_2_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CHANNELS_WIDTH);
        elsif ((P2H_HDMA_ADDR_SPACES > 3) and (p2h_req_tx_hibi_dma_comp(P2H_HDMA_ADDR_SPACES_WIDTH downto 1) = 3)) then
          p2h_req_base_addr_v := P2H_ADDR_3_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CHANNELS_WIDTH);
        elsif ((P2H_HDMA_ADDR_SPACES > 4) and (p2h_req_tx_hibi_dma_comp(P2H_HDMA_ADDR_SPACES_WIDTH downto 1) = 4)) then
          p2h_req_base_addr_v := P2H_ADDR_4_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CHANNELS_WIDTH);
        elsif ((P2H_HDMA_ADDR_SPACES > 5) and (p2h_req_tx_hibi_dma_comp(P2H_HDMA_ADDR_SPACES_WIDTH downto 1) = 5)) then
          p2h_req_base_addr_v := P2H_ADDR_5_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CHANNELS_WIDTH);
        elsif ((P2H_HDMA_ADDR_SPACES > 6) and (p2h_req_tx_hibi_dma_comp(P2H_HDMA_ADDR_SPACES_WIDTH downto 1) = 6)) then
          p2h_req_base_addr_v := P2H_ADDR_6_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CHANNELS_WIDTH);
        elsif ((P2H_HDMA_ADDR_SPACES > 7) and (p2h_req_tx_hibi_dma_comp(P2H_HDMA_ADDR_SPACES_WIDTH downto 1) = 7)) then
          p2h_req_base_addr_v := P2H_ADDR_7_HIBI_BASE(HIBI_DATA_WIDTH-1 downto HDMA_CHANNELS_WIDTH);
        end if;
        
        p2h_req_tx_waddr_r(HIBI_DATA_WIDTH-1 downto HDMA_CHANNELS_WIDTH) <= p2h_req_base_addr_v;
        if (p2h_req_tx_hibi_dma_comp(0) = '1') then
          p2h_req_tx_waddr_r(HDMA_CHANNELS_WIDTH-1 downto 0) <= HDMA_WR_REQ_OFFSET;
        else
          p2h_req_tx_waddr_r(HDMA_CHANNELS_WIDTH-1 downto 0) <= HDMA_RD_REQ_OFFSET;
        end if;
      end if;
      
      if (p2h_req_tx_ready = '1') then
        p2h_req_tx_we_r <= '0';
      end if;
      
    end if;
  end process;
  
  p2h_ack_rx_hibi_dma_comp <= hibi_msg_addr_in(P2H_HDMA_ADDR_SPACES_WIDTH downto 0);
  p2h_ack_rx_hibi_dma_offset <= hibi_msg_data_in(HDMA_CHANNELS_WIDTH-1 downto 0);
  
  process (hibi_msg_re_r, hibi_msg_empty_in, hibi_msg_addr_in(10 downto 8), hibi_msg_data_in, p2h_req_tx_we_r, hibi_msg_we_r, hibi_msg_full_in)
  begin
    if ((p2h_req_tx_we_r = '1') and (hibi_msg_we_r = '0') and (hibi_msg_full_in = '0')) then
      p2h_req_tx_ready <= '1';
    else
      p2h_req_tx_ready <= '0';
    end if;
    
    
    if ((hibi_msg_re_r = '1') and (hibi_msg_empty_in = '0') and (hibi_msg_addr_in(10 downto 8) = P2H_ACK_BASE_OFFSET(10 downto 8))) then
      p2h_ack_rx <= '1';
    else
      p2h_ack_rx <= '0';
    end if;
    
    if (hibi_msg_data_in /= 0) then
      p2h_ack_rx_valid <= '1';
    else
      p2h_ack_rx_valid <= '0';
    end if;
  end process;
  
------------------------------------------------------------------------------------------
-- PC to HIBI output packet conf memory
------------------------------------------------------------------------------------------
  p2h_opkt_conf_mem : entity work.onchip_mem_sc
  generic map ( DATA_WIDTH => P2H_RCONF_WIDTH,
                ADDR_WIDTH => P2H_RD_CHANS_WIDTH,
                MEM_SIZE   => P2H_RD_CHANS )
  
  port map ( clk         => clk,
             addr_0_in   => opkt_buf_reserve_index,
             addr_1_in   => opkt_buf_filled_index,
             wdata_0_in  => p2h_rconf_wdata,
             wdata_1_in  => p2h_rconf_upd_wdata,
             we_0_in     => p2h_rconf_we_r,
             we_1_in     => p2h_rconf_upd_we_r,
             be_0_in     => (others => '1'),
             be_1_in     => (others => '1'),
--             rdata_0_out => p2h_opkt_conf_rdata_0,
             rdata_1_out => p2h_rconf_upd_rdata );
  
  p2h_rconf_lower_addr_rv <= p2h_rconf_upd_rdata(P2H_LOWER_ADDR_U downto P2H_LOWER_ADDR_L);
  p2h_rconf_total_amount_rv <= p2h_rconf_upd_rdata(P2H_TOTAL_AMOUNT_U downto P2H_TOTAL_AMOUNT_L);
  p2h_rconf_packets_left_rv <= p2h_rconf_upd_rdata(P2H_PARTS_LEFT_U downto P2H_PARTS_LEFT_L);
  p2h_rconf_req_id_rv <= p2h_rconf_upd_rdata(P2H_REQ_ID_U downto P2H_REQ_ID_L);
  p2h_rconf_tag_rv <= p2h_rconf_upd_rdata(P2H_TAG_U downto P2H_TAG_L);
  
  p2h_rconf_wdata(P2H_LOWER_ADDR_U downto P2H_LOWER_ADDR_L) <= ipkt_addr_in(PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  p2h_rconf_wdata(P2H_TOTAL_AMOUNT_U downto P2H_TOTAL_AMOUNT_L) <= ipkt_length_in;
  p2h_rconf_wdata(P2H_PARTS_LEFT_U downto P2H_PARTS_LEFT_L) <= ipkt_length_in(HIBI_RW_LENGTH_WIDTH-1 downto PCIE_CPL_LENGTH_MIN_WIDTH);
  p2h_rconf_wdata(P2H_REQ_ID_U downto P2H_REQ_ID_L) <= ipkt_req_id_in;
  p2h_rconf_wdata(P2H_TAG_U downto P2H_TAG_L) <= ipkt_tag_in;
  
  p2h_rconf_upd_wdata(P2H_LOWER_ADDR_U downto P2H_LOWER_ADDR_L) <= opkt_tx_addr_r(PCIE_LOWER_ADDR_WIDTH-1 downto 0);
  p2h_rconf_upd_wdata(P2H_TOTAL_AMOUNT_U downto P2H_TOTAL_AMOUNT_L) <= opkt_tx_length_total_r;
  p2h_rconf_upd_wdata(P2H_PARTS_LEFT_U downto P2H_PARTS_LEFT_L) <= opkt_tx_packets_left_r;
  p2h_rconf_upd_wdata(P2H_REQ_ID_U downto P2H_REQ_ID_L) <= opkt_tx_req_id_r;
  p2h_rconf_upd_wdata(P2H_TAG_U downto P2H_TAG_L) <= opkt_tx_tag_r;
  
  
  
-----------------------------------------------------------------------------------------
-- HIBI to PC configuration memory routers:
-----------------------------------------------------------------------------------------
  process (h2p_conf_state_init_done_r, h2p_conf_state_windex_r, cur_h2p_chan_r, h2p_conf_load_data_r, h2p_rconf_we_r, h2p_wconf_we_r)
  begin
    if (h2p_conf_state_init_done_r = '0') then
      h2p_rconf_addr <= h2p_conf_state_windex_r(H2P_RD_CHANS_WIDTH-1 downto 0);
      h2p_rconf_wdata <= (others => '0');
      h2p_rconf_we <= '1';
      h2p_wconf_addr <= h2p_conf_state_windex_r(H2P_WR_CHANS_WIDTH-1 downto 0);
      h2p_wconf_wdata <= (others => '0');
      h2p_wconf_we <= '1';
    else
      h2p_rconf_addr <= cur_h2p_chan_r(H2P_RD_CHANS_WIDTH-1 downto 0);
      h2p_rconf_wdata <= h2p_conf_load_data_r(H2P_RCONF_WIDTH-1 downto 0);
      h2p_rconf_we <= h2p_rconf_we_r;
      h2p_wconf_addr <= cur_h2p_chan_r(H2P_WR_CHANS_WIDTH-1 downto 0);
      h2p_wconf_wdata <= h2p_conf_load_data_r(H2P_WCONF_WIDTH-1 downto 0);
      h2p_wconf_we <= h2p_wconf_we_r;
    end if;
  end process;

------------------------------------------------------------------------------------------
-- H2P read configuration memory
------------------------------------------------------------------------------------------
  h2p_rd_conf_mem : entity work.onchip_mem_sc
  generic map ( DATA_WIDTH => H2P_RCONF_WIDTH,
                ADDR_WIDTH => H2P_RD_CHANS_WIDTH,
                MEM_SIZE   => H2P_RD_CHANS )
  
  port map ( clk         => clk,
             addr_0_in   => h2p_rconf_addr,
             addr_1_in   => ipkt_tag_in(H2P_RD_CHANS_WIDTH-1 downto 0),
             wdata_0_in  => h2p_rconf_wdata,
             wdata_1_in  => h2p_rconf_upd_wdata,
             we_0_in     => h2p_rconf_we,
             we_1_in     => h2p_rconf_upd_we_r,
             be_0_in     => (others => '1'),
             be_1_in     => (others => '1'),
             rdata_0_out => h2p_rconf_rdata,
             rdata_1_out => h2p_rconf_upd_rdata );

  h2p_rconf_addr_rv <= h2p_rconf_upd_rdata(H2P_ADDR_U downto H2P_ADDR_L);
  h2p_rconf_total_amount_rv <= h2p_rconf_upd_rdata(H2P_TOTAL_AMOUNT_U downto H2P_TOTAL_AMOUNT_L);
  h2p_rconf_ret_addr_rv <= h2p_rconf_upd_rdata(H2P_RET_ADDR_U downto H2P_RET_ADDR_L);
  h2p_rconf_started_rv <= h2p_rconf_upd_rdata(H2P_CONF_STARTED_L);
  h2p_rconf_done_rv <= h2p_rconf_upd_rdata(H2P_CONF_DONE_L);
  
  h2p_rconf_upd_wdata(H2P_ADDR_U downto H2P_ADDR_L) <= h2p_rconf_addr_rv;
  h2p_rconf_upd_wdata(H2P_TOTAL_AMOUNT_U downto H2P_TOTAL_AMOUNT_L) <= hibi_wr_length_r;
  h2p_rconf_upd_wdata(H2P_RET_ADDR_U downto H2P_RET_ADDR_L) <= h2p_rconf_ret_addr_rv;
  h2p_rconf_upd_wdata(H2P_CONF_STARTED_L) <= not(h2p_rd_last_part_r);
  h2p_rconf_upd_wdata(H2P_CONF_DONE_L) <= not(h2p_rd_last_part_r);
  
  
  process (h2p_rd_res_init_done_r, h2p_conf_state_windex_r, h2p_rd_res_we_r)
  begin
    if (h2p_rd_res_init_done_r = '0') then
      h2p_rd_res_wdata <= h2p_conf_state_windex_r(H2P_RD_CHANS_WIDTH-1 downto 0);
      h2p_rd_res_we <= '1';
    else
      h2p_rd_res_wdata <= h2p_conf_state_windex_r(H2P_RD_CHANS_WIDTH-1 downto 0);
      h2p_rd_res_we <= h2p_rd_res_we_r;
    end if;
  end process;
  
  h2p_rd_res_fifo : entity work.fifo_sc
	generic map ( DATA_WIDTH => H2P_RD_CHANS_WIDTH,
                FIFO_LENGTH => H2P_RD_CHANS,
                CNT_WIDTH => H2P_RD_CHANS_WIDTH )
            
  port map ( clk => clk,
		         rst_n => rst_n,
             wdata_in => h2p_rd_res_wdata,
		         rdata_out => h2p_rd_res_rdata,
             re_in => h2p_rd_res_re_r,
            we_in => h2p_rd_res_we,
            empty_out => h2p_rd_res_empty );
  
  h2p_rd_cfg_wdata <= (others => '0');

  h2p_rd_cfg_fifo : entity work.fifo_sc
	generic map ( DATA_WIDTH => H2P_RD_CHANS_WIDTH,
                FIFO_LENGTH => H2P_RD_CHANS,
                CNT_WIDTH => H2P_RD_CHANS_WIDTH )
            
  port map ( clk => clk,
		         rst_n => rst_n,
             wdata_in => h2p_rd_cfg_wdata,
		         rdata_out => h2p_rd_cfg_rdata,
             re_in => h2p_rd_cfg_re_r,
		         we_in => h2p_rd_cfg_we_r,
		         empty_out => h2p_rd_cfg_empty );

------------------------------------------------------------------------------------------
-- HIBI to PC write conf memory
------------------------------------------------------------------------------------------
  h2p_opkt_conf_mem : entity work.onchip_mem_sc
  generic map ( DATA_WIDTH => H2P_WCONF_WIDTH,
                ADDR_WIDTH => H2P_WR_CHANS_WIDTH,
                MEM_SIZE   => H2P_WR_CHANS )
  
  port map ( clk         => clk,
             addr_0_in   => h2p_wconf_addr,
             addr_1_in   => opkt_buf_filled_index,
             wdata_0_in  => h2p_wconf_wdata,
             wdata_1_in  => h2p_wconf_upd_wdata,
             we_0_in     => h2p_wconf_we,
             we_1_in     => h2p_wconf_upd_we_r,
             be_0_in     => (others => '1'),
             be_1_in     => (others => '1'),
             rdata_0_out => h2p_wconf_rdata,
             rdata_1_out => h2p_wconf_upd_rdata );
  
  
  h2p_wconf_addr_rv <= h2p_wconf_upd_rdata(H2P_ADDR_U downto H2P_ADDR_L);
  h2p_wconf_length_total_rv <= h2p_wconf_upd_rdata(H2P_TOTAL_AMOUNT_U downto H2P_TOTAL_AMOUNT_L);
  h2p_wconf_packets_left_rv <= h2p_wconf_upd_wdata(H2P_PARTS_LEFT_U downto H2P_PARTS_LEFT_L);
  h2p_wconf_started_rv <= h2p_wconf_upd_rdata(H2P_CONF_STARTED_L);
  h2p_wconf_done_rv <= h2p_wconf_upd_rdata(H2P_CONF_DONE_L);
  
  h2p_wconf_upd_wdata(H2P_ADDR_U downto H2P_ADDR_L) <= opkt_tx_addr_r;
  h2p_wconf_upd_wdata(H2P_TOTAL_AMOUNT_U downto H2P_TOTAL_AMOUNT_L) <= opkt_tx_length_total_r;
  h2p_wconf_upd_wdata(H2P_PARTS_LEFT_U downto H2P_PARTS_LEFT_L) <= opkt_tx_packets_left_r;
  h2p_wconf_upd_wdata(H2P_CONF_STARTED_L) <= not(opkt_tx_buf_done_r);
  h2p_wconf_upd_wdata(H2P_CONF_DONE_L) <= not(opkt_tx_buf_done_r);
  
------------------------------------------------------------------------------------------
-- output packet buffer
------------------------------------------------------------------------------------------
  opkt_buf : entity work.pkt_buf
  generic map ( DATA_WIDTH   => HIBI_DATA_WIDTH,
--                RDATA_WIDTH   => HIBI_DATA_WIDTH,
                
                BUFFERS                => OPKT_BUFFERS,
                BUFFERS_WIDTH          => OPKT_BUFFERS_WIDTH,
                BUF_SIZE               => PCIE_CPL_HIBI_LENGTH_MIN*OPKT_BUF_PARTS,
                BUF_SIZE_WIDTH         => log2_ceil(PCIE_CPL_HIBI_LENGTH_MIN*OPKT_BUF_PARTS-1),
                BUF_PART_SIZE          => PCIE_CPL_HIBI_LENGTH_MIN,
                BUF_PART_SIZE_WIDTH    => log2_ceil(PCIE_CPL_HIBI_LENGTH_MIN-1),
                BUF_PARTS              => OPKT_BUF_PARTS,
                BUF_PARTS_WIDTH        => OPKT_BUF_PARTS_WIDTH,
                BUF_TYPE_WIDTH         => OPKT_TYPES_WIDTH,
                BUF_TOTAL_AMOUNT_WIDTH => HIBI_RW_LENGTH_WIDTH,
                ADDR_TO_LIMIT_WIDTH    => ADDR_TO_LIMIT_WIDTH )
  
  port map ( clk   => clk,
             rst_n => rst_n,
    
             init_done_out => opkt_buf_init_done,
    
             buf_reserve_in        => opkt_buf_reserve,
             buf_reserve_index_out => opkt_buf_reserve_index,
             buf_reserve_ready_out => opkt_buf_reserve_ready,

             buf_release_in => opkt_tx_buf_done_r,
             buf_release_index_in => opkt_buf_index_r,
             
             buf_conf_we_in     => opkt_buf_conf_we,
             buf_conf_type_in   => opkt_buf_conf_type,
             buf_conf_amount_in => opkt_buf_conf_amount,
             buf_conf_addr_to_limit_in => opkt_buf_conf_addr_to_limit,
             buf_conf_index_in  => opkt_buf_conf_index,
             buf_conf_ready_out => opkt_buf_conf_ready,
    
             buf_filled_re_in      => opkt_buf_filled_re_r,
             buf_filled_empty_out  => opkt_buf_filled_empty,
             buf_filled_size_out  => opkt_buf_filled_size,
             buf_filled_index_out  => opkt_buf_filled_index,
             buf_filled_type_out   => opkt_buf_filled_type,
             buf_filled_amount_out => opkt_buf_filled_amount,
    
             buf_we_in     => opkt_buf_we,
             buf_windex_in => buf_windex, --hibi_addr_in(OPKT_BUFFERS_WIDTH-1 downto 0),
             buf_wdata_in  => hibi_data_in,
    
             buf_wr_stall_out => opkt_buf_wr_stall,
             
             buf_read_start_in => opkt_buf_start_r,
             buf_ready_out => opkt_buf_ready,
             buf_re_in     => opkt_buf_re_r,
             buf_rindex_in => opkt_buf_index_r,
             buf_rdata_out => opkt_data_out );
  
  
  opkt_buf_we <= not(hibi_empty_in);
  
  opkt_buf_reserve <= p2h_buf_reserve_r or h2p_buf_reserve_r;
  p2h_buf_reserve_ready <= opkt_buf_reserve_ready;
  h2p_buf_reserve_ready <= opkt_buf_reserve_ready and not(p2h_buf_reserve_r);
  
  opkt_buf_conf_we <= p2h_buf_conf_we_r or h2p_buf_conf_we_r;
  p2h_buf_conf_ready <= opkt_buf_conf_ready;
  h2p_buf_conf_ready <= opkt_buf_conf_ready and not(p2h_buf_conf_we_r);
  
  process (p2h_buf_conf_we_r, p2h_buf_index_r, h2p_buf_conf_amount_r, h2p_buf_index_r, ipkt_length_in, h2p_conf_load_data_r, ipkt_addr_to_limit_in, h2p_buf_conf_addr_to_limit_r)
  begin
    if (p2h_buf_conf_we_r = '1') then
      opkt_buf_conf_type <= OPKT_P2H_TYPE; --p2h_buf_conf_type_r;
      opkt_buf_conf_amount <= ipkt_length_in; --p2h_buf_conf_amount_r;
      opkt_buf_conf_addr_to_limit <= ipkt_addr_to_limit_in;
      opkt_buf_conf_index <= p2h_buf_index_r;
    else
      opkt_buf_conf_type <= OPKT_H2P_TYPE; --h2p_buf_conf_type_r;
      opkt_buf_conf_amount <= h2p_buf_conf_amount_r;
      opkt_buf_conf_addr_to_limit <= h2p_buf_conf_addr_to_limit_r(ADDR_TO_LIMIT_WIDTH-1 downto 0);
      opkt_buf_conf_index <= h2p_buf_index_r;
    end if;
  end process;
  
--  opkt_tx_buf_done <= p2h_opkt_tx_buf_done_r or h2p_opkt_tx_buf_done_r;
--  h2p_opkt_tx_buf_done_ready <= not(p2h_opkt_tx_buf_done_r);
  
--   process (p2h_opkt_tx_buf_done_r, opkt_buf_index_r, h2p_opkt_tx_buf_done_index_r)
--   begin
--     if (p2h_opkt_tx_buf_done_r = '1') then
--       opkt_tx_buf_done_index <= opkt_buf_index_r;
--     else
--       opkt_tx_buf_done_index <= h2p_opkt_tx_buf_done_index_r;
--     end if;
--   end process;
  
end rtl;
