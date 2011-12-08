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
-- Title      : Generic packet buffer
-- Project    : Funbase
-------------------------------------------------------------------------------
-- File       : pkt_buf.vhd
-- Author     : Juha Arvio
-- Company    : TUT
-- Last update: 05.10.2011
-- Version    : 0.91
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 25.11.2010   0.1     arvio     Created
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

entity pkt_buf is

  generic ( BUFFERS : integer := 32;
            BUFFERS_WIDTH : integer := 5;
            DATA_WIDTH : integer := 32;
--            RDATA_WIDTH : integer := 128;
            
            BUF_SIZE : integer := 64;
            BUF_SIZE_WIDTH : integer := 6;
            BUF_PART_SIZE : integer := 32;
            BUF_PART_SIZE_WIDTH : integer := 5;
            BUF_PARTS : integer := 2;
            BUF_PARTS_WIDTH : integer := 1;
            
            BUF_TYPE_WIDTH : integer := 1;
            
            BUF_TOTAL_AMOUNT_WIDTH : integer := 13;
            ADDR_TO_LIMIT_WIDTH : integer := 12
            );

  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    
    init_done_out : out std_logic;
    
    buf_reserve_in        : in std_logic;
    buf_reserve_index_out : out std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    buf_reserve_ready_out : out std_logic;
    buf_release_in        : in std_logic;
    buf_release_index_in  : in std_logic_vector(BUFFERS_WIDTH-1 downto 0);
--    buf_release_ready_out : out std_logic;
    
    buf_conf_we_in     : in std_logic;
    buf_conf_type_in   : in std_logic_vector(BUF_TYPE_WIDTH-1 downto 0);
    buf_conf_amount_in : in std_logic_vector(BUF_TOTAL_AMOUNT_WIDTH-1 downto 0);
    buf_conf_addr_to_limit_in : in std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
    buf_conf_index_in  : in std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    buf_conf_ready_out : out std_logic;
    
    buf_we_in     : in std_logic;
    buf_windex_in : in std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    buf_wdata_in  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    
    buf_wr_stall_out : out std_logic;
    
    buf_re_in         : in std_logic;
    buf_rindex_in     : in std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    buf_rdata_out     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    
    buf_filled_re_in      : in std_logic;
    buf_filled_empty_out  : out std_logic;
    buf_filled_size_out : out std_logic_vector(BUF_PART_SIZE_WIDTH downto 0);
    buf_filled_index_out  : out std_logic_vector(BUFFERS_WIDTH-1 downto 0);
    buf_filled_type_out   : out std_logic_vector(BUF_TYPE_WIDTH-1 downto 0);
    buf_filled_amount_out : out std_logic_vector(BUF_PARTS_WIDTH downto 0);
    
    buf_read_start_in : in std_logic;
    buf_ready_out     : out std_logic
    );

end pkt_buf;

architecture rtl of pkt_buf is

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
  
--  constant DATA_WIDTH_RATIO : integer := RDATA_WIDTH/WDATA_WIDTH;
--  constant DATA_RATIO_WIDTH : integer := log2_ceil(DATA_WIDTH_RATIO-1);
  
  constant BUF_ADDR_WIDTH : integer := BUFFERS_WIDTH+BUF_SIZE_WIDTH;
--  constant BUF_RADDR_WIDTH : integer := BUF_WADDR_WIDTH-DATA_RATIO_WIDTH;
  
  constant BUF_PTR_WIDTH : integer := BUF_SIZE_WIDTH;
--  constant BUF_RPTR_WIDTH : integer := BUF_WPTR_WIDTH-DATA_RATIO_WIDTH;
  
