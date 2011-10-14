-------------------------------------------------------------------------------
-- Title      : Avalon reader
-- Project    : 
-------------------------------------------------------------------------------
-- File       : avalon_reader.vhd
-- Author     : kulmala3
-- Created    : 22.03.2005
-- Last update: 25.06.2007
-- Description: testbench block to model the avalon bus
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
use work.tb_n2h2_pkg.all;

entity avalon_reader is
  
  generic (
    data_file_g  : string  := "";
    addr_width_g : integer := 0;
    data_width_g : integer
    );

  port (
    clk                    : in  std_logic;
    rst_n                  : in  std_logic;
    avalon_we_in           : in  std_logic;
    avalon_be_in           : in  std_logic_vector(data_width_g/8-1 downto 0);
    avalon_writedata_in    : in  std_logic_vector(data_width_g-1 downto 0);
    avalon_addr_in         : in  std_logic_vector(addr_width_g-1 downto 0);
    avalon_waitrequest_out : out std_logic;
    increment_data_ptr     : in  std_logic;  -- hops over one data
    waitrequest_real_in    : in  std_logic;

    -- tb gets
    not_my_addr_out : out std_logic;
    --tb gives.
    init_in         : in  std_logic;
    my_own_addr_in  : in  std_logic_vector(data_width_g-1 downto 0)
    );

end avalon_reader;

architecture rtl of avalon_reader is

  constant addr_offset_c         : integer := data_width_g/8;
  constant assign_waitreq_c      : integer := 10;  -- between 10 datas...
  constant release_waitreq_c     : integer := 3;
  signal   addr_counter_r        : std_logic_vector(addr_width_g-1 downto 0);
  signal   data_counter_r        : integer;
  signal   waitreq_counter_r     : integer;
  signal   release_counter_r     : integer;
  signal   waitrequest_to_n2h_rx : std_logic;

  constant data_fixed_width_c : integer := 32;
  constant n_words_output_c   : integer := data_width_g/ data_fixed_width_c;
--  signal data_r : std_logic_vector(data_fixed_width_c-1 downto 0);  -- 32 bit words always!
  
begin  -- rtl

  avalon_waitrequest_out <= waitrequest_to_n2h_rx;

  process (clk, rst_n)
  begin  -- process
    if rst_n = '0' then
      waitreq_counter_r     <= 0;
      waitrequest_to_n2h_rx <= '0';
      release_counter_r     <= 0;
      
    elsif clk'event and clk = '1' then  -- rising clock edge
      if avalon_we_in = '1' then
        
        if (waitreq_counter_r = assign_waitreq_c) then
          waitreq_counter_r     <= 0;
          waitrequest_to_n2h_rx <= '1';
        else
          waitrequest_to_n2h_rx <= '0';
          waitreq_counter_r     <= waitreq_counter_r+1;
        end if;

      end if;

      if waitrequest_to_n2h_rx = '1' then
        release_counter_r <= release_counter_r+1;
        if release_counter_r >= release_waitreq_c then
          release_counter_r     <= 0;
          waitrequest_to_n2h_rx <= '0';
        end if;
      end if;
      
    end if;
  end process;

  process (clk, rst_n)
    file data_file           : text open read_mode is data_file_g;
    variable data_r          : integer;
    variable data_to_check_v : integer;
    variable not_my_addr_v   : integer;
    
  begin  -- process
    if rst_n = '0' then                 -- asynchronous reset (active low)
      addr_counter_r  <= (others => '0');
      data_counter_r  <= 0;
      not_my_addr_out <= '0';
      data_r          := 0;
      not_my_addr_v   := 0;
    elsif clk'event and clk = '1' then  -- rising clock edge
      if avalon_we_in = '1' and waitrequest_real_in = '0' then
        if (addr_counter_r + my_own_addr_in) /= avalon_addr_in then
          not_my_addr_out <= '1';
          not_my_addr_v   := 1;
        else
          not_my_addr_out <= '0';
          not_my_addr_v   := 0;
          addr_counter_r  <= addr_counter_r + addr_offset_c;
        end if;
        if not_my_addr_v = 0 then
          
          for i in 0 to n_words_output_c-1 loop
            
            if avalon_be_in((i+1)*4-1 downto i*4) = "1111" then
              data_to_check_v := conv_integer(avalon_writedata_in(data_fixed_width_c*(i+1)-1 downto data_fixed_width_c*i));
              if data_r /= data_to_check_v then
                assert false report "data mismatch on avalon!" severity error;
                assert false report "wait: " & str(data_r) & "got: " & str(data_to_check_v) severity error;
              else
                assert false report "Data OK" severity note;
              end if;

              data_r := data_r+1;
            end if;
          end loop;  -- i
        end if;

      elsif increment_data_ptr = '1' and waitrequest_real_in = '0' and not_my_addr_v = 0 then
        -- weren't actually writing, but data wre thrown away due to irq amount
        -- -> update file here also
--        read_data_file (
--          data     => data_r,
--          file_txt => data_file
--          );
        -- ??? AK 25.06.2007
--        data_r := data_r +1;
        
      end if;



      if init_in = '1' then
        addr_counter_r <= (others => '0');
      end if;

    end if;
  end process;
  

end rtl;
