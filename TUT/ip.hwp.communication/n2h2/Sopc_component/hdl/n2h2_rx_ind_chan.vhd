-------------------------------------------------------------------------------
-- Title      : Nios to HIBI version 2
-- Project    : 
-------------------------------------------------------------------------------
-- File       : n2h2_rx_channels.vhdl
-- Author     : kulmala3
-- Created    : 22.03.2005
-- Last update: 28.06.2005
-- Description: This version acts as a real dma.
--
-- THIS VERSION CONTAINS INDEPENDENT CHANNEL (DCT) AND A
-- TX TRANSFER BUFFER
--
-- Currently there's no double-registers in config - the user
-- must take care when configuring the device. (datas can go to
-- wrong address etc, if configured while still receiving data from
-- source)
--
-- Needs 2 clock cycles to propagate the IRQ (ack->irq down-> irq req)
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
--use work.txt_util.all;
--use work.log2_pkg.all;

entity n2h2_rx_channels is
  
  generic (
    -- generic values for @£$ stupid SOPC builder -crap...
    n_chans_g      : integer := 3;
    n_chans_bits_g : integer := 2;      -- how many bits to represet n_chans
    -- eg 2 for 4, 3 for 5, basically log2(n_chans_g)

    data_width_g       : integer := 1;
    hibi_addr_cmp_hi_g : integer := 1;  -- the highest bit used for comparing address
    hibi_addr_cmp_lo_g : integer := 1;  -- the lowest bit
    amount_width_g     : integer := 1);  -- in bits, maximum amount of data

  port (
    clk                   : in  std_logic;
    rst_n                 : in  std_logic;
    -- avalon master (rx) if
    avalon_addr_out       : out std_logic_vector(data_width_g-1 downto 0);
    avalon_we_out         : out std_logic;
    avalon_writedata_out  : out std_logic_vector(data_width_g-1 downto 0);
    avalon_waitrequest_in : in  std_logic;
    -- hibi if
    hibi_data_in          : in  std_logic_vector(data_width_g-1 downto 0);
    hibi_av_in            : in  std_logic;
    hibi_empty_in         : in  std_logic;
    hibi_comm_in          : in  std_logic_vector(2 downto 0);
    hibi_re_out           : out std_logic;

    --avalon slave if (config)
    --conf_bits_c bits for each channel
    avalon_cfg_addr_in      : in  std_logic_vector(n_chans_bits_g+4-1 downto 0);
    avalon_cfg_writedata_in : in  std_logic_vector(data_width_g-1 downto 0);
    avalon_cfg_we_in        : in  std_logic;
    avalon_cfg_readdata_out : out std_logic_vector(data_width_g-1 downto 0);
    avalon_cfg_re_in        : in  std_logic;
    avalon_cfg_cs_in        : in  std_logic;

    rx_irq_out : out std_logic;

    -- to/from tx
    tx_start_out      : out std_logic;
    tx_comm_out       : out std_logic_vector(2 downto 0);
    tx_mem_addr_out   : out std_logic_vector(data_width_g-1 downto 0);
    tx_hibi_addr_out  : out std_logic_vector(data_width_g-1 downto 0);
    tx_amount_out     : out std_logic_vector(amount_width_g-1 downto 0);
    tx_status_done_in : in  std_logic

    );

end n2h2_rx_channels;

architecture rtl of n2h2_rx_channels is

  -- NOTE!! Also have to change to interface!! avalon_cfg_addr_in !!!
  constant conf_bits_c     : integer := 4;  -- number of configuration bits in CPU
  -- side address
  constant control_bits_c  : integer := 2;  -- how many bits in ctrl reg
  constant status_bits_c   : integer := 2;  -- how many bits in ctrl reg
  constant addr_offset_c   : integer := data_width_g/8;
  constant dct_hibi_addr_r : integer := 16#1100#;


  type chan_data_array is array (n_chans_g-1 downto 0) of std_logic_vector(data_width_g-1 downto 0);
  type chan_amount_array is array (n_chans_g-1 downto 0) of std_logic_vector(amount_width_g-1 downto 0);

  -- registers the CPU will set
  signal mem_addr_r     : chan_data_array;
  signal sender_addr_r  : chan_data_array;
  signal irq_amount_r   : chan_amount_array;
  signal control_r      : std_logic_vector(control_bits_c-1 downto 0);
  signal tx_mem_addr_r  : std_logic_vector(data_width_g-1 downto 0);
  signal tx_hibi_addr_r : std_logic_vector(data_width_g-1 downto 0);
  signal tx_amount_r    : std_logic_vector(amount_width_g-1 downto 0);
  signal tx_comm_r      : std_logic_vector(2 downto 0);

  -- cpu sets, n2h clears
  signal init_chan_r : std_logic_vector(n_chans_g-1 downto 0);

  -- cpu clears, n2h sets
  signal irq_chan_r : std_logic_vector(n_chans_g-1 downto 0);

  -- cpu can read
  -- tells where the next data is stored
  signal current_mem_addr_r : chan_data_array;
  signal status_r           : std_logic_vector(status_bits_c-1 downto 0);


  -- counter of how many datas gotten (irq nullifies)
  signal irq_counter_r : chan_amount_array;
  signal irq_r         : std_logic;
  signal irq_given_r   : std_logic_vector(n_chans_g-1 downto 0);

  -- main process signals
