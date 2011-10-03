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
-- Title      : HIBI MEM DMA tester
-- Project    : 
-------------------------------------------------------------------------------
-- File       : hibi_mem_dma_tester.vhd
-- Author     : jua
-- Last update: 01.07.2010
--
--
-------------------------------------------------------------------------------
-- Copyright (c) 2010
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 04.06.2010    0.1     jua      created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- synthesis translate_off
use std.textio.all;
use work.txt_util.all;
-- synthesis translate_on

entity hibi_mem_dma_tester is
  generic (
    TESTER_HIBI_BASE        : unsigned(7 downto 0) := x"00";
    M2H2_HIBI_BASE          : unsigned(7 downto 0) := x"00";
    
    HIBI_DATA_WIDTH         : integer  := 32;
    HIBI_COMP_ADDR_WIDTH    : integer  := 8;
    
    CLK_FREQ                : integer  := 200000000;
    
    MEM_RW_AMOUNT_WIDTH     : integer  := 20;
    MEM_BE_WIDTH            : integer  := 4;
    MEM_BYTE_ADDRESSING     : integer  := 1;
    MEM_ADDR_WIDTH          : integer  := 20;
    
    TEST_DATA_UPPER_BITS    : unsigned := x"0";
    TEST_DATA_UPPER_BITS_LENGTH : integer := 4;
    
    DELAY_ENABLE            : integer  := 0;
    DELAY_WIDTH             : integer  := 4 );
  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    
    hibi_comm_in	: in  std_logic_vector(2 downto 0);
		hibi_data_in	: in  std_logic_vector(31 downto 0);
		hibi_av_in	: in  std_logic;
		hibi_full_in	: in  std_logic;
		hibi_one_p_in	: in  std_logic;
		hibi_empty_in	: in  std_logic;
		hibi_one_d_in	: in  std_logic;

		hibi_comm_out	: out std_logic_vector(2 downto 0);
		hibi_data_out	: out std_logic_vector(31 downto 0);
		hibi_av_out	: out std_logic;
		hibi_we_out	: out std_logic;
		hibi_re_out	: out std_logic;
    
    mem_rw_addr_in : unsigned(MEM_ADDR_WIDTH-1 downto 0);
    mem_rw_block_length_min_in : unsigned(MEM_ADDR_WIDTH-1 downto 0);
    mem_rw_block_length_max_in : unsigned(MEM_ADDR_WIDTH-1 downto 0);
    mem_rw_block_inc_in        : unsigned(MEM_ADDR_WIDTH-1 downto 0);
    mem_rw_blocks_in           : unsigned(MEM_ADDR_WIDTH-1 downto 0);
    
    test_start_in : in std_logic;
    test_cfg_delay_in : in std_logic_vector(DELAY_WIDTH-1 downto 0);
    
    test_done_out : out std_logic;
    test_error_out : out std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
    
    test_wr_cycle_cnt_out : out unsigned(23 downto 0);
    test_rd_cycle_cnt_out : out unsigned(23 downto 0) );
    
end hibi_mem_dma_tester;

