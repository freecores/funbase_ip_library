-------------------------------------------------------------------------------
-- Title      : Avalon cfg writer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : avalon_cfg_writer.vhd
-- Author     : kulmala3
-- Created    : 22.03.2005
-- Last update: 2010/05/07
-- Description: testbench block to config the dma via avalon
-------------------------------------------------------------------------------
-- Copyright (c) 2005 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 22.03.2005  1.0      AK      Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use work.txt_util.all;
--use work.log2_pkg.all;
use work.tb_n2h2_pkg.all;

entity avalon_cfg_writer is
  generic (
    n_chans_g    : integer := 0;
    data_width_g : integer := 0;
    conf_file_g  : string  := ""
    );
  port (
    clk                      : in  std_logic;
    rst_n                    : in  std_logic;
    start_in                 : in  std_logic;
    avalon_cfg_addr_out      : out std_logic_vector(log2(n_chans_g)+conf_bits_c-1 downto 0);
    avalon_cfg_writedata_out : out std_logic_vector(data_width_g-1 downto 0);
    avalon_cfg_we_out        : out std_logic;
    avalon_cfg_cs_out        : out std_logic;
    init_in                  : in  std_logic;
    done_out                 : out std_logic
    );
end avalon_cfg_writer;

architecture rtl of avalon_cfg_writer is

  signal state_r        : integer;
  signal init_state_r   : integer;
  signal chan_counter_r : integer;
begin  -- rtl

  process (clk, rst_n)
    file conf_file        : text open read_mode is conf_file_g;
    variable mem_addr_r   : integer;
    variable sender_r     : integer;
    variable irq_amount_r : integer;
    variable max_amount_r : integer;
  begin  -- process
    if rst_n = '0' then                 -- asynchronous reset (active low)
      chan_counter_r           <= 0;
      avalon_cfg_cs_out        <= '0';
      avalon_cfg_we_out        <= '0';
      avalon_cfg_writedata_out <= (others => '0');
      avalon_cfg_addr_out      <= (others => '0');
      done_out                 <= '0';
      state_r                  <= 0;
      init_state_r             <= 0;
      
    elsif clk'event and clk = '1' then  -- rising clock edge
      
      case state_r is
        when 0 =>
          if start_in = '1' then
            state_r  <= 1;
            done_out <= '0';
          else
            done_out <= '0';
            state_r  <= 0;
          end if;

        when 1 =>
          read_conf_file (
            mem_addr   => mem_addr_r ,
            sender     => sender_r,
            irq_amount => irq_amount_r,
--            max_amount => max_amount_r,
            file_txt   => conf_file
            );

          assert false report "mem_addr: " & str(mem_addr_r) severity note;
          assert false report "sender_r: " & str(sender_r) severity note;
          assert false report "irq_amount_r: " & str(irq_amount_r) severity note;
--          assert false report "max_amount_r: " & str(max_amount_r) severity note;

          avalon_cfg_writedata_out <= conv_std_logic_vector(mem_addr_r, data_width_g);
          avalon_cfg_addr_out      <= conv_std_logic_vector(chan_counter_r, log2(n_chans_g)) &
                                      conv_std_logic_vector(0, conf_bits_c);
          avalon_cfg_we_out <= '1';
          avalon_cfg_cs_out <= '1';
          state_r           <= 2;

        when 2 =>

          avalon_cfg_writedata_out <= conv_std_logic_vector(sender_r, data_width_g);
          avalon_cfg_addr_out      <= conv_std_logic_vector(chan_counter_r, log2(n_chans_g)) &
                                      conv_std_logic_vector(1, conf_bits_c);

          avalon_cfg_we_out <= '1';
          avalon_cfg_cs_out <= '1';
          state_r           <= 3;
          
        when 3 =>

          avalon_cfg_writedata_out <= conv_std_logic_vector(irq_amount_r, data_width_g);
          avalon_cfg_addr_out      <= conv_std_logic_vector(chan_counter_r, log2(n_chans_g)) &
                                      conv_std_logic_vector(2, conf_bits_c);

          avalon_cfg_we_out <= '1';
          avalon_cfg_cs_out <= '1';
          state_r           <= 5;

          -- obsolete
--        when 4 =>

--          avalon_cfg_writedata_out <= conv_std_logic_vector(max_amount_r, data_width_g);
--          avalon_cfg_addr_out      <= conv_std_logic_vector(chan_counter_r, log2(n_chans_g)) &
--                                      conv_std_logic_vector(0, conf_bits_c);
--          avalon_cfg_we_out        <= '1';
--          avalon_cfg_cs_out        <= '1';
--          state_r                  <= 5;

        when 5 =>
          -- set init bit
          avalon_cfg_writedata_out                 <= (others => '0');
          avalon_cfg_writedata_out(chan_counter_r) <= '1';
          avalon_cfg_addr_out                      <= conv_std_logic_vector(chan_counter_r, log2(n_chans_g)) &
                                                      conv_std_logic_vector(5, conf_bits_c);
          avalon_cfg_we_out <= '1';
          avalon_cfg_cs_out <= '1';
          state_r           <= 6;

        when 6 =>
          -- set irq_ena bit
          avalon_cfg_writedata_out    <= (others => '0');
          avalon_cfg_writedata_out(1) <= '1';
          avalon_cfg_addr_out         <= conv_std_logic_vector(chan_counter_r, log2(n_chans_g)) &
                                         conv_std_logic_vector(4, conf_bits_c);
          avalon_cfg_we_out <= '1';
          avalon_cfg_cs_out <= '1';
          state_r           <= 7;

          -- obsolete
--        when 6 =>
--          -- reset init
--          avalon_cfg_writedata_out <= conv_std_logic_vector(2, data_width_g);
--          avalon_cfg_addr_out      <= conv_std_logic_vector(chan_counter_r, log2(n_chans_g)) &
--                                      conv_std_logic_vector(0, conf_bits_c);
--          avalon_cfg_we_out        <= '1';
--          avalon_cfg_cs_out        <= '1';
--          state_r <= 7;

        when 7 =>
          avalon_cfg_cs_out <= '0';
          chan_counter_r    <= chan_counter_r+1;
          state_r           <= 8;

        when 8 =>
          if chan_counter_r = n_chans_g then
            state_r           <= 0;
            chan_counter_r    <= 0;
            avalon_cfg_we_out <= '0';
            done_out          <= '1';
          else
            state_r <= 1;
          end if;
          
        when others => null;
      end case;

      if init_in = '1' then
        init_state_r <= 1;
      end if;

      case init_state_r is
        when 1 =>
          -- set init bit
          avalon_cfg_writedata_out                 <= (others => '0');
          avalon_cfg_writedata_out(chan_counter_r) <= '1';

          avalon_cfg_addr_out <= conv_std_logic_vector(chan_counter_r, log2(n_chans_g)) &
                                 conv_std_logic_vector(5, conf_bits_c);
          avalon_cfg_we_out <= '1';
          avalon_cfg_cs_out <= '1';
          init_state_r      <= 2;
          chan_counter_r    <= chan_counter_r+1;

        when 2 =>
          if chan_counter_r = n_chans_g then
            init_state_r      <= 0;
            avalon_cfg_we_out <= '0';
            avalon_cfg_cs_out <= '0';
            done_out          <= '1';
            chan_counter_r    <= 0;
          else
            avalon_cfg_we_out <= '0';
            init_state_r      <= 1;
          end if;
          
        when others => null;
      end case;

    end if;
  end process;
  
  
end rtl;