--  type   main_ctrl_states is (idle, read_addr, read_data, wait_avalon);
--  signal main_ctrl_r : main_ctrl_states;
  signal hibi_re_r   : std_logic;
  signal avalon_we_r : std_logic;

  -- calc_chan signals
  signal avalon_addr_r         : std_logic_vector(data_width_g-1 downto 0);
  signal hibi_av_re_empty_r    : std_logic_vector(2 downto 0);
  signal curr_chan_avalon_we_r : std_logic;  -- 0 if no channel found

--  signal dirty_chan_r : std_logic_vector(n_chans_g-1 downto 0);
--  signal not_dirty_chan_we_r   : std_logic;
--  signal one_more_data_r : std_logic_vector(n_chans_g-1 downto 0);


  -- value n_chans_g means undefined
--  signal curr_chan_r : integer range n_chans_g downto 0;


  component n2h2_rx_chan
    generic (
      data_width_g   : integer;
      amount_width_g : integer;
      addr_cmp_lo_g  : integer;
      addr_cmp_hi_g  : integer);
    port (
      clk               : in  std_logic;
      rst_n             : in  std_logic;
      avalon_addr_in    : in  std_logic_vector(data_width_g-1 downto 0);
      hibi_addr_in      : in  std_logic_vector(data_width_g-1 downto 0);
      irq_amount_in     : in  std_logic_vector(amount_width_g-1 downto 0);
      hibi_data_in      : in  std_logic_vector(data_width_g-1 downto 0);
      hibi_av_in        : in  std_logic;
      hibi_empty_in     : in  std_logic;
      init_in           : in  std_logic;
      irq_ack_in        : in  std_logic;
      avalon_waitreq_in : in  std_logic;
      avalon_we_in      : in  std_logic;
      avalon_addr_out   : out std_logic_vector(data_width_g-1 downto 0);
      avalon_we_out     : out std_logic;
      addr_match_out    : out std_logic;
      irq_out           : out std_logic);
  end component;


--  signal irq_amount_r    : chan_amount_array;
  signal avalon_wes : std_logic_vector(n_chans_g-1 downto 0);
  signal matches    : std_logic_vector(n_chans_g-1 downto 0);
  signal irq_ack_r  : std_logic_vector(n_chans_g-1 downto 0);


  component n2h2_ind_chan
    generic (
      data_width_g   : integer;
      amount_width_g : integer;
      addr_cmp_lo_g  : integer;
      addr_cmp_hi_g  : integer;
      Tx_HIBI_addr_g : integer
      );
    port (
      clk             : in std_logic;
      rst_n           : in std_logic;
      avalon_addr_in  : in std_logic_vector(data_width_g-1 downto 0);
      hibi_data_in    : in std_logic_vector(data_width_g-1 downto 0);
      hibi_av_in      : in std_logic;
      hibi_empty_in   : in std_logic;
      hibi_addr_rx_in : in std_logic_vector(data_width_g-1 downto 0);

      init_in           : in  std_logic;
      tx_start_out      : out std_logic;
      tx_status_done_in : in  std_logic;
      tx_comm_out       : out std_logic_vector(2 downto 0);
      tx_hibi_addr_out  : out std_logic_vector(data_width_g-1 downto 0);
      tx_ram_addr_out   : out std_logic_vector(data_width_g-1 downto 0);
      tx_amount_out     : out std_logic_vector(amount_width_g-1 downto 0);
      tx_reserve_out    : out std_logic
      );
  end component;

  signal avalon_addr_to_dct    : std_logic_vector(data_width_g-1 downto 0);
  signal init_to_dct           : std_logic;
  signal hibi_addr_rx_to_dct   : std_logic_vector(data_width_g-1 downto 0);
  signal tx_start_from_dct     : std_logic;
  signal tx_status_done_to_dct : std_logic;
  signal tx_comm_from_dct      : std_logic_vector(2 downto 0);
  signal tx_hibi_addr_from_dct : std_logic_vector(data_width_g-1 downto 0);
  signal tx_ram_addr_from_dct  : std_logic_vector(data_width_g-1 downto 0);
  signal tx_amount_from_dct    : std_logic_vector(amount_width_g-1 downto 0);
  signal tx_reserve_from_dct   : std_logic;

  component one_hot_mux
    generic (
      data_width_g : integer);
    port (
      data_in  : in  std_logic_vector(data_width_g-1 downto 0);
      sel_in   : in  std_logic_vector(data_width_g-1 downto 0);
      data_out : out std_logic);
  end component;

  type chan_data_switched is array (data_width_g-1 downto 0) of std_logic_vector(n_chans_g-1 downto 0);

  signal avalon_addr_temp       : chan_data_switched;
  signal tx_req_cpu_when_busy_r : std_logic;
  signal was_not_high_r : std_logic;
  
