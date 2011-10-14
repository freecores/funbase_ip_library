-------------------------------------------------------------------------------
-- Title      : N2H2 TX
-- Project    : 
-------------------------------------------------------------------------------
-- File       : n2h2_tx.vhd
-- Author     : kulmala3
-- Created    : 30.03.2005
-- Last update: 27.04.2005
-- Description: Bufferless transmitter for N2H2. 
-- 
-------------------------------------------------------------------------------
-- Copyright (c) 2005 
-- Potential dead-lock (very bad luck): hibi is full, tx cant transfer,
-- -> tx reserves avalon bus until hibi is freed.
-- Fix needs some extra logic, done if necessary later (report!).
-- probably done anyway at some point.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 30.03.2005  1.0      AK      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity n2h2_tx is
  
  generic (
    -- legal values because of SOPC Builder £@££@ crap.
    data_width_g   : integer := 2;
    amount_width_g : integer := 1);

  port (
    clk                   : in  std_logic;
    rst_n                 : in  std_logic;
    -- Avalon master read interface
    avalon_addr_out       : out std_logic_vector(data_width_g-1 downto 0);
    avalon_re_out         : out std_logic;
    avalon_readdata_in    : in  std_logic_vector(data_width_g-1 downto 0);
    avalon_waitrequest_in : in  std_logic;
    -- hibi write interface
    hibi_data_out         : out std_logic_vector(data_width_g-1 downto 0);
    hibi_av_out           : out std_logic;
    hibi_full_in          : in  std_logic;
    hibi_comm_out         : out std_logic_vector(2 downto 0);
    hibi_we_out           : out std_logic;
    -- DMA conf interface
    tx_start_in           : in  std_logic;
    tx_status_done_out    : out std_logic;
    tx_comm_in            : in  std_logic_vector(2 downto 0);
    tx_hibi_addr_in       : in  std_logic_vector(data_width_g-1 downto 0);
    tx_ram_addr_in        : in  std_logic_vector(data_width_g-1 downto 0);
    tx_amount_in          : in  std_logic_vector(amount_width_g-1 downto 0)
    );

end n2h2_tx;

architecture rtl of n2h2_tx is

  constant addr_offset_c : integer := data_width_g/8;

  type   control_states is (idle, transmit_addr, transmit);
  signal control_r      : control_states;
  signal start_tx_r     : std_logic;
  signal hibi_we_r      : std_logic;
  signal amount_cnt_r   : std_logic_vector(amount_width_g-1 downto 0);
  signal avalon_addr_r  : std_logic_vector(data_width_g-1 downto 0);
  signal sel_data_src_r : std_logic;
  
begin  -- rtl

  hibi_we_r     <= (avalon_waitrequest_in nor hibi_full_in) and start_tx_r;
  hibi_we_out   <= hibi_we_r;
--  avalon_re_out <= start_tx_r and (not hibi_full_in);
  avalon_re_out <= start_tx_r; -- 27.4.
  avalon_addr_out <= avalon_addr_r;

  data_out : process (sel_data_src_r, avalon_readdata_in, tx_hibi_addr_in)
  begin  -- process hibi_data_out
    if sel_data_src_r = '0' then
      hibi_data_out <= avalon_readdata_in;
    else
      hibi_data_out <= tx_hibi_addr_in;
    end if;
  end process data_out;

  main : process (clk, rst_n)
  begin  -- process main
    if rst_n = '0' then                 -- asynchronous reset (active low)
      start_tx_r         <= '0';
      control_r          <= idle;
      amount_cnt_r       <= conv_std_logic_vector(0, amount_width_g);
      avalon_addr_r      <= (others => 'X');
      tx_status_done_out <= '0';
      hibi_av_out        <= '0';
      hibi_comm_out      <= (others => '0');
      sel_data_src_r     <= '1';
      
    elsif clk'event and clk = '1' then  -- rising clock edge
      case control_r is
        when idle =>
          if tx_start_in = '1' then
            -- transfer address from register
            control_r          <= transmit_addr;
            avalon_addr_r      <= tx_ram_addr_in;
            hibi_comm_out      <= tx_comm_in;
            hibi_av_out        <= '1';
            start_tx_r         <= '1';
            tx_status_done_out <= '0';
            sel_data_src_r     <= '1';
          else
            control_r          <= idle;
            avalon_addr_r      <= (others => 'X');
            hibi_comm_out      <= (others => 'X');
            hibi_av_out        <= '1';
            start_tx_r         <= '0';
            tx_status_done_out <= '1';
            
          end if;

        when transmit_addr =>
          start_tx_r <= '1';

          if hibi_we_r = '1' then
            sel_data_src_r     <= '0';
            -- transfer address from register
            control_r          <= transmit;
            avalon_addr_r      <= tx_ram_addr_in;  --+addr_offset_c;
            hibi_av_out        <= '0';
            tx_status_done_out <= '0';

            amount_cnt_r <= amount_cnt_r+1;
          else
            control_r          <= transmit_addr;
            avalon_addr_r      <= tx_ram_addr_in;
            hibi_av_out        <= '1';
            tx_status_done_out <= '0';
--            hibi_data_out <= tx_hibi_addr_in;
            sel_data_src_r     <= '1';
          end if;

        when transmit =>
          if hibi_we_r = '1' then
            hibi_av_out   <= '0';
            amount_cnt_r  <= amount_cnt_r+1;
            avalon_addr_r <= avalon_addr_r + addr_offset_c;
            -- start data transfer here
            start_tx_r    <= '1';

            -- every data transferred
            if amount_cnt_r >= tx_amount_in then
              amount_cnt_r       <= conv_std_logic_vector(0, amount_width_g);
              control_r          <= idle;
              start_tx_r         <= '0';
              tx_status_done_out <= '1';
            end if;
          end if;

        when others =>
          
      end case;
    end if;
  end process main;
  

end rtl;
