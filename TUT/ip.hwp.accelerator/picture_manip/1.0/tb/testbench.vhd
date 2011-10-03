--*****************************************************************************
--* File :   testbench.vhd  (testbench TOP)        
--* Author : Ari Metso
--* Date :   25.03.2010                   
--*****************************************************************************
--* Updates :
--*
--* 		rel.    dd.mm.yyyy   Author           Description
--*  	----------------------------------------------------------
--*		 1       25.03.2010   Ari Metso	       Created
--*
--*****************************************************************************
--* COMMENTS:   This testbench is for testing of picture_manip.vhd
--*  
--*
--*****************************************************************************

LIBRARY ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.std_logic_arith.ALL;
use ieee.math_real.all;

ENTITY testbench IS
END testbench;

architecture behavior OF testbench IS 

--=============================================================================
-- TB config

constant SYS_CLK                 : real    := 50000000.0; 
constant TEST_CASE               : integer := 3;

constant gHIBI_DATA_WIDTH        : positive := 32;
constant gHIBI_COMM_WIDTH         : positive := 3;

--=============================================================================

-------------------------------------------------------------------------------
-- COMPONENT DECLARATIONS
-------------------------------------------------------------------------------

component picture_manip 
    generic (
        -- Hibi addresses and bus widths
        gPICTURE_MANIP_BASE         : integer := 16#43000000#;  -- Own Base address
        gDDR2F_BASE                 : integer := 16#C0000000#;  -- DDR2 controller addresses
        gRAW_FRAME_LOCATION_START   : integer := 16#C0100000#;
        gMANIP_FRAME_LOCATION_START : integer := 16#C0200000#;
        gHIBI_DATA_WIDTH            : integer := 32;
        gHIBI_COMM_WIDTH            : integer := 3
    );

    port (
        -- System interface
        sys_iReset_n    : in std_logic;
        sys_iClk        : in std_logic;

        -- Input signals from HIBI wrapper (R4) interface 
        hibi_iAv          : in std_logic;
        hibi_iData        : in std_logic_vector( gHIBI_DATA_WIDTH-1 downto 0 );
        hibi_iComm        : in std_logic_vector( gHIBI_COMM_WIDTH-1 downto 0 );
        hibi_iEmpty       : in std_logic;
        hibi_iOne_d_left  : in std_logic;
        hibi_iFull        : in std_logic;
        hibi_iOne_p_left  : in std_logic;

        -- Output signals to HIBI wrapper
        hibi_oAv         : out std_logic;
        hibi_oData       : out std_logic_vector( gHIBI_DATA_WIDTH-1 downto 0 );
        hibi_oComm       : out std_logic_vector( gHIBI_COMM_WIDTH-1 downto 0 );
        hibi_oWe         : out std_logic;
        hibi_oRe         : out std_logic
    );
end component;
  

-------------------------------------------------------------------------------
-- SIGNAL DECLARATIONS
-------------------------------------------------------------------------------

signal sReset_n    : std_logic;
signal sMaster_Clk : std_logic;

-- Input signals from HIBI wrapper
signal hibi_iAv         : std_logic;
signal hibi_iData       : std_logic_vector( gHIBI_DATA_WIDTH-1 downto 0 );
signal hibi_iComm       : std_logic_vector( gHIBI_COMM_WIDTH-1 downto 0 );
signal hibi_iEmpty      : std_logic;
signal hibi_iOne_d_left : std_logic;
signal hibi_iFull       : std_logic;
signal hibi_iOne_p_left : std_logic;

-- Output signals to HIBI wrapper
signal hibi_oAv         : std_logic;
signal hibi_oData       : std_logic_vector( gHIBI_DATA_WIDTH-1 downto 0 );
signal hibi_oComm       : std_logic_vector( gHIBI_COMM_WIDTH-1 downto 0 );
signal hibi_oWe         : std_logic;
signal hibi_oRe         : std_logic;


-------------------------------------------------------------------------------
BEGIN
-------------------------------------------------------------------------------
-- TESTBENCH INSTANTATIONS 
-- Instanttiate testbeches for testcases
-------------------------------------------------------------------------------

-- testbench for test case 1
--tb_01: if TEST_CASE = 1 generate tc_01 : tb_TestCase_01; end generate tb_01;

-- testbench for test case 2
--tb_02: if TEST_CASE = 2 generate tc_02 : tb_TestCase_02; end generate tb_02;

-- testbench for test case 3
--tb_03: if TEST_CASE = 3 generate tc_03 : tb_TestCase_03; end generate tb_03;

-------------------------------------------------------------------------------
-- COMPONENT INSTANTATION
-------------------------------------------------------------------------------
pic_man: picture_manip 
    generic map(
        -- Hibi addresses and bus widths
        gPICTURE_MANIP_BASE         => 16#43000000#,  -- Own Base address
        gDDR2F_BASE                 => 16#C0000000#,  -- DDR2 controller addresses
        gRAW_FRAME_LOCATION_START   => 16#C0100000#,
        gMANIP_FRAME_LOCATION_START => 16#C0200000#,
        gHIBI_DATA_WIDTH            => gHIBI_DATA_WIDTH,
        gHIBI_COMM_WIDTH            => gHIBI_COMM_WIDTH
    )
    port map(
        -- System interface
        sys_iReset_n      => sReset_n,
        sys_iClk          => sMaster_Clk,

        -- Input signals from HIBI wrapper (R4) interface 
        hibi_iAv          => hibi_iAv,
        hibi_iData        => hibi_iData,
        hibi_iComm        => hibi_iComm,
        hibi_iEmpty       => hibi_iEmpty,
        hibi_iOne_d_left  => hibi_iOne_d_left,
        hibi_iFull        => hibi_iFull,
        hibi_iOne_p_left  => hibi_iOne_p_left,

        -- Output signals to HIBI wrapper
        hibi_oAv          => hibi_oAv,
        hibi_oData        => hibi_oData,
        hibi_oComm        => hibi_oComm,
        hibi_oWe          => hibi_oWe,
        hibi_oRe          => hibi_oRe
    );


-------------------------------------------------------------------------------
-- PROCESSES
-------------------------------------------------------------------------------

-- Testbench system processes
reset : process
begin
   sReset_n <= '0';        
   wait for 1 us;
   sReset_n <= '1';
   wait;
end process;

clk_seq : PROCESS
begin
   sMaster_Clk <= '0';
   wait for (1.0 sec)/(SYS_CLK*2.0);
   sMaster_Clk <= '1';
   wait for (1.0 sec)/(SYS_CLK*2.0);
end process;

-- Testbench processes
hibi_iAv          <= '0';
hibi_iData        <= (others=> '0');
hibi_iComm        <= (others=> '0');
hibi_iEmpty       <= '0';
hibi_iOne_d_left  <= '0';
hibi_iFull        <= '0';
hibi_iOne_p_left  <= '0';


-------------------------------------------------------------------------------
END;

--*****************************************************************************
-- END OF FILE
--*****************************************************************************