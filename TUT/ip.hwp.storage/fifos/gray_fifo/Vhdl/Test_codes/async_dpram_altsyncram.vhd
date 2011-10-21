library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of async_dpram is
  
  component altsyncram
    generic
      (
       ADDRESS_ACLR_A                     : string  := "UNUSED";
       ADDRESS_ACLR_B                     : string  := "NONE";
       ADDRESS_REG_B                      : string  := "CLOCK1";
       BYTE_SIZE                          : natural := 8;
       BYTEENA_ACLR_A                     : string  := "UNUSED";
       BYTEENA_ACLR_B                     : string  := "NONE";
       BYTEENA_REG_B                      : string  := "CLOCK1";
       CLOCK_ENABLE_INPUT_A               : string  := "NORMAL";
       CLOCK_ENABLE_INPUT_B               : string  := "NORMAL";
       CLOCK_ENABLE_OUTPUT_A              : string  := "NORMAL";
       CLOCK_ENABLE_OUTPUT_B              : string  := "NORMAL";
       INTENDED_DEVICE_FAMILY             : string  := "UNUSED";
       IMPLEMENT_IN_LES                   : string  := "OFF";
       INDATA_ACLR_A                      : string  := "UNUSED";
       INDATA_ACLR_B                      : string  := "NONE";
       INDATA_REG_B                       : string  := "CLOCK1";
       INIT_FILE                          : string  := "UNUSED";
       INIT_FILE_LAYOUT                   : string  := "PORT_A";
       MAXIMUM_DEPTH                      : natural := 0;
       NUMWORDS_A                         : natural := 0;
       NUMWORDS_B                         : natural := 0;
       OPERATION_MODE                     : string  := "BIDIR_DUAL_PORT";
       OUTDATA_ACLR_A                     : string  := "NONE";
       OUTDATA_ACLR_B                     : string  := "NONE";
       OUTDATA_REG_A                      : string  := "UNREGISTERED";
       OUTDATA_REG_B                      : string  := "UNREGISTERED";
       RAM_BLOCK_TYPE                     : string  := "AUTO";
       RDCONTROL_ACLR_B                   : string  := "NONE";
       RDCONTROL_REG_B                    : string  := "CLOCK1";
       READ_DURING_WRITE_MODE_MIXED_PORTS : string  := "DONT_CARE";
       WIDTH_A                            : natural;
       WIDTH_B                            : natural := 1;
       WIDTH_BYTEENA_A                    : natural := 1;
       WIDTH_BYTEENA_B                    : natural := 1;
       WIDTHAD_A                          : natural;
       WIDTHAD_B                          : natural := 1;
       WRCONTROL_ACLR_A                   : string  := "UNUSED";
       WRCONTROL_ACLR_B                   : string  := "NONE";
       WRCONTROL_WRADDRESS_REG_B          : string  := "CLOCK1";
       LPM_HINT                           : string  := "UNUSED";
       LPM_TYPE                           : string  := "ALTSYNCRAM"
        ); 

    port (
      wren_a                 : in  std_logic;
      address_a              : in  std_logic_vector(WIDTHAD_A-1 downto 0);
      address_b              : in  std_logic_vector(WIDTHAD_B-1 downto 0);
      clock0, clock1, rden_b : in  std_logic;
      data_a                 : in  std_logic_vector(WIDTH_A-1 downto 0);
      data_b                 : in  std_logic_vector(WIDTH_B-1 downto 0);
      q_a                    : out std_logic_vector(WIDTH_A-1 downto 0);
      q_b                    : out std_logic_vector(WIDTH_B-1 downto 0)
      ); 

  end component;
  constant ADDRESS_ACLR_A                     : STRING  := "UNUSED";
  constant ADDRESS_ACLR_B                     : STRING  := "NONE";
  constant ADDRESS_REG_B                      : STRING  := "CLOCK1";
  constant BYTE_SIZE                          : NATURAL := 8;
  constant BYTEENA_ACLR_A                     : STRING  := "UNUSED";
  constant BYTEENA_ACLR_B                     : STRING  := "NONE";
  constant BYTEENA_REG_B                      : STRING  := "CLOCK1";
  constant CLOCK_ENABLE_INPUT_A               : STRING  := "NORMAL"; -- normal...
  constant CLOCK_ENABLE_INPUT_B               : STRING  := "NORMAL";
  constant CLOCK_ENABLE_OUTPUT_A              : STRING  := "NORMAL";
  constant CLOCK_ENABLE_OUTPUT_B              : STRING  := "NORMAL";
  constant INTENDED_DEVICE_FAMILY             : STRING  := "UNUSED";
  constant IMPLEMENT_IN_LES                   : STRING  := "OFF";
  constant INDATA_ACLR_A                      : STRING  := "UNUSED";
  constant INDATA_ACLR_B                      : STRING  := "NONE";
  constant INDATA_REG_B                       : STRING  := "CLOCK1";
  constant INIT_FILE                          : STRING  := "UNUSED";
  constant INIT_FILE_LAYOUT                   : STRING  := "PORT_A";
  constant MAXIMUM_DEPTH                      : NATURAL := 0;
  constant NUMWORDS_A                         : NATURAL := 2**addrw_g;
  constant NUMWORDS_B                         : NATURAL := 2**addrw_g;
  constant OPERATION_MODE                     : STRING  := "DUAL_PORT";
  constant OUTDATA_ACLR_A                     : STRING  := "NONE";
  constant OUTDATA_ACLR_B                     : STRING  := "NONE";
  constant OUTDATA_REG_A                      : STRING  := "UNREGISTERED";
  constant OUTDATA_REG_B                      : STRING  := "UNREGISTERED";
  constant RAM_BLOCK_TYPE                     : STRING  := "AUTO";
  constant RDCONTROL_ACLR_B                   : STRING  := "NONE";
  constant RDCONTROL_REG_B                    : STRING  := "CLOCK1";
  constant READ_DURING_WRITE_MODE_MIXED_PORTS : STRING  := "DONT_CARE";
  constant WIDTH_A                            : NATURAL := dataw_g;
  constant WIDTH_B                            : NATURAL := dataw_g;
  constant WIDTH_BYTEENA_A                    : NATURAL := 1;
  constant WIDTH_BYTEENA_B                    : NATURAL := 1;
  constant WIDTHAD_A                          : NATURAL := addrw_g;
  constant WIDTHAD_B                          : NATURAL := addrw_g;
  constant WRCONTROL_ACLR_A                   : STRING  := "UNUSED";
  constant WRCONTROL_ACLR_B                   : STRING  := "NONE";
  constant WRCONTROL_WRADDRESS_REG_B          : STRING  := "CLOCK1";
  constant LPM_HINT                           : STRING  := "UNUSED";
  constant LPM_TYPE                           : STRING  := "ALTSYNCRAM";

  signal ONE : std_logic;
