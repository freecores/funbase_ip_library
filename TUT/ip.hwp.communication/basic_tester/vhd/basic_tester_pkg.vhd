-------------------------------------------------------------------------------
-- Title      : A block which sends data to HIBI ver B.
-- Project    : 
-------------------------------------------------------------------------------
-- File       : basic_test_tx.vhd
-- Author     : ege
-- Created    : 2010-03-24
-- Last update: 2011-11-25
--
--
-------------------------------------------------------------------------------
-- Copyright (c) 2010
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Funbase IP library Copyright (C) 2011 TUT Department of Computer Systems
--
--
-- This source file may be used and distributed without
-- restriction provided that this copyright statement is not
-- removed from the file and that any derivative work contains
-- the original copyright notice and the associated disclaimer.
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.opencores.org/lgpl.shtml
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use std.textio.all;
use ieee.std_logic_textio.all;                     -- 2010-10-06 for hread


package basic_test_pkg is
  procedure read_conf_file (
    variable delay        : out integer;
    variable dest_agent_n : out integer;
    variable value        : out integer;
    variable cmd          : out integer;
    file conf_dat         :     text);
  

end basic_test_pkg;

package body basic_test_pkg is


  -- Reads the (opened) file given. the file line structure is as follows:
  -- 1st integer: delay cycles before sending
  -- 2nd integer: destination addr
  -- 3rd integer: data value to be sent.
  -- 4th integer: HIBI command (optional)
  procedure read_conf_file (
    delay         : out integer;
    dest_agent_n  : out integer;
    value         : out integer;
    cmd           : out integer;
    file conf_dat :     text) is

    variable file_row         : line;
    variable delay_var        : integer;
--    variable dest_agent_n_var : integer;
--    variable data_val_var     : integer;
--    variable cmd_var          : integer;

    variable delay2_var       : std_logic_vector (16-1 downto 0);
    variable dest_agent_n_var : std_logic_vector (32-1 downto 0);
    variable data_val_var     : std_logic_vector (32-1 downto 0);
    variable cmd_var          : std_logic_vector (8-1 downto 0);

    variable delay_ok : boolean := FALSE;
    variable cmd_ok   : boolean := FALSE;
    
  begin  -- read_conf_file

    -- Loop until finding a line that is not a comment
    while delay_ok = false and not(endfile(conf_dat)) loop
      readline(conf_dat, file_row);
      
      hread (file_row, delay2_var, delay_ok);

      if delay_ok = FALSE then
         --Reading of the delay value failed
         --=> assume that this line is comment or empty, and skip other it
        -- assert false report "Skipped a line" severity note;
        next;                           -- start new loop interation
      end if;

      delay_var := to_integer(signed(delay2_var));
      --assert false report "tx viive: " & integer'image (delay_var) severity note;      
      
      hread (file_row, dest_agent_n_var);
      hread (file_row, data_val_var);
      hread (file_row, cmd_var, cmd_ok);
      if cmd_ok = FALSE then
        cmd_var := x"FF";
      end if;

      -- Return the values
      delay        := delay_var;
      dest_agent_n := to_integer( signed (dest_agent_n_var));
      value        := to_integer( signed (data_val_var));
      cmd          := to_integer( signed (cmd_var));
    end loop;

  end read_conf_file;


  
  

end basic_test_pkg;
