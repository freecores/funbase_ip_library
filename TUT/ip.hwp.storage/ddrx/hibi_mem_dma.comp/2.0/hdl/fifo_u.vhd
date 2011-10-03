-------------------------------------------------------------------------------
-- File        : fifo.vhdl
-- Description : General fifo buffer
-- Author      : Erno Salminen
-- e-mail      : erno.salminen@tut.fi
-- Project     : 
-- Design      : 
-- Date        : 29.04.2002
-- Modified    : 30.04.2002 Vesa Lahtinen Optimized for synthesis
--
-- 15.12.04     ES: names changed
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--  This file is part of Transaction Generator.
--
--  Transaction Generator is free software: you can redistribute it and/or modify
--  it under the terms of the Lesser GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  Transaction Generator is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  Lesser GNU General Public License for more details.
--
--  You should have received a copy of the Lesser GNU General Public License
--  along with Transaction Generator.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_u is
  generic (
    data_width_g :    integer := 32;
    depth_g      :    integer := 5 );
  port (
    clk          : in std_logic;
    rst_n        : in std_logic;

    data_in   : in  unsigned(data_width_g-1 downto 0);
    we_in     : in  std_logic;
    full_out  : out std_logic;
    one_p_out : out std_logic;
    re_in     : in  std_logic;
    data_out  : out unsigned(data_width_g-1 downto 0);
    empty_out : out std_logic;
    one_d_out : out std_logic );

end fifo_u;

architecture behavioral of fifo_u is
  signal rdata : std_logic_vector(data_width_g-1 downto 0);
begin
  
  data_out <= unsigned(rdata);
  
  fifo_0 : entity work.fifo_ram
  generic map (
    data_width_g => data_width_g,
    depth_g => depth_g )

  port map (
    clk => clk,
    rst_n => rst_n,
    data_in => std_logic_vector(data_in),
    we_in => we_in,
    one_p_out => one_p_out,
    full_out => full_out,
    data_out => rdata,
    re_in => re_in,
    empty_out => empty_out,
    one_d_out => one_d_out );


end behavioral;
