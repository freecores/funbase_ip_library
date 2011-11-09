-------------------------------------------------------------------------------
-- Title      : SDRAM TEST.
-- Project    : 
-------------------------------------------------------------------------------
-- File       : sdram_test.vhd
-- Author     :   <alhonena@BUMMALO>
-- Company    : 
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Quick test for SDRAM controller; writes 4 words to SDRAM, reads
-- them back and verifies the contents. The 3rd word is configured by external
-- switches so you can verify that the verification works :-).
--
-- Just for an experiment, I implemented the FSM as an integer counter.
-- It looks much nicer in SignalTap I primarily used to verify the operation.
-- LEDR shows the progress, LEDG shows error status.
-- LEDG(0) -> data came too early from the ctrl.
-- LEDG(1...4) -> data mismatch.
-- LEDG(5) -> extra data from the ctrl.
-- LEDR(0) -> Gave write command.
-- LEDR(1) -> Gave read command.
-- LEDR(10...13) -> data words succesfully read.
-- NOTE: Test number 3 comes from the switches -- this way, you can test
-- that the test can fail. Set the switches as "0101010101010101" to pass
-- the test.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2009/08/13  1.0      alhonena	Created
-- 2011/07/16  2.0      alhonena        Continued.
-- 2011/10/09  2.1      alhonena        Updated coding conventions & comments.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity de2_sdram_tester is
  
  port (
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    
    SW    : in  std_logic_vector(15 downto 0);
    LEDR : out std_logic_vector(17 downto 0);
    LEDG : out std_logic_vector(8 downto 0);

    -- INTERFACE TO SDRAM CTRL
    command_out            : out   std_logic_vector(1 downto 0);
    address_out            : out   std_logic_vector(21 downto 0);
    data_amount_out        : out   std_logic_vector(21 downto 0);
    byte_select_out        : out   std_logic_vector(1 downto 0);
    input_empty_out        : out   std_logic;
    input_one_d_out        : out   std_logic;
    output_full_out        : out   std_logic;
    data_out               : out   std_logic_vector(15 downto 0);
    write_on_in            : in    std_logic;
    busy_in                : in    std_logic;
    output_we_in           : in    std_logic;
    input_re_in            : in    std_logic;
    data_in                : in    std_logic_vector(15 downto 0);

    sdram_clk_out          : out   std_logic
    
    );

end de2_sdram_tester;

architecture rtl of de2_sdram_tester is

  component fifo
    generic (
      data_width_g : integer;
      depth_g      : integer);
    port (
      clk       : in  std_logic;
      rst_n     : in  std_logic;
      data_in   : in  std_logic_vector (data_width_g-1 downto 0);
      we_in     : in  std_logic;
      full_out  : out std_logic;
      one_p_out : out std_logic;
      re_in     : in  std_logic;
      data_out  : out std_logic_vector (data_width_g-1 downto 0);
      empty_out : out std_logic;
      one_d_out : out std_logic);
  end component;

  signal fifo_to_sdram_one_d : std_logic;
  signal fifo_to_sdram_empty : std_logic;
  signal fifo_to_sdram_re : std_logic;
  signal fifo_to_sdram_data : std_logic_vector(15 downto 0);
  signal fifo_from_sdram_data : std_logic_vector(15 downto 0);
  signal fifo_from_sdram_we : std_logic;
  signal fifo_from_sdram_full : std_logic;

  signal data_to_write_r : std_logic_vector(15 downto 0);
  signal we_r : std_logic;
  signal fifo_full : std_logic;

  signal data_to_read : std_logic_vector(15 downto 0);
  signal re_r : std_logic;
  signal empty_from_fifo : std_logic;

  signal state_r : integer range 0 to 15;

  signal read_cnt_r : integer range 0 to 7;

  signal command_to_sdram_ctrl : std_logic_vector(1 downto 0);
  signal address_to_sdram_ctrl : std_logic_vector(21 downto 0);
  signal data_amount_to_sdram_ctrl : std_logic_vector(21 downto 0);

  signal write_on, busy : std_logic;
  
begin  -- rtl

  command_out     <= command_to_sdram_ctrl;
  address_out     <= address_to_sdram_ctrl;
  data_amount_out <= data_amount_to_sdram_ctrl;
  byte_select_out <= "00";        -- Always do 16-bit writes.
  input_empty_out <= fifo_to_sdram_empty;
  input_one_d_out <= fifo_to_sdram_one_d;
  output_full_out <= fifo_from_sdram_full;
  data_out        <= fifo_to_sdram_data;

  write_on             <= write_on_in;
  busy                 <= busy_in;
  fifo_from_sdram_we   <= output_we_in;
  fifo_to_sdram_re     <= input_re_in;
  fifo_from_sdram_data <= data_in;