--  constant BUF_RPART_SIZE : integer := BUF_PART_SIZE/DATA_WIDTH_RATIO;
--  constant BUF_RPART_SIZE_WIDTH : integer := log2_ceil(BUF_RPART_SIZE-1);
  
  type buf_read_state_t is (BUF_READ, LOAD_RPARTS, START_BUF_READ, WAIT_READY);
  signal buf_read_state_r : buf_read_state_t;
  
  signal mem_init_done_r : std_logic;
  signal mem_init_ptr_r : std_logic_vector(BUFFERS_WIDTH-1 downto 0);
  
  signal buf_read_ready_r : std_logic;
  signal buf_rptr_r : std_logic_vector(BUF_SIZE_WIDTH-1 downto 0);
  signal buf_rpart_re_r : std_logic;
  signal buf_rpart_done_r : std_logic;
  
  signal pkt_buf_filled_empty : std_logic;
  signal buf_rpart_ready : std_logic;
  
  signal buf_rpart : std_logic_vector(BUF_PARTS_WIDTH-1 downto 0);
  
  signal free_pkt_buf_wdata : std_logic_vector(BUFFERS_WIDTH-1 downto 0);
  signal free_pkt_buf_we : std_logic;
  
  signal buf_reserve_empty : std_logic;
  
  signal buf_part_filled : std_logic;
  signal buf_part_filled_size : std_logic_vector(BUF_PART_SIZE_WIDTH downto 0);
  signal buf_part_filled_index : std_logic_vector(BUFFERS_WIDTH-1 downto 0);
  signal buf_part_filled_type : std_logic_vector(BUF_TYPE_WIDTH-1 downto 0);
  signal buf_filled_we : std_logic;
  signal buf_filled_wdata : std_logic_vector(BUF_PART_SIZE_WIDTH+BUFFERS_WIDTH+BUF_TYPE_WIDTH downto 0);
  signal buf_filled_rdata : std_logic_vector(BUF_PART_SIZE_WIDTH+BUFFERS_WIDTH+BUF_TYPE_WIDTH downto 0);
  signal buf_filled_size : std_logic_vector(BUF_PART_SIZE_WIDTH downto 0);
  signal buf_filled : std_logic;
  signal cnt_mem_init_done : std_logic;
  
  signal buf_we : std_logic;
  signal buf_waddr : std_logic_vector(BUF_ADDR_WIDTH-1 downto 0);
  signal buf_wdata : std_logic_vector(DATA_WIDTH-1 downto 0);
  
  signal buf_raddr : std_logic_vector(BUF_ADDR_WIDTH-1 downto 0);
  signal buf_filled_re_r : std_logic;
  