begin  -- rtl
  avalon_we_r   <= hibi_empty_in nor hibi_av_in;
  avalon_we_out <= avalon_we_r and curr_chan_avalon_we_r;  -- and not_dirty_chan_we_r;

--  hibi_re_r <= (not avalon_waitrequest_in)  or hibi_av_in;
  hibi_re_r <= '1' and (not ((avalon_waitrequest_in) and (avalon_we_r and curr_chan_avalon_we_r)));  -- or hibi_av_in;

  hibi_re_out          <= hibi_re_r;
  avalon_writedata_out <= hibi_data_in;

  hibi_av_re_empty_r <= hibi_av_in & hibi_re_r & hibi_empty_in;

  avalon_addr_out <= avalon_addr_r;

  channels : for i in 0 to n_chans_g-1 generate
    
    n2h2_rx_chan_1 : n2h2_rx_chan
      generic map (
        data_width_g   => data_width_g,
        amount_width_g => amount_width_g,
        addr_cmp_lo_g  => hibi_addr_cmp_lo_g,
        addr_cmp_hi_g  => hibi_addr_cmp_hi_g)
      port map (
        clk               => clk,
        rst_n             => rst_n,
        avalon_addr_in    => mem_addr_r(i),
        hibi_addr_in      => sender_addr_r(i),
        irq_amount_in     => irq_amount_r(i),
        hibi_data_in      => hibi_data_in,
        hibi_av_in        => hibi_av_in,
        hibi_empty_in     => hibi_empty_in,
        init_in           => init_chan_r(i),
        irq_ack_in        => irq_ack_r(i),
        avalon_waitreq_in => avalon_waitrequest_in,
        avalon_we_in      => avalon_we_r,
        avalon_addr_out   => current_mem_addr_r(i),
        avalon_we_out     => avalon_wes(i),
        addr_match_out    => matches(i),
        irq_out           => irq_chan_r(i)
        );

  end generate channels;

  one_hot_mux_1 : one_hot_mux
    generic map (
      data_width_g => n_chans_g)
    port map (
      data_in  => avalon_wes,
      sel_in   => matches,
      data_out => curr_chan_avalon_we_r
      );

  ava_temp : for i in 0 to n_chans_g-1 generate
    j : for j in 0 to data_width_g-1 generate
      avalon_addr_temp(j)(i) <= current_mem_addr_r(i)(j);
    end generate j;
  end generate ava_temp;

  avalon_address : for i in 0 to data_width_g-1 generate
    one_hot_mux_addr_i : one_hot_mux
      generic map (
        data_width_g => n_chans_g)
      port map (
        data_in  => avalon_addr_temp(i),
        sel_in   => matches,
        data_out => avalon_addr_r(i)
        );

  end generate avalon_address;

  DCT_control : n2h2_ind_chan
    generic map (
      data_width_g   => data_width_g,
      amount_width_g => amount_width_g,
      addr_cmp_lo_g  => hibi_addr_cmp_lo_g,
      addr_cmp_hi_g  => hibi_addr_cmp_hi_g,
      Tx_HIBI_addr_g => dct_hibi_addr_r
      )
    port map (
      clk               => clk,
      rst_n             => rst_n,
      avalon_addr_in    => avalon_addr_to_dct,
      hibi_data_in      => hibi_data_in,
      hibi_av_in        => hibi_av_in,
      hibi_empty_in     => hibi_empty_in,
      hibi_addr_rx_in   => hibi_addr_rx_to_dct,
      init_in           => init_to_dct,
      tx_start_out      => tx_start_from_dct,
      tx_status_done_in => tx_status_done_to_dct,
      tx_comm_out       => tx_comm_from_dct,
      tx_hibi_addr_out  => tx_hibi_addr_from_dct,
      tx_ram_addr_out   => tx_ram_addr_from_dct,
      tx_amount_out     => tx_amount_from_dct,
      tx_reserve_out    => tx_reserve_from_dct
      );

  


  
  cpu_side : process (clk, rst_n)
    variable legal_write : std_logic;
    variable legal_read  : std_logic;
    variable n_chan      : integer range n_chans_g-1 downto 0;
    variable n_dest      : integer range (2**conf_bits_c)-1 downto 0;
  begin  -- process cpu
    if rst_n = '0' then                 -- asynchronous reset (active low)
      for i in n_chans_g-1 downto 0 loop
        mem_addr_r(i)    <= (others => '0');
        sender_addr_r(i) <= (others => '0');
        irq_amount_r(i)  <= (others => '1');
      end loop;  -- i
      avalon_cfg_readdata_out <= (others => '0');
      init_chan_r             <= (others => '0');
      control_r               <= (others => '0');
      -- status for only rx signals..
      status_r(0)             <= '0';
      tx_mem_addr_r           <= (others => '0');
      tx_comm_r               <= (others => '0');
      tx_amount_r             <= (others => '0');
      tx_hibi_addr_r <= (others => '0');
      rx_irq_out              <= '0';
      init_to_dct             <= '0';
      
    elsif clk'event and clk = '1' then  -- rising clock edge
      -- set the IRQ. may be changed below if some IRQ
      -- is cleared and others are pending.
      if irq_chan_r /= 0 then
        -- irq ena bit...
        rx_irq_out <= control_r(1);
      end if;

      init_to_dct <= '0';
      irq_ack_r   <= (others => '0');

      legal_write := avalon_cfg_cs_in and avalon_cfg_we_in;
      legal_read  := avalon_cfg_cs_in and avalon_cfg_re_in;
      n_chan      := conv_integer(avalon_cfg_addr_in(n_chans_bits_g+conf_bits_c-1 downto conf_bits_c));
      n_dest      := conv_integer(avalon_cfg_addr_in(conf_bits_c-1 downto 0));


      if legal_write = '1' then
        case n_dest is
          when 0 =>                     -- mem_addr
            mem_addr_r(n_chan) <= avalon_cfg_writedata_in;
          when 1 =>                     -- sender addr
            sender_addr_r(n_chan) <= avalon_cfg_writedata_in;
          when 2 =>                     -- irq_amount
            irq_amount_r(n_chan) <= avalon_cfg_writedata_in(amount_width_g-1 downto 0);
            -- 3 is unwritable, curr addr ptr
          when 4 =>                     -- control
            control_r <= avalon_cfg_writedata_in(control_bits_c-1 downto 0);
          when 5 =>                     -- init channel
            init_chan_r <= avalon_cfg_writedata_in(n_chans_g-1 downto 0);
          when 7 =>                     -- IRQ chan
            irq_ack_r  <= avalon_cfg_writedata_in(n_chans_g-1 downto 0);
            -- goes down so that generates an edge
            -- when many interrupts are pending.
            rx_irq_out <= '0';

            -- NOW TX SIGNALS
          when 8 =>
            tx_mem_addr_r <= avalon_cfg_writedata_in;
          when 9 =>
            tx_amount_r <= avalon_cfg_writedata_in(amount_width_g-1 downto 0);
          when 10 =>
            tx_comm_r <= avalon_cfg_writedata_in(2 downto 0);
          when 11 =>
            tx_hibi_addr_r <= avalon_cfg_writedata_in;

            -- NOW DCT
          when 13 =>
            init_to_dct <= '1';
          when 14 =>
            hibi_addr_rx_to_dct <= avalon_cfg_writedata_in;
          when 15 =>
            avalon_addr_to_dct <= avalon_cfg_writedata_in;
          when others =>


            -- do nothing

        end case;
      end if;

      if legal_read = '1' then
        case n_dest is
          when 0 =>                     -- mem_addr
            avalon_cfg_readdata_out <= mem_addr_r(n_chan);
          when 1 =>                     -- sender addr
            avalon_cfg_readdata_out <= sender_addr_r(n_chan);
          when 2 =>                     -- irq amount
            avalon_cfg_readdata_out(data_width_g-1 downto amount_width_g) <= (others => '0');
            avalon_cfg_readdata_out(amount_width_g-1 downto 0)            <= irq_amount_r(n_chan);
          when 3 =>                     -- current addr ptr
            avalon_cfg_readdata_out <= current_mem_addr_r(n_chan);
          when 4 =>                     -- control and status regs
            avalon_cfg_readdata_out(15 downto control_bits_c)   <= (others => '0');
            avalon_cfg_readdata_out(control_bits_c-1 downto 0)  <= control_r;
            avalon_cfg_readdata_out(31 downto status_bits_c+15) <= (others => '0');
            avalon_cfg_readdata_out(status_bits_c+15 downto 16) <= status_r;
          when 5 =>                     -- Init Channel
            avalon_cfg_readdata_out(data_width_g-1 downto n_chans_g) <= (others => '0');
            avalon_cfg_readdata_out(n_chans_g-1 downto 0)            <= init_chan_r;
            -- 6 is reserved
          when 7 =>                     -- IRQ chan
            avalon_cfg_readdata_out(data_width_g-1 downto n_chans_g) <= (others => '0');
            avalon_cfg_readdata_out(n_chans_g-1 downto 0)            <= irq_chan_r;
          when others =>
            -- do nothing;
        end case;
      end if;

      -- busy bit
      status_r(0) <= avalon_we_r;

      if init_chan_r /= conv_std_logic_vector(0, n_chans_g) then
        init_chan_r <= (others => '0');
      end if;

      
    end if;
  end process cpu_side;


