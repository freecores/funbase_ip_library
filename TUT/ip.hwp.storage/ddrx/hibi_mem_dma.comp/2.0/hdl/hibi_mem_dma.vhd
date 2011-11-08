-------------------------------------------------------------------------------
-- Title      : HIBI MEM DMA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : hibi_mem_dma.vhd
-- Author     : 
-- Company    : 
-- Last update: 09.08.2010
-- Version    : 0.2
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
--
-------------------------------------------------------------------------------
-- Copyright (c) 2010
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 14.06.2010   0.1     arvio     Created
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
use ieee.numeric_std.all;

-- synthesis translate_off
use std.textio.all;
use work.txt_util.all;
-- synthesis translate_on

entity hibi_mem_dma is

  generic ( HIBI_DATA_WIDTH : integer := 32;
            HIBI_COM_WIDTH : integer := 3;
            HIBI_COM_WR     : std_logic_vector(15 downto 0) := x"0002"; -- hibi rev 2 com defaults
            HIBI_COM_RD     : std_logic_vector(15 downto 0) := x"0004";
            HIBI_COM_MSG_WR : std_logic_vector(15 downto 0) := x"0003";
--            HIBI_COM_MSG_RD : std_logic_vector(15 downto 0) := x"0000";
            
            HIBI_COMP_ADDR_WIDTH : integer := 8;
            
            MEM_DATA_WIDTH  : integer := 32;
            MEM_ADDR_WIDTH  : integer := 22;
            MEM_BE_WIDTH    : integer := 4;
            
            BURST_SIZE_WIDTH : integer := 1;
            
            READ_CHANNELS   : integer := 4;
            WRITE_CHANNELS  : integer := 4;
            
            RW_AMOUNT_WIDTH : integer := 20;
            RW_ADDR_INC_WIDTH   : integer := 14; -- RW_ADDR_INC_WIDTH + RW_ADDR_INTERVAL_WIDTH <= HIBI_DATA_WIDTH
            RW_ADDR_INTERVAL_WIDTH     : integer := 14;
            RW_ADDR_INTERVAL_INC_WIDTH : integer := 14; -- RW_ADDR_INTERVAL_INC_WIDTH <= HIBI_DATA_WIDTH
            DEBUG : integer := 0 );
            

  port (
    clk   : in std_logic;
    rst_n : in std_logic;

    hibi_addr_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_data_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_comm_in  : in  std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_empty_in : in  std_logic;
--    hibi_one_d_in : in  std_logic;
    hibi_re_out   : out std_logic;

    hibi_addr_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_data_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_comm_out : out std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_full_in  : in  std_logic;
--    hibi_one_p_in : in  std_logic;
    hibi_we_out   : out std_logic;

    hibi_msg_addr_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_data_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_comm_in  : in  std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_msg_empty_in : in  std_logic;
--    hibi_msg_one_d_in : in std_logic;
    hibi_msg_re_out   : out std_logic;

    hibi_msg_data_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_addr_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_comm_out : out std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_msg_full_in  : in  std_logic;
--    hibi_msg_one_p_in : in std_logic;
    hibi_msg_we_out   : out std_logic;

    
    mem_init_done_in   : in std_logic;
    
    mem_wr_req_out     : out std_logic;
    mem_rd_req_out     : out std_logic;
    mem_addr_out       : out std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
    mem_ready_in       : in  std_logic;
    mem_rdata_valid_in : in  std_logic;

    
    mem_wdata_out      : out std_logic_vector(MEM_DATA_WIDTH-1 downto 0);
    mem_rdata_in       : in  std_logic_vector(MEM_DATA_WIDTH-1 downto 0);
    
    mem_be_out         : out std_logic_vector(MEM_BE_WIDTH-1 downto 0);
    
    mem_burst_begin_out : out std_logic;
	  mem_burst_size_out  : out std_logic_vector(BURST_SIZE_WIDTH-1 downto 0) );

end hibi_mem_dma;

architecture rtl of hibi_mem_dma is

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
  
  constant HCOM_WR : unsigned(HIBI_COM_WIDTH-1 downto 0) := unsigned(HIBI_COM_WR(HIBI_COM_WIDTH-1 downto 0));
  constant HCOM_RD : unsigned(HIBI_COM_WIDTH-1 downto 0) := unsigned(HIBI_COM_RD(HIBI_COM_WIDTH-1 downto 0));
  constant HCOM_MSG_WR : unsigned(HIBI_COM_WIDTH-1 downto 0) := unsigned(HIBI_COM_MSG_WR(HIBI_COM_WIDTH-1 downto 0));
