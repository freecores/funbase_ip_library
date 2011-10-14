------------------------------------------------------------
-- Project : Engine
-- Author : Ari Kulmala
-- e-mail : ari.kulmala@tut.fi
-- Date : 7.7.2004
-- File : tb_n2h_tx.vhdl
-- Design : testbench for nios to hibi transmitter
-- Try with N2H2 TX 
------------------------------------------------------------
-- Description : a testbench for n2h_tx individual testing.
-- synchronous.
------------------------------------------------------------
-- $Log$
-- Revision 1.1  2005/04/14 06:45:55  kulmala3
-- First version to CVS
--
-- 31.08.04 AK Streaming
-- 05.01.04 AK Interface signals naming changed.
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity tb_n2h2_tx is

end tb_n2h2_tx;

architecture rtl of tb_n2h2_tx is
  constant PERIOD : time := 50 ns;

  constant data_width_g   : integer := 32;
  constant amount_width_g : integer := 9;
  constant addr_width_g   : integer := 32;
  constant addr_offset_c  : integer := (data_width_g)/8;

  constant comm_write     : std_logic_vector(4 downto 0) := "00010";
  constant comm_idle      : std_logic_vector(4 downto 0) := "00000";
  constant comm_write_msg : std_logic_vector(4 downto 0) := "00011";

  constant data_start      : integer := 0;
  constant wait_req_freq_c : integer := 10;


  type test_states is (test1, test2, test3, stop_tests);
  signal test_control      : test_states      := test1;
  type test_case_states is (assign, trigger, monitor, finish);
  signal test_case_control : test_case_states := trigger;

  signal clk   : std_logic;
  signal clk2  : std_logic;
  signal rst_n : std_logic;


  -- signals from n2h_tx
  signal tx_status_from_n2h_tx : std_logic := '0';
  signal tx_busy_from_n2h_tx   : std_logic;

  -- signals to n2h_tx
  signal internal_wait_to_n2h_tx        : std_logic := '0';
  signal tx_irq_to_n2h_tx               : std_logic;
  signal Amount_to_n2h_tx               : integer   := 0;
  signal Amount_vec_to_n2h_tx           : std_logic_vector(amount_width_g-1 downto 0);
  signal dpram_vec_addr_to_n2h_tx       : std_logic_vector(addr_width_g-1 downto 0);
  signal dpram_addr_to_n2h_tx           : integer   := 0;
  signal comm_to_n2h_tx                 : std_logic_vector(4 downto 0);
  --hibi
  signal hibi_data_vec_from_n2h_tx      : std_logic_vector(data_width_g-1 downto 0);
  signal hibi_data_from_n2h_tx          : integer   := 0;
  signal hibi_av_from_n2h_tx            : std_logic := '0';
  signal hibi_full_to_n2h_tx            : std_logic := '1';
  signal hibi_comm_from_n2h_tx          : std_logic_vector(4 downto 0);
  signal hibi_we_from_n2h_tx            : std_logic;
  -- avalon
  signal avalon_addr_from_n2h_tx        : std_logic_vector(addr_width_g-1 downto 0);
  signal avalon_read_from_n2h_tx        : std_logic;
  signal avalon_vec_readdata_to_n2h_tx  : std_logic_vector(data_width_g-1 downto 0);
  signal avalon_readdata_to_n2h_tx      : integer   := 0;
  signal avalon_waitrequest_to_n2h_tx   : std_logic;
  signal avalon_readdatavalid_to_n2h_tx : std_logic;
  -- others
  signal counter                        : integer   := 0;  -- temp counter, no special func
  signal new_hibi_addr                  : integer   := 0;
  signal new_amount                     : integer   := 0;
  signal new_dpram_addr                 : integer   := 0;

  -- which address hibi should get next
  signal global_hibi_address : integer := 0;
  -- global number of data in next packet
  signal global_amount       : integer := 0;
  signal global_comm         : std_logic_vector(4 downto 0);
  signal global_dpram_addr   : integer := 0;  -- given dpram addr

  -- check avalon signals
  signal avalon_data_counter : integer   := data_start;  -- data sent
  signal avalon_addr_counter : integer   := 0;  -- avalon addr right?
  signal avalon_amount       : integer   := 0;  -- how many data
  signal avalon_addr_sent    : std_logic := '0';  -- if already gave address
  signal avalon_last_addr    : integer   := 0;  -- store the old addr
--  signal avalon_gave_data    : std_logic := 0;  -- avalon timing
--  signal avalon_ok           : std_logic := '0';  -- all the avalon data ok

  -- check hibi signals
  signal hibi_addr_came    : std_logic := '0';
  signal hibi_data_counter : integer   := data_start;  -- data received
  signal hibi_addr         : integer   := 0;  -- right hibi addr
  signal hibi_amount       : integer   := 0;  -- how many datas hibi has received
