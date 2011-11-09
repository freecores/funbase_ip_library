-------------------------------------------------------------------------------
-- Title      : 2D mesh mk1 by ase
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ase_mesh1.vhdl
-- Author     : Lasse Lehtonen
-- Company    : 
-- Created    : 2010-06-14
-- Last update: 2011-10-07
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2010 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2010-06-14  1.0      ase     Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ase_mesh1 is

  generic (
    n_rows_g    : positive := 4;        -- Nuber of rows
    n_cols_g    : positive := 4;        -- Nuber of columns
    cmd_width_g : positive := 2;        -- Width of the cmd line
    bus_width_g : positive := 32);      -- Width of the data bus
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    data_in   : in  std_logic_vector(n_rows_g*n_cols_g*bus_width_g-1 downto 0);
    cmd_in    : in  std_logic_vector(n_rows_g*n_cols_g*cmd_width_g-1 downto 0);
    stall_out : out std_logic_vector(n_rows_g*n_cols_g-1 downto 0);
    data_out  : out std_logic_vector(n_rows_g*n_cols_g*bus_width_g-1 downto 0);
    cmd_out   : out std_logic_vector(n_rows_g*n_cols_g*cmd_width_g-1 downto 0);
    stall_in  : in  std_logic_vector(n_rows_g*n_cols_g-1 downto 0));

end entity ase_mesh1;


architecture rtl of ase_mesh1 is

  -- row data
  type r_data_type is array (0 to n_rows_g) of
    std_logic_vector(n_cols_g*bus_width_g-1 downto 0);
  type r_bit_type is array (0 to n_rows_g) of
    std_logic_vector(n_cols_g-1 downto 0);
  
  signal sn_data  : r_data_type;
  signal sn_av    : r_bit_type;
  signal sn_da    : r_bit_type;
  signal sn_stall : r_bit_type;

  signal ns_data  : r_data_type;
  signal ns_av    : r_bit_type;
  signal ns_da    : r_bit_type;
  signal ns_stall : r_bit_type;

  -- col data
  type c_data_type is array (0 to n_cols_g) of
    std_logic_vector(n_rows_g*bus_width_g-1 downto 0);
  type c_bit_type is array (0 to n_cols_g) of
    std_logic_vector(n_rows_g-1 downto 0);
  
  signal ew_data  : c_data_type;
  signal ew_av    : c_bit_type;
  signal ew_da    : c_bit_type;
  signal ew_stall : c_bit_type;

  signal we_data  : c_data_type;
  signal we_av    : c_bit_type;
  signal we_da    : c_bit_type;
  signal we_stall : c_bit_type;

  
begin  -- architecture rtl

  ns_data(0)         <= (others => '0');
  ns_av(0)           <= (others => '0');
  ns_da(0)           <= (others => '0');
  ns_stall(n_rows_g) <= (others => '0');

  we_data(0)         <= (others => '0');
  we_av(0)           <= (others => '0');
  we_da(0)           <= (others => '0');
  we_stall(n_cols_g) <= (others => '0');

  sn_data(n_rows_g) <= (others => '0');
  sn_av(n_rows_g)   <= (others => '0');
  sn_da(n_rows_g)   <= (others => '0');
  sn_stall(0)       <= (others => '0');

  ew_data(n_cols_g) <= (others => '0');
  ew_av(n_cols_g)   <= (others => '0');
  ew_da(n_cols_g)   <= (others => '0');
  ew_stall(0)       <= (others => '0');



  row : for r in 0 to n_rows_g-1 generate
    col : for c in 0 to n_cols_g-1 generate

      i_router : entity work.ase_mesh1_router(rtl)
        generic map (
          n_rows_g    => n_rows_g,
          n_cols_g    => n_cols_g,
          bus_width_g => bus_width_g)
        port map (
          clk   => clk,
          rst_n => rst_n,

          a_data_in   => data_in(((r*n_cols_g)+c+1)*bus_width_g-1 downto
                                 ((r*n_cols_g)+c)*bus_width_g),
          a_da_in     => cmd_in(2*((r*n_cols_g)+c)+1),
          a_av_in     => cmd_in(2*((r*n_cols_g)+c)),
          a_stall_out => stall_out((r*n_cols_g)+c),
          a_data_out  => data_out(((r*n_cols_g)+c+1)*bus_width_g-1 downto
                                  ((r*n_cols_g)+c)*bus_width_g),
          a_da_out    => cmd_out(2*((r*n_cols_g)+c)+1),
          a_av_out    => cmd_out(2*((r*n_cols_g)+c)),
          a_stall_in  => stall_in((r*n_cols_g)+c),

          n_data_in   => ns_data(r)((c+1)*bus_width_g-1 downto c*bus_width_g),
          n_da_in     => ns_da(r)(c),
          n_av_in     => ns_av(r)(c),
          n_stall_out => ns_stall(r)(c),
          n_data_out  => sn_data(r)((c+1)*bus_width_g-1 downto c*bus_width_g),
          n_da_out    => sn_da(r)(c),
          n_av_out    => sn_av(r)(c),
          n_stall_in  => sn_stall(r)(c),

          e_data_in   => ew_data(c+1)((r+1)*bus_width_g-1 downto r*bus_width_g),
          e_da_in     => ew_da(c+1)(r),
          e_av_in     => ew_av(c+1)(r),
          e_stall_out => ew_stall(c+1)(r),
          e_data_out  => we_data(c+1)((r+1)*bus_width_g-1 downto r*bus_width_g),
          e_da_out    => we_da(c+1)(r),
          e_av_out    => we_av(c+1)(r),
          e_stall_in  => we_stall(c+1)(r),

          s_data_in   => sn_data(r+1)((c+1)*bus_width_g-1 downto c*bus_width_g),
          s_da_in     => sn_da(r+1)(c),
          s_av_in     => sn_av(r+1)(c),
          s_stall_out => sn_stall(r+1)(c),
          s_data_out  => ns_data(r+1)((c+1)*bus_width_g-1 downto c*bus_width_g),
          s_da_out    => ns_da(r+1)(c),
          s_av_out    => ns_av(r+1)(c),
          s_stall_in  => ns_stall(r+1)(c),

          w_data_in   => we_data(c)((r+1)*bus_width_g-1 downto r*bus_width_g),
          w_da_in     => we_da(c)(r),
          w_av_in     => we_av(c)(r),
          w_stall_out => we_stall(c)(r),
          w_data_out  => ew_data(c)((r+1)*bus_width_g-1 downto r*bus_width_g),
          w_da_out    => ew_da(c)(r),
          w_av_out    => ew_av(c)(r),
          w_stall_in  => ew_stall(c)(r));

    end generate col;
  end generate row;
  


end architecture rtl;
