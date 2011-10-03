--*****************************************************************************
--* File :   picture_manip.vhd  (HIBI component)        
--* Author : Ari Metso / PaloDEx group oy
--*          ari.metso@palodexgroup.com
--* Date :   24.03.2010
--* 
--* This file is proprietary of PaloDEx group.
--*
--* Licence to use and modify this file within Funbase project is given to 
--* members of Funbase project. Redistribution or using of this file 
--*(or even part of it) to third parties is not allowed in any form without
--* authorisation of PaloDEx group oy.
--*****************************************************************************
--* Updates :
--*
--*   rel.  dd.mm.yyyy   Author        Description
--*   ----------------------------------------------------------
--*   1     24.03.2010   Ari Metso     Created
--*   2     14.04.2010   LM(TTY)       registers fixed
--*   3     18.05.2010   LM(TTY)       IO implemented
--*   
--*****************************************************************************
--* DESCRIPTION:
--*
--*
--*****************************************************************************

--*****************************************************************************
-- Library
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--PACKAGES
use work.picture_manip_pkg.all;

--*****************************************************************************
-- Entity
--*****************************************************************************
entity picture_manip is
  generic (
    -- Hibi addresses and bus widths
    gPICTURE_MANIP_BASE         : integer := 16#03000000#;  -- Own Base address
    gDDR2F_BASE                 : integer := 16#29000000#;  -- DDR2 controller addresses
    gRAW_FRAME_LOCATION_START   : integer := 16#C0100000#;  -- TODO: KORJAA! 
    gMANIP_FRAME_LOCATION_START : integer := 16#C0200000#;  -- TODO: KORJAA!
    gHIBI_DATA_WIDTH            : integer := 32;
    gHIBI_COMM_WIDTH            : integer := 3
    );

  port (
    -- System interface
    sys_iReset_n : in std_logic;
    sys_iClk     : in std_logic;

    -- Input signals from HIBI wrapper (R4) interface 
    hibi_iAv         : in std_logic;
    hibi_iData       : in std_logic_vector(gHIBI_DATA_WIDTH-1 downto 0);
    hibi_iComm       : in std_logic_vector(gHIBI_COMM_WIDTH-1 downto 0);
    hibi_iEmpty      : in std_logic;
    hibi_iOne_d_left : in std_logic;
    hibi_iFull       : in std_logic;
    hibi_iOne_p_left : in std_logic;

    -- Output signals to HIBI wrapper
    hibi_oAv   : out std_logic;
    hibi_oData : out std_logic_vector(gHIBI_DATA_WIDTH-1 downto 0);
    hibi_oComm : out std_logic_vector(gHIBI_COMM_WIDTH-1 downto 0);
    hibi_oWe   : out std_logic;
    hibi_oRe   : out std_logic
    );
end;

--*****************************************************************************
-- Architecture
--*****************************************************************************
architecture arch_pic_man of picture_manip is
-------------------------------------------------------------------------------
-- CONSTANT DECLARATIONS
-------------------------------------------------------------------------------
  constant RAW_FRAME_LOCATION_END   : integer := gRAW_FRAME_LOCATION_START + H_PIXEL_COUNT * V_PIXEL_COUNT * (PIXEL_WIDTH / 8);
  constant MANIP_FRAME_LOCATION_END : integer := gMANIP_FRAME_LOCATION_START+H_PIXEL_COUNT*V_PIXEL_COUNT*(PIXEL_WIDTH/8);

-------------------------------------------------------------------------------
-- SIGNAL DECLARATIONS
-------------------------------------------------------------------------------
-- Internal signals

  signal sFlowState : tFLOW_STATE;
  signal prevFlowState : tFLOW_STATE;
  signal sReset     : std_logic;

  signal sMMemAddr : std_logic_vector(CalcBusWidth(MANIP_BUFF_DEPTH-1)-1 downto 0);


  signal sManip : std_logic_vector( gHIBI_DATA_WIDTH-1 downto 0);
  
  signal sDataIn  : std_logic_vector(MANIP_BUFF_WWIDTH-1 downto 0);
  signal sRd_Ena  : std_logic;
  signal sWr_Ena  : std_logic;
  signal sDataOut : std_logic_vector(MANIP_BUFF_WWIDTH-1 downto 0);

  signal sMessage : std_logic_vector(gHIBI_DATA_WIDTH-1 downto 0);
  signal sMyAddr  : std_logic_vector(gHIBI_DATA_WIDTH-1 downto 0);
  signal sRawAddr : std_logic_vector(gHIBI_DATA_WIDTH-1 downto 0);
  signal sRawSize : std_logic_vector(gHIBI_DATA_WIDTH-1 downto 0);
  signal sNewAddr : std_logic_vector(CalcBusWidth(MANIP_BUFF_DEPTH-1)-1 downto 0);