architecture rtl of hibi_mem_dma_tester is
  
  function log2_ceil(N : natural) return positive is
  begin
    if N < 2 then
      return 1;
    else
      return 1 + log2_ceil(N/2);
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
  
  constant M2H2_WR_REQ_ACK_OFFSET : unsigned(23 downto 0) := x"800000";
  constant M2H2_RD_REQ_ACK_OFFSET : unsigned(23 downto 0) := x"800001";
  
  constant m2h2_rd_req_offset : unsigned(23 downto 0) := x"000021";
  constant m2h2_wr_req_offset : unsigned(23 downto 0) := x"000022";
  constant m2h2_direct_rd_req_offset : unsigned(23 downto 0) := x"000023";
  constant m2h2_direct_wr_req_offset : unsigned(23 downto 0) := x"000024";
  
  constant m2h2_rd_cfg_0_offset : unsigned(15 downto 0) := x"0001";
  
  
  constant HIBI_ADDR_CMP_WIDTH : integer := HIBI_DATA_WIDTH - HIBI_COMP_ADDR_WIDTH;
  
  constant DIRECT_RW_ADDR_U : integer := min(HIBI_ADDR_CMP_WIDTH-1, MEM_ADDR_WIDTH+1);
  
  constant MEM_BYTE_ADDR_OFFSET : integer := MEM_BYTE_ADDRESSING*log2_ceil(MEM_BE_WIDTH-1);
  
  constant HIBI_DATA_BYTE_WIDTH : integer := HIBI_DATA_WIDTH/8;
  
  constant M2H2_MAX_CHANS : integer := 2;
  constant M2H2_MAX_CHANS_WIDTH : integer := log2_ceil(M2H2_MAX_CHANS-1);
  
  signal hibi_wr_data : unsigned(31 downto 0);
  signal hibi_rd_data : unsigned(31 downto 0);
  signal hibi_we : std_logic;
  signal hibi_re : std_logic;
  
  signal hibi_msg_wr : std_logic;
  
  signal m2h2_hibi_wr_av : std_logic;
  signal m2h2_hibi_wr_data : unsigned(31 downto 0);
  signal m2h2_hibi_wr_req : std_logic;
  signal m2h2_hibi_rd_req : std_logic;
  
  signal fsm_hibi_wr_av : std_logic;
  signal fsm_hibi_wr_data : unsigned(31 downto 0);
  signal fsm_hibi_wr_req : std_logic;
  signal fsm_hibi_rd_req : std_logic;
    
  signal test_cfg_delay : unsigned(DELAY_WIDTH-1 downto 0);
  
  signal hibi_wr_req : std_logic;
  signal hibi_rd_req : std_logic;
  
  signal hibi_rd_fifo_ready : std_logic;
  signal hibi_wr_fifo_ready : std_logic;
  
  signal hibi_rd_addr : unsigned(31 downto 0);
  
  signal m2h2_rx_offset : unsigned(22 downto 0);
  
  signal m2h2_wr_requests_r : unsigned(M2H2_MAX_CHANS_WIDTH downto 0);
  signal m2h2_wr_chans_r : unsigned(M2H2_MAX_CHANS_WIDTH downto 0);
  signal m2h2_rd_requests_r : unsigned(M2H2_MAX_CHANS_WIDTH downto 0);
  signal m2h2_rd_chans_r : unsigned(M2H2_MAX_CHANS_WIDTH downto 0);
  
  signal m2h2_wait_req_r : std_logic;
  
  signal m2h2_conf_wr_req : std_logic;
  signal m2h2_conf_rd_req : std_logic;
  
  signal m2h2_conf_done : std_logic;
  
  signal m2h2_conf_rw_addr : unsigned(MEM_ADDR_WIDTH-1 downto 0);
  signal m2h2_conf_rw_length : unsigned(MEM_RW_AMOUNT_WIDTH-1 downto 0);
  signal mem_rw_block_length : unsigned(MEM_RW_AMOUNT_WIDTH-1 downto 0);
  
  
  signal m2h2_wr_req_fifo_full : std_logic;
  signal m2h2_wr_req_fifo_one_p : std_logic;
  signal m2h2_wr_req_fifo_empty : std_logic;
  signal m2h2_wr_req_fifo_one_d : std_logic;
  
  signal m2h2_wr_req_fifo_wdata_r : unsigned(23 downto 0);
  signal m2h2_wr_req_fifo_rdata : unsigned(23 downto 0);
  signal m2h2_wr_req_fifo_we_r : std_logic;
  signal m2h2_wr_req_fifo_re_r : std_logic;
  
  signal m2h2_rd_req_fifo_full : std_logic;
  signal m2h2_rd_req_fifo_one_p : std_logic;
  signal m2h2_rd_req_fifo_empty : std_logic;
  signal m2h2_rd_req_fifo_one_d : std_logic;
  
  signal m2h2_rd_req_fifo_wdata_r : unsigned(23 downto 0);
  signal m2h2_rd_req_fifo_rdata : unsigned(23 downto 0);
  signal m2h2_rd_req_fifo_we_r : std_logic;
  signal m2h2_rd_req_fifo_re_r : std_logic;
  
  
  type m2h2_conf_state_t is (M2H2_WAIT, M2H2_REQ_SEND_0, M2H2_REQ_SEND_1, M2H2_WR_CONF, M2H2_RD_CONF);
  signal m2h2_conf_state : m2h2_conf_state_t;
  
  signal m2h2_conf_type : std_logic;
  
  signal m2h2_conf_sub_state : unsigned(2 downto 0);
  
  
  type fsm_state_t is (WAIT_START, DELAY, CONF_WR, CONF_RD, SINGLE_WR_AV, RET_ADDR_WR, MEM_WR, MEM_RD, SINGLE_WR, SINGLE_RD);
  signal fsm_state : fsm_state_t;
  
  signal next_fsm_state : fsm_state_t;
  signal next_fsm_hibi_wr_req : std_logic;
  
  
  signal write_cmd : std_logic;
  
  signal delay_cnt : unsigned(DELAY_WIDTH-1 downto 0);
  signal mem_rw_block_cnt : unsigned(MEM_ADDR_WIDTH-1 downto 0);
  signal mem_rw_test_cnt : unsigned(31 downto 0);
  signal mem_rw_error_cnt : unsigned(MEM_ADDR_WIDTH-1 downto 0);
  
  
  signal m2h2_wr_cnt_r : unsigned(23 downto 0);
  signal m2h2_wr_cycle_cnt_r : unsigned(23 downto 0);
  signal m2h2_rd_cycle_cnt_r : unsigned(23 downto 0);
  signal m2h2_wr_cycle_cnt_started_r : std_logic;
  signal m2h2_rd_cycle_cnt_started_r : std_logic;
  signal m2h2_wr_cycle_cnt_ready_r : std_logic;
  signal m2h2_rd_cycle_cnt_ready_r : std_logic;
  
begin
  
  hibi_rd_data <= unsigned(hibi_data_in);
  hibi_data_out <= std_logic_vector(hibi_wr_data);
  
  hibi_re_out <= hibi_re;
  hibi_we_out <= hibi_we;
  
