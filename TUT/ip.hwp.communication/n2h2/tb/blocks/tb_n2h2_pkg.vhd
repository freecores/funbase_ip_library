
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--use work.txt_util.all;
use std.textio.all;
use ieee.std_logic_textio.all;

package tb_n2h2_pkg is

  procedure read_data_file (
    data          : out integer;
    file file_txt :     text);

  procedure read_conf_file (
    mem_addr      : out integer;
    sender        : out integer;
    irq_amount    : out integer;
--    max_amount    : out integer;
    file file_txt :     text);

    function log2 (
      constant x         : integer)
      return integer;

  
  type     addr_array is array (0 to 7) of integer;
--  constant addresses_c : addr_array := (16#1000000#, 16#3000000#, 16#5000000#, 16#7000000#, 16#9000000#, 16#b000000#, 16#d000000#, 16#f000000#);
    constant addresses_c : addr_array := (1111, 3333, 5555, 16#7000000#, 16#9000000#, 16#b000000#, 16#d000000#, 16#f000000#);
--  constant ava_addresses_c : addr_array := (1000000, 3000000, 5000000, 7000000, 9000000, 11000000, 13000000, 15000000);
  constant ava_addresses_c : addr_array := (1111,3333,5555, 7000000, 9000000, 11000000, 13000000, 15000000);

    constant conf_bits_c    : integer := 4;  -- number of configuration bits in CPU

end tb_n2h2_pkg;

package body tb_n2h2_pkg is

    
  procedure read_data_file (
    data          : out integer;
    file file_txt :     text) is
    variable file_row    : line;
    variable file_sample : integer;
  begin  -- read_data_file
    readline(file_txt, file_row);
    read(file_row, file_sample);
    data := file_sample;
  end read_data_file;

  procedure read_conf_file (
    mem_addr      : out integer;
    sender        : out integer;
    irq_amount    : out integer;
--    max_amount    : out integer;
    file file_txt :     text) is
    variable file_row    : line;
    variable file_sample : integer;
    variable file_sample_hex : std_logic_vector(31 downto 0);
    variable good : boolean ;
  begin  -- read_data_file
    readline(file_txt, file_row);

--    hread(file_row, file_sample_hex);
--    mem_addr   := conv_integer(file_sample_hex);
--    hread(file_row, file_sample_hex);
--    sender     := conv_integer(file_sample_hex);
    read(file_row,file_sample,good);
    assert good report "ei oo hyvä" severity note;
    mem_addr   := file_sample;
    read(file_row, file_sample);
    sender     := file_sample;
    read(file_row, file_sample);
    irq_amount := file_sample;
--    read(file_row, file_sample);
--    max_amount := file_sample;
  end read_conf_file;



    function log2 (
      constant x : integer)
      return integer is

      variable tmp_v : integer := 1;
      variable i_v   : integer := 0;
    begin  -- log2
      report "x is " &  integer'image(x);
      
      for i in 0 to 31 loop
        if tmp_v >= x then
          -- report "ceil(log2(x)) is " &  integer'image(i);

          return i;
        end if;
        tmp_v := tmp_v * 2;
        
      end loop;  -- i

      -- We should not ever come here, return definitely illegal value
      return -1;
      
    end log2;

  
end tb_n2h2_pkg;
