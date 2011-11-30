-------------------------------------------------------------------------------
-- Title      : Testbench for udp2hibi toplevel
-- Project    : UDP2HIBI
-------------------------------------------------------------------------------
-- File       : tb_udp2hibi.vhd
-- Author     : Jussi Nieminen
-- Last update: 2010/01/08
-- Platform   : Sim only
-------------------------------------------------------------------------------
-- Description: see the title
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2009/12/15  1.0      niemin95        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.udp2hibi_pkg.all;

entity tb_udp2hibi is
end tb_udp2hibi;


architecture tb of tb_udp2hibi is

  constant frequency_c     : integer   := 50000000;
  constant period_c        : time      := 20 ns;
  constant udp_ip_period_c : time      := 40 ns;
  signal   clk             : std_logic := '1';
  signal   clk_udp         : std_logic := '1';
  signal   rst_n           : std_logic := '0';

  constant hibi_comm_width_c : integer := 3;
  constant hibi_data_width_c : integer := 32;
  constant hibi_addr_width_c : integer := 32;

  constant receiver_table_size_c : integer := 4;
  constant tx_multiclk_fifo_depth_c : integer := 10;
  constant rx_multiclk_fifo_depth_c : integer := 10;
  constant hibi_tx_fifo_depth_c : integer := 10;
  constant ack_fifo_depth_c : integer := 4;


  -- ** to/from HIBI **
  -- receiver
  signal hibi_comm_to_duv       : std_logic_vector( hibi_comm_width_c-1 downto 0 ) := (others => '0');
  signal hibi_data_to_duv       : std_logic_vector( hibi_data_width_c-1 downto 0 ) := (others => '0');
  signal hibi_av_to_duv         : std_logic := '0';
  signal hibi_empty_to_duv      : std_logic := '1';
  signal hibi_re_from_duv       : std_logic;
  -- sender
  signal hibi_comm_from_duv     : std_logic_vector( hibi_comm_width_c-1 downto 0 );
  signal hibi_data_from_duv     : std_logic_vector( hibi_data_width_c-1 downto 0 );
  signal hibi_av_from_duv       : std_logic;
  signal hibi_we_from_duv       : std_logic;
  signal hibi_full_to_duv       : std_logic := '0';
  -- ** to/from UDP/IP **
  -- tx
  signal tx_data_from_duv       : std_logic_vector( udp_block_data_w_c-1 downto 0 );
  signal tx_data_valid_from_duv : std_logic;
  signal tx_re_to_duv           : std_logic := '0';
  signal new_tx_from_duv        : std_logic;
  signal tx_len_from_duv        : std_logic_vector( tx_len_w_c-1 downto 0 );
  signal dest_ip_from_duv       : std_logic_vector( ip_addr_w_c-1 downto 0 );
  signal dest_port_from_duv     : std_logic_vector( udp_port_w_c-1 downto 0 );
  signal source_port_from_duv   : std_logic_vector( udp_port_w_c-1 downto 0 );
  -- rx
  signal rx_data_to_duv         : std_logic_vector( udp_block_data_w_c-1 downto 0 ) := (others => '0');
  signal rx_data_valid_to_duv   : std_logic := '0';
  signal rx_re_from_duv         : std_logic;
  signal new_rx_to_duv          : std_logic := '0';
  signal rx_len_to_duv          : std_logic_vector( tx_len_w_c-1 downto 0 ) := (others => '0');
  signal source_ip_to_duv       : std_logic_vector( ip_addr_w_c-1 downto 0 ) := (others => '0');
  signal dest_port_to_duv       : std_logic_vector( udp_port_w_c-1 downto 0 ) := (others => '0');
  signal source_port_to_duv     : std_logic_vector( udp_port_w_c-1 downto 0 ) := (others => '0');
  signal rx_erroneous_to_duv    : std_logic := '0';


  signal udp_traffic_ready : std_logic := '0';

  -- *** test transfers ***
  -----------------------------------------------------------------------------
  -- test data

  type tx_data_type is array (integer range <>) of std_logic_vector( hibi_data_width_c-1 downto 0 );
  type tx_info_type is
    record
      addr  : std_logic_vector( hibi_addr_width_c-1 downto 0 );
      len   : integer;
      data_16bit_len : integer;
      delay : time;
      data  : tx_data_type(0 to 28);
  end record;
  signal current_tx : integer := 0;

  -----------------------------------------------------------------------------
  -- change these values, and array range of tx_info_type's data item to create
  -- new test traffic
  
  constant num_of_txs_c : integer := 6;
  type test_txs_type is array (0 to num_of_txs_c-1) of tx_info_type;

  type test_data_type is array (0 to 5) of std_logic_vector( 15 downto 0 );
  constant data1_c : test_data_type :=
    (x"0100", x"0302", x"0504", x"0706", x"0908", x"0a0b");

  constant test_txs_c : test_txs_type := (
    -- 0: tx_conf, this should get regs locked
    ( addr => x"01234567", len => 4, data_16bit_len => 0, delay => 1 us,
      data => (x"00001234", x"acdcabba", x"0101aaaa", x"0082faac", others => (others => '0') )),
    -- 1: an rx_conf
    ( addr => x"fedcba98", len => 4, data_16bit_len => 0, delay => 1 us,
      data => (x"30000000", x"12345678", x"32322323", x"0080abba", others => (others => '0'))),
    -- 1: another rx_conf
    ( addr => x"fedcba98", len => 4, data_16bit_len => 0, delay => 1 us,
      data => (x"30000000", x"23456789", x"43433434", x"0080beba", others => (others => '0'))),
    -- 3: start a tx by correct addr (107 bytes)
    ( addr => x"01234567", len => 28, data_16bit_len => 54, delay => 1 us,
      data => (x"1" & "00001101011" & "00000000000000000",
               data1_c(1) & data1_c(0),  -- 1
               data1_c(3) & data1_c(2),
               data1_c(5) & data1_c(4),
               data1_c(1) & data1_c(0),
               data1_c(3) & data1_c(2),
               data1_c(5) & data1_c(4),
               data1_c(1) & data1_c(0),
               data1_c(3) & data1_c(2),
               data1_c(5) & data1_c(4),
               data1_c(1) & data1_c(0),  -- 10
               data1_c(3) & data1_c(2),
               data1_c(5) & data1_c(4),
               data1_c(1) & data1_c(0),
               data1_c(3) & data1_c(2),
               data1_c(5) & data1_c(4),
               data1_c(1) & data1_c(0),
               data1_c(3) & data1_c(2),
               data1_c(5) & data1_c(4),
               data1_c(1) & data1_c(0),
               data1_c(3) & data1_c(2),  -- 20
               data1_c(5) & data1_c(4),
               data1_c(1) & data1_c(0),
               data1_c(3) & data1_c(2),
               data1_c(5) & data1_c(4),
               data1_c(1) & data1_c(0),
               data1_c(3) & data1_c(2),
               data1_c(5) & data1_c(4),  -- 27
               others => (others => '0') )),
    -- 4: start another small tx by correct addr (12 bytes)
    ( addr => x"01234567", len => 4, data_16bit_len => 6, delay => 1 us,
      data => (x"1" & "00000001100" & "00000000000000000",
               data1_c(1) & data1_c(0),
               data1_c(3) & data1_c(2),
               data1_c(5) & data1_c(4), others => (others => '0') )),
    -- 5: release
    ( addr => x"01234567", len => 1, data_16bit_len => 0, delay => 1 us,
      data => (x"20000000", others => (others => '0') ))
    );


  -----------------------------------------------------------------------------
  -- ** incoming transfers **

  constant test_rx_data_amount_c : integer := 16;
  type test_rx_data_type is array (0 to test_rx_data_amount_c-1) of std_logic_vector( udp_block_data_w_c-1 downto 0 );
  constant test_rx_data : test_rx_data_type :=
    ( x"0100", x"0302", x"0504", x"0706", x"0908", x"0b0a", x"0d0c", x"0f0e",
      x"1110", x"1312", x"1514", x"1716", x"1918", x"1b1a", x"1d1c", x"1f1e" );

  type test_rxs_type is
    record
      source_ip         : std_logic_vector( ip_addr_w_c-1 downto 0 );
      source_port       : std_logic_vector( udp_port_w_c-1 downto 0 );
      dest_port         : std_logic_vector( udp_port_w_c-1 downto 0 );
      rx_len            : integer;
      rx_erroneous      : std_logic;
      delay_before_next : time;
    end record;

  constant num_of_rx_tests_c : integer := 5;
  type test_rxs_array is array (0 to num_of_rx_tests_c-1) of test_rxs_type;

  -- test cases:
  -- 1. Normal (not erroneus, rx address valid) 200 bytes long packet
  -- 2. Packet without an receiver (should be dumped)
  -- 3. Erroneous packet (should also be dumped)
  -- 4. Very short (1 byte) transfer with minimal delay
  -- 5. just something following the earlier short one
  constant test_rxs : test_rxs_array :=
    (( source_ip         => x"01234567",
       source_port       => x"1212",
       dest_port         => x"2121",
       rx_len            => 50,
       rx_erroneous      => '0',
       delay_before_next => 100 * udp_ip_period_c ),
     ( source_ip         => x"12345678",
       source_port       => x"2323",
       dest_port         => x"3232",
       rx_len            => 20,
       rx_erroneous      => '1',
       delay_before_next => 20 * udp_ip_period_c ),
     ( source_ip         => x"23456789",
       source_port       => x"3434",
       dest_port         => x"4343",
       rx_len            => 30,
       rx_erroneous      => '0',
       delay_before_next => 20 * udp_ip_period_c ),
     ( source_ip         => x"3456789a",
       source_port       => x"4545",
       dest_port         => x"5454",
       rx_len            => 1,
       rx_erroneous      => '0',
       delay_before_next => udp_ip_period_c ),
     ( source_ip         => x"456789ab",
       source_port       => x"5656",
       dest_port         => x"6565",
       rx_len            => 20,
       rx_erroneous      => '0',
       delay_before_next => 20 * udp_ip_period_c )
     );
  
  signal hibi_re : std_logic;

