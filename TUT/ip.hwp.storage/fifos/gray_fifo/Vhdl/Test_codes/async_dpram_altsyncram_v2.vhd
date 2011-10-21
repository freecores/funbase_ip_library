library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of async_dpram is
  component ram2p_altsyncram_hh41
    port (
      address_a : in  std_logic_vector (3 downto 0);
      address_b : in  std_logic_vector (3 downto 0)  := (others => '1');
      clock0    : in  std_logic                      := '1';
      clock1    : in  std_logic                      := '1';
      data_a    : in  std_logic_vector (35 downto 0) := (others => '1');
      q_b       : out std_logic_vector (35 downto 0);
      wren_a    : in  std_logic                      := '0');
  end component;

  
  signal ONE : std_logic;
begin  -- architecture rtl
  ONE <= '1';
--
  ram2p_altsyncram_hh41_1: ram2p_altsyncram_hh41
    port map (
      address_a => '0' & wr_addr_in,
      address_b => '0' & rd_addr_in,
      clock0    => wr_clk,
      clock1    => rd_clk,
      data_a    => data_in,
      q_b       => data_out,
      wren_a    => wr_en_in
      );

  
--  generic (
--    addrw_g : integer := 0;
--    dataw_g : integer := 0);

--  port (
--    rd_clk, wr_clk         : in  std_logic;
--    wr_en_in               : in  std_logic;
--    data_in                : in  std_logic_vector(dataw_g-1 downto 0);
--    data_out               : out std_logic_vector(dataw_g-1 downto 0);
--    rd_addr_in, wr_addr_in : in  std_logic_vector (addrw_g-1 downto 0));

end architecture rtl;
