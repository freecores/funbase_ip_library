-------------------------------------------------------------------------------
-- Title      : Buffer pointer control
-- Project    : 
-------------------------------------------------------------------------------
-- File       : buf_ptr_ctrl.vhd
-- Author     : 
-- Company    : 
-- Last update: 27.05.2011
-- Version    : 0.9
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
--
-------------------------------------------------------------------------------
-- Copyright (c) 2011
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 30.11.2010   0.1     arvio     Created
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

entity buf_ptr_ctrl is

  generic ( BUFFERS : integer := 4;
            BUFFERS_WIDTH : integer := 2;
            
            BUFFER_PARTS : integer := 2;
            BUFFER_PARTS_WIDTH : integer := 1;
            BUFFER_PART_SIZE : integer := 32;
            BUFFER_PART_SIZE_WIDTH : integer := 5;
            BUFFER_TYPE_WIDTH : integer := 1;
            BUFFER_WDATA_WIDTH : integer := 32;
            
            TOTAL_COUNT_WIDTH : integer := 13;
            ADDR_TO_LIMIT_WIDTH : integer := 12
            );

  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    
    init_done_out : out std_logic;
    
    buf_cnt_we_in      : in std_logic;
    buf_cnt_windex_in  : in std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    buf_cnt_type_in    : in std_logic_vector(BUFFER_TYPE_WIDTH-1 downto 0);
    buf_cnt_amount_in  : in std_logic_vector(TOTAL_COUNT_WIDTH-1 downto 0);
    buf_cnt_addr_to_limit_in : in std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
    buf_cnt_wready_out : out std_logic;
    
    buf_we_in     : in std_logic;
    buf_windex_in : in std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    buf_wdata_in  : in std_logic_vector(BUFFER_WDATA_WIDTH-1 downto 0);
    buf_we_out    : out std_logic;
    buf_waddr_out : out std_logic_vector(BUFFERS_WIDTH+BUFFER_PART_SIZE_WIDTH+BUFFER_PARTS_WIDTH-1 downto 0);
    buf_wdata_out : out std_logic_vector(BUFFER_WDATA_WIDTH-1 downto 0);
    
    buf_wr_stall_out : out std_logic;
    
    buf_filled_out      : out std_logic;
    buf_part_filled_out : out std_logic;
    buf_part_filled_index_out : out std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    buf_part_filled_size_out : out std_logic_vector(BUFFER_PART_SIZE_WIDTH downto 0);
    buf_part_filled_type_out : out std_logic_vector(BUFFER_TYPE_WIDTH-1 downto 0);
    
    buf_rpart_re_in : in std_logic;
    buf_rpart_done_in : in std_logic;
    buf_rpart_index_in : in std_logic_vector(BUFFERS_WIDTH-1 downto 0);
--    buf_rpart_in : in std_logic_vector(BUFFER_PARTS_WIDTH-1 downto 0);
    buf_rpart_out : out std_logic_vector(BUFFER_PARTS_WIDTH-1 downto 0);
    buf_rparts_out : out std_logic_vector(BUFFER_PARTS_WIDTH downto 0);
    buf_rpart_ready_out : out std_logic
    );

end buf_ptr_ctrl;

architecture rtl of buf_ptr_ctrl is

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
  
  
  
  constant TOTAL_CNT_L : integer := 0;
  constant TOTAL_CNT_U : integer := TOTAL_CNT_L + TOTAL_COUNT_WIDTH - 1;
  constant BUFFER_WPTR_L : integer := TOTAL_CNT_U + 1;
  constant BUFFER_WPTR_U : integer := BUFFER_WPTR_L + BUFFER_PARTS_WIDTH + BUFFER_PART_SIZE_WIDTH - 1;
  constant BUFFER_PARTS_FILLED_L : integer := BUFFER_WPTR_U + 1;
  constant BUFFER_PARTS_FILLED_U : integer := BUFFER_PARTS_FILLED_L + BUFFER_PARTS_WIDTH;
