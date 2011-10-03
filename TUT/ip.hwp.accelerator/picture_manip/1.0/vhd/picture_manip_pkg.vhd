--*****************************************************************************
--* File :   picture_manip_pkg.vhd  (package)        
--* Author : Ari Metso / PaloDEx group oy
--*          ari.metso@palodexgroup.com
--* Date :   24.03.2010  
--*
--* Licence to use and modify this file within Funbase project is given to 
--* members of Funbase project. Redistribution or using of this file 
--*(or even part of it) to third parties is not allowed in any form without
--* authorisation of PaloDEx group oy.
--*****************************************************************************
--* Updates :
--*
--*   rel.   dd.mm.yyyy   Author           Description
--*   ----------------------------------------------------------
--*   1      24.03.2010   Ari Metso	       Created
--*
--*****************************************************************************
--* COMMENTS:
--*   
--*   Contains types, sub-programs and component declarations for the 
--*   picture_manip.vhd HIBI component
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

package picture_manip_pkg is
	   
    -- Common constants
    constant VERSION                    : natural   := 1;
    constant DEVICE_FAMILY              : string    := "Arria II GX";
    
    -- Configuration for the picture manipulation buffer    
	constant MANIP_BUFF_WWIDTH          : positive := 32;       -- word width
    constant MANIP_BUFF_DEPTH           : positive := 256;      -- counted as word
    constant MANIP_BUFF_BLOCK_TYPE      : string   := "M9K";    -- e.g. "M4K", M9K, etc.
    
    -- Configurations for picture manipulator
    constant PIXEL_WIDTH                : positive := 8;        -- as bits
    constant H_PIXEL_COUNT              : integer := 16;      -- Horizontal width of picture
    constant V_PIXEL_COUNT              : integer := 8;      -- Vertical height of picture
    constant ROTATION                   : positive := 90;       -- as degrees in clockwice 0, 90, 180, 270 (90deg supported only)
    
    
    -- Register map        
    --        REGISTER                                                 OFFSET ADDR
    ------------------------------------------------------------------------
    constant PICTURE_MANIPULATOR_DATA_INPUT      : natural  := 16#00000000#;
    constant START_RAW_FRAME_MANIPULATION_STATUS : positive := 16#00100000#;
    constant MANIPULATED_FRAME_STATUS            : positive := 16#00200000#;
    constant WRITE_ACKNOWLEDGEMENT_ADDRESS       : positive := 16#00300000#;
    constant READ_ACKNOWLEDGEMENT_ADDRESS        : positive := 16#00400000#;
    
    -- Messages
    constant MANIPULATED_FRAME_READY             : std_logic_vector( 31 downto 0 ) := X"00000010";
    constant MANIPULATED_FRAME_NOT_READY         : std_logic_vector( 31 downto 0 ) := X"00000000";
    constant START_NEW_FRAME                     : std_logic_vector( 31 downto 0 ) := X"00000011"; 
    constant START_RAW_FRAME_MANIPULATION        : std_logic_vector( 31 downto 0 ) := X"00000001";
    constant WRITE_COMPLETED                     : std_logic_vector( 31 downto 0 ) := X"00000100";
    constant READ_COMPLATED                      : std_logic_vector( 31 downto 0 ) := X"00001000";
    
    -- HIBI commands
    constant HIBI_CMD_IDLE      : std_logic_vector( 2 downto 0 ) := "000"; -- 0
    constant HIBI_CMD_RD        : std_logic_vector( 2 downto 0 ) := "100"; -- 1
                                                                         --
                                                    
    constant HIBI_CMD_WR        : std_logic_vector( 2 downto 0 ) := "010"; -- 2
    constant HIBI_CMD_WR_MSG    : std_logic_vector( 2 downto 0 ) := "011"; -- 3
    constant HIBI_CMD_WR_CNF    : std_logic_vector( 2 downto 0 ) := "100"; -- 4
    constant HIBI_CMD_RD_CNF    : std_logic_vector( 2 downto 0 ) := "101"; -- 5
    constant HIBI_CMD_MULTI     : std_logic_vector( 2 downto 0 ) := "110"; -- 6
    constant HIBI_CMD_UNKNOWN   : std_logic_vector( 2 downto 0 ) := "111"; -- 7
    
    
    
    -- types
    type tFLOW_STATE is (ST_IDLE, ST_SEND_RD_CMD, ST_RECEIVE_ONE_ROW, ST_WRITE_AND_REALLOCATE, 
                         ST_IMAGE_READY, ST_TRANSMIT_DATA, ST_ERR);
      
     
    -- sub-programs
    function CalcBusWidth( Value : integer ) return integer;
   	
    -- components
    component manip_memory IS
    port
	(
        iAClr		: in std_logic ;
		iAddress	: in std_logic_vector( CalcBusWidth( MANIP_BUFF_DEPTH-1)-1 downto 0 );
		iClock		: in std_logic ;
		iData_In	: in std_logic_vector( MANIP_BUFF_WWIDTH-1 downto 0 );
		iRead		: in std_logic ;
		iWrite		: in std_logic ;
		iData_Out   : out std_logic_vector( MANIP_BUFF_WWIDTH-1 downto 0 )
	);
    end component;
    
end picture_manip_pkg;

--*****************************************************************************
package body picture_manip_pkg is

--=============================================================================
-- Function: CalcBusWidth
--
--	Calculates needed bus width from max value
--	Restrictions: - Max calculated bus width is 31 bits

function CalcBusWidth( Value : integer ) return integer is
	variable vBusWidth : integer := 0;
begin
	vBusWidth := 0;
	loop 
		exit when( ((2**vBusWidth)-1) > Value );
		vBusWidth := vBusWidth + 1; 
	end loop;
	return vBusWidth;      
end CalcBusWidth;


end picture_manip_pkg;
--*****************************************************************************
-- END OF FILE
--*****************************************************************************
