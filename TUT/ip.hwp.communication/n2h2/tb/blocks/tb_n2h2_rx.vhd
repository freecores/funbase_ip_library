-------------------------------------------------------------------------------
-- Title      : Testbench for design "n2h2_rx"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_n2h2_rx.vhdl
-- Author     : kulmala3
-- Created    : 22.03.2005
-- Last update: 2011-03-09
-- Description: 
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
use work.tb_n2h2_pkg.all;
-- use work.log2_pkg.all;
-------------------------------------------------------------------------------

entity tb_n2h2_rx is

end tb_n2h2_rx;

-------------------------------------------------------------------------------

architecture tb of tb_n2h2_rx is

  signal clk   : std_logic := '0';
  signal clk2  : std_logic := '0';
  signal rst_n : std_logic := '0';

  -- component n2h2 rx generics
  constant n_chans_c          : integer := 3;
  constant n_chans_bits_c     : integer := 2;
  constant data_width_c       : integer := 64;  -- 32 and 64 legal
  constant addr_width_c       : integer := 32;
  constant comm_width_c       : integer := 5;
  constant hibi_addr_cmp_hi_c : integer := 31;
  constant hibi_addr_cmp_lo_c : integer := 0;
  constant amount_width_c     : integer := 5;   -- 2**5 flits max

  -- component ports
  signal avalon_addr_from_rx      : std_logic_vector(addr_width_c-1 downto 0);
  signal avalon_we_from_rx        : std_logic;
  signal avalon_be_from_rx        : std_logic_vector(data_width_c/8-1 downto 0);
  signal avalon_writedata_from_rx : std_logic_vector(data_width_c-1 downto 0);
  signal avalon_waitrequest_to_rx : std_logic;
  signal avalon_waitreqvec_to_rx  : std_logic_vector(n_chans_c-1 downto 0);
  signal hibi_data_to_rx          : std_logic_vector(data_width_c-1 downto 0);
  signal hibi_av_to_rx            : std_logic;
  signal hibi_empty_to_rx         : std_logic;
  signal hibi_comm_to_rx          : std_logic_vector(4 downto 0);

  signal hibi_re_from_rx             : std_logic;
  signal avalon_cfg_addr_to_rx       : std_logic_vector(log2(n_chans_c)+conf_bits_c-1 downto 0);
  signal avalon_cfg_writedata_to_rx  : std_logic_vector(addr_width_c-1 downto 0);
  signal avalon_cfg_we_to_rx         : std_logic;
  signal avalon_cfg_readdata_from_rx : std_logic_vector(addr_width_c-1 downto 0);
  signal avalon_cfg_re_to_rx         : std_logic;
  signal avalon_cfg_cs_to_rx         : std_logic;
  signal rx_irq_from_rx              : std_logic;
  signal tx_start_from_rx            : std_logic;
  signal tx_status_done_to_rx        : std_logic;

  -- config writer
  constant conf_file_c              : string := "tbrx_conf_rx.dat";
  constant conf_file_hsender_c      : string := "tbrx_conf_hibisend.dat";
  constant data_file_c              : string := "tbrx_data_file.dat";
  signal   start_to_cfg             : std_logic;
  signal   avalon_cfg_addr_from_cfg : std_logic_vector(log2(n_chans_c)+conf_bits_c-1 downto 0);
--  signal   avalon_cfg_we_from_cfg        : std_logic;
  signal   avalon_cfg_cs_from_cfg   : std_logic;
  signal   done_from_cfg            : std_logic;
  signal   init_to_cfg              : std_logic;

-- config reader
  signal start_to_cfg_reader             : std_logic;
  signal avalon_cfg_addr_from_cfg_reader : std_logic_vector(log2(n_chans_c)+conf_bits_c-1 downto 0);
--  signal avalon_cfg_readdata_to_cfg_reader : std_logic_vector(data_width_c-1 downto 0);
--  signal avalon_cfg_re_from_cfg_reader     : std_logic;
  signal avalon_cfg_cs_from_cfg_reader   : std_logic;
  signal done_from_cfg_reader            : std_logic;

  -- hibi writer
  signal done_from_hibi_sender    : std_logic;
  signal pause_hibi_send          : std_logic;
  signal pause_ack_hibi_send      : std_logic;
-- avalon reader
  signal init_to_reader           : std_logic_vector(n_chans_c-1 downto 0);
  signal not_my_addr_from_readers : std_logic_vector(n_chans_c-1 downto 0);


  -- clock and reset
  constant Period : time := 10 ns;

  -- cpu side signals

  -- system control signals
  type system_control_states is (config, wait_for_config, check_config,
                                 wait_check, wait_for_irq);
  signal system_control_r    : system_control_states;
  signal hibi_sender_start   : std_logic;
  signal hibi_sender_rst_n   : std_logic;
  type   chan_data_array is array (n_chans_c-1 downto 0) of std_logic_vector(data_width_c-1 downto 0);
  signal my_own_addr_c       : chan_data_array;