--  constant HCOM_MSG_RD : unsigned(HIBI_COM_WIDTH-1 downto 0) := unsigned(HIBI_COM_MSG_RD(HIBI_COM_WIDTH-1 downto 0));
  
  constant CONF : std_logic := '0';
  constant DIRECT : std_logic := '1';
  
  constant HIBI_ADDR_CMP_WIDTH : integer := HIBI_DATA_WIDTH - HIBI_COMP_ADDR_WIDTH;
  
  constant DIRECT_RW_ADDR_U : integer := min(HIBI_ADDR_CMP_WIDTH-1, MEM_ADDR_WIDTH+1);
  
  constant READ_CHANNELS_WIDTH : integer := log2_ceil(READ_CHANNELS-1);
  constant WRITE_CHANNELS_WIDTH : integer := log2_ceil(WRITE_CHANNELS-1);
  constant RW_CHANNELS_WIDTH : integer := maximum(WRITE_CHANNELS_WIDTH, READ_CHANNELS_WIDTH);
  
  constant WRITE_CHANNELS_MOD : integer := WRITE_CHANNELS
  -- synthesis translate_off
  + 1
  -- synthesis translate_on
  ;
  
  constant READ_CHANNELS_MOD : integer := READ_CHANNELS
  -- synthesis translate_off
  + 1
  -- synthesis translate_on
  ;
  
  
  constant MEM_BYTE_ADDR_WIDTH : integer := MEM_ADDR_WIDTH + log2_ceil(MEM_BE_WIDTH);
  
  
  constant HIBI_BE_WIDTH : integer := HIBI_DATA_WIDTH/8;
  
  constant WR_CONF_WIDTH : integer := MEM_ADDR_WIDTH + RW_AMOUNT_WIDTH + RW_ADDR_INC_WIDTH
                                      + RW_ADDR_INTERVAL_WIDTH*2 + RW_ADDR_INTERVAL_INC_WIDTH + 2 + HIBI_BE_WIDTH;
  
  constant RD_CONF_WIDTH : integer := MEM_ADDR_WIDTH + RW_AMOUNT_WIDTH + RW_ADDR_INC_WIDTH
                                      + RW_ADDR_INTERVAL_WIDTH*2 + RW_ADDR_INTERVAL_INC_WIDTH + 2 + HIBI_DATA_WIDTH;
  
  constant RW_MEM_ADDR_L : integer := 0;
  constant RW_MEM_ADDR_U : integer := RW_MEM_ADDR_L + MEM_ADDR_WIDTH - 1;
  constant RW_AMOUNT_L   : integer := RW_MEM_ADDR_U + 1;
  constant RW_AMOUNT_U   : integer := RW_AMOUNT_L + RW_AMOUNT_WIDTH - 1;
  constant RW_ADDR_INC_L : integer := RW_AMOUNT_U + 1;
  constant RW_ADDR_INC_U : integer := RW_ADDR_INC_L + RW_ADDR_INC_WIDTH - 1;
  constant RW_ADDR_INTERVAL_L : integer := RW_ADDR_INC_U + 1;
  constant RW_ADDR_INTERVAL_U : integer := RW_ADDR_INTERVAL_L + RW_ADDR_INTERVAL_WIDTH - 1;
  constant RW_ADDR_INTERVAL_CNT_L : integer := RW_ADDR_INTERVAL_U + 1;
  constant RW_ADDR_INTERVAL_CNT_U : integer := RW_ADDR_INTERVAL_CNT_L + RW_ADDR_INTERVAL_WIDTH - 1;
  constant RW_ADDR_INTERVAL_INC_L : integer := RW_ADDR_INTERVAL_CNT_U + 1;
  constant RW_ADDR_INTERVAL_INC_U : integer := RW_ADDR_INTERVAL_INC_L + RW_ADDR_INTERVAL_INC_WIDTH - 1;
  constant RW_CONF_STARTED_L : integer := RW_ADDR_INTERVAL_INC_U + 1;
  constant RW_CONF_STARTED_U : integer := RW_CONF_STARTED_L;
  constant RW_CONF_DONE_L : integer := RW_CONF_STARTED_U + 1;
  constant RW_CONF_DONE_U : integer := RW_CONF_DONE_L;
  constant RW_EXTRA_CONF_L : integer := RW_CONF_DONE_U + 1;
  
  constant RW_HIBI_RET_ADDR_L : integer := RW_EXTRA_CONF_L;
  constant RW_HIBI_RET_ADDR_U : integer := RW_HIBI_RET_ADDR_L + HIBI_DATA_WIDTH - 1;
  constant RW_MEM_BE_L : integer := RW_EXTRA_CONF_L;
  constant RW_MEM_BE_U : integer := RW_MEM_BE_L + HIBI_BE_WIDTH - 1;
  
  constant RW_CONF_STATE_WIDTH : integer := 3;
  
  constant MEM_RD_REQ_MAX_LENGTH : integer := 32;
  constant MEM_RD_REQ_MAX_WIDTH : integer := log2_ceil(MEM_RD_REQ_MAX_LENGTH);
  
  signal hibi_msg_re_r : std_logic;
  signal hibi_msg_rd_data : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_msg_rd_addr : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  
  signal hibi_msg_rd_data_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_msg_rd_addr_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_msg_rd_empty_r : std_logic;
  
  signal hibi_msg_re_stall_r : std_logic;
  
  
  
  signal hibi_msg_we_r : std_logic;
  signal hibi_msg_wr_data_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_msg_wr_addr_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  
  
  signal hibi_msg_ret_addr_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  
  signal hibi_re_r : std_logic;
  signal hibi_rd_data : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_rd_addr : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_rd_comm : unsigned(HIBI_COM_WIDTH-1 downto 0);
  signal hibi_rd_addr_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_rd_data_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_rd_comm_r : unsigned(HIBI_COM_WIDTH-1 downto 0);
  signal hibi_rd_empty_r : std_logic;
  
  signal hibi_rd_fifo_we_r : std_logic;
  signal hibi_rd_fifo_re_r : std_logic;
  
  signal hibi_rd_fifo_addr : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_rd_fifo_data : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_rd_fifo_comm : unsigned(HIBI_COM_WIDTH-1 downto 0);
  signal hibi_rd_fifo_full : std_logic;
  signal hibi_rd_fifo_one_p : std_logic;
  signal hibi_rd_fifo_empty : std_logic;
  signal hibi_rd_fifo_one_d : std_logic;
  
  signal hibi_rd_fifo_wdata : unsigned(HIBI_DATA_WIDTH*2+HIBI_COM_WIDTH-1 downto 0);
  signal hibi_rd_fifo_rdata : unsigned(HIBI_DATA_WIDTH*2+HIBI_COM_WIDTH-1 downto 0);
  signal hibi_rd_fifo_re : std_logic;
  
  signal hibi_rd_fifo_addr_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_rd_fifo_data_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_rd_fifo_comm_r : unsigned(HIBI_COM_WIDTH-1 downto 0);
  signal hibi_rd_fifo_empty_r : std_logic;
  signal hibi_rd_fifo_one_d_r : std_logic;
  
  
  signal hibi_we_r : std_logic;
  signal hibi_wr_data : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_wr_addr : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_wr_data_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal hibi_wr_addr_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  
  signal hibi_false_wr_r : std_logic;
  signal hibi_false_wr : std_logic;
  signal hibi_false_rd_r : std_logic;
  signal hibi_rd_fifo_false_rd_r : std_logic;
  
  signal rw_conf_load_state : std_logic;
  signal rw_conf_load_index_r : std_logic;
  signal rw_conf_load_index_d1_r : std_logic;
  signal rw_chan_conf_index_r : unsigned(RW_CONF_STATE_WIDTH-1 downto 0);
  signal rw_conf_load_data_part_r : std_logic;
  signal rw_conf_load_data_r : unsigned(RD_CONF_WIDTH-1 downto 0);
  
  signal cur_rw_chan_rd_r : std_logic;
  signal cur_rw_chan_wr_r : std_logic;
  signal cur_rw_chan_r : unsigned(RW_CHANNELS_WIDTH-1 downto 0);
  
  signal rw_conf_state_mem_raddr : unsigned(RW_CHANNELS_WIDTH downto 0);
  signal rw_conf_state_mem_rdata : unsigned(RW_CONF_STATE_WIDTH-1 downto 0);
  
  signal rw_conf_state_mem_waddr_r : unsigned(RW_CHANNELS_WIDTH downto 0);
  signal rw_conf_state_mem_wdata : unsigned(RW_CONF_STATE_WIDTH-1 downto 0);
  signal rw_conf_state_mem_we_r : std_logic;
  signal rw_conf_state_mem_we : std_logic;
  
  
  ------------------------------------------------------------------------------------
  -- write configuration memory
  ------------------------------------------------------------------------------------
  signal wr_conf_mem_we_0 : std_logic;
  signal wr_conf_mem_we_0_r : std_logic;
  signal wr_conf_mem_we_1_r : std_logic;
  signal wr_conf_mem_addr_0 : unsigned(WRITE_CHANNELS_WIDTH-1 downto 0);
  signal wr_conf_mem_addr_1_r : unsigned(WRITE_CHANNELS_WIDTH-1 downto 0);
  
  signal wr_conf_mem_wdata_0 : unsigned(WR_CONF_WIDTH-1 downto 0);
  signal wr_conf_mem_wdata_1 : unsigned(WR_CONF_WIDTH-1 downto 0);
  signal wr_conf_mem_rdata_0 : unsigned(WR_CONF_WIDTH-1 downto 0);
  signal wr_conf_mem_rdata_1 : unsigned(WR_CONF_WIDTH-1 downto 0);
  
  signal wr_mem_addr_rv          : unsigned(MEM_ADDR_WIDTH-1 downto 0);
  signal wr_amount_rv            : unsigned(RW_AMOUNT_WIDTH-1 downto 0);
  signal wr_addr_inc_rv          : unsigned(RW_ADDR_INC_WIDTH-1 downto 0);
  signal wr_addr_interval_rv     : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal wr_addr_interval_cnt_rv : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal wr_addr_interval_inc_rv : unsigned(RW_ADDR_INTERVAL_INC_WIDTH-1 downto 0);
  signal wr_be_rv                : unsigned(HIBI_BE_WIDTH-1 downto 0);
  signal wr_conf_started_rv      : std_ulogic;
  signal wr_conf_done_rv         : std_ulogic;

  signal wr_mem_addr_r          : unsigned(MEM_ADDR_WIDTH-1 downto 0);
  signal wr_amount_r            : unsigned(RW_AMOUNT_WIDTH-1 downto 0);
  signal wr_addr_inc_r          : unsigned(RW_ADDR_INC_WIDTH-1 downto 0);
  signal wr_addr_interval_r     : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal wr_addr_interval_cnt_r : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal wr_addr_interval_inc_r : unsigned(RW_ADDR_INTERVAL_INC_WIDTH-1 downto 0);
  signal wr_be_r                : unsigned(HIBI_BE_WIDTH-1 downto 0);
  signal wr_conf_started_r      : std_ulogic;
  signal wr_conf_done_r         : std_ulogic;
  
  signal load_wr_conf_r : std_logic;
  signal load_wr_conf_d1_r : std_logic;
  
  
  signal load_wr_conf_delayed_r : std_logic;
  
  ------------------------------------------------------------------------------------
  -- read configuration memory
  ------------------------------------------------------------------------------------
  signal rd_conf_mem_we_0 : std_logic;
  signal rd_conf_mem_we_0_r : std_logic;
  signal rd_conf_mem_we_1_r : std_logic;
  signal rd_conf_mem_addr_0 : unsigned(READ_CHANNELS_WIDTH-1 downto 0);
  signal rd_conf_mem_addr_1_r : unsigned(READ_CHANNELS_WIDTH-1 downto 0);
  
  signal rd_conf_mem_wdata_0 : unsigned(RD_CONF_WIDTH-1 downto 0);
  signal rd_conf_mem_wdata_1 : unsigned(RD_CONF_WIDTH-1 downto 0);
  signal rd_conf_mem_rdata_0 : unsigned(RD_CONF_WIDTH-1 downto 0);
  signal rd_conf_mem_rdata_1 : unsigned(RD_CONF_WIDTH-1 downto 0);
  
  signal rd_mem_addr_rv          : unsigned(MEM_ADDR_WIDTH-1 downto 0);
  signal rd_amount_rv            : unsigned(RW_AMOUNT_WIDTH-1 downto 0);
  signal rd_addr_inc_rv          : unsigned(RW_ADDR_INC_WIDTH-1 downto 0);
  signal rd_addr_interval_rv     : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal rd_addr_interval_cnt_rv : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal rd_addr_interval_inc_rv : unsigned(RW_ADDR_INTERVAL_INC_WIDTH-1 downto 0);
  signal rd_hibi_ret_addr_rv     : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal rd_conf_started_rv      : std_ulogic;
  signal rd_conf_done_rv         : std_ulogic;
    
  signal rd_mem_addr_r          : unsigned(MEM_ADDR_WIDTH-1 downto 0);
  signal rd_amount_r            : unsigned(RW_AMOUNT_WIDTH-1 downto 0);
  signal rd_addr_inc_r          : unsigned(RW_ADDR_INC_WIDTH-1 downto 0);
  signal rd_addr_interval_r     : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal rd_addr_interval_cnt_r : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal rd_addr_interval_inc_r : unsigned(RW_ADDR_INTERVAL_INC_WIDTH-1 downto 0);
  signal rd_hibi_ret_addr_r     : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal rd_conf_started_r      : std_ulogic;
  signal rd_conf_done_r         : std_ulogic;
  
  signal rw_conf_mem_init_done_r : std_logic;
  
  
  signal wr_chan_reserve_r : std_logic;
  signal rw_chan_reserve_busy_r : std_logic;
  
  signal rw_req_type_r : std_logic;

  signal rd_chan_reserve_r : std_logic;
  
  
  signal free_wr_chan_we_r : std_logic;
  signal free_wr_chan_re_r : std_logic;
  signal free_wr_chan_wdata_r : unsigned(WRITE_CHANNELS_WIDTH-1 downto 0) ;
  signal free_wr_chan_rdata : unsigned(WRITE_CHANNELS_WIDTH-1 downto 0) ;
  signal free_wr_chan_full : std_logic;
  signal free_wr_chan_empty : std_logic;
  
  signal free_rd_chan_we_r : std_logic;
  signal free_rd_chan_re_r : std_logic;
  signal free_rd_chan_wdata_r : unsigned(READ_CHANNELS_WIDTH-1 downto 0) ;
  signal free_rd_chan_rdata : unsigned(READ_CHANNELS_WIDTH-1 downto 0) ;
  signal free_rd_chan_full : std_logic;
  signal free_rd_chan_empty : std_logic;
  
  signal cur_wr_chan_r : unsigned(WRITE_CHANNELS_WIDTH-1 downto 0);
  
  signal free_wr_chan_init_done_r : std_logic;
  
  signal hibi_wr_data_fifo_re_r : std_logic;
  signal hibi_wr_data_fifo_re_tmp : std_logic;
  signal hibi_wr_cnt_r : unsigned(7 downto 0);
  
  signal ret_addr_we_r : std_logic;
  signal ret_addr_re_r : std_logic;
  signal ret_addr_re_tmp : std_logic;
  signal ret_addr_wdata_r : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  
  signal next_rd_chan_r : std_logic;
  
  signal free_rd_chan_r : unsigned(READ_CHANNELS_WIDTH-1 downto 0);
  signal cur_rd_chan_r : unsigned(READ_CHANNELS_WIDTH-1 downto 0);
--  signal rd_chan_empty_r : std_logic;
--  signal rd_chan_full_r : std_logic;
  
  
  signal mem_wr_req_r : std_logic;
  signal mem_rd_req_r : std_logic;
  signal mem_addr_r : unsigned(MEM_ADDR_WIDTH-1 downto 0);
  signal mem_wdata_r : unsigned(MEM_DATA_WIDTH-1 downto 0);
  signal mem_be_r : unsigned(MEM_BE_WIDTH-1 downto 0);
  