-- IO signals

  signal shibi_oAv   : std_logic;
  signal shibi_oData : std_logic_vector(gHIBI_DATA_WIDTH-1 downto 0);
  signal shibi_oComm : std_logic_vector(gHIBI_COMM_WIDTH-1 downto 0);
  signal shibi_oWe   : std_logic;
  signal shibi_oRe   : std_logic;
-- debug signals
  signal sDBG        : std_logic_vector(8 downto 1);

-------------------------------------------------------------------------------
begin

-------------------------------------------------------------------------------
-- COMPONENT INSTANTATIONS
-------------------------------------------------------------------------------
  m_mem : manip_memory
    port map(
      iAClr     => sReset,
      iClock    => sys_iClk,
      iAddress  => sMMemAddr,
      iWrite    => sWr_Ena,
      iRead     => sRd_Ena,
      iData_In  => sDataIn,
      iData_Out => sDataOut
      );

-------------------------------------------------------------------------------
-- SIGNAL ASSIGMENTS
-------------------------------------------------------------------------------
-- internal 
  sReset     <= sys_iReset_n;
-- IO Outputs 
  hibi_oAv   <= shibi_oAv;
  hibi_oData <= shibi_oData;
  hibi_oComm <= shibi_oComm;
  hibi_oWe   <= shibi_oWe;
  hibi_oRe   <= shibi_oRe;