--  signal reset_buses_r : std_logic;
  signal avalon_reader_rst_n : std_logic;
  signal hibi_data_read      : std_logic;

  signal irq_was_up  : std_logic;
  signal irq_counter : integer;
begin  -- tb
  tx_status_done_to_rx <= '0';

  hibi_sender_rst_n <= hibi_sender_start and rst_n;
  process (clk, rst_n)
  begin  -- process
    if rst_n = '0' then                 -- asynchronous reset (active low)
      system_control_r    <= config;
      start_to_cfg_reader <= '0';
      start_to_cfg        <= '0';
      hibi_sender_start   <= '0';
--      reset_buses_r <= '1';
      init_to_cfg         <= '0';
      irq_was_up          <= '0';
      irq_counter         <= 0;
      pause_hibi_send     <= '0';
      for i in n_chans_c-1 downto 0 loop
        init_to_reader(i) <= '0';
      end loop;  -- i
      
    elsif clk'event and clk = '1' then  -- rising clock edge
      case system_control_r is
        when config =>
          -- write the dma config
          start_to_cfg     <= '1';
          system_control_r <= wait_for_config;
          
        when wait_for_config =>
          start_to_cfg <= '0';
          -- wait until it finishes configuring all channels
          if done_from_cfg = '1' then
            system_control_r <= check_config;
          end if;

        when check_config =>
          -- check that the config is written alright
          start_to_cfg_reader <= '1';
          system_control_r    <= wait_check;

        when wait_check =>
          -- wait for check to complete
          start_to_cfg_reader <= '0';
          if done_from_cfg_reader = '1' then
            system_control_r  <= wait_for_irq;
            -- unleash the hibi_sender
            hibi_sender_start <= '1';
          end if;

        when wait_for_irq =>
          -- check that irq amounts etc are all right.
          -- TODO stuff here.
          init_to_cfg <= '0';
          if done_from_cfg = '1' then
            pause_hibi_send <= '0';
          end if;

          if rx_irq_from_rx = '1' and irq_was_up = '0' then
            irq_counter <= irq_counter + 1;
            irq_was_up  <= '1';
          elsif rx_irq_from_rx = '0' then
            irq_was_up <= '0';
          end if;

          if irq_counter = n_chans_c then
            if pause_ack_hibi_send = '1' and hibi_empty_to_rx = '1' then
              init_to_cfg     <= '1';
              pause_hibi_send <= '1';
              irq_counter     <= 0;
            else
              init_to_cfg     <= '0';
              pause_hibi_send <= '1';
            end if;
          end if;

        when others => null;
      end case;


      
    end if;
  end process;

  waitreq : process (avalon_waitreqvec_to_rx)
  begin  -- process waitreq
    if avalon_waitreqvec_to_rx /= conv_std_logic_vector(0, n_chans_c) then
      avalon_waitrequest_to_rx <= '1';
    else
      avalon_waitrequest_to_rx <= '0';
    end if;
    
  end process waitreq;


  -- component instantiation
  DUT : entity work.n2h2_rx_channels
    generic map (
      n_chans_g          => n_chans_c,
      n_chans_bits_g     => n_chans_bits_c,
      data_width_g       => data_width_c,
      addr_width_g       => addr_width_c,
      hibi_addr_cmp_hi_g => hibi_addr_cmp_hi_c,
      hibi_addr_cmp_lo_g => hibi_addr_cmp_lo_c,
      amount_width_g     => amount_width_c)
    port map (
      clk                     => clk,
      rst_n                   => rst_n,
      avalon_addr_out         => avalon_addr_from_rx,
      avalon_we_out           => avalon_we_from_rx,
      avalon_be_out           => avalon_be_from_rx,
      avalon_writedata_out    => avalon_writedata_from_rx,
      avalon_waitrequest_in   => avalon_waitrequest_to_rx,
      hibi_data_in            => hibi_data_to_rx,
      hibi_av_in              => hibi_av_to_rx,
      hibi_empty_in           => hibi_empty_to_rx,
      hibi_comm_in            => hibi_comm_to_rx,
      hibi_re_out             => hibi_re_from_rx,
      avalon_cfg_addr_in      => avalon_cfg_addr_to_rx,
      avalon_cfg_writedata_in => avalon_cfg_writedata_to_rx,
      avalon_cfg_we_in        => avalon_cfg_we_to_rx,
      avalon_cfg_readdata_out => avalon_cfg_readdata_from_rx,
      avalon_cfg_re_in        => avalon_cfg_re_to_rx,
      avalon_cfg_cs_in        => avalon_cfg_cs_to_rx,
      rx_irq_out              => rx_irq_from_rx,
      tx_start_out            => tx_start_from_rx,
      tx_status_done_in       => tx_status_done_to_rx);


  cfg_mux : process (avalon_cfg_cs_from_cfg, avalon_cfg_cs_from_cfg_reader,
                     avalon_cfg_addr_from_cfg_reader, avalon_cfg_addr_from_cfg)
    variable vector : std_logic_vector(1 downto 0);
  begin  -- process cfg mux
    vector := avalon_cfg_cs_from_cfg & avalon_cfg_cs_from_cfg_reader;
    case vector is
      when "01" =>
        avalon_cfg_addr_to_rx <= avalon_cfg_addr_from_cfg_reader;
        avalon_cfg_cs_to_rx   <= avalon_cfg_cs_from_cfg_reader;

      when others =>
