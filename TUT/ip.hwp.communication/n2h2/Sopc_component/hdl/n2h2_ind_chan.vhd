-------------------------------------------------------------------------------
-- Title      : N2H2 independent channel
-- Project    : 
-------------------------------------------------------------------------------
-- File       : n2h2_ind_chan.vhd
-- Author     : kulmala3
-- Created    : 20.06.2005
-- Last update: 28.06.2005
-- Description: An independent channel for N2H2. Sits on the RX side and can
-- respond to requests to compile-time constant HIBI address. sends data from
-- given address to the requesting block. HIBI address of the block is
-- compile-time constant currently. An example of the block is DCT.
-------------------------------------------------------------------------------
-- Copyright (c) 2005 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 20.06.2005  1.0      AK      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity n2h2_ind_chan is
  
  generic (
    data_width_g   : integer := 0;
    amount_width_g : integer := 0;
    addr_cmp_lo_g  : integer := 0;
    addr_cmp_hi_g  : integer := 0;
    Tx_HIBI_addr_g : integer := 0       -- where data is sent to
    );

  port (
    clk   : in std_logic;
    rst_n : in std_logic;

    avalon_addr_in : in std_logic_vector(data_width_g-1 downto 0);

    hibi_data_in    : in std_logic_vector(data_width_g-1 downto 0);
    hibi_av_in      : in std_logic;
    hibi_empty_in   : in std_logic;
    init_in         : in std_logic;
    -- keep still between transfers
    hibi_addr_rx_in : in std_logic_vector(data_width_g-1 downto 0);

    tx_start_out      : out std_logic;
    tx_status_done_in : in  std_logic;
    tx_comm_out       : out std_logic_vector(2 downto 0);
    tx_hibi_addr_out  : out std_logic_vector(data_width_g-1 downto 0);
    tx_ram_addr_out   : out std_logic_vector(data_width_g-1 downto 0);
    tx_amount_out     : out std_logic_vector(amount_width_g-1 downto 0);
    -- this never writes anything.
--    avalon_waitreq_in : in std_logic;
--    avalon_we_in      : in std_logic;
--    avalon_addr_out : out std_logic_vector(data_width_g-1 downto 0);
--    avalon_we_out   : out std_logic;
    tx_reserve_out    : out std_logic
    );

end n2h2_ind_chan;

architecture rtl of n2h2_ind_chan is
  constant dont_care_c   : std_logic := 'X';
  constant addr_offset_c : integer   := data_width_g/8;

  type control_state is (normal, wait_tx);

  signal ctrl_r : control_state;

  signal addr_match_r : std_logic;
  signal av_empty     : std_logic_vector(1 downto 0);

  signal amount_r   : std_logic_vector(amount_width_g-1 downto 0);
  signal ram_addr_r : std_logic_vector(data_width_g-1 downto 0);
  signal tx_comm_r  : std_logic_vector(2 downto 0);
begin  -- rtl

--  tx_reserve_out <= addr_match_r;
  tx_comm_out      <= tx_comm_r;
  tx_ram_addr_out  <= ram_addr_r;
  tx_amount_out    <= amount_r;
  tx_hibi_addr_out <= conv_std_logic_vector(Tx_HIBI_addr_g, data_width_g);

  av_empty <= hibi_av_in & hibi_empty_in;

  addr_matching : process (clk, rst_n)
  begin  -- process addr_matching
    if rst_n = '0' then                 -- asynchronous reset (active low)
      addr_match_r <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      case av_empty is
        when "11" | "01" =>
          addr_match_r <= '0';
        when "10" =>
          if hibi_data_in(addr_cmp_hi_g downto addr_cmp_lo_g) =
            hibi_addr_rx_in(addr_cmp_hi_g downto addr_cmp_lo_g) then
            addr_match_r <= '1';
          else
            addr_match_r <= '0';
          end if;
        when others =>
          -- one request per time!
--          addr_match_r <= addr_match_r;
          addr_match_r <= '0';
      end case;
      
    end if;
  end process addr_matching;


  ena : process (clk, rst_n)
  begin  -- process ena
    if rst_n = '0' then                 -- asynchronous reset (active low)
      ctrl_r <= normal;
    elsif clk'event and clk = '1' then  -- rising clock edge
      tx_start_out   <= '0';
      tx_reserve_out <= '0';

      tx_comm_r <= "010";

      case ctrl_r is
        when normal =>
          if init_in = '1' then
            ram_addr_r     <= avalon_addr_in;
            amount_r       <= conv_std_logic_vector(1, amount_width_g);
            tx_reserve_out <= tx_status_done_in;
            tx_comm_r      <= "011";
            if tx_status_done_in = '0' then
              ctrl_r       <= wait_tx;
              tx_start_out <= '0';
            else
              tx_start_out <= '1';
              ctrl_r       <= normal;
            end if;
          end if;

          -- addr is checked in previous turn, result is seen when the
          -- data is on the bus
          if addr_match_r = '1' then
            amount_r   <= hibi_data_in(amount_width_g-1 downto 0);
            -- NOTE! update multiply with shift
            ram_addr_r <= ram_addr_r + conv_integer(amount_r)*addr_offset_c;
            tx_comm_r  <= "010";
            if tx_status_done_in = '0' then
              ctrl_r       <= wait_tx;
              tx_start_out <= '0';
            else
              tx_start_out <= '1';
              ctrl_r       <= normal;
            end if;
            tx_reserve_out <= tx_status_done_in;
          end if;

        when wait_tx =>
          if tx_status_done_in = '1' then
            tx_start_out   <= '1';
            tx_reserve_out <= '1';
            tx_comm_r      <= tx_comm_r;
            ctrl_r         <= normal;
          else
            tx_start_out   <= '0';
            tx_reserve_out <= '0';
            tx_comm_r      <= tx_comm_r;
            ctrl_r         <= wait_tx;
          end if;
        when others => null;
      end case;
      
      
    end if;
  end process ena;

  

  
end rtl;