--  constant CNT_STALLED_L : integer := BUFFER_WPTR_U + 1;
--  constant CNT_STALLED_U : integer := CNT_STALLED_L;
  constant BUFFER_TYPE_L : integer := BUFFER_PARTS_FILLED_U + 1;
  constant BUFFER_TYPE_U : integer := BUFFER_TYPE_L + BUFFER_TYPE_WIDTH - 1;
  constant BUFFER_WR_ENABLED_L : integer := BUFFER_TYPE_U + 1;
  constant BUFFER_WR_ENABLED_U : integer := BUFFER_WR_ENABLED_L;
  constant BUFFER_RPART_L : integer := BUFFER_WR_ENABLED_U + 1;
  constant BUFFER_RPART_U : integer := BUFFER_RPART_L + BUFFER_PARTS_WIDTH - 1;
  constant ADDR_TO_LIMIT_L : integer := BUFFER_RPART_U + 1;
  constant ADDR_TO_LIMIT_U : integer := ADDR_TO_LIMIT_L + ADDR_TO_LIMIT_WIDTH - 1;
  
  constant COUNT_DATA_WIDTH : integer := ADDR_TO_LIMIT_U + 1;
  constant BUFFER_WDATA_BYTE_WIDTH : integer := BUFFER_WDATA_WIDTH/8;
  
  type cnt_mem_rw_state_t is (WAIT_RW, DELAY, LOAD_COUNT_DATA, STORE_BUFFER_RPART);
  signal cnt_mem_rw_state_r : cnt_mem_rw_state_t;
  
  signal mem_init_done_r : std_logic;
  signal mem_init_ptr_r  : std_logic_vector(BUFFERS_WIDTH-1 downto 0);
  
  signal cnt_addr_p2_r  : std_logic_vector(BUFFERS_WIDTH-1 downto 0);
  signal cnt_wdata_p2_r : std_logic_vector(COUNT_DATA_WIDTH-1 downto 0);
  signal cnt_rdata_p1   : std_logic_vector(COUNT_DATA_WIDTH-1 downto 0);
  signal cnt_rdata_1    : std_logic_vector(COUNT_DATA_WIDTH-1 downto 0);
  signal cnt_rdata_1_r  : std_logic_vector(COUNT_DATA_WIDTH-1 downto 0);
  signal cnt_we_p2_r    : std_logic;
  
  signal total_cnt_p1          : std_logic_vector(TOTAL_COUNT_WIDTH-1 downto 0);
  signal total_cnt_p2_r        : std_logic_vector(TOTAL_COUNT_WIDTH-1 downto 0);
  signal buf_wptr_p1           : std_logic_vector(BUFFER_PARTS_WIDTH+BUFFER_PART_SIZE_WIDTH-1 downto 0);
  signal buf_wptr_p2_r         : std_logic_vector(BUFFER_PARTS_WIDTH+BUFFER_PART_SIZE_WIDTH-1 downto 0);
  signal buf_part_filled_size_r : std_logic_vector(BUFFER_PARTS_WIDTH+BUFFER_PART_SIZE_WIDTH-1 downto 0);
  signal buf_parts_filled_p1   : std_logic_vector(BUFFER_PARTS_WIDTH downto 0);
  signal buf_parts_filled_p2_r : std_logic_vector(BUFFER_PARTS_WIDTH downto 0);
  signal buf_type_p1           : std_logic_vector(BUFFER_TYPE_WIDTH-1 downto 0);
  signal buf_type_p2_r         : std_logic_vector(BUFFER_TYPE_WIDTH-1 downto 0);
  signal buf_wr_enabled_p1     : std_logic;
  signal buf_wr_enabled_p2_r   : std_logic;
  signal buf_rpart_p1          : std_logic_vector(BUFFER_PARTS_WIDTH-1 downto 0);
  signal buf_rpart_p2_r        : std_logic_vector(BUFFER_PARTS_WIDTH-1 downto 0);
  signal addr_to_limit_p1      : std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
  signal addr_to_limit_p2_r    : std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
  
  signal buf_rpart_ready_r : std_logic;
  signal buf_rpart_src_r : std_logic;
  
  signal buf_rpart_r : std_logic_vector(BUFFER_PARTS_WIDTH-1 downto 0);
  signal buf_rparts_r : std_logic_vector(BUFFER_PARTS_WIDTH downto 0);
  
  signal cnt_wready_r : std_logic;
  
  signal buf_wr_stalled_r : std_logic;
  
  signal buf_we_p1_r     : std_logic;
  signal buf_windex_p1_r : std_logic_vector(BUFFERS_WIDTH-1 downto 0);
  signal buf_windex_p2_r : std_logic_vector(BUFFERS_WIDTH-1 downto 0);
  signal buf_wdata_p1_r  : std_logic_vector(BUFFER_WDATA_WIDTH-1 downto 0);
  signal buf_wdata_p2_r  : std_logic_vector(BUFFER_WDATA_WIDTH-1 downto 0);
  
  signal debug_total_cnt_p1        : std_logic_vector(TOTAL_COUNT_WIDTH-1 downto 0);
  signal debug_buf_wptr_p1         : std_logic_vector(BUFFER_PARTS_WIDTH+BUFFER_PART_SIZE_WIDTH-1 downto 0);
  signal debug_buf_parts_filled_p1 : std_logic_vector(BUFFER_PARTS_WIDTH downto 0);
  signal debug_buf_wr_enabled_p1   : std_logic;
  signal debug_buf_rpart_p1        : std_logic_vector(BUFFER_PARTS_WIDTH-1 downto 0);
  