--  sdram_clk_out <= clk;

  de2_sdram_pll_1: entity work.de2_sdram_pll
    port map (
      inclk0 => clk,
      c0     => sdram_clk_out);
  
  fifo_to_sdram: fifo
    generic map (
        data_width_g => 16,
        depth_g      => 8)
    port map (
        clk       => clk,
        rst_n     => rst_n,
        data_in   => data_to_write_r,
        we_in     => we_r,
        full_out  => fifo_full,
        one_p_out => open,
        re_in     => fifo_to_sdram_re,
        data_out  => fifo_to_sdram_data,
        empty_out => fifo_to_sdram_empty,
        one_d_out => fifo_to_sdram_one_d);

  fifo_from_sdram: fifo
    generic map (
        data_width_g => 16,
        depth_g      => 8)
    port map (
        clk       => clk,
        rst_n     => rst_n,
        data_in   => fifo_from_sdram_data,
        we_in     => fifo_from_sdram_we,
        full_out  => fifo_from_sdram_full,
        one_p_out => open,
        re_in     => re_r,
        data_out  => data_to_read,
        empty_out => empty_from_fifo,
        one_d_out => open);
  
  tester: process (clk, rst_n)
  begin  -- process tester
    if rst_n = '0' then                 -- asynchronous reset (active low)

      state_r <= 0;
      read_cnt_r <= 0;

      command_to_sdram_ctrl <= "00";

      LEDR <= (others => '0');
      LEDG <= (others => '0');
      
    elsif clk'event and clk = '1' then  -- rising clock edge

      -- Wait for initialization.
      if state_r = 0 and busy = '0' then
        state_r <= 1;
      end if;

      if state_r = 1 then
        data_to_write_r <= "1011001100011101";
        we_r <= '1';
        state_r <= 2;
      end if;

      if state_r = 2 then
        data_to_write_r <= "0001010100010100";
        we_r <= '1';
        state_r <= 3;
      end if;      

      if state_r = 3 then
        data_to_write_r <= SW;
        we_r <= '1';
        state_r <= 4;
      end if;

      if state_r = 4 then
        data_to_write_r <= "0010000001001100";
        we_r <= '1';
        state_r <= 5;
      end if;

      if state_r = 5 then
        we_r <= '0';
        command_to_sdram_ctrl <= "10";  -- WRITE COMMAND.
        address_to_sdram_ctrl <= "0000000000010011010010";  -- just a test address.
        data_amount_to_sdram_ctrl <= std_logic_vector(to_unsigned(4, 22));  -- Write four.
        state_r <= 6;
        LEDR(0) <= '1';
      end if;

      if state_r = 6 then
        command_to_sdram_ctrl <= "00";
        if busy = '0' then
          state_r <= 7;
        end if;
      end if;

      if state_r = 7 then
        command_to_sdram_ctrl <= "00";
        if busy = '0' then
          state_r <= 8;
        end if;
      end if;

      if state_r = 8 then
        command_to_sdram_ctrl <= "00";
        if busy = '0' then
          state_r <= 9;
        end if;
      end if;      

      if state_r = 9 then
        if busy = '0' then
          command_to_sdram_ctrl <= "01";  -- READ COMMAND.
          address_to_sdram_ctrl <= "0000000000010011010010";
          data_amount_to_sdram_ctrl <= std_logic_vector(to_unsigned(4, 22));
          state_r <= 10;
          LEDR(1) <= '1';
        end if;
        
      end if;

      if state_r = 10 then
        command_to_sdram_ctrl <= "00";
        state_r <= 11;
      end if;

      if empty_from_fifo = '0' and state_r < 10 then
        -- Error led: SDRAM controller gave data before it was asked for.
        LEDG(0) <= '1';
      end if;

      re_r <= '0';

      if empty_from_fifo = '0' then
        read_cnt_r <= read_cnt_r + 1;
        LEDR(read_cnt_r + 10) <= '1';
        re_r <= '1';
        case read_cnt_r is
          when 1 => if data_to_read /= "1011001100011101" then
                       LEDG(1) <= '1';
                     end if;
          when 2 => if data_to_read /= "0001010100010100" then
                       LEDG(2) <= '1';
                     end if;
          when 3 => if data_to_read /= "0101010101010101" then
                       LEDG(3) <= '1';
                     end if;
          when 4 => if data_to_read /= "0010000001001100" then
                       LEDG(4) <= '1';
                     end if;
          when 5 => LEDG(5) <= '1';  -- Too much data came from the ctrl.

          when others => null;
        end case;
      end if;


    end if;
  end process tester;

end rtl;