--  signal mem_burst_size_r : unsigned(1 downto 0);
  signal mem_burst_begin_r : std_logic;
  
  signal mem_rdata : unsigned(MEM_DATA_WIDTH-1 downto 0);
  
  signal mem_wr_delayed_r : std_logic;
  signal mem_rd_delayed_r : std_logic;
  
  signal mem_rd_cnt_r : unsigned(7 downto 0);
  
  type mem_rd_state_t is (MEM_RD_WAIT, MEM_RD_REQ, MEM_RD_DONE);
  signal mem_rd_state_r : mem_rd_state_t;
  
  
  --synthesis translate_off
  signal debug_hibi_rd_data : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal debug_hibi_rd_addr : unsigned(HIBI_DATA_WIDTH-1 downto 0);
  signal debug_hibi_rd_comm : unsigned(HIBI_COM_WIDTH-1 downto 0);
  signal debug_hibi_rd_empty : std_logic;
  
  signal debug_hibi_rd_addr_valid : std_logic;
  
  signal debug_wr_conf_mem_rdata : unsigned(WR_CONF_WIDTH-1 downto 0);
  
  signal debug_wr_mem_addr          : unsigned(MEM_ADDR_WIDTH-1 downto 0);
  signal debug_wr_amount            : unsigned(RW_AMOUNT_WIDTH-1 downto 0);
  signal debug_wr_addr_inc          : unsigned(RW_ADDR_INC_WIDTH-1 downto 0);
  signal debug_wr_addr_interval     : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal debug_wr_addr_interval_cnt : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
  signal debug_wr_addr_interval_inc : unsigned(RW_ADDR_INTERVAL_INC_WIDTH-1 downto 0);
  signal debug_wr_be                : unsigned(HIBI_BE_WIDTH-1 downto 0);
  signal debug_wr_conf_started      : std_ulogic;
  signal debug_wr_conf_done         : std_ulogic;
  
  signal debug_wr_conf_mem_stall_r : std_logic;
  
  signal debug_wr_chan_error : std_logic;
  
  --synthesis translate_on
  
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
  
  
  hibi_msg_rd_data <= unsigned(hibi_msg_data_in);
  hibi_msg_rd_addr <= unsigned(hibi_msg_addr_in);
  
  hibi_msg_data_out <= std_logic_vector(hibi_msg_wr_data_r);
  hibi_msg_addr_out <= std_logic_vector(hibi_msg_wr_addr_r);
  
  hibi_msg_re_out <= hibi_msg_re_r and not(hibi_msg_re_stall_r);
  hibi_msg_we_out <= hibi_msg_we_r;
  
  
  hibi_rd_data <= unsigned(hibi_data_in);
  hibi_rd_addr <= unsigned(hibi_addr_in);
  hibi_rd_comm <= unsigned(hibi_comm_in);
  
  hibi_re_out <= hibi_re_r and not(hibi_false_rd_r);
  hibi_we_out <= hibi_we_r;
  
  mem_wr_req_out <= mem_wr_req_r;
  mem_rd_req_out <= mem_rd_req_r;
  mem_addr_out <= std_logic_vector(mem_addr_r);
  mem_wdata_out <= std_logic_vector(mem_wdata_r);
  mem_be_out <= std_logic_vector(mem_be_r);
  
  mem_rdata <= unsigned(mem_rdata_in);
  
  gen_0 : if BURST_SIZE_WIDTH = 1 generate
  mem_burst_size_out <= "1";
  mem_burst_begin_out <= mem_wr_req_r or mem_rd_req_r;
  end generate;
  
  gen_1 : if BURST_SIZE_WIDTH > 1 generate
  mem_burst_size_out(1 downto 0) <= "01";
  mem_burst_begin_out <= mem_wr_req_r or mem_rd_req_r; --mem_burst_begin_r;
  end generate;
  
  gen_2 : if BURST_SIZE_WIDTH > 2 generate
  mem_burst_size_out(BURST_SIZE_WIDTH-1 downto 2) <= (others => '0');
  end generate;
  
--  mem_burst_size_out(0) <= '1';
  

  hibi_msg_comm_out <= std_logic_vector(HCOM_MSG_WR);           -- write message
  hibi_comm_out     <= std_logic_vector(HCOM_WR);           -- write data

  process (hibi_wr_data, hibi_wr_addr, hibi_wr_data_r, hibi_wr_addr_r, hibi_false_wr_r)
  begin
    if (hibi_false_wr_r = '0') then
      hibi_data_out <= std_logic_vector(hibi_wr_data);
      hibi_addr_out <= std_logic_vector(hibi_wr_addr);
    else
      hibi_data_out <= std_logic_vector(hibi_wr_data_r);
      hibi_addr_out <= std_logic_vector(hibi_wr_addr_r);
    end if;
  end process;