--      when "00" | "10" | "11" =>
        avalon_cfg_addr_to_rx <= avalon_cfg_addr_from_cfg;
        avalon_cfg_cs_to_rx   <= avalon_cfg_cs_from_cfg;
        
    end case;
    
  end process cfg_mux;

  assert not_my_addr_from_readers /= "111" report "address mismatch on avalon!" severity error;

  avalon_cfg_writer_1 : entity work.avalon_cfg_writer
    generic map (
      n_chans_g    => n_chans_c,
      data_width_g => addr_width_c,
      conf_file_g  => conf_file_c)
    port map (
      clk                      => clk,
      rst_n                    => rst_n,
      start_in                 => start_to_cfg,
      avalon_cfg_addr_out      => avalon_cfg_addr_from_cfg,
      avalon_cfg_writedata_out => avalon_cfg_writedata_to_rx,
      avalon_cfg_we_out        => avalon_cfg_we_to_rx,
      avalon_cfg_cs_out        => avalon_cfg_cs_from_cfg,
      init_in                  => init_to_cfg,
      done_out                 => done_from_cfg
      );
-- different clock...
  avalon_cfg_reader_1 : entity work.avalon_cfg_reader
    generic map (
      n_chans_g    => n_chans_c,
      data_width_g => addr_width_c,
      conf_file_g  => conf_file_c)
    port map (
      clk                    => clk2,
      rst_n                  => rst_n,
      start_in               => start_to_cfg_reader,
      avalon_cfg_addr_out    => avalon_cfg_addr_from_cfg_reader,
      avalon_cfg_readdata_in => avalon_cfg_readdata_from_rx,
      avalon_cfg_re_out      => avalon_cfg_re_to_rx,
      avalon_cfg_cs_out      => avalon_cfg_cs_from_cfg_reader,
      done_out               => done_from_cfg_reader
      );

  hibi_sender_n2h2_1 : entity work.hibi_sender_n2h2
    generic map (
      data_1_g     => data_file_c,
      conf_file_g  => conf_file_hsender_c,
      own_number_g => 4,
      comm_width_g => comm_width_c,
      data_width_g => data_width_c
      )
    port map (
      clk             => clk,
      rst_n           => hibi_sender_rst_n,
      pause_in        => pause_hibi_send,
      pause_ack       => pause_ack_hibi_send,
      done_out        => done_from_hibi_sender,
      agent_empty_out => hibi_empty_to_rx,
      agent_re_in     => hibi_re_from_rx,
      agent_comm_out  => hibi_comm_to_rx,
      agent_data_out  => hibi_data_to_rx,
      agent_av_out    => hibi_av_to_rx
      );

  hibi_data_read      <= hibi_empty_to_rx nor hibi_av_to_rx;
  avalon_reader_rst_n <= rst_n;
  avalon : for i in n_chans_c-1 downto 0 generate
    my_own_addr_c(i) <= conv_std_logic_vector(ava_addresses_c(i), data_width_c);

    avalon_reader_i : entity work.avalon_reader
      generic map (
        data_file_g  => data_file_c,
        addr_width_g => addr_width_c,
        data_width_g => data_width_c
        )
      port map (
        clk                    => clk,
        rst_n                  => avalon_reader_rst_n,
        avalon_we_in           => avalon_we_from_rx,
        avalon_be_in           => avalon_be_from_rx,
        increment_data_ptr     => hibi_data_read,
        waitrequest_real_in    => avalon_waitrequest_to_rx,
        avalon_writedata_in    => avalon_writedata_from_rx,
        avalon_addr_in         => avalon_addr_from_rx,
        avalon_waitrequest_out => avalon_waitreqvec_to_rx(i),
        my_own_addr_in         => my_own_addr_c(i),
        not_my_addr_out        => not_my_addr_from_readers(i),
        init_in                => pause_hibi_send
        );
  end generate avalon;



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



end tb;

-------------------------------------------------------------------------------
