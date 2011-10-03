-------------------------------------------------------------------------------
-- Title      : Dual port ram (unsigned)
-- Project    : 
-------------------------------------------------------------------------------
-- File       : dual_port_ram_u.vhd
-- Author     : 
-- Company    : 
-- Last update: 17.08.2010
-- Version    : 0.2
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
--
-------------------------------------------------------------------------------
-- Copyright (c) 2010
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 17.08.2010   0.1     arvio     Created
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--  This file is a part of a free IP-block: you can redistribute it and/or modify
--  it under the terms of the Lesser GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This IP-block is distributed in the hope that it will be useful,
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

entity dual_port_ram_u is
  generic ( DATA_WIDTH : integer := 8;
            ADDR_WIDTH : integer := 6;
            MEM_SIZE : integer := 64 );
            
            
  port ( clk         : in std_logic;
         addr_0_in   : in  unsigned(ADDR_WIDTH-1 downto 0);
         addr_1_in   : in  unsigned(ADDR_WIDTH-1 downto 0);
         wdata_0_in  : in  unsigned(DATA_WIDTH-1 downto 0);
         wdata_1_in  : in  unsigned(DATA_WIDTH-1 downto 0);
         we_0_in     : in  std_logic;
         we_1_in     : in  std_logic;
         rdata_0_out : out unsigned(DATA_WIDTH -1 downto 0);
         rdata_1_out : out unsigned(DATA_WIDTH -1 downto 0) );

end dual_port_ram_u;

architecture rtl of dual_port_ram_u is
  constant ENABLE_SIM : integer := 0
  -- synthesis translate_off
  + 1
  -- synthesis translate_on
  ;
  
  -- Build a 2-D array type for the RAM
  type memory_t is array (MEM_SIZE-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
  -- Declare the RAM signal.
  signal ram : memory_t; -- := (others => (others => '0'));
  
  signal addr_0 : integer range MEM_SIZE-1 downto 0;
  signal addr_1 : integer range MEM_SIZE-1 downto 0;
  signal wdata_0 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal wdata_1 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal rdata_0 : std_logic_vector(DATA_WIDTH -1 downto 0);
  signal rdata_1 : std_logic_vector(DATA_WIDTH -1 downto 0);
  
begin
  
  addr_0 <= to_integer(addr_0_in);
  addr_1 <= to_integer(addr_1_in);
  wdata_0 <= std_logic_vector(wdata_0_in);
  wdata_1 <= std_logic_vector(wdata_1_in);
  rdata_0_out <= unsigned(rdata_0);
  rdata_1_out <= unsigned(rdata_1);
  
  gen_0 : if ENABLE_SIM = 0 generate
  process(clk)
  begin
    if(clk'event and clk = '1') then -- Port 0
      if(we_0_in = '1') then
        ram(addr_0) <= wdata_0;
        -- Read-during-write on the same port returns NEW data
        rdata_0 <= wdata_0;
      else
        -- Read-during-write on the mixed port returns OLD data
        rdata_0 <= ram(addr_0);
      end if;
    end if;
  end process;    
  
  process(clk)
  begin
    if(clk'event and clk = '1') then -- Port 1
      if(we_1_in = '1') then
        ram(addr_1) <= wdata_1;
        -- Read-during-write on the same port returns NEW data
        rdata_1 <= wdata_1;
      else
        -- Read-during-write on the mixed port returns OLD data
        rdata_1 <= ram(addr_1);
      end if;
    end if;
  end process;
  end generate;
  
  gen_1 : if ENABLE_SIM = 1 generate
  process(clk)
  begin
    if(clk'event and clk = '1') then
      if(we_0_in = '1') then
        ram(addr_0) <= wdata_0;
        rdata_0 <= wdata_0;
      else
        rdata_0 <= ram(addr_0);
      end if;
      
      if(we_1_in = '1') then
        ram(addr_1) <= wdata_1;
        rdata_1 <= wdata_1;
      else
        rdata_1 <= ram(addr_1);
      end if;
    end if;
  end process;
  end generate;
  
end rtl;