begin
  init_done_out <= mem_init_done_r and cnt_mem_init_done;
  
  buf_filled_empty_out <= pkt_buf_filled_empty;
  
  buf_ready_out <= buf_read_ready_r;
  
  process (clk, rst_n)
     variable buf_rpart_done_v : std_logic;
  begin
    if (rst_n = '0') then
      mem_init_done_r <= '0';
      mem_init_ptr_r <= (others => '0');
      
      buf_read_state_r <= BUF_READ;
      buf_read_ready_r <= '0';
      buf_filled_re_r <= '0';
      buf_rptr_r <= (others => '0');
      
      buf_rpart_re_r <= '0';
      buf_rpart_done_r <= '0';
      
    elsif (clk'event and clk = '1') then
      
      if (mem_init_done_r = '0') then
        mem_init_ptr_r <= mem_init_ptr_r + 1;
        
        if (mem_init_ptr_r = BUFFERS-1) then
          mem_init_done_r <= '1';
        end if;
      end if;
      
      buf_read_ready_r <= '0';
      buf_filled_re_r <= '0';
      
      buf_rpart_done_v := buf_rpart_done_r;
      
      if (buf_re_in = '1') then
        if (buf_rptr_r(BUF_PART_SIZE_WIDTH-1 downto 0) = (buf_filled_size-1)) then
          buf_rpart_done_v := '1';
        end if;
        buf_rptr_r <= buf_rptr_r + 1;
      end if;
      
      case buf_read_state_r is
        when BUF_READ =>
          if (buf_rpart_done_v = '1') then
            buf_read_state_r <= WAIT_READY;
          elsif ((buf_filled_re_in = '1') and (buf_read_ready_r = '0')) then
            buf_rpart_re_r <= '1';
            buf_read_state_r <= LOAD_RPARTS;
          elsif ((buf_read_start_in = '1') and (buf_read_ready_r = '0')) then
            buf_rpart_re_r <= '1';
            buf_read_state_r <= START_BUF_READ;
          end if;
        
        when LOAD_RPARTS =>
          if (buf_rpart_ready = '1') then
            buf_rpart_re_r <= '0';
            buf_filled_re_r <= '1';
            buf_read_ready_r <= '1';
            buf_read_state_r <= BUF_READ;
          end if;
        
        when START_BUF_READ =>
          if (buf_rpart_ready = '1') then
            buf_rptr_r <= (others => '0');
            buf_rptr_r(BUF_PTR_WIDTH-1 downto BUF_PTR_WIDTH-BUF_PARTS_WIDTH) <= buf_rpart;
            buf_rpart_re_r <= '0';
            buf_read_ready_r <= '1';
            buf_read_state_r <= BUF_READ;
          end if;
        
        when WAIT_READY =>
          if (buf_rpart_ready = '1') then
            buf_rpart_done_v := '0';
            buf_read_state_r <= BUF_READ;
          end if;
      end case;
      
      buf_rpart_done_r <= buf_rpart_done_v;
    end if;
  end process;
  
-----------------------------------------------------------------------------------------
-- free buffer fifo initialization router:
-----------------------------------------------------------------------------------------
  process (mem_init_done_r, mem_init_ptr_r, buf_release_index_in, buf_release_in)
  begin
    if (mem_init_done_r = '0') then
      free_pkt_buf_wdata <= mem_init_ptr_r;
      free_pkt_buf_we <= '1';
    else
      free_pkt_buf_wdata <= buf_release_index_in;
      free_pkt_buf_we <= buf_release_in;
    end if;
  end process;
  
  
  free_pkt_buf_fifo : entity work.alt_fifo_sc
	generic map ( DATA_WIDTH => BUFFERS_WIDTH,
                FIFO_LENGTH => BUFFERS,
                CNT_WIDTH => log2_ceil(BUFFERS-1) )
            
  port map ( clk => clk,
		         rst_n => rst_n,
             wdata_in => free_pkt_buf_wdata,
		         rdata_out => buf_reserve_index_out,
             re_in => buf_reserve_in,
		         we_in => free_pkt_buf_we,
		         empty_out => buf_reserve_empty );
  
  buf_reserve_ready_out <= not(buf_reserve_empty);
  
  buf_filled_we <= buf_part_filled or buf_filled;
  buf_filled_wdata <= buf_part_filled_size & buf_part_filled_index & buf_part_filled_type;
  
  pkt_buf_filled_fifo : entity work.alt_fifo_sc
	generic map ( DATA_WIDTH => BUF_PART_SIZE_WIDTH+1+BUFFERS_WIDTH+BUF_TYPE_WIDTH,
                FIFO_LENGTH => BUFFERS*BUF_PARTS,
                CNT_WIDTH => log2_ceil(BUFFERS*BUF_PARTS-1) )
            
  port map ( clk => clk,
		         rst_n => rst_n,
             wdata_in => buf_filled_wdata,
		         rdata_out => buf_filled_rdata,
             re_in => buf_filled_re_r,
		         we_in => buf_filled_we,
		         empty_out => pkt_buf_filled_empty );
  
  buf_filled_size <= buf_filled_rdata(BUF_PART_SIZE_WIDTH+BUFFERS_WIDTH+BUF_TYPE_WIDTH downto BUFFERS_WIDTH+BUF_TYPE_WIDTH);
  buf_filled_size_out <= buf_filled_size;
  buf_filled_index_out <= buf_filled_rdata(BUFFERS_WIDTH+BUF_TYPE_WIDTH-1 downto BUF_TYPE_WIDTH);
  buf_filled_type_out <= buf_filled_rdata(BUF_TYPE_WIDTH-1 downto 0);
  
  buf_ptr_ctrl_0 : entity work.buf_ptr_ctrl
  generic map ( BUFFERS => BUFFERS,
                BUFFERS_WIDTH => BUFFERS_WIDTH,
                BUFFER_PARTS => BUF_PARTS,
                BUFFER_PARTS_WIDTH => BUF_PARTS_WIDTH,
                BUFFER_PART_SIZE => BUF_PART_SIZE,
                BUFFER_PART_SIZE_WIDTH => BUF_PART_SIZE_WIDTH,
                BUFFER_TYPE_WIDTH => BUF_TYPE_WIDTH,
                BUFFER_WDATA_WIDTH => DATA_WIDTH,
                TOTAL_COUNT_WIDTH => BUF_TOTAL_AMOUNT_WIDTH,
                ADDR_TO_LIMIT_WIDTH => ADDR_TO_LIMIT_WIDTH )
  port map ( clk   => clk,
             rst_n => rst_n,
             
             init_done_out => cnt_mem_init_done,
             
             buf_cnt_we_in      => buf_conf_we_in,
             buf_cnt_windex_in  => buf_conf_index_in,
             buf_cnt_type_in    => buf_conf_type_in,
             buf_cnt_amount_in  => buf_conf_amount_in,
             buf_cnt_addr_to_limit_in => buf_conf_addr_to_limit_in,
             buf_cnt_wready_out => buf_conf_ready_out,
             
             buf_we_in     => buf_we_in,
             buf_windex_in => buf_windex_in,
             buf_wdata_in  => buf_wdata_in,
             buf_we_out    => buf_we,
             buf_waddr_out => buf_waddr,
             buf_wdata_out => buf_wdata,
             
             buf_wr_stall_out => buf_wr_stall_out,
             
             buf_filled_out      => buf_filled,
             buf_part_filled_out => buf_part_filled,
             buf_part_filled_index_out => buf_part_filled_index,
             buf_part_filled_size_out => buf_part_filled_size,
             buf_part_filled_type_out => buf_part_filled_type,
             
             buf_rpart_re_in => buf_rpart_re_r,
             buf_rpart_done_in => buf_rpart_done_r,
             buf_rpart_index_in => buf_rindex_in,
--             buf_rpart_in => buf_rpart_r,
             buf_rpart_out => buf_rpart,
             buf_rparts_out => buf_filled_amount_out,
             buf_rpart_ready_out => buf_rpart_ready );
  
  
  buf_raddr <= buf_rindex_in & buf_rptr_r;
  
------------------------------------------------------------------------------------------
-- packet buffer memory
------------------------------------------------------------------------------------------
  pkt_buf_mem : entity work.alt_mem_sc --work.alt_mem_dc_dw
  generic map ( --MEM_PORTS  => 2,
                DATA_WIDTH => DATA_WIDTH,
                --DATA_1_WIDTH => RDATA_WIDTH,
                ADDR_WIDTH => BUF_SIZE_WIDTH + BUFFERS_WIDTH,
                --ADDR_1_WIDTH => BUF_SIZE_WIDTH - DATA_RATIO_WIDTH + BUFFERS_WIDTH,
                MEM_SIZE   => BUF_SIZE*BUFFERS )
  
  port map ( clk         => clk,
             addr_0_in   => buf_waddr,
             addr_1_in   => buf_raddr,
             wdata_0_in  => buf_wdata,
             wdata_1_in  => (others => '0'),
             we_0_in     => buf_we,
             we_1_in     => '0',
             be_0_in     => (others => '1'),
             be_1_in     => (others => '0'),
--             rdata_0_out => wr_conf_mem_rdata_0,
             rdata_1_out => buf_rdata_out );

  
end rtl;
