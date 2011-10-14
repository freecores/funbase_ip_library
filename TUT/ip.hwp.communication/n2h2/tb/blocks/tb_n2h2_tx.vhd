-------------------------------------------------------------------------------
-- Title      : Testbench for design "n2h2_tx"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_n2h2_tx.vhd
-- Author     : kulmala3
-- Created    : 30.03.2005
-- Last update: 2011-03-09
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2005 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 30.03.2005  1.0      AK      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity tb_n2h2_tx is

end tb_n2h2_tx;

-------------------------------------------------------------------------------

architecture rtl of tb_n2h2_tx is


  -- component generics
  constant data_width_g   : integer := 32;  --0;
  constant amount_width_g : integer := 16;  --0;

  -- component ports
  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';

  signal avalon_addr_from_tx        : std_logic_vector(data_width_g-1 downto 0);
  signal avalon_re_from_tx          : std_logic;
  signal avalon_readdata_to_tx      : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  signal avalon_readdatavalid_to_tx : std_logic                                 := '0';

  signal avalon_waitrequest_to_tx : std_logic := '0';
  signal hibi_data_from_tx        : std_logic_vector(data_width_g-1 downto 0);
  signal hibi_av_from_tx          : std_logic;
  signal hibi_full_to_tx          : std_logic := '0';
  signal hibi_comm_from_tx        : std_logic_vector(4 downto 0);
  signal hibi_we_from_tx          : std_logic;
  signal tx_start_to_tx           : std_logic := '0';
  signal tx_status_done_from_tx   : std_logic;

  signal tx_comm_to_tx : std_logic_vector(4 downto 0) := (others => '0');

  signal tx_hibi_addr_to_tx : std_logic_vector(data_width_g-1 downto 0)   := (others => '0');
  signal tx_ram_addr_to_tx  : std_logic_vector(data_width_g-1 downto 0)   := (others => '0');
  signal tx_amount_to_tx    : std_logic_vector(amount_width_g-1 downto 0) := (others => '0');

  -- clock and reset
  signal   Clk2   : std_logic;
  constant Period : time := 10 ns;

begin  -- rtl




  -- component instantiation
  DUT : entity work.n2h2_tx
    generic map (
      data_width_g   => data_width_g,
      amount_width_g => amount_width_g)
    port map (
      clk                     => clk,
      rst_n                   => rst_n,
      avalon_addr_out         => avalon_addr_from_tx,
      avalon_re_out           => avalon_re_from_tx,
      avalon_readdata_in      => avalon_readdata_to_tx,
      avalon_waitrequest_in   => avalon_waitrequest_to_tx,
      avalon_readdatavalid_in => avalon_readdatavalid_to_tx,
      hibi_data_out           => hibi_data_from_tx,
      hibi_av_out             => hibi_av_from_tx,
      hibi_full_in            => hibi_full_to_tx,
      hibi_comm_out           => hibi_comm_from_tx,
      hibi_we_out             => hibi_we_from_tx,
      tx_start_in             => tx_start_to_tx,
      tx_status_done_out      => tx_status_done_from_tx,
      tx_comm_in              => tx_comm_to_tx,
      tx_hibi_addr_in         => tx_hibi_addr_to_tx,
      tx_ram_addr_in          => tx_ram_addr_to_tx,
      tx_amount_in            => tx_amount_to_tx);


  CLOCK1 : process                      -- generate clock signal for design
    variable clktmp : std_logic := '0';
  begin
    wait for PERIOD/2;
    clktmp := not clktmp;
    Clk    <= clktmp;
  end process CLOCK1;

  CLOCK2 : process                      -- generate clock signal for design
    variable clktmp : std_logic := '0';
  begin
    clktmp := not clktmp;
    Clk2   <= clktmp;
    wait for PERIOD/2;
  end process CLOCK2;

  RESET : process
  begin
    Rst_n <= '0';                       -- Reset the testsystem
    wait for 6*PERIOD;                  -- Wait 
    Rst_n <= '1';                       -- de-assert reset
    wait;
  end process RESET;




end rtl;

-------------------------------------------------------------------------------