--  signal hibi_ok           : std_logic := '0';  --hibi received all ok.
begin  -- rtl

  hibi_data_from_n2h_tx         <= conv_integer(hibi_data_vec_from_n2h_tx);
  Amount_vec_to_n2h_tx          <= conv_std_logic_vector(Amount_to_n2h_tx, amount_width_g);
  dpram_vec_addr_to_n2h_tx      <=
    conv_std_logic_vector(dpram_addr_to_n2h_tx, addr_width_g);
  avalon_vec_readdata_to_n2h_tx <=
    conv_std_logic_vector(avalon_readdata_to_n2h_tx, data_width_g);


  n2h2_tx_1 : entity work.n2h2_tx
    generic map (
      data_width_g          => data_width_g,
      amount_width_g        => amount_width_g)
    port map (
      clk                   => clk,
      rst_n                 => rst_n,
      
      -- Avalon master read interface
      avalon_addr_out       => avalon_addr_from_n2h_tx,
      avalon_re_out         => avalon_read_from_n2h_tx,
      avalon_readdata_in    => avalon_vec_readdata_to_n2h_tx,
      avalon_waitrequest_in => avalon_waitrequest_to_n2h_tx,
      avalon_readdatavalid_in => avalon_readdatavalid_to_n2h_tx,  -- ES 2010/05/07
      
      -- hibi write interface
      hibi_data_out         => hibi_data_vec_from_n2h_tx,
      hibi_av_out           => hibi_av_from_n2h_tx,
      hibi_full_in          => hibi_full_to_n2h_tx,
      hibi_comm_out         => hibi_comm_from_n2h_tx,
      hibi_we_out           => hibi_we_from_n2h_tx,

      -- DMA conf interface
      tx_start_in        => tx_irq_to_n2h_tx,
      tx_status_done_out => tx_status_from_n2h_tx,
      tx_comm_in         => comm_to_n2h_tx,
      tx_hibi_addr_in    => (others => '0'),
      tx_ram_addr_in     => dpram_vec_addr_to_n2h_tx,
      tx_amount_in       => Amount_vec_to_n2h_tx
      );


  
-- tx : n2h_tx
-- generic map (
-- data_width_g => data_width_g,
-- amount_width_g => amount_width_g,
-- addr_width_g => addr_width_g
-- )

-- port map (
-- clk => clk,
-- rst_n => rst_n,
-- tx_busy_out => tx_busy_from_n2h_tx,
-- comm_in => comm_to_n2h_tx,
-- Amount_in => Amount_vec_to_n2h_tx,
-- dpram_addr_in => dpram_vec_addr_to_n2h_tx,
-- tx_irq_in => tx_irq_to_n2h_tx,
-- tx_status_out => tx_status_from_n2h_tx,
-- avalon_addr_out => avalon_addr_from_n2h_tx,
-- avalon_re_out => avalon_read_from_n2h_tx,
-- avalon_readdata_in => avalon_vec_readdata_to_n2h_tx,
-- avalon_readdatavalid_in => avalon_readdatavalid_to_n2h_tx,
-- avalon_waitrequest_in => avalon_waitrequest_to_n2h_tx,
-- internal_wait_in => internal_wait_to_n2h_tx,
-- hibi_data_out => hibi_data_vec_from_n2h_tx,
-- hibi_comm_out => hibi_comm_from_n2h_tx,
-- hibi_av_out => hibi_av_from_n2h_tx,
-- hibi_we_out => hibi_we_from_n2h_tx,
-- hibi_full_in => hibi_full_to_n2h_tx
-- );

  -- check_avalon and check_hibi continuously monitor avalon and hibi
  -- buses. the tests doesn't have to check whether the data came right,
  -- those do it automatically. that's because the sent data is implemented
  -- as a counter, so that the incoming data should be in order.
  -- if theres too much data read from avalon, hibi gets wrong packets
  -- and informs.
  -- if theres too much/few data sent to hibi, hibi informs.


  -- test is the main process that is implented as a state machine
  -- (test1, test2 ... etc) so that new tests can be easily implemented
  test : process (clk, rst_n)
  begin  -- process test
    if rst_n = '0' then                 -- asynchronous reset (active low)
      test_control      <= test2;
      test_case_control <= assign;

    elsif clk'event and clk = '1' then  -- rising clock edge
      case test_control is

        -----------------------------------------------------------------------
        -- tests is controlled by following signals, which must be set
        --       global_hibi_address 
        --       global_amount
        --       global_comm

        -- TEST 1 IS OBSOLETE
        --
        -----------------------------------------------------------------------
        when test1       =>
          -- basic test. tests action under hibi_full signal
          -- and how one packet is transferred.
          case test_case_control is
            when trigger =>
              -- assign and trigger irq.


              if tx_status_from_n2h_tx = '1' then
                global_amount        <= 4;
                Amount_to_n2h_tx     <= 4;
                global_hibi_address  <= 230;
                global_comm          <= comm_write;
                comm_to_n2h_tx       <= comm_write;
                tx_irq_to_n2h_tx     <= '1';
                dpram_addr_to_n2h_tx <= 8;
                global_dpram_addr    <= 8;
                test_case_control    <= monitor;
                -- assert hibi full signal
                hibi_full_to_n2h_tx  <= '1';

              else
                assert false report "cannot start test, tx_status low" severity note;
              end if;
            when monitor =>
              tx_irq_to_n2h_tx <= '0';

              counter               <= counter+1;
              if counter < 10 then
                test_case_control   <= monitor;
              else
                hibi_full_to_n2h_tx <= '0';
                test_case_control   <= finish;
              end if;