-----------------------------------------------------------------------------------------
-- HIBI reader:
-----------------------------------------------------------------------------------------
-- input: HIBI read interface
-- output: HIBI read fifo
-----------------------------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      hibi_re_r <= '0';
      hibi_rd_addr_r <= (others => '0');
      hibi_rd_data_r <= (others => '0');
      hibi_rd_comm_r <= (others => '0');
      hibi_rd_fifo_we_r <= '0';
      hibi_false_rd_r <= '0';
    elsif (clk'event and clk = '1') then
      
      if (hibi_false_rd_r = '0') then
        hibi_rd_addr_r <= hibi_rd_addr;
        hibi_rd_data_r <= hibi_rd_data;
        hibi_rd_comm_r <= hibi_rd_comm;
      else
        hibi_rd_addr_r <= hibi_rd_addr_r;
        hibi_rd_data_r <= hibi_rd_data_r;
        hibi_rd_comm_r <= hibi_rd_comm_r;
      end if;
      
      if ((hibi_re_r = '1') and (hibi_rd_fifo_one_p = '1')) then
        hibi_false_rd_r <= '1';
      end if;
      
      if ((hibi_empty_in = '0') and (hibi_rd_fifo_full = '0') and (hibi_rd_fifo_one_p = '0')) then
        hibi_re_r <= '1';
      else
        hibi_re_r <= '0';
      end if;
      
      if ((hibi_re_r = '1') and (hibi_empty_in = '0') and (hibi_rd_fifo_full = '0') and (hibi_rd_fifo_one_p = '0')) then
        hibi_rd_fifo_we_r <= '1';
        hibi_false_rd_r <= '0';
      else
        hibi_rd_fifo_we_r <= '0';
      end if;
    end if;
  end process;

-----------------------------------------------------------------------------------------
-- HIBI message reader:
-----------------------------------------------------------------------------------------
-- initialization:
-- --------------
-- increment rw_conf_state_mem_waddr_r from zero until it reaches maximum(WRITE_CHANNELS, READ_CHANNELS)*2 - 1
-- set rw_conf_mem_init_done_r <= '1' after reaching maximum
--
-- normal operation:
-- ----------------
-- Pass read and write channel requests to the channel request processer
-- Write read and write channel configurations to read or write configure memory
-----------------------------------------------------------------------------------------
  process (clk, rst_n)
    variable hibi_msg_rd_addr_v : unsigned(HIBI_DATA_WIDTH-1 downto 0);
    variable hibi_msg_rd_data_v : unsigned(HIBI_DATA_WIDTH-1 downto 0);
    variable hibi_msg_rd_empty_v : std_logic;
    variable rw_chan_conf_index_v : unsigned(RW_CONF_STATE_WIDTH-1 downto 0);
    variable rw_conf_done_v : std_logic;
    variable rw_conf_load_data_v : unsigned(RD_CONF_WIDTH-1 downto 0);
    variable rw_conf_load_v : std_logic;
  begin
    if (rst_n = '0') then
      hibi_msg_re_r <= '0';
      hibi_msg_rd_addr_r <= (others => '0');
      hibi_msg_rd_data_r <= (others => '0');
      hibi_msg_rd_empty_r <= '0';
      
      hibi_msg_re_stall_r <= '0';
      
      rd_chan_reserve_r <= '0';
      wr_chan_reserve_r <= '0';
      hibi_msg_ret_addr_r <= (others => '0');
      
      rw_conf_load_index_r <= '0';
      rw_conf_load_index_d1_r <= '0';
      rw_chan_conf_index_r <= "000";
      rw_conf_load_data_r <= (others => '0');
      
      rw_conf_state_mem_waddr_r <= (others => '0');
      rw_conf_state_mem_we_r <= '0';
      
      cur_rw_chan_rd_r <= '0';
      cur_rw_chan_wr_r <= '0';
      cur_rw_chan_r <= (others => '0');
      
      rw_conf_mem_init_done_r <= '0';
      
      wr_conf_mem_we_0_r <= '0';
      rd_conf_mem_we_0_r <= '0';
      
    elsif (clk'event and clk = '1') then
      hibi_msg_re_r <= '0';
      
      rd_chan_reserve_r <= '0';
      wr_chan_reserve_r <= '0';
      
      rw_conf_state_mem_we_r <= '0';
      rw_conf_load_index_r <= '0';
      rw_conf_load_index_d1_r <= rw_conf_load_index_r;
      rw_conf_load_v := '0';
      
      rw_conf_done_v := '0';
      
      wr_conf_mem_we_0_r <= '0';
      rd_conf_mem_we_0_r <= '0';
      
      -- increment rw_conf_state_mem_waddr_r until it reaches maximum(WRITE_CHANNELS, READ_CHANNELS)*2 - 1
      if (rw_conf_mem_init_done_r = '0') then
        if (rw_conf_state_mem_waddr_r = (maximum(WRITE_CHANNELS, READ_CHANNELS)*2 - 1)) then
          rw_conf_mem_init_done_r <= '1';
        end if;
        rw_conf_state_mem_waddr_r <= rw_conf_state_mem_waddr_r + 1;
      end if;
      
      -- if a hibi message read stall is occurring route the stored value of the HIBI address, data and empty to the next block
      if (hibi_msg_re_stall_r = '0') then
        hibi_msg_rd_addr_v := hibi_msg_rd_addr;
        hibi_msg_rd_data_v := hibi_msg_rd_data;
        hibi_msg_rd_empty_v := hibi_msg_empty_in;
      else
        hibi_msg_rd_addr_v := hibi_msg_rd_addr_r;
        hibi_msg_rd_data_v := hibi_msg_rd_data_r;
        hibi_msg_rd_empty_v := hibi_msg_rd_empty_r;
      end if;
      
      hibi_msg_rd_addr_r <= hibi_msg_rd_addr_v;
      hibi_msg_rd_data_r <= hibi_msg_rd_data_v;
      hibi_msg_rd_empty_r <= hibi_msg_rd_empty_v;
      
      ------------------------------------------------------------------------------------
      -- HIBI read message address demux:
      ------------------------------------------------------------------------------------
      if (free_wr_chan_init_done_r = '1') then
        if ((hibi_msg_re_r = '1') and (hibi_msg_rd_empty_v = '0')) then
          if (hibi_msg_rd_addr_v(HIBI_ADDR_CMP_WIDTH-1 downto 8) = 0) then
            case hibi_msg_rd_addr_v(7 downto 0) is
              when x"21" =>
                if (rw_chan_reserve_busy_r = '0') then
                  rd_chan_reserve_r <= '1';
                  hibi_msg_ret_addr_r <= hibi_msg_rd_data_v;
                  hibi_msg_re_stall_r <= '0';
                else
                  hibi_msg_re_stall_r <= '1';
                end if;
              when x"22" =>
                if (rw_chan_reserve_busy_r = '0') then
                  wr_chan_reserve_r <= '1';
                  hibi_msg_ret_addr_r <= hibi_msg_rd_data_v;
                  hibi_msg_re_stall_r <= '0';
                else
                  hibi_msg_re_stall_r <= '1';
                end if;
              when others =>
                rd_chan_reserve_r <= '0';
            end case;

          elsif ( (hibi_msg_rd_addr_v(HIBI_ADDR_CMP_WIDTH-1 downto 8) = 1) or (hibi_msg_rd_addr_v(HIBI_ADDR_CMP_WIDTH-1 downto 8) = 2) ) then
            if ( ((cur_rw_chan_wr_r & cur_rw_chan_rd_r) /= hibi_msg_rd_addr_v(9 downto 8)) or  (cur_rw_chan_r /= hibi_msg_rd_addr_v(RW_CHANNELS_WIDTH-1 downto 0)) ) then
              rw_conf_load_index_r <= '1';
              
              cur_rw_chan_rd_r <= hibi_msg_rd_addr_v(8);
              cur_rw_chan_wr_r <= hibi_msg_rd_addr_v(9);
              cur_rw_chan_r <= hibi_msg_rd_addr_v(RW_CHANNELS_WIDTH-1 downto 0);
              
              
              hibi_msg_re_stall_r <= '1';
              
            elsif (hibi_msg_re_stall_r = '0') then
              rw_conf_load_v := '1';
            end if;
          end if;
        end if;
        
        if (hibi_msg_rd_empty_v = '0') then
          hibi_msg_re_r <= '1';
        end if;
        
        if (rw_conf_load_index_d1_r = '1') then
          rw_conf_load_v := '1';
          rw_chan_conf_index_v := rw_conf_state_mem_rdata;
          rw_chan_conf_index_r <= rw_conf_state_mem_rdata;
          if (rw_chan_conf_index_v /= 0) then
            if (cur_rw_chan_wr_r = '1') then
              rw_conf_load_data_v(RD_CONF_WIDTH-1 downto WR_CONF_WIDTH) := (others => '0');
              rw_conf_load_data_v(WR_CONF_WIDTH-1 downto 0) := wr_conf_mem_rdata_0;
            else
              rw_conf_load_data_v := rd_conf_mem_rdata_0;
            end if;
          else
            rw_conf_load_data_v := (others => '0');
            rw_conf_load_data_v(RW_CONF_STARTED_L) := '1';
          end if;
          hibi_msg_re_stall_r <= '0';
        else
          rw_chan_conf_index_v := rw_chan_conf_index_r;
          rw_conf_load_data_v := rw_conf_load_data_r;
        end if;
        
        ------------------------------------------------------------------------------------
        -- R/W configuration processer:
        ------------------------------------------------------------------------------------
        if (rw_conf_load_v = '1') then
          rw_conf_load_data_r <= rw_conf_load_data_v;
          
          if (cur_rw_chan_wr_r = '1') then
            case rw_chan_conf_index_v is
              when "000" =>
                rw_conf_load_data_r(RW_MEM_ADDR_U downto RW_MEM_ADDR_L) <= hibi_msg_rd_data_v(MEM_ADDR_WIDTH + log2_ceil(MEM_BE_WIDTH-1) - 1 downto log2_ceil(MEM_BE_WIDTH-1));
                rw_conf_load_data_r(RW_ADDR_INTERVAL_CNT_U downto RW_ADDR_INTERVAL_CNT_L) <= (others => '0');
                rw_conf_load_data_r(RW_CONF_STARTED_L) <= '1';
              when "001" =>
                rw_conf_load_data_r(RW_AMOUNT_U downto RW_AMOUNT_L) <= hibi_msg_rd_data_v(RW_AMOUNT_WIDTH-1 downto 0);

              when "010" =>
                rw_conf_load_data_r(RW_ADDR_INC_U downto RW_ADDR_INC_L) <= hibi_msg_rd_data_v(RW_ADDR_INC_WIDTH-1 downto 0);
                rw_conf_load_data_r(RW_ADDR_INTERVAL_U downto RW_ADDR_INTERVAL_L) <= hibi_msg_rd_data_v(RW_ADDR_INC_WIDTH + RW_ADDR_INTERVAL_WIDTH - 1
                                                                                                      downto RW_ADDR_INC_WIDTH);
                
                if (hibi_msg_rd_data_v(RW_ADDR_INC_WIDTH + RW_ADDR_INTERVAL_WIDTH - 1 downto RW_ADDR_INC_WIDTH) = 0) then
                  rw_conf_load_data_r(RW_CONF_DONE_L) <= '1';
                  rw_conf_done_v := '1';
                end if;
              when others => -- "011" =>
                rw_conf_load_data_r(RW_ADDR_INTERVAL_INC_U downto RW_ADDR_INTERVAL_INC_L) <= hibi_msg_rd_data_v(RW_ADDR_INTERVAL_INC_WIDTH-1 downto 0);
                rw_conf_load_data_r(RW_CONF_DONE_L) <= '1';
                rw_conf_done_v := '1';
            end case;
            
          else
            case rw_chan_conf_index_v is
              when "000" =>
                rw_conf_load_data_r(RW_MEM_ADDR_U downto RW_MEM_ADDR_L) <= hibi_msg_rd_data_v(MEM_ADDR_WIDTH + log2_ceil(MEM_BE_WIDTH-1) - 1 downto log2_ceil(MEM_BE_WIDTH-1));
                rw_conf_load_data_r(RW_ADDR_INTERVAL_CNT_U downto RW_ADDR_INTERVAL_CNT_L) <= (others => '0');
                rw_conf_load_data_r(RW_CONF_STARTED_L) <= '1';
              when "001" =>
                rw_conf_load_data_r(RW_AMOUNT_U downto RW_AMOUNT_L) <= hibi_msg_rd_data_v(RW_AMOUNT_WIDTH-1 downto 0);
                rw_conf_load_data_r(RW_MEM_BE_U downto RW_MEM_BE_L) <= hibi_msg_rd_data_v(RW_AMOUNT_WIDTH + MEM_BE_WIDTH - 1 downto RW_AMOUNT_WIDTH);
              when "010" =>
                rw_conf_load_data_r(RW_HIBI_RET_ADDR_U downto RW_HIBI_RET_ADDR_L) <= hibi_msg_rd_data_v(HIBI_DATA_WIDTH-1 downto 0);
              when "011" =>
                rw_conf_load_data_r(RW_ADDR_INC_U downto RW_ADDR_INC_L) <= hibi_msg_rd_data_v(RW_ADDR_INC_WIDTH-1 downto 0);
                rw_conf_load_data_r(RW_ADDR_INTERVAL_U downto RW_ADDR_INTERVAL_L) <= hibi_msg_rd_data_v(RW_ADDR_INC_WIDTH + RW_ADDR_INTERVAL_WIDTH - 1 downto RW_ADDR_INC_WIDTH);
                if (hibi_msg_rd_data_v(RW_ADDR_INC_WIDTH + RW_ADDR_INTERVAL_WIDTH - 1 downto RW_ADDR_INC_WIDTH) = 0) then
                  rw_conf_load_data_r(RW_CONF_DONE_L) <= '1';
                  rw_conf_done_v := '1';
                end if;
              when others => -- "100" =>
                rw_conf_load_data_r(RW_ADDR_INTERVAL_INC_U downto RW_ADDR_INTERVAL_INC_L) <= hibi_msg_rd_data_v(RW_ADDR_INTERVAL_INC_WIDTH-1 downto 0);
                rw_conf_load_data_r(RW_CONF_DONE_L) <= '1';
                rw_conf_done_v := '1';
            end case;
            
          end if;
          
          wr_conf_mem_we_0_r <= cur_rw_chan_wr_r;
          rd_conf_mem_we_0_r <= cur_rw_chan_rd_r;
          
          rw_conf_state_mem_waddr_r <= cur_rw_chan_wr_r & cur_rw_chan_r;
          rw_conf_state_mem_we_r <= '1';
          
          if (rw_conf_done_v = '0') then
            rw_chan_conf_index_r <= rw_chan_conf_index_v + 1;
          else
            rw_chan_conf_index_r <= (others => '0');
          end if;
          
        end if;
      end if;
    end if;
  end process;
  
  
-----------------------------------------------------------------------------------------
-- Request processer:
-----------------------------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      hibi_msg_we_r <= '0';
      hibi_msg_wr_addr_r <= (others => '0');
      hibi_msg_wr_data_r <= (others => '0');
      
      rw_req_type_r <= '0';
      rw_chan_reserve_busy_r <= '0';
      
      free_wr_chan_re_r <= '0';
      free_rd_chan_re_r <= '0'; --next_rd_chan_r <= '0';
      
    elsif (clk'event and clk = '1') then
      hibi_msg_we_r <= '0';
      free_wr_chan_re_r <= '0';
      free_rd_chan_re_r <= '0'; --next_rd_chan_r <= '0';
      
      if (rd_chan_reserve_r = '1') then
        rw_chan_reserve_busy_r <= '1';
        rw_req_type_r <= '0';
      elsif (wr_chan_reserve_r = '1') then
        rw_chan_reserve_busy_r <= '1';
        rw_req_type_r <= '1';
      end if;
      
      if (rw_chan_reserve_busy_r = '1') then
        if (rw_req_type_r = '0') then
          if ((free_rd_chan_empty = '0') and (hibi_msg_full_in = '0')) then
            hibi_msg_we_r <= '1';
            hibi_msg_wr_addr_r <= hibi_msg_ret_addr_r;
            hibi_msg_wr_data_r <= (others => '0');
            hibi_msg_wr_data_r(31 downto 8) <= x"000001";
            hibi_msg_wr_data_r(READ_CHANNELS_WIDTH-1 downto 0) <= free_rd_chan_rdata; --free_rd_chan_r;
            
            free_rd_chan_re_r <= '1'; --next_rd_chan_r <= '1';
            rw_chan_reserve_busy_r <= '0';
          end if;
        
        else
          if ((free_wr_chan_empty = '0') and (hibi_msg_full_in = '0')) then
            hibi_msg_we_r <= '1';
            hibi_msg_wr_addr_r <= hibi_msg_ret_addr_r;
            hibi_msg_wr_data_r <= (others => '0');
            hibi_msg_wr_data_r(31 downto 8) <= x"000002";
            hibi_msg_wr_data_r(WRITE_CHANNELS_WIDTH-1 downto 0) <= free_wr_chan_rdata;
            
            free_wr_chan_re_r <= '1';
            rw_chan_reserve_busy_r <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  


-----------------------------------------------------------------------------------------
-- Mem. access processer:
-----------------------------------------------------------------------------------------
  process (clk, rst_n)
    variable hibi_rd_fifo_addr_v : unsigned(HIBI_DATA_WIDTH-1 downto 0);
    variable hibi_rd_fifo_data_v : unsigned(HIBI_DATA_WIDTH-1 downto 0);
    variable hibi_rd_fifo_comm_v : unsigned(HIBI_COM_WIDTH-1 downto 0);
    variable hibi_rd_fifo_empty_v : std_logic;
    variable hibi_rd_fifo_one_d_v : std_logic;
    
    variable hibi_rd_fifo_re_v : std_logic;
    
    variable hibi_rd_fifo_addr_valid_v : std_logic;
    variable wr_conf_mem_init_ptr_i_v : integer;
    variable rd_conf_mem_init_ptr_i_v : integer;
    
    variable wr_conf_mem_stall_v : std_logic;
    
    variable mem_wr_req_v : std_logic;
    variable mem_rd_req_v : std_logic;
    variable mem_addr_v : unsigned(MEM_ADDR_WIDTH-1 downto 0);
    
    variable wr_mem_addr_v          : unsigned(MEM_ADDR_WIDTH-1 downto 0);
    variable wr_amount_v            : unsigned(RW_AMOUNT_WIDTH-1 downto 0);
    variable wr_addr_inc_v          : unsigned(RW_ADDR_INC_WIDTH-1 downto 0);
    variable wr_addr_interval_v     : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
    variable wr_addr_interval_cnt_v : unsigned(RW_ADDR_INTERVAL_WIDTH-1 downto 0);
    variable wr_addr_interval_inc_v : unsigned(RW_ADDR_INTERVAL_INC_WIDTH-1 downto 0);
    variable wr_be_v                : unsigned(HIBI_BE_WIDTH-1 downto 0);
    variable wr_conf_started_v      : std_ulogic;
    variable wr_conf_done_v         : std_ulogic;
    
    
    
    variable rd_chan_release_v : std_logic;
    
    variable mem_rd_cnt_inc_v : std_logic;
    
    variable cur_wr_chan_v : unsigned(WRITE_CHANNELS_WIDTH-1 downto 0);
  begin
    if (rst_n = '0') then
      hibi_rd_fifo_re_r <= '0';
      hibi_rd_fifo_addr_r <= (others => '0');
      hibi_rd_fifo_data_r <= (others => '0');
      hibi_rd_fifo_comm_r <= (others => '0');
      hibi_rd_fifo_empty_r <= '0';
      hibi_rd_fifo_one_d_r <= '0';
      hibi_rd_fifo_false_rd_r <= '0';
      
      mem_wr_req_r <= '0';
      mem_rd_req_r <= '0';
      mem_be_r <= (others => '0');
      mem_wdata_r <= (others => '0');
      mem_addr_r <= (others => '0');
      
--      mem_burst_size_r <= (others => '0');
      mem_burst_begin_r <= '0';
      
      mem_wr_delayed_r <= '0';
      mem_rd_delayed_r <= '0';
      
      wr_mem_addr_r <= (others => '0');
      wr_amount_r <= (others => '0');
      wr_addr_inc_r <= (others => '0');
      wr_addr_interval_r <= (others => '0');
      wr_addr_interval_cnt_r <= (others => '0');
      wr_addr_interval_inc_r <= (others => '0');
      wr_be_r <= (others => '0');
      wr_conf_started_r <= '0';
      wr_conf_done_r <= '0';
      
      rd_mem_addr_r <= (others => '0');
      rd_amount_r <= (others => '0');
      rd_addr_inc_r <= (others => '0');
      rd_addr_interval_r <= (others => '0');
      rd_addr_interval_cnt_r <= (others => '0');
      rd_addr_interval_inc_r <= (others => '0');
      rd_hibi_ret_addr_r <= (others => '0');
      rd_conf_started_r <= '0';
      rd_conf_done_r <= '0';
      
      mem_rd_state_r <= MEM_RD_WAIT;
      
      wr_conf_mem_we_1_r <= '0';
      wr_conf_mem_addr_1_r <= (others => '0');
      
      
      load_wr_conf_r <= '0';
      load_wr_conf_d1_r <= '0';
      
      load_wr_conf_delayed_r <= '0';
      
--      rd_chan_full_r <= '0';
--      rd_chan_empty_r <= '1';
      
      ret_addr_we_r <= '0';
      ret_addr_wdata_r <= (others => '0');
      
      free_wr_chan_we_r <= '0';
      free_wr_chan_wdata_r <= (others => '0');
      free_wr_chan_init_done_r <= '0';
      
      free_rd_chan_we_r <= '0';
      free_rd_chan_wdata_r <= (others => '0');
      
      free_rd_chan_r <= (others => '0');
      cur_rd_chan_r <= (others => '0');
      
      cur_wr_chan_r <= (others => '0');
      
      mem_rd_cnt_r <= (others => '0');
      
    elsif (clk'event and clk = '1') then
      hibi_rd_fifo_re_r <= '0';
      hibi_rd_fifo_re_v := '0';
      
      mem_wr_req_v := '0';
      mem_rd_req_v := '0';
      mem_addr_v := mem_addr_r;
      
      mem_wr_req_r <= '0';
      mem_rd_req_r <= '0';
      mem_be_r <= mem_be_r;
      mem_wdata_r <= mem_wdata_r;
--      mem_addr_r <= mem_addr_r;
      
--      mem_burst_size_r <= "01";
      mem_burst_begin_r <= '0';
      
      wr_conf_mem_stall_v := '0';
      
      free_wr_chan_we_r <= '0';
      free_rd_chan_we_r <= '0';
      
--      rd_chan_empty_r <= rd_chan_empty_r;
--      rd_chan_full_r <= rd_chan_full_r;
      
      rd_chan_release_v := '0';
      
      wr_conf_mem_we_1_r <= '0';
      rd_conf_mem_we_1_r <= '0';
      
      ret_addr_we_r <= '0';
      
      mem_rd_cnt_inc_v := '0';
      
      mem_rd_state_r <= mem_rd_state_r;
      
      cur_rd_chan_r <= cur_rd_chan_r;
      
      load_wr_conf_r <= '0';
      load_wr_conf_d1_r <= load_wr_conf_r;
      
      if (hibi_rd_fifo_addr(23 downto 8) = 2) then
        cur_wr_chan_r <= hibi_rd_fifo_addr(WRITE_CHANNELS_WIDTH-1 downto 0);
        cur_wr_chan_v := hibi_rd_fifo_addr(WRITE_CHANNELS_WIDTH-1 downto 0);
      else
        cur_wr_chan_r <= cur_wr_chan_r;
        cur_wr_chan_v := cur_wr_chan_r;
      end if;
      
      
      if (hibi_rd_fifo_false_rd_r = '0') then
        hibi_rd_fifo_addr_v := hibi_rd_fifo_addr;
        hibi_rd_fifo_data_v := hibi_rd_fifo_data;
        hibi_rd_fifo_comm_v := hibi_rd_fifo_comm;
        hibi_rd_fifo_empty_v := hibi_rd_fifo_empty;
        hibi_rd_fifo_one_d_v := hibi_rd_fifo_one_d;
      else
        hibi_rd_fifo_addr_v := hibi_rd_fifo_addr_r;
        hibi_rd_fifo_data_v := hibi_rd_fifo_data_r;
        hibi_rd_fifo_comm_v := hibi_rd_fifo_comm_r;
        hibi_rd_fifo_empty_v := hibi_rd_fifo_empty_r;
        hibi_rd_fifo_one_d_v := hibi_rd_fifo_one_d_r;
      end if;
      
      hibi_rd_fifo_addr_r <= hibi_rd_fifo_addr_v;
      hibi_rd_fifo_data_r <= hibi_rd_fifo_data_v;
      hibi_rd_fifo_comm_r <= hibi_rd_fifo_comm_v;
      hibi_rd_fifo_empty_r <= hibi_rd_fifo_empty_v;
      hibi_rd_fifo_one_d_r <= hibi_rd_fifo_one_d_v;
      
      if ((hibi_rd_fifo_addr_v(23 downto 8) >= 1) and (hibi_rd_fifo_addr_v(23 downto 8) <= 2)) then
        hibi_rd_fifo_addr_valid_v := '1';
      else
        hibi_rd_fifo_addr_valid_v := '0';
      end if;
      
      if ((cur_wr_chan_r /= cur_wr_chan_v) or (load_wr_conf_delayed_r = '1')) then
        if (hibi_rd_fifo_false_rd_r = '0') then
          load_wr_conf_r <= '1';
          wr_conf_mem_addr_1_r <= cur_wr_chan_v;
          wr_conf_mem_stall_v := '1';
          load_wr_conf_delayed_r <= '0';
        else
          load_wr_conf_delayed_r <= '1';
        end if;
      end if;
      
      if (load_wr_conf_r = '1') then
        wr_conf_mem_stall_v := '1';
      end if;
      
      if ((load_wr_conf_d1_r = '1') or ((wr_conf_done_rv = '1') and (wr_conf_done_r = '0'))) then
        wr_mem_addr_r <= wr_mem_addr_rv;
        wr_amount_r <= wr_amount_rv;
        wr_addr_inc_r <= wr_addr_inc_rv;
        wr_addr_interval_r <= wr_addr_interval_rv;
        wr_addr_interval_cnt_r <= wr_addr_interval_cnt_rv;
        wr_addr_interval_inc_r <= wr_addr_interval_inc_rv;
        wr_be_r <= wr_be_rv;
        wr_conf_started_r <= wr_conf_started_rv;
        wr_conf_done_r <= wr_conf_done_rv;
        
        wr_mem_addr_v := wr_mem_addr_rv;
        wr_amount_v := wr_amount_rv;
        wr_addr_inc_v := wr_addr_inc_rv;
        wr_addr_interval_v := wr_addr_interval_rv;
        wr_addr_interval_cnt_v := wr_addr_interval_cnt_rv;
        wr_addr_interval_inc_v := wr_addr_interval_inc_rv;
        wr_be_v := wr_be_rv;
        wr_conf_started_v := wr_conf_started_rv;
        wr_conf_done_v := wr_conf_done_rv;
        
      else
        wr_mem_addr_v := wr_mem_addr_r;
        wr_amount_v := wr_amount_r;
        wr_addr_inc_v := wr_addr_inc_r;
        wr_addr_interval_v := wr_addr_interval_r;
        wr_addr_interval_cnt_v := wr_addr_interval_cnt_r;
        wr_addr_interval_inc_v := wr_addr_interval_inc_r;
        wr_be_v := wr_be_r;
        wr_conf_started_v := wr_conf_started_r;
        wr_conf_done_v := wr_conf_done_r;
      end if;
      
      if ((hibi_rd_fifo_re_r = '1') and ((mem_ready_in = '0') or (wr_conf_mem_stall_v = '1'))) then
        hibi_rd_fifo_false_rd_r <= '1';
      elsif ((hibi_rd_fifo_re_r = '1') and (mem_ready_in = '1') and (wr_conf_mem_stall_v = '0')) then
        hibi_rd_fifo_false_rd_r <= '0';
      end if;
      
      rd_conf_started_r <= '0';
      rd_conf_done_r <= '0';
      
      ret_addr_wdata_r <= rd_hibi_ret_addr_r;
      
      if (free_wr_chan_init_done_r = '0') then
        free_wr_chan_we_r <= '1';
        free_rd_chan_we_r <= '1';
        if (free_wr_chan_full = '1') then
          free_wr_chan_init_done_r <= '1';
        end if;
        if (free_wr_chan_we_r = '1') then
          free_wr_chan_wdata_r <= free_wr_chan_wdata_r + 1;
          free_rd_chan_wdata_r <= free_rd_chan_wdata_r + 1;
        end if;
      end if;
      
      if (rw_conf_mem_init_done_r = '1') then
        if (mem_init_done_in = '1') then
          if ( (hibi_rd_fifo_empty_v = '0') and ( (hibi_rd_fifo_one_d_v = '0') or ((hibi_rd_fifo_one_d_v = '1') and (hibi_rd_fifo_re_r = '0')) )
               and (mem_ready_in = '1') and not((wr_conf_mem_stall_v = '1') and (hibi_rd_fifo_comm = HCOM_WR))
               and not( (hibi_rd_fifo_addr_valid_v = '1') and (wr_conf_mem_stall_v = '0') and (wr_conf_done_rv = '0') and (wr_conf_started_rv = '1') ) ) then
            hibi_rd_fifo_re_r <= '1';
          end if;
          
          if (mem_ready_in = '0') then
            if (mem_wr_req_r = '1') then
              mem_wr_delayed_r <= '1';
            elsif (mem_rd_req_r = '1') then
              mem_rd_delayed_r <= '1';
            end if;
          end if;
          
          if (mem_ready_in = '1') then
            if ((mem_wr_delayed_r = '1') or (mem_rd_delayed_r = '1')) then
              mem_wr_req_v := mem_wr_delayed_r;
              mem_rd_req_v := mem_rd_delayed_r;
              
              mem_wr_delayed_r <= '0';
              mem_rd_delayed_r <= '0';
              
            elsif ((hibi_rd_fifo_re_r = '1') and (hibi_rd_fifo_empty_v = '0')) then
              if (hibi_rd_fifo_addr_valid_v = '1') then
                if ((wr_conf_mem_stall_v = '0') and (hibi_rd_fifo_comm_v = HCOM_WR) and (wr_conf_done_v = '1')) then
                  mem_wr_req_v := '1';
                  mem_be_r <= wr_be_v;
                  mem_wdata_r <= hibi_rd_fifo_data_v;
                  mem_addr_v := wr_mem_addr_v;
                  
                  if (wr_amount_v > 4) then
                    if (wr_addr_interval_v /= 0) then
                      if (wr_addr_interval_cnt_v /= 1) then
                        wr_mem_addr_r <= wr_mem_addr_v + wr_addr_inc_v;
                        wr_addr_interval_cnt_r <= wr_addr_interval_cnt_v - 1;
                      else
                        wr_mem_addr_r <= wr_mem_addr_v + wr_addr_interval_inc_v;
                        wr_addr_interval_cnt_r <= wr_addr_interval_v;
                      end if;
                    else
                      wr_mem_addr_r <= wr_mem_addr_v + wr_addr_inc_v;
                      wr_addr_interval_cnt_r <= (others => '0');
                    end if;
                    
                    wr_conf_started_r <= '1';
                    wr_conf_done_r <= '1';
                    
                  else
                    free_wr_chan_wdata_r <= hibi_rd_fifo_addr_v(WRITE_CHANNELS_WIDTH-1 downto 0);
                    free_wr_chan_we_r <= '1';
                    
                    wr_mem_addr_r <= wr_mem_addr_v + wr_addr_inc_v;
                    wr_addr_interval_cnt_r <= (others => '0');
                    
                    wr_conf_started_r <= '0';
                    wr_conf_done_r <= '0';
                    
                  end if;
                  
                  if (load_wr_conf_delayed_r = '0') then
                    wr_conf_mem_addr_1_r <= cur_wr_chan_r;
                  else
                    wr_conf_mem_addr_1_r <= wr_conf_mem_addr_1_r;
                  end if;
                  
                  wr_amount_r <= wr_amount_v - 4;
                  wr_conf_mem_we_1_r <= '1';
                end if;   
                
                
              elsif (hibi_rd_fifo_addr_valid_v = '0') then
                if (hibi_rd_fifo_comm_v = HCOM_WR) then
                  mem_wr_req_v := '1';
                  
                  mem_be_r <= (others => '1');
                  mem_wdata_r <= hibi_rd_fifo_data_v;
                  mem_addr_v := (others => '0');
                  mem_addr_v(DIRECT_RW_ADDR_U-2 downto 0) := hibi_rd_fifo_addr_v(DIRECT_RW_ADDR_U downto 2);
                elsif ((hibi_rd_fifo_comm_v = HCOM_RD) and (mem_rd_cnt_r < 32)) then
                  mem_rd_req_v := '1';
                  
                  mem_addr_v := (others => '0');
                  mem_addr_v(DIRECT_RW_ADDR_U-2 downto 0) := hibi_rd_fifo_addr_v(DIRECT_RW_ADDR_U downto 2);
                  ret_addr_we_r <= '1';
                  ret_addr_wdata_r <= hibi_rd_fifo_data_v;
                  mem_rd_cnt_inc_v := '1';
                end if;
              end if;
            elsif (mem_rd_cnt_r < 32) then
              case mem_rd_state_r is
                when MEM_RD_WAIT =>
                  if (rd_conf_done_rv = '1') then -- and (rd_chan_empty_r = '0')) then
                    mem_rd_state_r <= MEM_RD_REQ;
                    
                    rd_mem_addr_r <= rd_mem_addr_rv;
                    rd_amount_r <= rd_amount_rv;
                    rd_addr_inc_r <= rd_addr_inc_rv;
                    rd_addr_interval_r <= rd_addr_interval_rv;
                    rd_addr_interval_cnt_r <= rd_addr_interval_cnt_rv;
                    rd_addr_interval_inc_r <= rd_addr_interval_inc_rv;
                    rd_hibi_ret_addr_r <= rd_hibi_ret_addr_rv;
                  end if;
                
                when MEM_RD_REQ =>
                  if ((mem_ready_in = '1') and (hibi_wr_cnt_r < (MEM_RD_REQ_MAX_LENGTH-17))) then
                    mem_rd_req_v := '1';
                    mem_addr_v := rd_mem_addr_r;
                    ret_addr_we_r <= '1';
                    
                    mem_rd_cnt_inc_v := '1';
                    
                    if (rd_amount_r > 4) then
                      if (rd_addr_interval_cnt_r /= 1) then
                        rd_mem_addr_r <= rd_mem_addr_r + rd_addr_inc_r;
                        rd_addr_interval_cnt_r <= rd_addr_interval_cnt_r - 1;
                      else
                        rd_mem_addr_r <= rd_mem_addr_r + rd_addr_interval_inc_r;
                        rd_addr_interval_cnt_r <= rd_addr_interval_r;
                      end if;
                      
                    else
                      
                      rd_conf_mem_we_1_r <= '1';
                      
                      rd_mem_addr_r <= rd_mem_addr_r + rd_addr_inc_r;
                      rd_addr_interval_cnt_r <= rd_addr_interval_cnt_r - 1;
                      
                      mem_rd_state_r <= MEM_RD_DONE;
                    end if;
                    
                    rd_amount_r <= rd_amount_r - 4;
                  end if;
                
                when others => --MEM_RD_DONE =>
                  rd_chan_release_v := '1';
                  mem_rd_state_r <= MEM_RD_WAIT;
                  
              end case;
            end if;
          end if;
        end if;
      end if;
      
      
      mem_addr_r <= mem_addr_v;
      mem_wr_req_r <= mem_wr_req_v;
      mem_rd_req_r <= mem_rd_req_v;
      
--       if ((mem_wr_req_v = '1') or (mem_rd_req_v = '1')) then
--         if (mem_burst_begin_r = '0') then
--           mem_wr_req_r <= mem_wr_req_v;
--           mem_rd_req_r <= mem_rd_req_v;
--           
--           mem_burst_begin_r <= '1';
--         else
--           if ( (((mem_wr_req_v = '1') and (mem_wr_req_r = '1')) or ((mem_rd_req_v = '1') and (mem_rd_req_r = '1')))
--                  and (mem_addr_r(MEM_ADDR_WIDTH-1 downto 1) = mem_addr_v(MEM_ADDR_WIDTH-1 downto 1)) and (mem_addr_r(0) = '0') and (mem_addr_v(0) = '1') ) then
--             mem_wr_req_r <= mem_wr_req_v;
-- --            mem_rd_req_r <= mem_rd_req_v;
--             
--           else
--             mem_wr_delayed_r <= mem_wr_req_v;
--             mem_rd_delayed_r <= mem_rd_req_v;
--           end if;
--         end if;
--       end if;
      
      
      if (mem_rd_cnt_inc_v = mem_rdata_valid_in) then
        mem_rd_cnt_r <= mem_rd_cnt_r;
      elsif (mem_rd_cnt_inc_v = '1') then
        mem_rd_cnt_r <= mem_rd_cnt_r + 1;
      elsif (mem_rdata_valid_in = '1') then
        mem_rd_cnt_r <= mem_rd_cnt_r - 1;
      end if;
      
--       if ((next_rd_chan_r = '1') and (rd_chan_release_v = '1')) then
--         cur_rd_chan_r <= cur_rd_chan_r + 1;
--         free_rd_chan_r <= free_rd_chan_r + 1;
-- 
--       elsif (next_rd_chan_r = '1') then
--         if (cur_rd_chan_r = (free_rd_chan_r + 1)) then
--           rd_chan_full_r <= '1';
--         end if;
--         rd_chan_empty_r <= '0';
--         free_rd_chan_r <= free_rd_chan_r + 1;
--       
--       elsif (rd_chan_release_v = '1') then
--         if (free_rd_chan_r = (cur_rd_chan_r + 1)) then
--           rd_chan_empty_r <= '1';
--         end if;
--         rd_chan_full_r <= '0';
--         cur_rd_chan_r <= cur_rd_chan_r + 1;
--       end if;
      
      --synthesis translate_off
      debug_wr_conf_mem_stall_r <= wr_conf_mem_stall_v;
      --synthesis translate_on
      
    end if;
  end process;
  

  
  --synthesis translate_off
  
  process (load_wr_conf_r, wr_mem_addr_rv, wr_amount_rv, wr_addr_inc_rv, wr_addr_interval_rv, wr_addr_interval_cnt_rv, wr_addr_interval_inc_rv,
           wr_be_rv, wr_conf_started_rv, wr_conf_done_rv, wr_mem_addr_r, wr_amount_r, wr_addr_inc_r, wr_addr_interval_r, wr_addr_interval_cnt_r,
           wr_addr_interval_inc_r, wr_be_r, wr_conf_started_r, wr_conf_done_r)
  begin
    if (load_wr_conf_r = '1') then
      debug_wr_mem_addr <= wr_mem_addr_rv;
      debug_wr_amount <= wr_amount_rv;
      debug_wr_addr_inc <= wr_addr_inc_rv;
      debug_wr_addr_interval <= wr_addr_interval_rv;
      debug_wr_addr_interval_cnt <= wr_addr_interval_cnt_rv;
      debug_wr_addr_interval_inc <= wr_addr_interval_inc_rv;
      debug_wr_be <= wr_be_rv;
      debug_wr_conf_started <= wr_conf_started_rv;
      debug_wr_conf_done <= wr_conf_done_rv;
    else  
      debug_wr_mem_addr <= wr_mem_addr_r;
      debug_wr_amount <= wr_amount_r;
      debug_wr_addr_inc <= wr_addr_inc_r;
      debug_wr_addr_interval <= wr_addr_interval_r;
      debug_wr_addr_interval_cnt <= wr_addr_interval_cnt_r;
      debug_wr_addr_interval_inc <= wr_addr_interval_inc_r;
      debug_wr_be <= wr_be_r;
      debug_wr_conf_started <= wr_conf_started_r;
      debug_wr_conf_done <= wr_conf_done_r;
    end if;
    
  end process;
  
  debug_wr_chan_error <= debug_wr_conf_done and free_wr_chan_full;
  
  --synthesis translate_on
  
  
-----------------------------------------------------------------------------------------
-- HIBI data writer:
-----------------------------------------------------------------------------------------
-- waits for data to be available by checking hibi_wr_cnt_r
-- writes the data and address to HIBI if hibi_full_in = 0
-----------------------------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      hibi_we_r <= '0';
      hibi_false_wr_r <= '0';
      hibi_wr_data_fifo_re_r <= '0';
      ret_addr_re_r <= '0';
      hibi_wr_cnt_r <= (others => '0');
      
      hibi_wr_data_r <= (others => '0');
      hibi_wr_addr_r <= (others => '0');
      
    elsif (clk'event and clk = '1') then
      hibi_wr_data_fifo_re_r <= '0';
      ret_addr_re_r <= '0';
      hibi_we_r <= '0';
      
      hibi_wr_data_r <= hibi_wr_data_r;
      hibi_wr_addr_r <= hibi_wr_addr_r;
      
      if ( (hibi_full_in = '0') and ((hibi_wr_cnt_r > 1) or ((hibi_wr_cnt_r = 1) and (hibi_we_r = '0'))) ) then
        hibi_we_r <= '1';
        ret_addr_re_r <= '1';
        hibi_wr_data_fifo_re_r <= '1';
      end if;

      if (mem_rdata_valid_in = hibi_wr_data_fifo_re_tmp) then
        hibi_wr_cnt_r <= hibi_wr_cnt_r;
      elsif (mem_rdata_valid_in = '1') then
        hibi_wr_cnt_r <= hibi_wr_cnt_r + 1;
      elsif (hibi_wr_data_fifo_re_tmp = '1') then
        hibi_wr_cnt_r <= hibi_wr_cnt_r - 1;
      end if;
      
      if (hibi_false_wr = '1') then
        hibi_wr_data_r <= hibi_wr_data;
        hibi_wr_addr_r <= hibi_wr_addr;
        hibi_false_wr_r <= '1';
      elsif (hibi_we_r = '1') then
        hibi_false_wr_r <= '0';
      end if;
    end if;
  end process;
  
  hibi_false_wr <= hibi_we_r and hibi_full_in;
  
  -- don't read the data and address from the fifo if a false write the HIBI has occurred
  hibi_wr_data_fifo_re_tmp <= hibi_wr_data_fifo_re_r and (not hibi_false_wr);
  ret_addr_re_tmp <= ret_addr_re_r and (not hibi_false_wr);
  
  rw_conf_state_mem_raddr <= cur_rw_chan_wr_r & cur_rw_chan_r;
  
-----------------------------------------------------------------------------------------
-- Read/write configuration state memory write port router:
-----------------------------------------------------------------------------------------
-- initialization:
-- --------------
-- (others => '0') => rw_conf_state_mem_wdata
-- '1'             => rw_conf_state_mem_we
--
-- normal operation:
-- ----------------
-- rw_chan_conf_index_r   => rw_conf_state_mem_wdata
-- rw_conf_state_mem_we_r => rw_conf_state_mem_we
-----------------------------------------------------------------------------------------
  process (rw_conf_mem_init_done_r, rw_chan_conf_index_r, rw_conf_state_mem_we_r)
  begin
    if (rw_conf_mem_init_done_r = '0') then
      rw_conf_state_mem_wdata <= (others => '0');
      rw_conf_state_mem_we <= '1';
    else
      rw_conf_state_mem_wdata <= rw_chan_conf_index_r;
      rw_conf_state_mem_we <= rw_conf_state_mem_we_r;
    end if;
  end process;
  
------------------------------------------------------------------------------------------
-- Read/write configuration state memory
------------------------------------------------------------------------------------------
  rw_conf_state_mem : entity work.onchip_ram_u
  generic map ( MEM_PORTS  => 2,
                FORCE_ONE_PROC => 1,
                DATA_WIDTH => RW_CONF_STATE_WIDTH,
                ADDR_WIDTH => RW_CHANNELS_WIDTH+1,
                MEM_SIZE   => maximum(WRITE_CHANNELS, READ_CHANNELS)*2 )
  
  port map ( clk         => clk,
             addr_0_in   => rw_conf_state_mem_raddr,
             wdata_0_in  => (others => '0'),
             rdata_0_out => rw_conf_state_mem_rdata,
             we_0_in     => '0',
             addr_1_in   => rw_conf_state_mem_waddr_r,
             wdata_1_in  => rw_conf_state_mem_wdata,
 --            rdata_1_out => rw_conf_state_mem_rdata
             we_1_in     => rw_conf_state_mem_we );
  
  
------------------------------------------------------------------------------------------
-- write configuration memory
------------------------------------------------------------------------------------------
  wr_conf_mem : entity work.onchip_ram_u
  generic map ( MEM_PORTS  => 2,
                DATA_WIDTH => WR_CONF_WIDTH,
                ADDR_WIDTH => WRITE_CHANNELS_WIDTH,
                MEM_SIZE   => WRITE_CHANNELS )
  
  port map ( clk         => clk,
             addr_0_in   => wr_conf_mem_addr_0,
             addr_1_in   => wr_conf_mem_addr_1_r,
             wdata_0_in  => wr_conf_mem_wdata_0,
             wdata_1_in  => wr_conf_mem_wdata_1,
             we_0_in     => wr_conf_mem_we_0,
             we_1_in     => wr_conf_mem_we_1_r,
             rdata_0_out => wr_conf_mem_rdata_0,
             rdata_1_out => wr_conf_mem_rdata_1 );
  
  
-----------------------------------------------------------------------------------------
-- Write configuration memory port 0 router:
-----------------------------------------------------------------------------------------
-- initialization:
-- --------------
-- rw_conf_state_mem_waddr_r => wr_conf_mem_addr_0
-- (others => '0')           => wr_conf_mem_wdata_0
-- '1'                       => wr_conf_mem_we_0
--
-- normal operation:
-- ----------------
-- cur_rw_chan_r       => wr_conf_mem_addr_0
-- rw_conf_load_data_r => wr_conf_mem_wdata_0
-- wr_conf_mem_we_0_r  => wr_conf_mem_we_0
-----------------------------------------------------------------------------------------
  process (rw_conf_mem_init_done_r, rw_conf_state_mem_waddr_r, cur_rw_chan_r, rw_conf_load_data_r, wr_conf_mem_we_0_r)
  begin
    if (rw_conf_mem_init_done_r = '0') then
      wr_conf_mem_addr_0 <= rw_conf_state_mem_waddr_r(WRITE_CHANNELS_WIDTH-1 downto 0);
      wr_conf_mem_wdata_0 <= (others => '0');
      wr_conf_mem_we_0 <= '1';
    else
      wr_conf_mem_addr_0 <= cur_rw_chan_r(WRITE_CHANNELS_WIDTH-1 downto 0);
      wr_conf_mem_wdata_0 <= rw_conf_load_data_r(WR_CONF_WIDTH-1 downto 0);
      wr_conf_mem_we_0 <= wr_conf_mem_we_0_r;
    end if;
  end process;


  wr_mem_addr_rv <= wr_conf_mem_rdata_1(RW_MEM_ADDR_U downto RW_MEM_ADDR_L);
  wr_amount_rv <= wr_conf_mem_rdata_1(RW_AMOUNT_U downto RW_AMOUNT_L);
  wr_addr_inc_rv <= wr_conf_mem_rdata_1(RW_ADDR_INC_U downto RW_ADDR_INC_L);
  wr_addr_interval_rv <= wr_conf_mem_rdata_1(RW_ADDR_INTERVAL_U downto RW_ADDR_INTERVAL_L);
  wr_addr_interval_cnt_rv <= wr_conf_mem_rdata_1(RW_ADDR_INTERVAL_CNT_U downto RW_ADDR_INTERVAL_CNT_L);
  wr_addr_interval_inc_rv <= wr_conf_mem_rdata_1(RW_ADDR_INTERVAL_INC_U downto RW_ADDR_INTERVAL_INC_L);
  wr_be_rv <= wr_conf_mem_rdata_1(RW_MEM_BE_U downto RW_MEM_BE_L);
  wr_conf_started_rv <= wr_conf_mem_rdata_1(RW_CONF_STARTED_L);
  wr_conf_done_rv <= wr_conf_mem_rdata_1(RW_CONF_DONE_L);
  
  wr_conf_mem_wdata_1(RW_MEM_ADDR_U downto RW_MEM_ADDR_L) <= wr_mem_addr_r;
  wr_conf_mem_wdata_1(RW_AMOUNT_U downto RW_AMOUNT_L) <= wr_amount_r;
  wr_conf_mem_wdata_1(RW_ADDR_INTERVAL_CNT_U downto RW_ADDR_INTERVAL_CNT_L) <= wr_addr_interval_cnt_r;
  wr_conf_mem_wdata_1(RW_CONF_STARTED_L) <= wr_conf_started_r;
  wr_conf_mem_wdata_1(RW_CONF_DONE_L) <= wr_conf_done_r;
  
  wr_conf_mem_wdata_1(RW_ADDR_INC_U downto RW_ADDR_INC_L) <= wr_addr_inc_r;
  wr_conf_mem_wdata_1(RW_ADDR_INTERVAL_U downto RW_ADDR_INTERVAL_L) <= wr_addr_interval_r;
  wr_conf_mem_wdata_1(RW_ADDR_INTERVAL_INC_U downto RW_ADDR_INTERVAL_INC_L) <= wr_addr_interval_inc_r;
  wr_conf_mem_wdata_1(RW_MEM_BE_U downto RW_MEM_BE_L) <= wr_be_r;
  
------------------------------------------------------------------------------------------
-- read configuration memory
------------------------------------------------------------------------------------------
  rd_conf_mem : entity work.onchip_ram_u
  generic map ( MEM_PORTS  => 2,
                DATA_WIDTH => RD_CONF_WIDTH,
                ADDR_WIDTH => READ_CHANNELS_WIDTH,
                MEM_SIZE   => READ_CHANNELS )
  
  port map ( clk         => clk,
             addr_0_in   => rd_conf_mem_addr_0,
             addr_1_in   => cur_rw_chan_r, --cur_rd_chan_r,
             wdata_0_in  => rd_conf_mem_wdata_0,
             wdata_1_in  => rd_conf_mem_wdata_1,
             we_0_in     => rd_conf_mem_we_0,
             we_1_in     => rd_conf_mem_we_1_r,
             rdata_0_out => rd_conf_mem_rdata_0,
             rdata_1_out => rd_conf_mem_rdata_1 );

-----------------------------------------------------------------------------------------
-- Read configuration memory port 0 router:
-----------------------------------------------------------------------------------------
-- initialization:
-- --------------
-- rw_conf_state_mem_waddr_r => wr_conf_mem_addr_0
-- (others => '0')           => wr_conf_mem_wdata_0
-- '1'                       => wr_conf_mem_we_0
--
-- normal operation:
-- ----------------
-- cur_rw_chan_r       => wr_conf_mem_addr_0
-- rw_conf_load_data_r => wr_conf_mem_wdata_0
-- rd_conf_mem_we_0_r  => wr_conf_mem_we_0
-----------------------------------------------------------------------------------------
  process (rw_conf_mem_init_done_r, rw_conf_state_mem_waddr_r, cur_rw_chan_r, rw_conf_load_data_r, rd_conf_mem_we_0_r)
  begin
    if (rw_conf_mem_init_done_r = '0') then
      rd_conf_mem_addr_0 <= rw_conf_state_mem_waddr_r(READ_CHANNELS_WIDTH-1 downto 0);
      rd_conf_mem_wdata_0 <= (others => '0');
      rd_conf_mem_we_0 <= '1';
    else
      rd_conf_mem_addr_0 <= cur_rw_chan_r(READ_CHANNELS_WIDTH-1 downto 0);
      rd_conf_mem_wdata_0 <= rw_conf_load_data_r(RD_CONF_WIDTH-1 downto 0);
      rd_conf_mem_we_0 <= rd_conf_mem_we_0_r;
    end if;
  end process;
  
  rd_mem_addr_rv <= rd_conf_mem_rdata_1(RW_MEM_ADDR_U downto RW_MEM_ADDR_L);
  rd_amount_rv <= rd_conf_mem_rdata_1(RW_AMOUNT_U downto RW_AMOUNT_L);
  rd_addr_inc_rv <= rd_conf_mem_rdata_1(RW_ADDR_INC_U downto RW_ADDR_INC_L);
  rd_addr_interval_rv <= rd_conf_mem_rdata_1(RW_ADDR_INTERVAL_U downto RW_ADDR_INTERVAL_L);
  rd_addr_interval_cnt_rv <= rd_conf_mem_rdata_1(RW_ADDR_INTERVAL_CNT_U downto RW_ADDR_INTERVAL_CNT_L);
  rd_addr_interval_inc_rv <= rd_conf_mem_rdata_1(RW_ADDR_INTERVAL_INC_U downto RW_ADDR_INTERVAL_INC_L);
  rd_hibi_ret_addr_rv <= rd_conf_mem_rdata_1(RW_HIBI_RET_ADDR_U downto RW_HIBI_RET_ADDR_L);
  rd_conf_started_rv <= rd_conf_mem_rdata_1(RW_CONF_STARTED_L);
  rd_conf_done_rv <= rd_conf_mem_rdata_1(RW_CONF_DONE_L);
  
  rd_conf_mem_wdata_1(RW_MEM_ADDR_U downto RW_MEM_ADDR_L) <= rd_mem_addr_r;
  rd_conf_mem_wdata_1(RW_AMOUNT_U downto RW_AMOUNT_L) <= rd_amount_r;
  rd_conf_mem_wdata_1(RW_ADDR_INTERVAL_CNT_U downto RW_ADDR_INTERVAL_CNT_L) <= rd_addr_interval_cnt_r;
  rd_conf_mem_wdata_1(RW_CONF_STARTED_L) <= rd_conf_started_r;
  rd_conf_mem_wdata_1(RW_CONF_DONE_L) <= rd_conf_done_r;
  
  rd_conf_mem_wdata_1(RW_ADDR_INC_U downto RW_ADDR_INC_L) <= rd_addr_inc_r;
  rd_conf_mem_wdata_1(RW_ADDR_INTERVAL_U downto RW_ADDR_INTERVAL_L) <= rd_addr_interval_r;
  rd_conf_mem_wdata_1(RW_ADDR_INTERVAL_INC_U downto RW_ADDR_INTERVAL_INC_L) <= rd_addr_interval_inc_r;
  rd_conf_mem_wdata_1(RW_HIBI_RET_ADDR_U downto RW_HIBI_RET_ADDR_L) <= rd_hibi_ret_addr_r;

-----------------------------------------------------------------------------------------
-- HIBI read fifo
-----------------------------------------------------------------------------------------
-- input data:  mem_rdata (data words read from the memory)
-- input write: mem_rdata_valid_in
-- output data: hibi_wr_data (data words to be written to HIBI)
-- output read: hibi_wr_data_fifo_re_tmp
-----------------------------------------------------------------------------------------
  hibi_rd_fifo_wdata <= hibi_rd_data_r & hibi_rd_addr_r & hibi_rd_comm_r;
  hibi_rd_fifo_data <= hibi_rd_fifo_rdata(HIBI_DATA_WIDTH*2 + HIBI_COM_WIDTH - 1 downto HIBI_DATA_WIDTH + HIBI_COM_WIDTH);
  hibi_rd_fifo_addr <= hibi_rd_fifo_rdata(HIBI_DATA_WIDTH + HIBI_COM_WIDTH - 1 downto HIBI_COM_WIDTH);
  hibi_rd_fifo_comm <= hibi_rd_fifo_rdata(HIBI_COM_WIDTH-1 downto 0);
  hibi_rd_fifo_re <= hibi_rd_fifo_re_r and not(hibi_rd_fifo_false_rd_r);
  
  hibi_rd_fifo : entity work.fifo_u
	generic map (
		data_width_g => HIBI_DATA_WIDTH*2 + HIBI_COM_WIDTH, 
		depth_g => MEM_RD_REQ_MAX_LENGTH )  
	port map (
		clk => clk,
		rst_n => rst_n,
		data_in => hibi_rd_fifo_wdata,
		we_in => hibi_rd_fifo_we_r,
		data_out => hibi_rd_fifo_rdata,
		re_in => hibi_rd_fifo_re,
    full_out => hibi_rd_fifo_full,
    one_p_out => hibi_rd_fifo_one_p,
    empty_out => hibi_rd_fifo_empty,
    one_d_out => hibi_rd_fifo_one_d );
    
-----------------------------------------------------------------------------------------
-- Free write channel fifo
-----------------------------------------------------------------------------------------
-- input data:  free_wr_chan_wdata_r (write channel numbers released from write processer)
-- input write: free_wr_chan_we_r
-- output data: free_wr_chan_rdata (write channel number used by request processer)
-- output read: free_wr_chan_re_r
-----------------------------------------------------------------------------------------
  free_wr_chan_fifo : entity work.fifo_u
	generic map (
		data_width_g => WRITE_CHANNELS_WIDTH, 
		depth_g => WRITE_CHANNELS )  
	port map (
		clk => clk,
		rst_n => rst_n,
		data_in => free_wr_chan_wdata_r,
		we_in => free_wr_chan_we_r,
		data_out => free_wr_chan_rdata,
		re_in => free_wr_chan_re_r,
		full_out => free_wr_chan_full,
    empty_out => free_wr_chan_empty );
  
-----------------------------------------------------------------------------------------
-- Free read channel fifo
-----------------------------------------------------------------------------------------
-- input data:  free_rd_chan_wdata_r (read channel numbers released from write processer)
-- input write: free_rd_chan_we
-- output data: free_rd_chan_rdata (read channel number used by request processer)
-- output read: free_rd_chan_re_r
-----------------------------------------------------------------------------------------
  free_rd_chan_fifo : entity work.fifo_u
	generic map (
		data_width_g => WRITE_CHANNELS_WIDTH, 
		depth_g => WRITE_CHANNELS )  
	port map (
		clk => clk,
		rst_n => rst_n,
		data_in => free_rd_chan_wdata_r,
		we_in => free_rd_chan_we_r,
		data_out => free_rd_chan_rdata,
		re_in => free_rd_chan_re_r,
		full_out => free_rd_chan_full,
    empty_out => free_rd_chan_empty );

-----------------------------------------------------------------------------------------
-- HIBI write data fifo
-----------------------------------------------------------------------------------------
-- input data:  mem_rdata (data words read from the memory)
-- input write: mem_rdata_valid_in
-- output data: hibi_wr_data (data words to be written to HIBI)
-- output read: hibi_wr_data_fifo_re_tmp
-----------------------------------------------------------------------------------------
  hibi_wr_data_fifo : entity work.fifo_u
	generic map (
		data_width_g => HIBI_DATA_WIDTH, 
		depth_g => MEM_RD_REQ_MAX_LENGTH )  
	port map (
		clk => clk,
		rst_n => rst_n,
		data_in => mem_rdata,
		we_in => mem_rdata_valid_in,
		data_out => hibi_wr_data,
		re_in => hibi_wr_data_fifo_re_tmp );
--		full_out => hibi_wr_data_fifo_full,
--    empty_out => hibi_wr_data_fifo_empty );

-----------------------------------------------------------------------------------------
-- HIBI write address fifo
-----------------------------------------------------------------------------------------
-- input data:  ret_addr_wdata_r (address words written by read processer)
-- input write: ret_addr_we_r
-- output data: hibi_wr_addr (address words to be written to HIBI)
-- output read: ret_addr_re_tmp
-----------------------------------------------------------------------------------------
  hibi_wr_ret_addr_fifo : entity work.fifo_u
	generic map (
		data_width_g => HIBI_DATA_WIDTH, 
		depth_g => MEM_RD_REQ_MAX_LENGTH*2 )  
	port map (
		clk => clk,
		rst_n => rst_n,
		data_in => ret_addr_wdata_r,
		we_in => ret_addr_we_r,
		data_out => hibi_wr_addr,
		re_in => ret_addr_re_tmp );
--		full_out => ret_addr_full,
--    empty_out => ret_addr_empty );
  
end rtl;