-------------------------------------------------------------------------------
begin  -- tb
-------------------------------------------------------------------------------


  duv : entity work.udp2hibi
    generic map (
      receiver_table_size_g      => receiver_table_size_c,
      ack_fifo_depth_g           => ack_fifo_depth_c,
      tx_multiclk_fifo_depth_g   => tx_multiclk_fifo_depth_c,
      rx_multiclk_fifo_depth_g   => rx_multiclk_fifo_depth_c,
      hibi_tx_fifo_depth_g       => hibi_tx_fifo_depth_c,
      hibi_data_width_g          => hibi_data_width_c,
      hibi_addr_width_g          => hibi_addr_width_c,
      hibi_comm_width_g          => hibi_comm_width_c,
      frequency_g                => frequency_c
      )
    port map (
      clk                   => clk,
      clk_udp               => clk_udp,
      rst_n                 => rst_n,
      hibi_comm_in          => hibi_comm_to_duv,
      hibi_data_in          => hibi_data_to_duv,
      hibi_av_in            => hibi_av_to_duv,
      hibi_empty_in         => hibi_empty_to_duv,
      hibi_re_out           => hibi_re_from_duv,
      hibi_comm_out         => hibi_comm_from_duv,
      hibi_data_out         => hibi_data_from_duv,
      hibi_av_out           => hibi_av_from_duv,
      hibi_we_out           => hibi_we_from_duv,
      hibi_full_in          => hibi_full_to_duv,
      tx_data_out           => tx_data_from_duv,
      tx_data_valid_out     => tx_data_valid_from_duv,
      tx_re_in              => tx_re_to_duv,
      new_tx_out            => new_tx_from_duv,
      tx_len_out            => tx_len_from_duv,
      dest_ip_out           => dest_ip_from_duv,
      dest_port_out         => dest_port_from_duv,
      source_port_out       => source_port_from_duv,
      rx_data_in            => rx_data_to_duv,
      rx_data_valid_in      => rx_data_valid_to_duv,
      rx_re_out             => rx_re_from_duv,
      new_rx_in             => new_rx_to_duv,
      rx_len_in             => rx_len_to_duv,
      source_ip_in          => source_ip_to_duv,
      dest_port_in          => dest_port_to_duv,
      source_port_in        => source_port_to_duv,
      rx_erroneous_in       => rx_erroneous_to_duv,
      eth_link_up_in        => '1'
      );


  -- clk generation
  clk     <= not clk     after period_c/2;
  clk_udp <= not clk_udp after udp_ip_period_c/2;
  rst_n   <= '1'         after 4*period_c;

  stuupiid: postponed process (hibi_re_from_duv)
  begin
    hibi_re <= hibi_re_from_duv;
  end process stuupiid;

  -----------------------------------------------------------------------------
  hibi_traffic: process
  begin  -- process hibi_traffic

    if rst_n = '0' then
      wait until rst_n = '1';
    end if;

    wait for period_c*4;

    ---------------------------------------------------------------------------

    for n in 0 to num_of_txs_c-1 loop

      hibi_av_to_duv <= '1';
      hibi_empty_to_duv <= '0';
      hibi_data_to_duv <= test_txs_c(n).addr;
      wait for period_c;
      
      if hibi_re = '0' then
        wait until hibi_re = '1';
        wait for period_c;
      end if;
      
      hibi_av_to_duv <= '0';

      for k in 0 to test_txs_c(n).len-1 loop
        
        hibi_data_to_duv <= test_txs_c(n).data(k);

        wait for period_c;
        if hibi_re = '0' then
          wait until hibi_re = '1';
          wait for period_c;
        end if;
        
      end loop;  -- k

      hibi_empty_to_duv <= '1';

      wait for test_txs_c(n).delay;
      
    end loop;  -- n
    

    ---------------------------------------------------------------------------
    wait for period_c*50;

    if udp_traffic_ready = '0' then
      wait until udp_traffic_ready = '1';
    end if;
    
    report "Simulation ended, manual check required!." severity failure;
  end process hibi_traffic;
  -----------------------------------------------------------------------------





  
  -----------------------------------------------------------------------------
  udp_traffic: process
  begin  -- process udp_traffic

    if rst_n = '0' then
      wait until rst_n = '1';
    end if;

    wait for period_c*4;

    ---------------------------------------------------------------------------

    for n in 0 to num_of_rx_tests_c-1 loop

      new_rx_to_duv        <= '1';
      rx_len_to_duv        <= std_logic_vector( to_unsigned( test_rxs(n).rx_len, tx_len_w_c ));
      source_ip_to_duv     <= test_rxs(n).source_ip;
      source_port_to_duv   <= test_rxs(n).source_port;
      dest_port_to_duv     <= test_rxs(n).dest_port;
      rx_erroneous_to_duv  <= test_rxs(n).rx_erroneous;
      rx_data_to_duv       <= test_rx_data(0);
      rx_data_valid_to_duv <= '1';

      wait until rx_re_from_duv = '1';
      wait for udp_ip_period_c;

      new_rx_to_duv       <= '0';
      rx_len_to_duv       <= (others => 'Z');
      source_ip_to_duv    <= (others => 'Z');
      source_port_to_duv  <= (others => 'Z');
      dest_port_to_duv    <= (others => 'Z');
      rx_erroneous_to_duv <= 'Z';

      rx_data_valid_to_duv <= '0';
      wait for udp_ip_period_c;

      for k in 0 to (test_rxs(n).rx_len+1)/2 - 2 loop

        rx_data_valid_to_duv <= '1';
        rx_data_to_duv <= test_rx_data( (k + 1) mod test_rx_data_amount_c );
        
        if rx_re_from_duv = '0' then
          wait until rx_re_from_duv = '1';
        end if;
        wait for udp_ip_period_c;
        rx_data_valid_to_duv <= '0';
        wait for udp_ip_period_c;
        
      end loop;  -- k

      wait for test_rxs(n).delay_before_next;
      
    end loop;  -- n

    ---------------------------------------------------------------------------
    wait for period_c*50;

    udp_traffic_ready <= '1';
    wait;
    
  end process udp_traffic;
  -----------------------------------------------------------------------------






  
  -----------------------------------------------------------------------------
  -- read tx data, when it's available
  udp_ip_reader: process (clk_udp, rst_n)
    variable read_cnt : integer := 0;
    variable read_indx : integer;
  begin  -- process udp_ip_reader
    if rst_n = '0' then                 -- asynchronous reset (active low)
      tx_re_to_duv <= '0';
    elsif clk_udp'event and clk_udp = '1' then  -- rising clock edge

      if tx_data_valid_from_duv = '1' then
        tx_re_to_duv <= '1';
      end if;

      if tx_re_to_duv = '1' and tx_data_valid_from_duv = '1' then
        -- check that data correct?
        read_cnt := read_cnt + 1;
      end if;
    end if;
  end process udp_ip_reader;


end tb;