-- tx signals
  -- done bit, start tx
  status_r(1)           <= tx_status_done_in;
  tx_status_done_to_dct <= tx_status_done_in;

  tx_start : process (clk, rst_n)
  begin  -- process sel_tx_start
    if rst_n = '0' then                 -- asynchronous reset (active low)
      was_not_high_r             <= '1';
      tx_req_cpu_when_busy_r <= '0';
      
    elsif clk'event and clk = '1' then  -- rising clock edge
      
      if tx_status_done_in = '0' and control_r(0) = '1' then --and was_not_high_r = '1' then
        tx_req_cpu_when_busy_r <= '1';
      end if;

      if tx_status_done_in  = '1' and tx_req_cpu_when_busy_r = '1' and tx_start_from_dct = '0' then
        tx_req_cpu_when_busy_r <= '0';
      end if;

--      tx_req_cpu_when_busy_r <= (d and c) or ((r and s) or ((r or s) and (d or c)));
      
      if control_r(0) = '1' and tx_status_done_in = '1' then
        if was_not_high_r = '1' then
          was_not_high_r   <= '1';
--          tx_start_out <= '1';
        else
          was_not_high_r   <= '0';
--          tx_start_out <= '0';
        end if;
      else
        was_not_high_r   <= '1';
--        tx_start_out <= '0';
      end if;