--  hibi_msg_wr <= m2h2_hibi_wr_req;
  
  hibi_comm_out <= ((not write_cmd) & write_cmd & hibi_msg_wr);
  
  hibi_av_out <= m2h2_hibi_wr_av or fsm_hibi_wr_av;
  hibi_wr_data <= m2h2_hibi_wr_data or fsm_hibi_wr_data;
  
  test_cfg_delay <= unsigned(test_cfg_delay_in);
  test_error_out <= std_logic_vector(mem_rw_error_cnt);
  test_wr_cycle_cnt_out <= m2h2_wr_cycle_cnt_r;
  test_rd_cycle_cnt_out <= m2h2_rd_cycle_cnt_r;
  
  hibi_rd_req <= m2h2_hibi_rd_req or fsm_hibi_rd_req;
  hibi_wr_req <= m2h2_hibi_wr_req or fsm_hibi_wr_req;
  
  hibi_re <= hibi_rd_req and hibi_rd_fifo_ready;
  hibi_we <= hibi_wr_req and hibi_wr_fifo_ready;
  
  --
  -- create hibi_rd_fifo_ready signal based on hibi_empty_in and hibi_one_d_in and
  -- store the current hibi read address:
  --
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      hibi_rd_fifo_ready <= '0';
      
      hibi_rd_addr <= x"00000000";
    elsif (clk'event and clk = '1') then
      if (hibi_one_d_in = '1') then
        if (hibi_re = '1') then        -- last read fifo data word was read
          hibi_rd_fifo_ready <= '0';
        else
          hibi_rd_fifo_ready <= '1';
        end if;
      elsif (hibi_empty_in = '0') then      -- hibi read fifo has atleast two data words
        hibi_rd_fifo_ready  <= '1';
      end if;
      if (hibi_re = '1') then
        
        if (hibi_av_in = '1') then
          hibi_rd_addr <= hibi_rd_data;
        end if;
        
      end if;
    end if;
  end process;

  --
  -- create hibi_wr_fifo_ready signal base on hibi_full_in and hibi_one_p_in:
  --
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      hibi_wr_fifo_ready  <= '0';
    elsif (clk'event and clk = '1') then
      if (hibi_one_p_in = '1') then
        if (hibi_we = '1') then
          hibi_wr_fifo_ready  <= '0';
        else
          hibi_wr_fifo_ready  <= '1';
        end if;
      elsif (hibi_full_in = '0') then
        hibi_wr_fifo_ready  <= '1';
      else
        hibi_wr_fifo_ready  <= '0';
      end if;
    end if;
  end process;
  
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      m2h2_wr_cycle_cnt_r      <= (others => '0');
      m2h2_rd_cycle_cnt_r      <= (others => '0');
      
      m2h2_wr_cnt_r <= (others => '0');
      
    elsif (clk'event and clk = '1') then
      m2h2_wr_cycle_cnt_r <= m2h2_wr_cycle_cnt_r;
      m2h2_rd_cycle_cnt_r <= m2h2_rd_cycle_cnt_r;
      
      if (test_start_in = '1') then
        m2h2_wr_cycle_cnt_r <= (others => '0');
        m2h2_rd_cycle_cnt_r <= (others => '0');
      else
        if (m2h2_wr_cycle_cnt_started_r = '1') then
          m2h2_wr_cycle_cnt_r <= m2h2_wr_cycle_cnt_r + 1;
        end if;
      
        if (m2h2_rd_cycle_cnt_started_r = '1') then
          m2h2_rd_cycle_cnt_r <= m2h2_rd_cycle_cnt_r + 1;
        end if;
      end if;
      
      if ((hibi_msg_wr = '0') and (write_cmd = '1') and ((m2h2_hibi_wr_av or fsm_hibi_wr_av) = '0') and (hibi_we = '1')) then
        m2h2_wr_cnt_r <= m2h2_wr_cnt_r + 1;
      elsif (m2h2_rd_cycle_cnt_ready_r = '1') then
        m2h2_wr_cnt_r <= (others => '0');
      end if;
      
      --synthesis translate_off
      if (m2h2_wr_cycle_cnt_ready_r = '1') then
        report "---------------------------------------------------";
        report "block length: " & str(to_integer(mem_rw_block_length_min_in));
        report "---------------------------------------------------";
        report "M2H2 wr cycle count: " & str(to_integer(m2h2_wr_cycle_cnt_r));
        report "M2H2 wr count:       " & str(to_integer(m2h2_wr_cnt_r));
        report "M2H2 wr speed:       " & str(to_integer( ((m2h2_wr_cnt_r*HIBI_DATA_BYTE_WIDTH*CLK_FREQ)/m2h2_wr_cycle_cnt_r)/(1024*1024)) ) & " MB/s";
        report "M2H2 wr speed:       " & str(to_integer( ((m2h2_wr_cnt_r*HIBI_DATA_BYTE_WIDTH*CLK_FREQ)/m2h2_wr_cycle_cnt_r)/((CLK_FREQ*HIBI_DATA_BYTE_WIDTH)/100)) ) & "%";
        report "";
      end if;
      
      if (m2h2_rd_cycle_cnt_ready_r = '1') then
        report "M2H2 rd cycle count: " & str(to_integer(m2h2_rd_cycle_cnt_r));
        report "M2H2 rd count:       " & str(to_integer(m2h2_wr_cnt_r));
        report "M2H2 rd speed:       " & str(to_integer( ((m2h2_wr_cnt_r*HIBI_DATA_BYTE_WIDTH*CLK_FREQ)/m2h2_rd_cycle_cnt_r)/(1024*1024)) ) & " MB/s";
        report "M2H2 rd speed:       " & str(to_integer( ((m2h2_wr_cnt_r*HIBI_DATA_BYTE_WIDTH*CLK_FREQ)/m2h2_rd_cycle_cnt_r)/((CLK_FREQ*HIBI_DATA_BYTE_WIDTH)/100)) ) & "%";
        report "---------------------------------------------------";
        report "";
      end if;
      --synthesis translate_on
    end if;
  end process;
  
  
  
  process (clk, rst_n)
    variable m2h2_req_done_v : std_logic;
    variable m2h2_wr_requests_inc_v : std_logic;
    variable m2h2_wr_requests_dec_v : std_logic;
    variable m2h2_rd_requests_inc_v : std_logic;
    variable m2h2_rd_requests_dec_v : std_logic;
      
    variable m2h2_wr_chans_inc_v : std_logic;
    variable m2h2_wr_chans_dec_0_v : std_logic;
    variable m2h2_wr_chans_dec_1_v : std_logic;
    variable m2h2_rd_chans_inc_v : std_logic;
    variable m2h2_rd_chans_dec_0_v : std_logic;
    variable m2h2_rd_chans_dec_1_v : std_logic;
  begin
    if (rst_n = '0') then
      m2h2_hibi_wr_req <= '0';
      m2h2_hibi_rd_req <= '0';
      m2h2_hibi_wr_av <= '0';
      
      hibi_msg_wr <= '0';
      
      m2h2_conf_type <= '0';
      
      m2h2_hibi_wr_data <= x"00000000";
      
      m2h2_conf_state <= M2H2_WAIT;
      m2h2_conf_sub_state <= "000";
      m2h2_conf_done <= '0';
      
      m2h2_rx_offset <= (others => '0');
      
      m2h2_wr_req_fifo_wdata_r <= (others => '0');
      m2h2_wr_req_fifo_we_r <= '0';
      m2h2_wr_req_fifo_re_r <= '0';
      m2h2_rd_req_fifo_wdata_r <= (others => '0');
      m2h2_rd_req_fifo_we_r <= '0';
      m2h2_rd_req_fifo_re_r <= '0';
      
      m2h2_wr_requests_r <= (others => '0');
      m2h2_rd_requests_r <= (others => '0');
      m2h2_wr_chans_r <= (others => '0');
      m2h2_rd_chans_r <= (others => '0');
      
    elsif (clk'event and clk = '1') then
      m2h2_wr_req_fifo_we_r <= '0';
      m2h2_wr_req_fifo_re_r <= '0';
      m2h2_rd_req_fifo_we_r <= '0';
      m2h2_rd_req_fifo_re_r <= '0';
      
      m2h2_wr_requests_inc_v := '0';
      m2h2_wr_requests_dec_v := '0';
      m2h2_rd_requests_inc_v := '0';
      m2h2_rd_requests_dec_v := '0';
      
      m2h2_wr_chans_inc_v := '0';
      m2h2_wr_chans_dec_0_v := '0';
      m2h2_wr_chans_dec_1_v := '0';
      m2h2_rd_chans_inc_v := '0';
      m2h2_rd_chans_dec_0_v := '0';
      m2h2_rd_chans_dec_1_v := '0';
      
      if ((hibi_re = '1') and (hibi_av_in = '0')) then
        if (hibi_rd_addr = (TESTER_HIBI_BASE & M2H2_WR_REQ_ACK_OFFSET)) then
          if (hibi_rd_data /= x"00000000") then
            if (m2h2_wr_req_fifo_full = '0') then
              m2h2_wr_req_fifo_wdata_r <= hibi_rd_data(23 downto 0);
              m2h2_wr_req_fifo_we_r <= '1';
            end if;
          else
            m2h2_wr_chans_dec_0_v := '1';
          end if;
          
          if ((m2h2_wr_requests_r = 1) and (m2h2_rd_requests_r = 0)) then
            m2h2_hibi_rd_req <= '0';
          end if;
          
          m2h2_wr_requests_dec_v := '1';
          
        elsif (hibi_rd_addr = (TESTER_HIBI_BASE & M2H2_RD_REQ_ACK_OFFSET)) then
          if (hibi_rd_data /= x"00000000") then
            if (m2h2_rd_req_fifo_full = '0') then
              m2h2_rd_req_fifo_wdata_r <= hibi_rd_data(23 downto 0);
              m2h2_rd_req_fifo_we_r <= '1';
            end if;
          else
            m2h2_rd_chans_dec_0_v := '1';
          end if;
          
          if ((m2h2_rd_requests_r = 1) and (m2h2_wr_requests_r = 0)) then
            m2h2_hibi_rd_req <= '0';
          end if;
          
          m2h2_rd_requests_dec_v := '1';
        end if;
      end if;
      
      case m2h2_conf_state is
        when M2H2_WAIT =>
          m2h2_conf_done <= '0';
          
          if (fsm_state /= DELAY) then
            if (m2h2_conf_wr_req = '1') then
              m2h2_conf_state <= M2H2_REQ_SEND_0;
              
              m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_wr_req_offset;
              
              m2h2_hibi_wr_req <= '1';
              m2h2_hibi_wr_av <= '1';
              hibi_msg_wr <= '1';
              
              m2h2_conf_type <= '1';
              m2h2_rx_offset <= m2h2_rx_offset + 1;
              
            elsif (m2h2_conf_rd_req = '1') then
              m2h2_conf_state <= M2H2_REQ_SEND_0;
              
              m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_rd_req_offset;
              
              m2h2_hibi_wr_req <= '1';
              m2h2_hibi_wr_av <= '1';
              hibi_msg_wr <= '1';
              
              m2h2_conf_type <= '0';
              m2h2_rx_offset <= m2h2_rx_offset + 1;
            end if;
          end if;

        when M2H2_REQ_SEND_0 =>
          if (hibi_we = '1') then
            m2h2_hibi_wr_av <= '0';
            
            m2h2_conf_state <= M2H2_REQ_SEND_1;
            
            if (m2h2_conf_type = '1') then
              m2h2_hibi_wr_data <= TESTER_HIBI_BASE & M2H2_WR_REQ_ACK_OFFSET;
              m2h2_wr_requests_inc_v := '1';
              m2h2_wr_chans_inc_v := '1';
            else
              m2h2_hibi_wr_data <= TESTER_HIBI_BASE & M2H2_RD_REQ_ACK_OFFSET;
              m2h2_rd_requests_inc_v := '1';
              m2h2_rd_chans_inc_v := '1';
            end if;
          end if;
          
        when M2H2_REQ_SEND_1 =>
          if (hibi_we = '1') then
            m2h2_hibi_wr_req <= '0';
            m2h2_hibi_rd_req <= '1';
          end if;
          
          if ((hibi_we = '1') or (m2h2_hibi_wr_req = '0')) then
            if (m2h2_conf_type = '1') then
              if ((m2h2_wr_chans_r = M2H2_MAX_CHANS) and (m2h2_wr_req_fifo_empty = '0')) then
                m2h2_conf_state <= M2H2_WR_CONF;
                
                m2h2_hibi_wr_req <= '1';
                m2h2_hibi_wr_av <= '1';
                m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_wr_req_fifo_rdata;
                
                hibi_msg_wr <= '1';
                m2h2_conf_sub_state <= (others => '0');
                
              elsif (m2h2_wr_chans_r /= M2H2_MAX_CHANS) then
                m2h2_conf_state <= M2H2_REQ_SEND_0;
                
                m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_wr_req_offset;
              
                m2h2_hibi_wr_req <= '1';
                m2h2_hibi_wr_av <= '1';
                hibi_msg_wr <= '1';
              end if;
            
            else
              if ((m2h2_rd_chans_r = M2H2_MAX_CHANS) and (m2h2_rd_req_fifo_empty = '0')) then
                m2h2_conf_state <= M2H2_RD_CONF;
              
                m2h2_hibi_wr_req <= '1';
                m2h2_hibi_wr_av <= '1';
                m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_rd_req_fifo_rdata;
                
                hibi_msg_wr <= '1';
                m2h2_conf_sub_state <= (others => '0');
                
              elsif (m2h2_rd_chans_r /= M2H2_MAX_CHANS) then
                m2h2_conf_state <= M2H2_REQ_SEND_0;
                
                m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_rd_req_offset;
              
                m2h2_hibi_wr_req <= '1';
                m2h2_hibi_wr_av <= '1';
                hibi_msg_wr <= '1';
              end if;
            end if;
            
          end if;
        
--         when M2H2_REQ_ACK_WAIT =>
--           if ((m2h2_requests_done_r < 2) and (m2h2_hibi_rd_req = '0')) then -- request done, channels requested < 2
--             if (m2h2_conf_type = '1') then
--               m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_wr_req_offset;
--             else
--               m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_rd_req_offset;
--             end if;
--             
--             m2h2_conf_state <= M2H2_REQ_SEND;
--             
--             m2h2_hibi_wr_req <= '1';
--             m2h2_hibi_wr_av <= '1';
--             hibi_msg_wr <= '1';
--             m2h2_conf_sub_state <= (others => '0');
--             
--             m2h2_wr_req_cycle_cnt_started_r <= '0';
--             m2h2_rd_req_cycle_cnt_started_r <= '0';
--           
--           elsif ( ((m2h2_req_fifo_full = '1') and (m2h2_hibi_rd_req = '0')) or ((m2h2_requests_done_r = 1) and (m2h2_hibi_rd_req = '1') and (m2h2_wait_req_r = '0')) ) then
--             if (m2h2_conf_type = '1') then
--               m2h2_conf_state <= M2H2_WR_CONF;
--               m2h2_wr_req_cycle_cnt_ready_r <= '1';  
--               m2h2_wr_conf_cycle_cnt_started_r <= '1';
--             else
--               m2h2_conf_state <= M2H2_RD_CONF;
--               m2h2_rd_req_cycle_cnt_ready_r <= '1';
--               m2h2_rd_conf_cycle_cnt_started_r <= '1';
--             end if;
--             
--             m2h2_hibi_wr_req <= '1';
--             m2h2_hibi_wr_av <= '1';
--             m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_chan_offset_mem_r(to_integer(m2h2_chan_offset_mem_ptr_r));
--             
--             m2h2_cur_chan_offset_r <= m2h2_chan_offset_mem_r(to_integer(m2h2_chan_offset_mem_ptr_r));
--             
--             hibi_msg_wr <= '1';
--             m2h2_conf_sub_state <= (others => '0');
--           end if;
        
        when M2H2_WR_CONF =>
          if (hibi_we = '1') then
            m2h2_hibi_wr_av <= '0';
            
            m2h2_conf_sub_state <= m2h2_conf_sub_state + 1;
            
            case m2h2_conf_sub_state is
              when "000" =>
                m2h2_hibi_wr_data <= (others => '0');
                m2h2_hibi_wr_data(31 downto MEM_ADDR_WIDTH+MEM_BYTE_ADDR_OFFSET) <= (others => '0');
                m2h2_hibi_wr_data(MEM_ADDR_WIDTH+MEM_BYTE_ADDR_OFFSET-1 downto MEM_BYTE_ADDR_OFFSET) <= m2h2_conf_rw_addr;
              when "001" =>
                m2h2_hibi_wr_data(MEM_RW_AMOUNT_WIDTH-1 downto 0) <= m2h2_conf_rw_length;
                m2h2_hibi_wr_data(MEM_BE_WIDTH+MEM_RW_AMOUNT_WIDTH-1  downto MEM_RW_AMOUNT_WIDTH) <= (others => '1');
                m2h2_hibi_wr_data(31 downto MEM_BE_WIDTH+MEM_RW_AMOUNT_WIDTH) <= (others => '0');
              when "010" =>
                m2h2_hibi_wr_data <= x"00000001";
              when "011" =>
                m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_wr_req_fifo_rdata;
                m2h2_hibi_wr_av <= '1';
                hibi_msg_wr <= '0';
                
                m2h2_wr_req_fifo_re_r <= '1';
                m2h2_wr_chans_dec_1_v := '1';
              when others => -- "100" =>
                m2h2_hibi_wr_data <= x"00000000";
                m2h2_hibi_wr_req <= '0';
                
                m2h2_conf_done <= '1';
                m2h2_conf_state <= M2H2_WAIT;
            end case;
          end if;
        
        when M2H2_RD_CONF =>
          if (hibi_we = '1') then
            m2h2_hibi_wr_av <= '0';
            
            m2h2_conf_sub_state <= m2h2_conf_sub_state + 1;
            
            case m2h2_conf_sub_state is
              when "000" =>
                m2h2_hibi_wr_data <= (others => '0');
                m2h2_hibi_wr_data(31 downto MEM_ADDR_WIDTH+MEM_BYTE_ADDR_OFFSET) <= (others => '0');
                m2h2_hibi_wr_data(MEM_ADDR_WIDTH+MEM_BYTE_ADDR_OFFSET-1 downto MEM_BYTE_ADDR_OFFSET) <= m2h2_conf_rw_addr;
              when "001" =>
                m2h2_hibi_wr_data(MEM_ADDR_WIDTH-1 downto 0) <= m2h2_conf_rw_length;
                m2h2_hibi_wr_data(31 downto MEM_ADDR_WIDTH) <= (others => '0');
              when "010" =>
                m2h2_hibi_wr_data <= TESTER_HIBI_BASE & '0' & m2h2_rx_offset;
              when "011" =>
                m2h2_hibi_wr_data <= x"00000001";
                
                m2h2_rd_req_fifo_re_r <= '1';
                m2h2_rd_chans_dec_1_v := '1';
                
--               when "100" =>
--                 m2h2_hibi_wr_data <= M2H2_HIBI_BASE & m2h2_rd_chan_offset;
--                 m2h2_hibi_wr_av <= '1';
--                 hibi_msg_wr <= '0';
              when others => -- "101" =>
                m2h2_hibi_wr_data <= x"00000000";
                m2h2_hibi_wr_req <= '0';
                m2h2_conf_done <= '1';
                m2h2_conf_state <= M2H2_WAIT;
            end case;
          end if;
      end case;
      
      if ((m2h2_wr_requests_inc_v = '1') and (m2h2_wr_requests_dec_v = '0')) then
        m2h2_wr_requests_r <= m2h2_wr_requests_r + 1;
      elsif ((m2h2_wr_requests_inc_v = '0') and (m2h2_wr_requests_dec_v = '1')) then
        m2h2_wr_requests_r <= m2h2_wr_requests_r - 1;
      else
        m2h2_wr_requests_r <= m2h2_wr_requests_r;
      end if;
      
      if ((m2h2_rd_requests_inc_v = '1') and (m2h2_rd_requests_dec_v = '0')) then
        m2h2_rd_requests_r <= m2h2_rd_requests_r + 1;
      elsif ((m2h2_rd_requests_inc_v = '0') and (m2h2_rd_requests_dec_v = '1')) then
        m2h2_rd_requests_r <= m2h2_rd_requests_r - 1;
      else
        m2h2_rd_requests_r <= m2h2_rd_requests_r;
      end if;
      
      if ((m2h2_wr_chans_dec_0_v = '1') and (m2h2_wr_chans_dec_1_v = '1')) then
        m2h2_wr_chans_r <= m2h2_wr_chans_r - 2;
      elsif ((m2h2_wr_chans_dec_0_v = '0') and (m2h2_wr_chans_inc_v = '1')) then
        m2h2_wr_chans_r <= m2h2_wr_chans_r + 1;
      elsif ( ((m2h2_wr_chans_dec_0_v = '1') and (m2h2_wr_chans_inc_v = '0')) or ((m2h2_wr_chans_dec_0_v = '0') and (m2h2_wr_chans_dec_1_v = '1')) ) then
        m2h2_wr_chans_r <= m2h2_wr_chans_r - 1;
      else
        m2h2_wr_chans_r <= m2h2_wr_chans_r;
      end if;
      
      if ((m2h2_rd_chans_dec_0_v = '1') and (m2h2_rd_chans_dec_1_v = '1')) then
        m2h2_rd_chans_r <= m2h2_rd_chans_r - 2;
      elsif ((m2h2_rd_chans_dec_0_v = '0') and (m2h2_rd_chans_inc_v = '1')) then
        m2h2_rd_chans_r <= m2h2_rd_chans_r + 1;
      elsif ( ((m2h2_rd_chans_dec_0_v = '1') and (m2h2_rd_chans_inc_v = '0')) or ((m2h2_rd_chans_dec_0_v = '0') and (m2h2_rd_chans_dec_1_v = '1')) ) then
        m2h2_rd_chans_r <= m2h2_rd_chans_r - 1;
      else
        m2h2_rd_chans_r <= m2h2_rd_chans_r;
      end if;
    end if;
  end process;
  
  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      fsm_state <= WAIT_START;
      delay_cnt <= (others => '0');

      fsm_hibi_wr_req <= '0';
      fsm_hibi_rd_req <= '0';
      fsm_hibi_wr_av <= '0';
      fsm_hibi_wr_data <= x"00000000";
      
      m2h2_conf_wr_req <= '0';
      m2h2_conf_rd_req <= '0';
      m2h2_conf_rw_addr <= (others => '0');
      m2h2_conf_rw_length <= (others => '0');
      
      m2h2_wait_req_r <= '0';
      
      next_fsm_state <= WAIT_START;
      next_fsm_hibi_wr_req <= '0';
      
      write_cmd <= '0';
      
      mem_rw_test_cnt <= x"00000000";
      mem_rw_block_length <= (others => '0');
      mem_rw_block_cnt <= (others => '0');
      test_done_out <= '0';
      mem_rw_error_cnt <= (others => '0');
      
      m2h2_wr_cycle_cnt_started_r <= '0';
      m2h2_wr_cycle_cnt_ready_r <= '0';
      m2h2_rd_cycle_cnt_started_r <= '0';
      m2h2_rd_cycle_cnt_ready_r <= '0';
      
    elsif (clk'event and clk = '1') then
      m2h2_wr_cycle_cnt_ready_r <= '0';
      m2h2_rd_cycle_cnt_ready_r <= '0';
      
      test_done_out <= '0';
      
      case fsm_state is
        when WAIT_START =>
          if (test_start_in = '1') then
            delay_cnt <= test_cfg_delay;
            
            m2h2_wait_req_r <= '1';
            
            if ((mem_rw_block_length_min_in = 1) and (mem_rw_block_inc_in = 0)) then
              if (DELAY_ENABLE = 0) then
                fsm_state <= SINGLE_WR_AV;
                fsm_hibi_wr_req <= '1';
              else
                fsm_state <= DELAY;
              end if;
              
              next_fsm_state <= SINGLE_WR_AV;
              next_fsm_hibi_wr_req <= '1';
              
              fsm_hibi_wr_av <= '1';
              
              fsm_hibi_wr_data <= (others => '0');
              fsm_hibi_wr_data(31 downto 24) <= M2H2_HIBI_BASE;
              fsm_hibi_wr_data(DIRECT_RW_ADDR_U downto MEM_BYTE_ADDR_OFFSET) <= mem_rw_addr_in;
              
              m2h2_wr_cycle_cnt_started_r <= '1';
            else
              if (DELAY_ENABLE = 0) then
                fsm_state <= CONF_WR;
              else
                fsm_state <= DELAY;
              end if;
              
              next_fsm_state <= CONF_WR;
              m2h2_conf_wr_req <= '1';
              
              fsm_hibi_wr_data <= x"00000000";
              
              m2h2_wr_cycle_cnt_started_r <= '1';
            end if;
            
            write_cmd <= '1';
            
            m2h2_conf_rw_addr <= mem_rw_addr_in;
            m2h2_conf_rw_length <= mem_rw_block_length_min_in;
            mem_rw_block_length <= mem_rw_block_length_min_in;
            mem_rw_block_cnt <= mem_rw_blocks_in;
            mem_rw_test_cnt(31-TEST_DATA_UPPER_BITS_LENGTH downto 0) <= (others => '0');
            mem_rw_test_cnt(31 downto 32-TEST_DATA_UPPER_BITS_LENGTH) <= TEST_DATA_UPPER_BITS;
          end if;
        
        when DELAY =>
          if (mem_rw_block_length > mem_rw_block_length_max_in) then
            m2h2_conf_rw_length <= mem_rw_block_length_min_in;
            mem_rw_block_length <= mem_rw_block_length_min_in;
          end if;
          
          if (delay_cnt = 0) then
            fsm_state <= next_fsm_state;
            fsm_hibi_wr_req <= next_fsm_hibi_wr_req;
          end if;
          
          delay_cnt <= delay_cnt - 1;
        
        when CONF_WR =>
          m2h2_conf_wr_req <= '0';
          
          if (m2h2_conf_done = '1') then
            fsm_hibi_wr_req <= '1';
            
            fsm_hibi_wr_data <= mem_rw_test_cnt;
            
--            mem_rw_test_cnt <= mem_rw_test_cnt + 1;
            
            fsm_state <= MEM_WR;
          end if;
        
        when CONF_RD =>
          m2h2_conf_rd_req <= '0';
          
          if (m2h2_conf_done = '1') then
            fsm_hibi_rd_req <= '1';
            
--            mem_rw_test_cnt <= mem_rw_test_cnt + 1;
            
            fsm_state <= MEM_RD;
          end if;
        
        when SINGLE_WR_AV =>
          if (hibi_we = '1') then
            fsm_hibi_wr_av <= '0';
            
            if (write_cmd = '1') then
              fsm_hibi_wr_data <= mem_rw_test_cnt;
              fsm_state <= SINGLE_WR;
            else
              fsm_hibi_wr_data <= TESTER_HIBI_BASE & '0' & m2h2_rx_offset;
              fsm_state <= RET_ADDR_WR;
            end if;
          end if;
        
        when RET_ADDR_WR =>
          if (hibi_we = '1') then
            fsm_hibi_wr_req <= '0';
            fsm_hibi_rd_req <= '1';
            fsm_state <= SINGLE_RD;
          end if;
        
        when MEM_WR =>
          if (hibi_we = '1') then
            fsm_hibi_wr_data <= mem_rw_test_cnt + 1;
            mem_rw_test_cnt <= mem_rw_test_cnt + 1;
            
            m2h2_wait_req_r <= '0';
            
            if (m2h2_conf_rw_length > 1) then
              m2h2_conf_rw_length <= m2h2_conf_rw_length - 1;
            else
              fsm_hibi_wr_req <= '0';
              fsm_hibi_wr_data <= x"00000000";
              
              if (mem_rw_block_cnt /= 0) then
                mem_rw_block_cnt <= mem_rw_block_cnt - 1;

                m2h2_conf_wr_req <= '1';
                
                m2h2_conf_rw_addr <= m2h2_conf_rw_addr + mem_rw_block_length;
                m2h2_conf_rw_length <= mem_rw_block_length + mem_rw_block_inc_in;
                mem_rw_block_length <= mem_rw_block_length + mem_rw_block_inc_in;
                
                
                if (DELAY_ENABLE = 0) then
                  fsm_state <= CONF_WR;
                else
                  fsm_state <= DELAY;
                end if;
                
                next_fsm_state <= CONF_WR;
                delay_cnt <= test_cfg_delay;
              else
                m2h2_conf_rd_req <= '1';
                
                m2h2_conf_rw_addr <= mem_rw_addr_in;
                m2h2_conf_rw_length <= mem_rw_block_length_min_in;
                mem_rw_block_length <= mem_rw_block_length_min_in;
                mem_rw_block_cnt <= mem_rw_blocks_in;
                mem_rw_test_cnt(31-TEST_DATA_UPPER_BITS_LENGTH downto 0) <= (others => '0');
                mem_rw_test_cnt(31 downto 32-TEST_DATA_UPPER_BITS_LENGTH) <= TEST_DATA_UPPER_BITS;
                
                m2h2_rd_cycle_cnt_started_r <= '1';
                
                m2h2_wr_cycle_cnt_started_r <= '0';
                m2h2_wr_cycle_cnt_ready_r <= '1';
                
                if (DELAY_ENABLE = 0) then
                  fsm_state <= CONF_RD;
                else
                  fsm_state <= DELAY;
                end if;
                
                next_fsm_state <= CONF_RD;
                delay_cnt <= test_cfg_delay;
              end if;
            end if;
          end if;
        
        
        when MEM_RD =>
          if ( (hibi_re = '1') and (hibi_av_in = '0') and (hibi_rd_addr = (TESTER_HIBI_BASE & '0' & m2h2_rx_offset)) ) then
            if (mem_rw_test_cnt /= hibi_rd_data) then
              mem_rw_error_cnt <= mem_rw_error_cnt + 1;
            end if;
            
            mem_rw_test_cnt <= mem_rw_test_cnt + 1;
            
            if (m2h2_conf_rw_length > 1) then
              m2h2_conf_rw_length <= m2h2_conf_rw_length - 1;
            else
              fsm_hibi_rd_req <= '0';
              if (mem_rw_block_cnt /= 0) then
                mem_rw_block_cnt <= mem_rw_block_cnt - 1;

                m2h2_conf_rd_req <= '1';
                
                m2h2_conf_rw_addr <= m2h2_conf_rw_addr + mem_rw_block_length;
                m2h2_conf_rw_length <= mem_rw_block_length + mem_rw_block_inc_in;
                mem_rw_block_length <= mem_rw_block_length + mem_rw_block_inc_in;
                
                
                if (DELAY_ENABLE = 0) then
                  fsm_state <= CONF_RD;
                else
                  fsm_state <= DELAY;
                end if;
                
                
                next_fsm_state <= CONF_RD;
                delay_cnt <= test_cfg_delay;
              else
                test_done_out <= '1';
                fsm_state <= WAIT_START;
                
                m2h2_rd_cycle_cnt_started_r <= '0';
                m2h2_rd_cycle_cnt_ready_r <= '1';
              end if;
            end if;
          end if;
        
        when SINGLE_WR =>
          if (hibi_we = '1') then
            fsm_hibi_wr_data <= mem_rw_test_cnt + 1;
            mem_rw_test_cnt <= mem_rw_test_cnt + 1;
            
            fsm_hibi_wr_req <= '0';
            
            
            if (mem_rw_block_cnt /= 0) then
              mem_rw_block_cnt <= mem_rw_block_cnt - 1;

              next_fsm_hibi_wr_req <= '1';
              
              fsm_hibi_wr_av <= '1';
              
              fsm_hibi_wr_data <= (others => '0');
              fsm_hibi_wr_data(31 downto 24) <= M2H2_HIBI_BASE;
              fsm_hibi_wr_data(DIRECT_RW_ADDR_U downto MEM_BYTE_ADDR_OFFSET) <= m2h2_conf_rw_addr + 1;
              
              m2h2_conf_rw_addr <= m2h2_conf_rw_addr + 1;
              
              
              if (DELAY_ENABLE = 0) then
                fsm_state <= SINGLE_WR_AV;
                fsm_hibi_wr_req <= '1';
              else
                fsm_state <= DELAY;
              end if;
              
              next_fsm_state <= SINGLE_WR_AV;
              delay_cnt <= test_cfg_delay;
            else
              mem_rw_block_cnt <= mem_rw_blocks_in;
              mem_rw_test_cnt(31-TEST_DATA_UPPER_BITS_LENGTH downto 0) <= (others => '0');
              mem_rw_test_cnt(31 downto 32-TEST_DATA_UPPER_BITS_LENGTH) <= TEST_DATA_UPPER_BITS;
              
              next_fsm_hibi_wr_req <= '1';
              
              fsm_hibi_wr_av <= '1';
              fsm_hibi_wr_data <= (others => '0');
              fsm_hibi_wr_data(31 downto 24) <= M2H2_HIBI_BASE;
              fsm_hibi_wr_data(DIRECT_RW_ADDR_U downto MEM_BYTE_ADDR_OFFSET) <= mem_rw_addr_in;
              
              m2h2_conf_rw_addr <= mem_rw_addr_in;
              
              write_cmd <= '0';
              
              m2h2_rd_cycle_cnt_started_r <= '1';
              
              m2h2_wr_cycle_cnt_started_r <= '0';
              m2h2_wr_cycle_cnt_ready_r <= '1';
              
              if (DELAY_ENABLE = 0) then
                fsm_state <= SINGLE_WR_AV;
                fsm_hibi_wr_req <= '1';
              else
                fsm_state <= DELAY;
              end if;
              
              next_fsm_state <= SINGLE_WR_AV;
              delay_cnt <= test_cfg_delay;
            end if;
          end if;
        
        when SINGLE_RD =>
          if ((hibi_re = '1') and (hibi_av_in = '0') and (hibi_rd_addr = (TESTER_HIBI_BASE & '0' & m2h2_rx_offset))) then
            if (mem_rw_test_cnt /= hibi_rd_data) then
              mem_rw_error_cnt <= mem_rw_error_cnt + 1;
            end if;
            
            mem_rw_test_cnt <= mem_rw_test_cnt + 1;
            
            fsm_hibi_rd_req <= '0';
            
            
            if (mem_rw_block_cnt /= 0) then
              mem_rw_block_cnt <= mem_rw_block_cnt - 1;
              
              next_fsm_hibi_wr_req <= '1';
              
              fsm_hibi_wr_av <= '1';
              
              fsm_hibi_wr_data <= (others => '0');
              fsm_hibi_wr_data(31 downto 24) <= M2H2_HIBI_BASE;
              fsm_hibi_wr_data(DIRECT_RW_ADDR_U downto MEM_BYTE_ADDR_OFFSET) <= m2h2_conf_rw_addr + 1;
              
              m2h2_conf_rw_addr <= m2h2_conf_rw_addr + 1;
              
              if (DELAY_ENABLE = 0) then
                fsm_state <= SINGLE_WR_AV;
                fsm_hibi_wr_req <= '1';
              else
                fsm_state <= DELAY;
              end if;
              
              next_fsm_state <= SINGLE_WR_AV;
              delay_cnt <= test_cfg_delay;
            else
              test_done_out <= '1';
              
              fsm_state <= WAIT_START;
              
              m2h2_rd_cycle_cnt_started_r <= '0';
              m2h2_rd_cycle_cnt_ready_r <= '1';
            end if;
          end if;
      end case;
    end if;
  end process;
  
  m2h2_wr_req_fifo : entity work.fifo_u
	generic map (
		data_width_g => 24, 
		depth_g => M2H2_MAX_CHANS )  
	port map (
		clk => clk,
		rst_n => rst_n,
		data_in => m2h2_wr_req_fifo_wdata_r,
		we_in => m2h2_wr_req_fifo_we_r,
		data_out => m2h2_wr_req_fifo_rdata,
		re_in => m2h2_wr_req_fifo_re_r,
    full_out => m2h2_wr_req_fifo_full,
    one_p_out => m2h2_wr_req_fifo_one_p,
    empty_out => m2h2_wr_req_fifo_empty,
    one_d_out => m2h2_wr_req_fifo_one_d );
  
  m2h2_rd_req_fifo : entity work.fifo_u
	generic map (
		data_width_g => 24, 
		depth_g => M2H2_MAX_CHANS )  
	port map (
		clk => clk,
		rst_n => rst_n,
		data_in => m2h2_rd_req_fifo_wdata_r,
		we_in => m2h2_rd_req_fifo_we_r,
		data_out => m2h2_rd_req_fifo_rdata,
		re_in => m2h2_rd_req_fifo_re_r,
    full_out => m2h2_rd_req_fifo_full,
    one_p_out => m2h2_rd_req_fifo_one_p,
    empty_out => m2h2_rd_req_fifo_empty,
    one_d_out => m2h2_rd_req_fifo_one_d );
  
end rtl;