-------------------------------------------------------------------------------
-- PROCESSES
-------------------------------------------------------------------------------
  FlowCtrl : process(Sys_iReset_n, Sys_iClk)
    variable vMsgAtribCnter : natural := 0;
    variable vPixelCounter  : natural := 0;
    variable vRowCounter    : natural := 0;
    variable vManipDataTmp : std_logic_vector( 31 downto 0); 
    variable vWordCnt : integer := 0;
    variable vDataTmp : std_logic_vector(7 downto 0):= (others => '0');
    variable v_delay : integer := 0;
  begin
    if(Sys_iReset_n = '0') then
      sFlowState     <= ST_IDLE;
      vMsgAtribCnter := 3;              -- attrib cnt in IDLE state
      vPixelCounter  := 0;
      vRowCounter    := 0;
      sMessage       <= (others => '0');
      sRawAddr       <= (others => '0');
      sRawSize       <= (others => '0');
      sNewAddr       <= (others => '0');
      sMyAddr        <= (others => '0');
      

      -- manip memory control
      sMMemAddr <= (others => '0');
      sDataIn   <= (others => '0');
      sRd_Ena   <= '0';
      sWr_Ena   <= '0';

      -- hibi outputs
      shibi_oAv   <= '0';
      shibi_oData <= (others => '0');
      shibi_oComm <= (others => '0');
      shibi_oWe   <= '0';
      shibi_oRe   <= '0';
      
    elsif(Sys_iClk'event and Sys_iClk = '1') then

      prevFlowState <= sFlowState;
      -- keep transactions initiated at default
      -- to hibi
      shibi_oAv   <= '0';
      shibi_oData <= (others => '0');
      shibi_oComm <= (others => '0');
      shibi_oWe   <= '0';
      shibi_oRe   <= '0';
      -- to manipulation memory
      sMMemAddr   <= (others => '0');
      sDataIn     <= (others => '0');
      sRd_Ena     <= '0';
      sWr_Ena     <= '0';
      sManip      <= (others => '0');

      case sFlowState is
        ---------------------------------------------------------------------------------------------------------
        when ST_IDLE =>                 -- wait for raw frame

          if (hibi_iOne_d_left = '1' and shibi_oRe ='1') or hibi_iEmpty = '1' then
            shibi_oRe <= '0';
          else
            shibi_oRe <='1';
          end if;
            
          if shibi_oRe = '1' and hibi_iAv = '1' then  -- start reading fifo when data in it
            --shibi_oRe <= '1';
            --if(hibi_iAv = '1') then
             if vMsgAtribCnter = 3 then
               sMyAddr <= hibi_iData;     
               vMsgAtribCnter:= vMsgAtribCnter-1;
             end if;
            
            -- vMsgAtribCnter:= vMsgAtribCnter-1;
            --end if;
            
              
            --else
             -- sMyAddr <= (others => '0');  -- error trap
            --end if;


          --elsif((hibi_iEmpty = '0' and vMsgAtribCnter >= 0 and hibi_iAv = '0') or
            --    (shibi_oRe ='0' and hibi_iOne_d_left = '1')) then  -- read rx fifo until all mesage attributes are got
          else
            
            -- if vMsgAtribCnter > 0 then
             -- vMsgAtribCnter := vMsgAtribCnter - 1;
            -- end if;
         if  shibi_oRe = '1' then
            case vMsgAtribCnter is
              when 2 =>
                sMessage <= hibi_iData;
                vMsgAtribCnter := vMsgAtribCnter - 1;
              when 1 =>
                sRawAddr <= hibi_iData;
                vMsgAtribCnter := vMsgAtribCnter - 1;
              when 0 =>
                --shibi_oRe <= '0';
                sRawSize <= hibi_iData;
                sFlowState    <= ST_SEND_RD_CMD;
                vMsgAtribCnter := 4;
                vRowCounter := 0;
              when others =>
                --vMsgAtribCnter := 0;    -- cleared just for fun
                -- sFlowState     <= ST_ERR;
            end case;
          end if;
         -- else
           -- shibi_oRe <= '1';
           if(vMsgAtribCnter = 0) then  -- if whole message is got
--               shibi_oRe <= '0';
              if (sMessage = start_raw_frame_manipulation) then  -- if valid message, jump next stage
--                -- initiate read reguest
--                vMsgAtribCnter := 4;  -- LM 5 -->6
                vRowCounter    := 0;  -- initiate for write back and re allocation
--                --sFlowState     <= ST_SEND_RD_CMD;
--                v_delay := 100;
--              else                      -- trap if got junk   
--                vRowCounter := 0;       --DEBUGGGGG
--                vMsgAtribCnter := 4;
            --    sFlowState     <= ST_ERR;
--               --  sFlowState   <= ST_SEND_RD_CMD;
              end if;
            end if;
          end if;
          ---------------------------------------------------------------------------------------------------------    


        when ST_SEND_RD_CMD =>

--          if v_delay > 0 then
--          v_delay := v_delay -1;  
--          else
          shibi_oAv   <= shibi_oAv;
          shibi_oData <= shibi_oData;
          shibi_oComm <= shibi_oComm;
          shibi_oRe   <= shibi_oRe;
          --shibi_oWe   <= shibi_oWe;
          if ((hibi_iFull = '0') and (hibi_iOne_p_left = '0') and (vMsgAtribCnter = 4)) then  -- send rd command
            shibi_oWe      <= '1';
            shibi_oAv      <= '1';
            shibi_oComm    <= HIBI_CMD_RD;
            shibi_oData    <= std_logic_vector(conv_unsigned(gDDR2F_BASE + 16#10#, gHIBI_DATA_WIDTH));
            vMsgAtribCnter := vMsgAtribCnter - 1;
          elsif(hibi_iFull = '0' and hibi_iOne_p_left = '0' and vMsgAtribCnter > 0) then  -- send rest of atributes
            shibi_oAv <= '0';

            case vMsgAtribCnter is
              when 4 =>
                sFlowState <= ST_SEND_RD_CMD;
              when 3 =>                 -- DMA initiation 
                shibi_oWe <= '1';
                shibi_oData    <= conv_std_logic_vector((H_PIXEL_COUNT/4), gHIBI_DATA_WIDTH);
                vMsgAtribCnter := vMsgAtribCnter - 1;
              when 2 =>                 -- start adress of raw frame
                shibi_oWe <= '1';
                --shibi_oData    <= conv_std_logic_vector(gRAW_FRAME_LOCATION_START, gHIBI_DATA_WIDTH) or conv_std_logic_vector(vRowCounter*(H_PIXEL_COUNT/4), gHIBI_DATA_WIDTH);
                shibi_oData    <= sRawSize or conv_std_logic_vector(vRowCounter*(H_PIXEL_COUNT/4), gHIBI_DATA_WIDTH);
                shibi_oData    <= sRawAddr or conv_std_logic_vector(vRowCounter*(H_PIXEL_COUNT/4), gHIBI_DATA_WIDTH);

                vMsgAtribCnter := vMsgAtribCnter - 1;
              when 1 =>                 -- my data input
                shibi_oWe <= '1';
                shibi_oData    <= conv_std_logic_vector(gPICTURE_MANIP_BASE, shibi_oData'high+1);
                vMsgAtribCnter := vMsgAtribCnter - 1;
              when 0 =>                 -- address for read acknowledgement
                shibi_oWe <= '0';
              
              when others =>
                vMsgAtribCnter := 0;
                sFlowState     <= ST_ERR;
            end case;
          else
            shibi_oWe <= '0';
          if(vMsgAtribCnter = 0) then
            vMsgAtribCnter := 1;
            sFlowState     <= ST_RECEIVE_ONE_ROW;
          end if;
      end if;
    
          ---------------------------------------------------------------------------------------------------------    
        when ST_RECEIVE_ONE_ROW =>
          sMMemAddr <= conv_std_logic_vector(vPixelCounter, sMMemAddr'high+1);
          sRd_Ena   <= '0';
          --sWr_Ena   <= (sWr_Ena and not hibi_iEmpty);
          sWr_Ena <= '1';
          shibi_oRe <= shibi_oRe;

          if ((hibi_iEmpty = '0') and (hibi_iOne_d_left = '0') and (vMsgAtribCnter = 1)) then  -- start reading fifo when data in it
            shibi_oRe <= '1';
            if(hibi_iAv = '1') then
              sMyAddr <= hibi_iData;
            else
              sMyAddr <= (others => '0');                      -- error trap
            end if;
            vMsgAtribCnter := 0;
            vPixelCounter  := 0;
            sWr_Ena        <= '1';

          
          elsif((hibi_iEmpty = '0') and (sWr_Ena = '1') and hibi_iAv = '0') then  -- read rx fifo until all pixels in row are got
            if(sMyAddr = gPICTURE_MANIP_BASE + PICTURE_MANIPULATOR_DATA_INPUT) then
              if(vPixelCounter < H_PIXEL_COUNT/4) then
                sWr_Ena       <= '1';
                vPixelCounter := vPixelCounter + 1;
                sDataIn   <= hibi_iData;
              else
                shibi_oRe <= '0';
                sWr_Ena       <= '0';
                vPixelCounter := vPixelCounter;
              end if;
            else
              vMsgAtribCnter := 0;
              sFlowState     <= ST_ERR;
            end if;
          elsif(vPixelCounter = H_PIXEL_COUNT/4) then
            sWr_Ena        <= '0';
            vMsgAtribCnter := 4;        -- LM increased counter value for
                                        -- all DDR2 cfg attributes
           
            vPixelCounter := 0;
            sFlowState    <= ST_WRITE_AND_REALLOCATE;
          end if;

          ---------------------------------------------------------------------------------------------------------    
        when ST_WRITE_AND_REALLOCATE =>
          
          -- 
          shibi_oAv   <= shibi_oAv;
          shibi_oData <= shibi_oData;
          shibi_oComm <= shibi_oComm;
          shibi_oWe   <= shibi_oWe;
          -- sMMemAddr   <= sNewAddr;  --conv_std_logic_vector( , sMMemAddr'HIGH+1 );
          sRd_Ena     <= sRd_Ena;
          sWr_Ena     <= '0';           --(sRd_Ena and not hibi_iFull);
          sManip  <= sDataOut;

          ---------------------------------------------------------------
          -- NEW SEND MECHNISM INCLUDING DDR INITIALIZATION
          ---------------------------------------------------------------

          
          if(vRowCounter < V_PIXEL_COUNT) then

            if(vPixelCounter < H_PIXEL_COUNT) then

              if (vPixelCounter mod 4) = 0 and  vMsgAtribCnter = 4  then
                 if prevFlowState = ST_WRITE_AND_REALLOCATE then
                   vWordCnt := vWordCnt +1;  
                 end if;
             sMMemAddr <= conv_std_logic_vector(vWordCnt, sMMemAddr'high+1);    
                 sRd_Ena <= '1';         -- enable read form altsyncram
                -- sManip <= sDataOut;
               
                
               
              end if;
              

              
              case vMsgAtribCnter is
            when 4 =>                   -- DDR2 cfg param
              if ((hibi_iFull = '0') and (hibi_iOne_p_left = '0')) then
                shibi_oWe      <= '1';
                shibi_oAv      <= '1';
                shibi_oComm    <= HIBI_CMD_WR;
                shibi_oData    <= std_logic_vector(conv_unsigned(gDDR2F_BASE + 16#10#, gHIBI_DATA_WIDTH));
                vMsgAtribCnter := vMsgAtribCnter -1;
                -- sRd_Ena <= '1';         -- enable read form altsyncram
              else
                shibi_oWe <= '0';

              end if;

            when 3 =>                   -- byte_enable & data_count
              if ((hibi_iFull = '0') and (hibi_iOne_p_left = '0')) then
                shibi_oWe      <= '1';
                shibi_oAv      <= '0';
                vDataTmp := vDataTmp xor vDataTmp;
                vDataTmp((vRowCounter) mod 4) := '1';
                shibi_oData    <= '0' & vDataTmp & "000" & x"00001";
                vMsgAtribCnter := vMsgAtribCnter -1;
                sRd_Ena <= '0';         -- enable read form altsyncram
              else
                shibi_oWe <= '0'; 
                
              end if;

            when 2 =>                   -- DDR2 write address
              if ((hibi_iFull = '0') and (hibi_iOne_p_left = '0'))then
                shibi_oWe      <= '1';
                shibi_oAv   <= '0';
                shibi_oData     <= conv_std_logic_vector( gMANIP_FRAME_LOCATION_START+(vRowCounter+( vPixelCounter*V_PIXEL_COUNT ))/4, shibi_oData'HIGH+1 );
                vMsgAtribCnter := vMsgAtribCnter - 1;
              else
                shibi_oWe <= '0'; 

              end if;

            when 1 =>                   -- DDR2 input port
              
              if ((hibi_iFull = '0') and (hibi_iOne_p_left = '0'))then
                shibi_oWe      <= '1';
                shibi_oAv   <= '1';
                shibi_oData    <= std_logic_vector(conv_unsigned(gDDR2F_BASE, gHIBI_DATA_WIDTH));
                vMsgAtribCnter := vMsgAtribCnter -1;
              else
                shibi_oWe <= '0';   
              end if;

            when 0 =>
               -- data from altsyncram to DDR2
              if ((hibi_iFull = '0') and (hibi_iOne_p_left = '0'))then
                shibi_oWe      <= '1';
                vManipDataTmp := (others => '0');
                vManipDataTmp(((vRowCounter mod 4) +1)*8-1 downto ((vRowCounter) mod 4)*8 ):=
                  sManip(((vPixelCounter mod 4)+1)*8-1 downto (vPixelCounter mod 4)*8 );
                shibi_oData  <=  vManipDataTmp; 
                shibi_oAv   <= '0';
                vPixelCounter := vPixelCounter+1;
                vMsgAtribCnter := 4;
              else
                shibi_oWe <= '0'; 

              end if;
              
              when others => null;
                           
          end case;

              
  


            else                        -- read next row from raw image
              shibi_oWe <= '0';
              vMsgAtribCnter := 4;
              -- sFlowState     <= ST_SEND_RD_CMD;
              vPixelCounter := 0;
              vWordCnt := 0;
              vRowCounter := vRowCounter +1;
              if vRowCounter = V_PIXEL_COUNT then
                sFlowState     <= ST_IMAGE_READY;
                vMsgAtribCnter := 4;
                vRowCounter := 0;
                shibi_oComm <= HIBI_CMD_IDLE;
              else
                sFlowState <= ST_SEND_RD_CMD;
              end if;

            end if;
          else
            vMsgAtribCnter := 0;
            sFlowState     <= ST_IMAGE_READY;
          end if;


--        when ST_DELAY =>
--      if vMsgAtribCnter > 0 then
--        vMsgAtribCnter := vMsgAtribCnter -1;
--      else
--        sFlowState <= ST_IMAGE_READY;
--        vMsgAtribCnter := 4;
--      end if;
      
      

        when ST_IMAGE_READY =>

--    shibi_oAv   <= shibi_oAv;
--    --shibi_oData <= shibi_oData;
--         shibi_oComm <= shibi_oComm;
--        --  shibi_oRe   <= shibi_oRe;
--          -- shibi_oWe   <= shibi_oWe;
--          if ((hibi_iFull = '0') and (hibi_iOne_p_left = '0') and (vMsgAtribCnter = 4)) then  -- send rd command
--            shibi_oWe      <= '1';
--            shibi_oAv      <= '1';
--            shibi_oComm    <= HIBI_CMD_RD;
--            shibi_oData    <= std_logic_vector(conv_unsigned(gDDR2F_BASE + 16#10#, gHIBI_DATA_WIDTH));
--            vMsgAtribCnter := vMsgAtribCnter - 1;
--          elsif((hibi_iFull = '0'  and vMsgAtribCnter > 0) and hibi_iOne_p_left = '0' ) then  -- send rest of atributes
--           -- elsif((hibi_iEmpty = '0' and vMsgAtribCnter >= 0 and hibi_iAv = '0') or (shibi_oRe ='1' and hibi_iOne_d_left = '0')) then
--            shibi_oAv <= '0';

--            case vMsgAtribCnter is
--              when 4 =>
--                sFlowState <= ST_IMAGE_READY;
--              when 3 =>                 -- DMA initiation 
--                shibi_oWe <= '1';
--                shibi_oData    <= conv_std_logic_vector(16, gHIBI_DATA_WIDTH);
--                vMsgAtribCnter := vMsgAtribCnter - 1;
--              when 2 =>                 -- start adress of raw frame
--                shibi_oWe <= '1';
--                shibi_oData   <= conv_std_logic_vector(gMANIP_FRAME_LOCATION_START, gHIBI_DATA_WIDTH);
--                vMsgAtribCnter := vMsgAtribCnter - 1;
--              when 1 =>
--               -- my data input
--                shibi_oWe <= '1';
--                shibi_oData    <= conv_std_logic_vector(5, gHIBI_DATA_WIDTH);
--                vMsgAtribCnter := vMsgAtribCnter - 1;
--              when 0 =>                 -- address for read acknowledgement
--                shibi_oWe <= '0';
              
--              when others =>
--                vMsgAtribCnter := 0;
--                sFlowState     <= ST_ERR;
--            end case;
--          else
--            shibi_oWe <= '0';
--          if(vMsgAtribCnter = 0) then
--            vMsgAtribCnter := 4;
--            sFlowState     <= ST_DELAY; 
--          end if;
--      end if;



--              when ST_DELAY =>
    
     
--          shibi_oAv   <= shibi_oAv;
--          shibi_oData <= shibi_oData;
--          shibi_oComm <= shibi_oComm;
--          shibi_oRe   <= shibi_oRe;
--          shibi_oWe   <= shibi_oWe;

--          if (hibi_iFull = '0') and (hibi_iOne_p_left = '0') and (vMsgAtribCnter = 4) then  -- send rd command
--            shibi_oWe      <= '1';
--            shibi_oAv      <= '1';
--            shibi_oComm    <= HIBI_CMD_WR;
--            shibi_oData    <= std_logic_vector(conv_unsigned(16#41000000#, gHIBI_DATA_WIDTH));
--            vMsgAtribCnter := vMsgAtribCnter - 1;

--          elsif(hibi_iFull = '0' and vMsgAtribCnter > 0) then  -- send rest of atributes
--            shibi_oAv <= '0';
--            case vMsgAtribCnter is
--              when 3 =>                 -- DMA initiation 
                
--                shibi_oData    <= conv_std_logic_vector(17, shibi_oData'high+1);
--                vMsgAtribCnter := vMsgAtribCnter - 1;
               
--              when 2 =>                 -- read complited message
--                -- shibi_oData <= READ_COMPLATED;
--                sFlowState <= ST_IDLE;
--                vMsgAtribCnter := 3;
--              when others =>
               
--            end case;
--          end if;

          




    
          sFlowState <= ST_IDLE;
          vMsgAtribCnter := 3;




          ---------------------------------------------------------------------------------------------------------
        when ST_ERR =>
          -- flush RX fifo
          shibi_oRe <= '1';
          if(hibi_iEmpty = '1') then
            shibi_oRe      <= '0';
            vMsgAtribCnter := 3;
            sFlowState     <= ST_IDLE;
          end if;
          
        when others =>
          vMsgAtribCnter := 0;
          sFlowState     <= ST_ERR;
      end case;
    end if;
  end process;


end arch_pic_man;
--*****************************************************************************
-- END OF FILE
--*****************************************************************************