--      if tx_status_done_in = '1' then
--        if tx_reserve_from_dct = '1' then
--          tx_amount_out    <= tx_amount_from_dct;
--          tx_mem_addr_out  <= tx_ram_addr_from_dct;
--          tx_comm_out      <= tx_comm_from_dct;
--          tx_hibi_addr_out <= tx_hibi_addr_from_dct;
--          tx_start_out <= tx_start_from_dct;
--        else
--          tx_amount_out    <= tx_amount_r;
--          tx_mem_addr_out  <= tx_mem_addr_r;
--          tx_comm_out      <= tx_comm_r;
--          tx_hibi_addr_out <= tx_hibi_addr_r;
--          if tx_req_cpu_when_busy_r = '1' then
--            tx_start_out           <= '1';
--            tx_req_cpu_when_busy_r <= '0';
--          end if;
--        end if;
--      end if;



    end if;

  end process tx_start;

  tx_start_out <= tx_start_from_dct or ((control_r(0) or tx_req_cpu_when_busy_r) and (tx_status_done_in));
  
  asynch_tx: process (tx_start_from_dct, tx_amount_r, tx_mem_addr_r, tx_comm_r, tx_hibi_addr_r,
                        tx_amount_from_dct, tx_ram_addr_from_dct, tx_comm_from_dct, tx_hibi_addr_from_dct)
  begin  -- process asynch_tx_
        if tx_start_from_dct = '1' then
          tx_amount_out    <= tx_amount_from_dct;
          tx_mem_addr_out  <= tx_ram_addr_from_dct;
          tx_comm_out      <= tx_comm_from_dct;
          tx_hibi_addr_out <= tx_hibi_addr_from_dct;
        else
          tx_amount_out    <= tx_amount_r;
          tx_mem_addr_out  <= tx_mem_addr_r;
          tx_comm_out      <= tx_comm_r;
          tx_hibi_addr_out <= tx_hibi_addr_r;
        end if;
  end process asynch_tx;

  
end rtl;