-- if tx_status_from_n2h_tx = '1' then
--  -- values read.
--                Amount_to_n2h_tx     <= 0;
--                dpram_addr_to_n2h_tx <= 0;
--                comm_to_n2h_tx       <= comm_idle;
--                -- lets test the full signal
--              end if;

            when finish =>
              if tx_status_from_n2h_tx = '1' then
                assert false report "test1 finished." severity note;
                test_control      <= test2;
                test_case_control <= assign;
                counter           <= 0;
              else
                test_case_control <= finish;
              end if;


            when others => null;
          end case;
        when test2      =>
          -- tests how multiple packets are transferred and
          -- how max values are treated.

          case test_case_control is
            when assign =>
              -- we always go to trigger next, unless otherwise noted.
              test_case_control   <= trigger;
              -- assign new values
              if counter = 0 then
                new_amount        <= 6;
                new_hibi_addr     <= 6302;
                new_dpram_addr    <= 400;
              elsif counter = 1 then
                new_amount        <= 172;
                new_hibi_addr     <= 30;
                new_dpram_addr    <= 300;
              elsif counter = 2 then
                new_amount        <= 1;
                new_hibi_addr     <= 21;
                new_dpram_addr    <= 323;
              elsif counter = 3 then
                new_amount        <= 14;
                new_hibi_addr     <= 54;
                new_dpram_addr    <= 12;
              elsif counter = 4 then
                new_amount        <= 6;
                new_hibi_addr     <= 602;
                new_dpram_addr    <= 40;
              elsif counter = 5 then
                new_amount        <= 9;
                new_hibi_addr     <= 64510;
                new_dpram_addr    <= 511;
              else
                --stop the tests
                test_control      <= stop_tests;
                test_case_control <= assign;
              end if;

              counter <= counter+1;

            when trigger =>
              -- assign and trigger irq.

              if tx_status_from_n2h_tx = '1' then
                global_amount        <= new_amount;
                Amount_to_n2h_tx     <= new_amount;
                global_hibi_address  <= new_hibi_addr;
                global_comm          <= comm_write;
                comm_to_n2h_tx       <= comm_write;
                tx_irq_to_n2h_tx     <= '1';
                dpram_addr_to_n2h_tx <= new_dpram_addr;
                global_dpram_addr    <= new_dpram_addr;
                test_case_control    <= monitor;
                -- deassert hibi full signal, just in case
                hibi_full_to_n2h_tx  <= '0';

              else
                assert false report "cannot start test, tx_status low" severity note;
              end if;

            when monitor =>
              tx_irq_to_n2h_tx  <= '0';
-- if tx_status_from_n2h_tx = '1' then
--  -- values read.
--                Amount_to_n2h_tx     <= 0;
--                dpram_addr_to_n2h_tx <= 0;
--                comm_to_n2h_tx       <= comm_idle;
              -- lets test the full signal
              test_case_control <= finish;