begin  -- architecture rtl
  ONE <= '1';

  altsyncram_1 : altsyncram
    generic map (
      ADDRESS_ACLR_A                     => ADDRESS_ACLR_A,
      ADDRESS_ACLR_B                     => ADDRESS_ACLR_B,
      ADDRESS_REG_B                      => ADDRESS_REG_B,
      BYTE_SIZE                          => BYTE_SIZE,
      BYTEENA_ACLR_A                     => BYTEENA_ACLR_A,
      BYTEENA_ACLR_B                     => BYTEENA_ACLR_B,
      BYTEENA_REG_B                      => BYTEENA_REG_B,
      CLOCK_ENABLE_INPUT_A               => CLOCK_ENABLE_INPUT_A,
      CLOCK_ENABLE_INPUT_B               => CLOCK_ENABLE_INPUT_B,
      CLOCK_ENABLE_OUTPUT_A              => CLOCK_ENABLE_OUTPUT_A,
      CLOCK_ENABLE_OUTPUT_B              => CLOCK_ENABLE_OUTPUT_B,
      INTENDED_DEVICE_FAMILY             => INTENDED_DEVICE_FAMILY,
      IMPLEMENT_IN_LES                   => IMPLEMENT_IN_LES,
      INDATA_ACLR_A                      => INDATA_ACLR_A,
      INDATA_ACLR_B                      => INDATA_ACLR_B,
      INDATA_REG_B                       => INDATA_REG_B,
      INIT_FILE                          => INIT_FILE,
      INIT_FILE_LAYOUT                   => INIT_FILE_LAYOUT,
      MAXIMUM_DEPTH                      => MAXIMUM_DEPTH,
      NUMWORDS_A                         => NUMWORDS_A,
      NUMWORDS_B                         => NUMWORDS_B,
      OPERATION_MODE                     => OPERATION_MODE,
      OUTDATA_ACLR_A                     => OUTDATA_ACLR_A,
      OUTDATA_ACLR_B                     => OUTDATA_ACLR_B,
      OUTDATA_REG_A                      => OUTDATA_REG_A,
      OUTDATA_REG_B                      => OUTDATA_REG_B,
      RAM_BLOCK_TYPE                     => RAM_BLOCK_TYPE,
      RDCONTROL_ACLR_B                   => RDCONTROL_ACLR_B,
      RDCONTROL_REG_B                    => RDCONTROL_REG_B,
      READ_DURING_WRITE_MODE_MIXED_PORTS => READ_DURING_WRITE_MODE_MIXED_PORTS,
      WIDTH_A                            => WIDTH_A,
      WIDTH_B                            => WIDTH_B,
      WIDTH_BYTEENA_A                    => WIDTH_BYTEENA_A,
      WIDTH_BYTEENA_B                    => WIDTH_BYTEENA_B,
      WIDTHAD_A                          => WIDTHAD_A,
      WIDTHAD_B                          => WIDTHAD_B,
      WRCONTROL_ACLR_A                   => WRCONTROL_ACLR_A,
      WRCONTROL_ACLR_B                   => WRCONTROL_ACLR_B,
      WRCONTROL_WRADDRESS_REG_B          => WRCONTROL_WRADDRESS_REG_B,
      LPM_HINT                           => LPM_HINT,
      LPM_TYPE                           => LPM_TYPE)
    port map (
      wren_a    => wr_en_in,
      address_a => wr_addr_in,
      address_b => rd_addr_in,
      clock0    => wr_clk,
      clock1    => rd_clk,
      rden_b    => ONE,
      data_a    => data_in,
      q_b       => data_out
      );

--
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