begin
  
  init_done_out <= mem_init_done_r;
  
  buf_cnt_wready_out <= cnt_wready_r;
  
  
  buf_wdata_out <= buf_wdata_p2_r;
  
  buf_wr_stall_out <= buf_wr_stalled_r;
  
  
  
  buf_rpart_ready_out <= buf_rpart_ready_r;
  buf_part_filled_size_out <= buf_part_filled_size_r(BUFFER_PART_SIZE_WIDTH downto 0);
  
  process (buf_rpart_src_r, buf_rpart_p2_r, cnt_rdata_1(BUFFER_RPART_U downto BUFFER_RPART_L), buf_rpart_r, buf_rparts_r)
  begin
    if (buf_rpart_src_r = '0') then
      buf_rpart_out <= buf_rpart_r;
      buf_rparts_out <= buf_rparts_r;
    else
      buf_rpart_out <= cnt_rdata_1(BUFFER_RPART_U downto BUFFER_RPART_L);
      buf_rparts_out <= cnt_rdata_1(BUFFER_PARTS_FILLED_U downto BUFFER_PARTS_FILLED_L);
    end if;
  end process;
  
  process (clk, rst_n)
    variable mem_init_ptr_v : std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    variable total_cnt_p1_v : std_logic_vector(TOTAL_COUNT_WIDTH-1 downto 0);
    variable total_cnt_p2_v : std_logic_vector(TOTAL_COUNT_WIDTH-1 downto 0);
    variable buf_wptr_p1_v : std_logic_vector(BUFFER_PARTS_WIDTH+BUFFER_PART_SIZE_WIDTH-1 downto 0);
    variable buf_wptr_p2_v : std_logic_vector(BUFFER_PARTS_WIDTH+BUFFER_PART_SIZE_WIDTH-1 downto 0);
    variable buf_parts_filled_p1_v : std_logic_vector(BUFFER_PARTS_WIDTH downto 0);
    variable buf_parts_filled_p2_v : std_logic_vector(BUFFER_PARTS_WIDTH downto 0);
    variable buf_type_p1_v : std_logic_vector(BUFFER_TYPE_WIDTH-1 downto 0);
    variable buf_type_p2_v : std_logic_vector(BUFFER_TYPE_WIDTH-1 downto 0);
    variable buf_wr_enabled_p1_v : std_logic;
    variable buf_wr_enabled_p2_v : std_logic;
    variable buf_rpart_p1_v : std_logic_vector(BUFFER_PARTS_WIDTH-1 downto 0);
    variable buf_rpart_p2_v : std_logic_vector(BUFFER_PARTS_WIDTH-1 downto 0);
    variable addr_to_limit_p1_v : std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
    variable addr_to_limit_p2_v : std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
    variable buf_parts_filled_inc_v : std_logic;
    variable buf_parts_filled_dec_v : std_logic;
    variable cnt_rw_busy_v : std_logic;
    variable cnt_addr_p2_v : std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    variable cnt_wdata_p2_v : std_logic_vector(COUNT_DATA_WIDTH-1 downto 0);
    variable cnt_we_p2_v : std_logic;
    variable buf_wr_stalled_v : std_logic;
    variable buf_rpart_read_v : std_logic;
  begin
    if (rst_n = '0') then
      mem_init_done_r <= '0';
      mem_init_ptr_r <= (others => '0');
      
      cnt_mem_rw_state_r <= WAIT_RW;
      
      cnt_wready_r <= '0';
      
      buf_windex_p1_r <= (others => '0');
      buf_windex_p2_r <= (others => '0');
      buf_wdata_p1_r <= (others => '0');
      buf_wdata_p2_r <= (others => '0');
      buf_we_p1_r <= '0';
      
      total_cnt_p2_r <= (others => '0');
      buf_wptr_p2_r <= (others => '0');
      buf_parts_filled_p2_r <= (others => '0');
      buf_type_p2_r <= (others => '0');
      buf_wr_enabled_p2_r <= '0';
      buf_rpart_p2_r <= (others => '0');
      addr_to_limit_p2_r <= (others => '0');
      
      buf_wr_stalled_r <= '0';
      
      buf_rpart_ready_r <= '0';
      buf_rpart_src_r <= '0';
      
      cnt_rdata_1_r <= (others => '0');
      
      cnt_addr_p2_r <= (others => '0');
      cnt_wdata_p2_r <= (others => '0');
      cnt_we_p2_r <= '0';
      
      buf_rpart_r <= (others => '0');
      buf_rparts_r <= (others => '0');
      buf_part_filled_size_r <= (others => '0');
      
    elsif (clk'event and clk = '1') then
      
      if (mem_init_done_r = '0') then
        mem_init_ptr_v := mem_init_ptr_r + 1;
        if (mem_init_ptr_r = BUFFERS-1) then
          mem_init_done_r <= '1';
        end if;
      end if;
      
      mem_init_ptr_r <= mem_init_ptr_v;
      
      if (buf_wr_stalled_r = '0') then
        buf_we_p1_r <= buf_we_in;
        buf_windex_p1_r <= buf_windex_in;
        buf_wdata_p1_r <= buf_wdata_in;
      else
        buf_we_p1_r <= buf_we_p1_r;
        buf_windex_p1_r <= buf_windex_p1_r;
        buf_wdata_p1_r <= buf_wdata_p1_r;
      end if;
      
      buf_windex_p2_r <= buf_windex_p1_r;
      buf_wdata_p2_r <= buf_wdata_p1_r;
      
      if (buf_windex_p2_r /= buf_windex_p1_r) then
        total_cnt_p1_v := total_cnt_p1;
        buf_wptr_p1_v := buf_wptr_p1;
        buf_rpart_p1_v := buf_rpart_p1;
        addr_to_limit_p1_v := addr_to_limit_p1;
        buf_parts_filled_p1_v := buf_parts_filled_p1;
        buf_type_p1_v := buf_type_p1;
        buf_wr_enabled_p1_v := buf_wr_enabled_p1;
      else
        total_cnt_p1_v := total_cnt_p2_r;
        buf_wptr_p1_v := buf_wptr_p2_r;
        buf_rpart_p1_v := buf_rpart_p2_r;
        addr_to_limit_p1_v := addr_to_limit_p2_r;
        buf_parts_filled_p1_v := buf_parts_filled_p2_r;
        buf_type_p1_v := buf_type_p2_r;
        buf_wr_enabled_p1_v := buf_wr_enabled_p2_r;
      end if;
      
      buf_wr_enabled_p2_v := buf_wr_enabled_p1_v;
      buf_rpart_p2_v := buf_rpart_p1_v;
      buf_type_p2_v := buf_type_p1_v;
      
      buf_wr_stalled_v := buf_wr_stalled_r;
      
      buf_parts_filled_inc_v := '0';
      buf_part_filled_out <= '0';
      buf_filled_out <= '0';
      
      buf_part_filled_size_r <= buf_part_filled_size_r;
      
      if ((buf_we_p1_r = '1') and (buf_wr_enabled_p1_v = '1') and (buf_wr_stalled_r = '0')) then
        if ((buf_wptr_p1_v(BUFFER_PART_SIZE_WIDTH-1 downto 0) = (BUFFER_PART_SIZE-1)) or (addr_to_limit_p2_v = BUFFER_WDATA_BYTE_WIDTH)) then
          buf_parts_filled_inc_v := '1';
          buf_part_filled_out <= '1';
          buf_part_filled_size_r <= (i2s(0, BUFFER_PARTS_WIDTH) & buf_wptr_p1_v(BUFFER_PART_SIZE_WIDTH-1 downto 0)) + 1;
          buf_wptr_p2_v(BUFFER_PART_SIZE_WIDTH-1 downto 0) := (others => '0');
          buf_wptr_p2_v(BUFFER_PARTS_WIDTH+BUFFER_PART_SIZE_WIDTH-1 downto BUFFER_PART_SIZE_WIDTH) := buf_wptr_p2_v(BUFFER_PARTS_WIDTH+BUFFER_PART_SIZE_WIDTH-1 downto BUFFER_PART_SIZE_WIDTH) + 1;
          
        elsif (total_cnt_p1_v = BUFFER_WDATA_BYTE_WIDTH) then
          buf_wr_enabled_p2_v := '0';
          cnt_we_p2_v := '1';
          buf_part_filled_size_r <= (i2s(0, BUFFER_PARTS_WIDTH) & buf_wptr_p1_v(BUFFER_PART_SIZE_WIDTH-1 downto 0)) + 1;
          buf_filled_out <= '1';
        
        else
          buf_wptr_p2_v := buf_wptr_p1_v + 1;
        end if;
        
        total_cnt_p2_v := total_cnt_p1_v - BUFFER_WDATA_BYTE_WIDTH;
        
        if (addr_to_limit_p1_v > BUFFER_WDATA_BYTE_WIDTH) then
          addr_to_limit_p2_v := addr_to_limit_p1_v - BUFFER_WDATA_BYTE_WIDTH;
        else
          addr_to_limit_p2_v := "100000000000"; --addr_to_limit_p1_v;
        end if;
        
        if (total_cnt_p1_v = 1) then
          buf_wr_enabled_p2_v := '0';
        end if;
      else
        total_cnt_p2_v := total_cnt_p1_v;
        buf_wptr_p2_v := buf_wptr_p1_v;
        addr_to_limit_p2_v := addr_to_limit_p1_v;
      end if;
      
      
      
      if (buf_windex_p1_r /= buf_windex_in) then
        cnt_rw_busy_v := '1';
      else
        cnt_rw_busy_v := '0';
      end if;
      
      cnt_wready_r <= '0';
      buf_rpart_ready_r <= '0';
      
      buf_parts_filled_dec_v := '0';
      buf_rpart_read_v := '0';
      cnt_we_p2_v := '0';
      
      buf_rpart_src_r <= '0';
      
      if (buf_rpart_src_r = '1') then
        buf_rpart_r <= cnt_rdata_1(BUFFER_RPART_U downto BUFFER_RPART_L);
        buf_rparts_r <= cnt_rdata_1(BUFFER_PARTS_FILLED_U downto BUFFER_PARTS_FILLED_L);
      end if;
      
      case cnt_mem_rw_state_r is
        when WAIT_RW =>
          if (cnt_rw_busy_v = '0') then
            if ((buf_cnt_we_in = '1') and (cnt_wready_r = '0')) then
              cnt_addr_p2_v := buf_cnt_windex_in;
              cnt_wdata_p2_v := (others => '0');
              cnt_wdata_p2_v(BUFFER_WR_ENABLED_L) := '1';
              cnt_wdata_p2_v(TOTAL_CNT_U downto TOTAL_CNT_L) := buf_cnt_amount_in;
              cnt_wdata_p2_v(BUFFER_TYPE_U downto BUFFER_TYPE_L) := buf_cnt_type_in;
              cnt_wdata_p2_v(ADDR_TO_LIMIT_U downto ADDR_TO_LIMIT_L) := buf_cnt_addr_to_limit_in;
              cnt_we_p2_v := '1';
              cnt_wready_r <= '1';
              if (buf_cnt_windex_in = buf_windex_p2_r) then
                total_cnt_p2_v := buf_cnt_amount_in;
                addr_to_limit_p2_v := buf_cnt_addr_to_limit_in;
                buf_wptr_p2_v := (others => '0');
                buf_wr_enabled_p2_v := '1';
              end if;
            elsif ((buf_rpart_re_in = '1') and (buf_rpart_ready_r = '0')) then
              if (buf_rpart_index_in = buf_windex_p2_r) then
                buf_rpart_r <= buf_rpart_p2_r;
                buf_rparts_r <= buf_parts_filled_p2_r;
              else
                buf_rpart_src_r <= '1';
              end if;
              cnt_addr_p2_v := buf_rpart_index_in;
              buf_rpart_ready_r <= '1';
            elsif ((buf_rpart_done_in = '1') and (buf_rpart_ready_r = '0')) then
              buf_rpart_read_v := '1';
              cnt_addr_p2_v := buf_rpart_index_in;
              cnt_mem_rw_state_r <= DELAY;
            else
              cnt_addr_p2_v := buf_windex_in;
              cnt_wdata_p2_v := buf_rpart_p2_v & buf_wr_enabled_p2_v & buf_type_p2_v & buf_parts_filled_p2_v & buf_wptr_p2_v & total_cnt_p2_v & addr_to_limit_p2_v;
              cnt_we_p2_v := '0';
            end if;
          end if;
          
        when DELAY =>
          buf_rpart_read_v := '1';
          cnt_mem_rw_state_r <= LOAD_COUNT_DATA;
          
        when LOAD_COUNT_DATA =>
          buf_rpart_read_v := '1';
          cnt_rdata_1_r <= cnt_rdata_1;
          cnt_mem_rw_state_r <= STORE_BUFFER_RPART;
          
        when STORE_BUFFER_RPART =>
          buf_rpart_read_v := '1';
          if (cnt_rw_busy_v = '0') then
            buf_parts_filled_dec_v := '1';
            buf_rpart_ready_r <= '1';
            cnt_wdata_p2_v := cnt_rdata_1_r;
            cnt_wdata_p2_v(BUFFER_RPART_U downto BUFFER_RPART_L) := cnt_rdata_1_r(BUFFER_RPART_U downto BUFFER_RPART_L) + 1;
            if (buf_parts_filled_inc_v = '0') then
              cnt_wdata_p2_v(BUFFER_PARTS_FILLED_U downto BUFFER_PARTS_FILLED_L) := cnt_rdata_1_r(BUFFER_PARTS_FILLED_U downto BUFFER_PARTS_FILLED_L) - 1;
            end if;
            
            cnt_we_p2_v := '1';
            cnt_mem_rw_state_r <= WAIT_RW;
          end if;
      end case;
      
      if ((buf_rpart_read_v = '1') and (buf_rpart_index_in = buf_windex_p2_r)) then
        buf_rpart_p2_v := buf_rpart_p1_v + 1;
        
        buf_parts_filled_dec_v := '1';
        
        if (buf_parts_filled_inc_v = '0') then
          buf_parts_filled_p2_v := buf_parts_filled_p1_v - 1;
          buf_wr_stalled_v := '0';
        end if;
        buf_rpart_ready_r <= '1';
        
        cnt_we_p2_v := '0';
        
        cnt_mem_rw_state_r <= WAIT_RW;
      
      elsif ((buf_parts_filled_inc_v = '1') and (buf_parts_filled_dec_v = '0')) then
        buf_parts_filled_p2_v := buf_parts_filled_p1_v + 1;
        
        if ((buf_parts_filled_p1_v = (BUFFER_PARTS-1)) and (total_cnt_p1_v > 1)) then
          buf_wr_stalled_v := '1';
        end if;
      else
        buf_parts_filled_p2_v := buf_parts_filled_p1_v;
      end if;
      
      
      if (cnt_rw_busy_v = '1') then
        cnt_addr_p2_v := buf_windex_p1_r;
        cnt_wdata_p2_v := buf_rpart_p2_v & buf_wr_enabled_p2_v & buf_type_p2_v & buf_parts_filled_p2_v & buf_wptr_p2_v & total_cnt_p2_v & addr_to_limit_p2_v;
        cnt_we_p2_v := '1';
      end if;
      
--      buf_filled_out <= '0';
--      buf_part_filled_out <= '0';
      
--      if ((buf_we_p1_r = '1') and (buf_wr_enabled_p1_v = '1')) then
--        if (total_cnt_p1_v = BUFFER_WDATA_BYTE_WIDTH) then
--          buf_wr_enabled_p2_v := '0';
--          cnt_we_p2_v := '1';
--          buf_filled_out <= '1';
--        end if;
        
--        if ((buf_wptr_p1_v(BUFFER_PART_SIZE_WIDTH-1 downto 0) = (BUFFER_PART_SIZE-1)) or (addr_to_limit_p2_v = 0)) then
--          buf_part_filled_out <= '1';
--        end if;
--      end if;
      
      if ((buf_we_p1_r = '1') and (buf_wr_enabled_p1_v = '1') and (buf_wr_stalled_r = '0')) then
        buf_we_out <= '1';
      else
        buf_we_out <= '0';
      end if;
      
      
      if (mem_init_done_r = '0') then
        cnt_addr_p2_r <= mem_init_ptr_v;
        cnt_wdata_p2_r <= (others => '0');
        cnt_we_p2_r <= '1';
      else
        cnt_addr_p2_r <= cnt_addr_p2_v;
        cnt_wdata_p2_r <= cnt_wdata_p2_v;
        cnt_we_p2_r <= cnt_we_p2_v;
      end if;
      
      buf_part_filled_index_out <= buf_windex_p1_r;
      buf_part_filled_type_out <= buf_type_p1_v;
      
      buf_waddr_out <= buf_windex_p1_r & buf_wptr_p1_v;
      
      
      
      buf_wr_stalled_r <= buf_wr_stalled_v;
      
      total_cnt_p2_r <= total_cnt_p2_v;
      buf_wptr_p2_r <= buf_wptr_p2_v;
      buf_wr_enabled_p2_r <= buf_wr_enabled_p2_v;
      buf_parts_filled_p2_r <= buf_parts_filled_p2_v;
      buf_type_p2_r <= buf_type_p2_v;
      buf_rpart_p2_r <= buf_rpart_p2_v;
      addr_to_limit_p2_r <= addr_to_limit_p2_v;
    end if;
  end process;
  
  -- synthesis translate_off
  
  process (buf_windex_p1_r, buf_windex_p2_r, total_cnt_p1, buf_wptr_p1, buf_rpart_p1, buf_parts_filled_p1, buf_wr_enabled_p1, total_cnt_p2_r, buf_wptr_p2_r, buf_rpart_p2_r, buf_parts_filled_p2_r, buf_wr_enabled_p2_r)
  begin
    if (buf_windex_p2_r /= buf_windex_p1_r) then
      debug_total_cnt_p1 <= total_cnt_p1;
      debug_buf_wptr_p1 <= buf_wptr_p1;
      debug_buf_rpart_p1 <= buf_rpart_p1;
      debug_buf_parts_filled_p1 <= buf_parts_filled_p1;
      debug_buf_wr_enabled_p1 <= buf_wr_enabled_p1;
    else
      debug_total_cnt_p1 <= total_cnt_p2_r;
      debug_buf_wptr_p1 <= buf_wptr_p2_r;
      debug_buf_rpart_p1 <= buf_rpart_p2_r;
      debug_buf_parts_filled_p1 <= buf_parts_filled_p2_r;
      debug_buf_wr_enabled_p1 <= buf_wr_enabled_p2_r;
    end if;
  end process;
  -- synthesis translate_on
  
  
  total_cnt_p1 <= cnt_rdata_p1(TOTAL_CNT_U downto TOTAL_CNT_L);
  buf_wptr_p1 <= cnt_rdata_p1(BUFFER_WPTR_U downto BUFFER_WPTR_L);
  buf_parts_filled_p1 <= cnt_rdata_p1(BUFFER_PARTS_FILLED_U downto BUFFER_PARTS_FILLED_L);
  buf_type_p1 <= cnt_rdata_p1(BUFFER_TYPE_U downto BUFFER_TYPE_L);
  buf_wr_enabled_p1 <= cnt_rdata_p1(BUFFER_WR_ENABLED_L);
  buf_rpart_p1 <= cnt_rdata_p1(BUFFER_RPART_U downto BUFFER_RPART_L);
  addr_to_limit_p1 <= cnt_rdata_p1(ADDR_TO_LIMIT_U downto ADDR_TO_LIMIT_L);
  
  cnt_mem_0 : entity work.onchip_mem_sc
  generic map ( DATA_WIDTH => COUNT_DATA_WIDTH,
                ADDR_WIDTH => BUFFERS_WIDTH,
                MEM_SIZE   => BUFFERS )
  
  port map ( clk         => clk,
             addr_0_in   => buf_windex_in,
             addr_1_in   => cnt_addr_p2_r,
             wdata_0_in  => (others => '0'),
             wdata_1_in  => cnt_wdata_p2_r,
             we_0_in     => '0',
             we_1_in     => cnt_we_p2_r,
             be_0_in     => (others => '1'),
             be_1_in     => (others => '1'),
             rdata_0_out => cnt_rdata_p1,
             rdata_1_out => cnt_rdata_1 );
  
end rtl;