-- end if;

            when finish =>
              if tx_status_from_n2h_tx = '1' then
                assert false report "test2 finished." severity note;
                test_case_control <= assign;
              else
                test_case_control <= finish;
              end if;


            when others => null;
          end case;
        when test3      =>
        when stop_tests =>
          assert false report "all tests finished." severity failure;
        when others     => null;
      end case;
    end if;
  end process test;

  -- checks whether incoming data to hibi is right
  check_hibi : process (clk)
  begin  -- process check_hibi
    if clk = '1' and clk'event then
      if hibi_amount = 0 then
        hibi_addr_came <= '0';
      end if;

      assert hibi_amount >= 0 report "hibi amount negative - too much data" severity warning;

      if hibi_we_from_n2h_tx = '1' then

        if hibi_comm_from_n2h_tx /= global_comm then
          assert false report "hibi command failure - not as expected" severity warning;
        end if;

        -- if address valid comes before we have received all the data
        -- we expected, thats wrong
        if hibi_av_from_n2h_tx = '1' then
          if hibi_amount = 0 then
            if hibi_data_from_n2h_tx = global_hibi_address then
              hibi_addr_came <= '1';
              hibi_amount    <= global_amount;
            else
              assert false report "hibi address wasn't expected" severity warning;
            end if;

          else
            assert false report "Hibi data failure, address came but shouldn't have" severity warning;
          end if;

        else
          -- if address has been received
          if hibi_addr_came = '1' then
            -- and the data is right
            if hibi_data_from_n2h_tx = hibi_data_counter then
              hibi_data_counter <= hibi_data_counter+1;
              hibi_amount       <= hibi_amount-1;
              if hibi_amount = 1 then
                hibi_addr_came  <= '0';
              end if;
            else
              assert false report "hibi data was wrong" severity warning;
            end if;

          else
            assert false report "data came before an address" severity warning;
          end if;
        end if;

      end if;
    end if;

  end process check_hibi;

  check_avalon             : process (clk2)
    variable waitreq_cnt_r : integer := 0;
  begin  -- process check_avalon
    if clk2'event and clk2 = '1' then   -- rising clock edge


      avalon_last_addr <= conv_integer(avalon_addr_from_n2h_tx);

      assert avalon_amount >= 0 report "avalon amount negative - tried to read too much data" severity warning;

      if avalon_read_from_n2h_tx = '1' and avalon_waitrequest_to_n2h_tx = '0' then  --and
--        avalon_readdatavalid_to_n2h_tx = '1' then
--        avalon_readdatavalid_to_n2h_tx <= '1';
        if (global_dpram_addr + avalon_addr_counter) /=
          avalon_addr_from_n2h_tx then
          assert false report "address to avalon is wrong" severity warning;
        else
          if (global_dpram_addr + avalon_addr_counter) = (2**addr_width_g-2) then
            avalon_addr_counter <= 0 - global_dpram_addr;
          elsif (global_dpram_addr + avalon_addr_counter) = (2**addr_width_g-1) then
            -- odd number (eg. 511) overflow, add one.
            avalon_addr_counter <= 1 - global_dpram_addr;
          else
            avalon_addr_counter <= avalon_addr_counter + addr_offset_c;
          end if;
        end if;

        --avalon_waitrequest_to_n2h_tx <= '0';
        avalon_readdatavalid_to_n2h_tx <= '1';
        if avalon_addr_sent = '0' then
          -- first slot contains address
          avalon_readdata_to_n2h_tx    <= global_hibi_address;
          avalon_addr_sent             <= '1';
          avalon_amount                <= global_amount;
        else
          -- now the data
          if avalon_last_addr = avalon_addr_from_n2h_tx then
            avalon_readdata_to_n2h_tx  <= avalon_data_counter;
            avalon_data_counter        <= avalon_data_counter;
            avalon_amount              <= avalon_amount;
          else
            avalon_readdata_to_n2h_tx  <= avalon_data_counter;
            avalon_data_counter        <= avalon_data_counter+1;
            avalon_amount              <= avalon_amount-1;
          end if;
          if avalon_amount = 1 then
            -- next we expect that a new packet should be sent.
            avalon_addr_sent           <= '0';
            avalon_addr_counter        <= 0;
          end if;
        end if;
-- elsif avalon_read_from_n2h_tx = '1' and avalon_readdatavalid_to_n2h_tx = '0' then
-- avalon_readdatavalid_to_n2h_tx <= '1';
-- avalon_waitrequest_to_n2h_tx <= '0';
      else

-- avalon_readdata_to_n2h_tx <= 0;
        --avalon_waitrequest_to_n2h_tx <= '1';
--        avalon_readdatavalid_to_n2h_tx <= '0';
      end if;
      avalon_waitrequest_to_n2h_tx   <= '0';  -- was always
      waitreq_cnt_r   := waitreq_cnt_r +1;
      -- generate waitreq
      if waitreq_cnt_r = wait_req_freq_c then
        avalon_waitrequest_to_n2h_tx <= '1';
        waitreq_cnt_r := 0;
      end if;


    end if;
  end process check_avalon;

  CLOCK1            : process           -- generate clock signal for design
    variable clktmp : std_logic := '0';
  begin
    wait for PERIOD/2;
    clktmp                      := not clktmp;
    Clk <= clktmp;
  end process CLOCK1;

  -- different phase for the avalon bus
  CLOCK2             : process          -- generate clock signal for design
    variable clk2tmp : std_logic := '0';
  begin
    clk2tmp                      := not clk2tmp;
    Clk2 <= clk2tmp;
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
