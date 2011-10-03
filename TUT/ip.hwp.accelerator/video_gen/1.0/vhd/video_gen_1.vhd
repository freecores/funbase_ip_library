----------------------------------------------------------------------------------
-- Company:        Viconsys Oy
-- Engineer:        J.A
-- 
-- Create Date:    00:00:00 21/1/2010 
-- Design Name: 
-- Module Name:    video_gen_1 - Behavioral 
-- Project Name:   Funbase First Aplication
-- Target Devices: 
-- Tool versions: 
-- Description:    Generate test pattern video feed to HIBI bus.
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments:           STOPPING THE COUNTERS IF HIBI NOT AVAILABLE     
--                                  
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity video_gen_1 is

  generic (

    image_data_width : integer := 8;    -- bits!
    image_fps        : integer := 50;   -- Hz
    image_pattern_id : integer := 1;    -- test image pattern type  
                                        -- 1=Constant Squares, 2=T-letter, 3=Moving T-letter

    H_pixels_across : integer := 640;   -- Horizontal width
    V_pixels_down   : integer := 480;   -- Vertical height

    -- Hibi related: addresses and bus widths
    video_gen_1_addr_g         : integer;  -- Own address
    ddr2_controller_addr_g     : integer;  -- DDR2 controller address
    picture_manipulator_addr_g : integer;  -- Picture manipulator address

    data_width_g : integer := 32;
    comm_width_g : integer := 5 --3
    );

  port (
    rst_n : in std_logic;
    clk   : in std_logic;

    -- to HIBI
    hibi_av_out   : out std_logic;
    hibi_data_out : out std_logic_vector (data_width_g-1 downto 0);
    hibi_comm_out : out std_logic_vector (comm_width_g-1 downto 0);
    hibi_we_out   : out std_logic;
    hibi_full_in  : in  std_logic;
    hibi_one_p_in : in  std_logic;

    -- from HIBI
    hibi_av_in    : in  std_logic;
    hibi_data_in  : in  std_logic_vector (data_width_g-1 downto 0);
    hibi_comm_in  : in  std_logic_vector (comm_width_g-1 downto 0);
    hibi_re_out   : out std_logic;
    hibi_empty_in : in  std_logic;
    hibi_one_d_in : in  std_logic
    );

end video_gen_1;


architecture arc of video_gen_1 is

  signal pix_clk : std_logic;

  signal h_count_r       : integer range 0 to 1023;
  signal v_count_r       : integer range 0 to 1023;
  signal frame_counter_r : integer range 0 to 1023;

  signal x_move_r : integer range 0 to 1023;
  signal y_move_r : integer range 0 to 1023;


  signal image_data_i           : std_logic_vector(image_data_width - 1 downto 0);

  type states is (cfg_ddr_dma,
                  start,                -- FSM States
                  start_pic_gen,
                  send_picture,
                  picture_done,
                  inform_pic_manipulator,
                  wait_info_from_linux);

  signal state_r : states;


  signal picture_start_r : std_logic;
  signal hibi_full_r     : std_logic;

  
  signal we_r   : std_logic;
  signal re_r   : std_logic;
  signal av_r   : std_logic;
  signal data_r : std_logic_vector(data_width_g-1 downto 0);

  constant curr_pix_max_c      : integer := data_width_g/8-1;
  signal   curr_pix_r          : integer range 0 to curr_pix_max_c;

  constant ddr_dma_cfg_reg_offset_c : integer := 16#10#;
  signal   ddr_dma_cfg_param_r      : integer range 0 to 2;
  constant raw_frame_offset_c : integer := 16#100000#;  -- raw frame memory
                                                        -- offset 
  constant n_words_per_pic_c : integer := (H_pixels_across * V_pixels_down) / (data_width_g / 8);
  -- korjaa pyöristys! nyt esim 1*5/4 on 1 eikä 2!
   signal frame_ready_param_r : integer;
  -- Currently unused signals
  signal fail_r : std_logic;
  signal delay_between_pictures : integer range 0 to 1000000;
  signal x_count_r : integer range 0 to 1023;

begin

  ----------------------------------------------------------------
  -- PIXEL CLOCK
  ----------------------------------------------------------------

  -- aargh, delta-delay problem! => process frame will be executed _after_ others
--  pix_clk <= clk;  -- Try first with 50MHz..  -- PIX_CLK defines the video fps..

  --pix_clk      <= pix_clk_pll;        -- For other frequencies..
  --
  -- PLL for pixel clock frequencies.
  -- 
  -- video_PLL_inst : video_PLL PORT MAP (
  --                            inclk0  => clk,
  --                            c0              => pix_clk_pll);
  ----------------------------------------------------------------

  ----------------------------------------------------------------
  -- PROCESS FOR CALCULATING THE PICTURE SIZE
  ----------------------------------------------------------------
--  frame : process(rst_n, pix_clk)
  frame : process(rst_n, clk)
  begin

    if rst_n = '0' then                 -- asynchronous reset (active low)
--      counting_picture_r <= '0';        -- when powerup, delayed start counting the picture
      h_count_r          <= 0;
      v_count_r          <= 0;

    elsif (clk'event and clk = '1')then

      -- IF HIBI is available, keep counting.
      -- ELSE IF HIBI BUSS IS NOT AVAILABLE, STOP COUNTERS.
      if (hibi_full_r = '0') then
        
        if state_r = send_picture then
          -- 0  ----------------------> H_pixels_across
          -- |
          -- |
          -- |
          -- V_pixels_down ----------> H_pixels_across

          if (h_count_r = H_pixels_across-1) then  -- ES fixed off-by-one
            h_count_r            <= 0;
            if (v_count_r = V_pixels_down-1) then
              -- Whole frame complete
              v_count_r          <= 0;
--              counting_picture_r <= '0';
            else
              -- new horiz row starts
              v_count_r          <= v_count_r +1;
            end if;

          else                                                                  
            h_count_r          <= h_count_r + 1;  
            -- After start_counting_picture_r has been triggered,
            -- signal that tells we now keep counting the picture...
--            counting_picture_r <= '1';  
          end if;

          
        end if;  -- if state_r 
      end if;  -- if hibi_full_r = '1', we will stop the counters.
    end if;
  end process frame;
  ----------------------------------------------------------------



  ----------------------------------------------------------------
  -- PROCESS FOR GENERATING TEST IMAGE PATTERNS,  
  ----------------------------------------------------------------
    --ES, pilkoin kahdeksi prosessiksi
  pattern : process(h_count_r, v_count_r,
                    x_move_r, y_move_r
                    )
  begin
    if image_pattern_id = 1 then        -- 1. Constant Square pattern
      if (v_count_r >= V_pixels_down / 4 and
             h_count_r >= H_pixels_across / 4) then
        image_data_i <= (others => '1');  -- White

      elsif (v_count_r <= V_pixels_down / 2 and
             h_count_r <= H_pixels_across / 2) then
        image_data_i             <= (others => '0');
        image_data_i(image_data_width/2-1 downto 0) <= "1111";           -- Grey
      else
        image_data_i             <= (others => '0');  -- Black
      end if;


    elsif image_pattern_id = 2 then     -- 2. Constant T-letter

      if (h_count_r > 60 and
             h_count_r < 120 and
             v_count_r > 50 and
             v_count_r < 65) then
        image_data_i <= (others => '1');  -- White T-letter

      elsif (h_count_r > 80 and
             h_count_r < 100 and
             v_count_r > 50 and
             v_count_r < 100) then
        image_data_i <= (others => '1');  -- White T-letter

      else
        image_data_i <= (others => '0');  -- Black background
      end if;


    elsif image_pattern_id = 3 then     -- 3. Moving T-letter      

      if (h_count_r > 60 + x_move_r and
             h_count_r < 120 + x_move_r and
             v_count_r > 50 + y_move_r and
             v_count_r < 65 + y_move_r) then

        image_data_i <= (others => '1');  -- White T-letter, _-section

      elsif (h_count_r > 80 + x_move_r and
             h_count_r < 100 + x_move_r and
             v_count_r > 50 + y_move_r and
             v_count_r < 100 + y_move_r) then

        image_data_i <= (others => '1');  -- White T-letter, I-section
      else
        image_data_i <= (others => '0');  -- Black background         
      end if;

    else
      image_data_i <= (others => '0');
    end if;

    -- ES, dbg, put some very easy value
    -- image_data_i <= std_logic_vector(conv_unsigned(v_count_r, image_data_width));

  end process;


    --ES, pilkoin kahdeksi prosessiksi
  counters : process(clk, rst_n )     
  begin

    if rst_n = '0' then

      picture_start_r <= '0';
      x_move_r        <= 0;
      y_move_r        <= 0;

    elsif clk'event and clk = '1' then 
      
        -- FRAME COUNTER, increased at the start of a every frame
        if (h_count_r = 0 and v_count_r = 0) then
          picture_start_r <= '1';
--           -- frame_counter optimized away unless using
--           -- > vsim -novopt work.tb_video_gen_1
--           frame_counter_r <= frame_counter_r + 1;  -- entäs ylivuoto ?
        else
          picture_start_r <= '0';
        end if;
        


        if image_pattern_id = 3 and picture_start_r = '1' then
        -- T-letter moves one pixel to right/down at each frame
        -- First to the right and then down                  

          if x_move_r < 320 then
            x_move_r <= x_move_r + 1;
          else
            --  x_move_r <= 0;            -- ??
            x_move_r <= x_move_r;       -- ES: keeps x position?
          end if;

          if x_move_r = 319 then 
            if y_move_r >= 240 then
              y_move_r <= 0;
            else
              y_move_r <= y_move_r + 1;
            end if;
          end if;

        end if;                         -- pic_start

      end if;  -- rst_n

  end process counters;
  ----------------------------------------------------------------






  ----------------------------------------------------------------
  -- PROCESS FOR SENDING GENERATED DATA TO THE HIBI BUS
  ----------------------------------------------------------------
  fsm : process (clk, rst_n)
  begin  -- process fsm
    if rst_n = '0' then                 -- asynchronous reset (active low)
      state_r             <= cfg_ddr_dma; --start;
      we_r                <= '0';
      re_r                <= '0';
      av_r                <= '0';
      data_r              <= (others => 'Z');
      fail_r              <= '0';
-- start_counting_picture_r <= '0';     -- ES
      frame_counter_r     <= 0;
      curr_pix_r          <= 0;
      ddr_dma_cfg_param_r <= 0;
      frame_ready_param_r <= 0;

    elsif clk'event and clk = '1' then  -- rising clock edge

      case state_r is

        when cfg_ddr_dma => 

          re_r   <= '0';

          if (we_r = '1' and hibi_one_p_in = '1') or hibi_full_in = '1' then  -- mahdollisesti hukkuisi kuvadataa, jos väylä on varattu
            we_r                <= '0';
          else
            we_r                <= '1';

            case ddr_dma_cfg_param_r is
              when 0 =>
                av_r                <= '1';  -- address valid
                data_r              <= std_logic_vector (conv_unsigned(ddr2_controller_addr_g + ddr_dma_cfg_reg_offset_c, data_width_g));
                ddr_dma_cfg_param_r <= 1;

              when 1 =>
                av_r <=  '0';
                data_r <= x"7F800000"  or std_logic_vector (conv_unsigned(n_words_per_pic_c, data_width_g));
                ddr_dma_cfg_param_r <= 2;

              when 2 =>
                av_r    <= '0';
                data_r  <= std_logic_vector (conv_unsigned(ddr2_controller_addr_g + raw_frame_offset_c, data_width_g));
                state_r <= start;
                ddr_dma_cfg_param_r <= 0;       

                
              when others => null;
            end case;
          end if;
          
          
        
        when start =>                   -- AFTER RESET, and when COM Express linux, gives permission to start over again...
                                        -- Give HIBI wrapper the address of video_gen_1 component.
                                        -- This is only done once after reset.

          re_r   <= '0';
          av_r   <= '1';                -- address valid
          data_r <= std_logic_vector (conv_unsigned(ddr2_controller_addr_g, data_width_g));  -- kirjoitetaan osoite väylälle
          we_r   <= '1';

          if (we_r = '1' and hibi_one_p_in = '1') or hibi_full_in = '1' then  -- mahdollisesti hukkuisi kuvadataa, jos väylä on varattu
            we_r    <= '0';
            state_r <= start;           -- State on next clock cycle
          else          
            state_r <= start_pic_gen;     -- State on next clock cycle
          end if;
          --------------------------------------------------------


        when start_pic_gen =>
          -- Starting the counters and
--          -- feeding the 1st pixel of the picture to HIBI-bus        
--          start_counting_picture_r <= '1'; 
          av_r                     <= '0';  -- address NOT valid
          re_r                     <= '0';

          if (we_r = '1' and hibi_one_p_in = '1') or hibi_full_in = '1' then  -- mahdollisesti hukkuisi kuvadataa, jos väylä on varattu
            -- Cease sending for a moment if hibi wrappers FIFO is full.
            -- keskeytetään kuvan laskenta, siksi aikaa
            -- kunnes hibi väylä on taas vapaana lähetystä varten
--            we_r        <= '0';
            hibi_full_r <= '1';         -- keskeyttää kuvan laskurit.
          else
            -- HIBI väylä on vapaana, voidaan laskea kuvaa eteenpäin
            -- ja lähettää sitä väylälle.            
            hibi_full_r                           <= '0';
--             we_r                                  <= '1';
--             data_r                                <= (others => '0');  --ES
--             data_r(image_data_width - 1 downto 0) <= image_data_i;
          end if;

          we_r   <= '0';                -- 2010/03/19
          data_r <= (others => 'Z');    -- dbg, 2010/03/19
          curr_pix_r <= 0;

          
          state_r <= send_picture;      -- State on next clock cycle
          --------------------------------------------------------          

          
        when send_picture =>
--          start_counting_picture_r <= '0';      -- Process frame should allready now be started.
                                                -- Picture counters should be running
          av_r                     <= '0';      -- and there should be outgoing traffic at the HIBI-bus
          re_r                     <= '0';

          if (we_r = '1' and hibi_one_p_in = '1') or hibi_full_in = '1' then  -- mahdollisesti hukkuisi kuvadataa, jos väylä on varattu
            -- Cease sending for a moment if hibi wrappers FIFO is full.
            -- keskeytetään kuvan laskenta, siksi aikaa
            -- kunnes hibi väylä on taas vapaana lähetystä varten
            we_r <= '0';
            
            hibi_full_r <= '1';                 -- keskeyttää kuvan laskurit.

          else
            hibi_full_r <= '0';                 -- HIBI väylä on vapaana, voidaan laskea kuvaa eteenpäin
                                                -- ja lähettää sitä väylälle.

            
            -- Old way: one pixel at a time
--            we_r      <= '1';
--             data_r                                <= (others => '0');  --ES
--             data_r(image_data_width - 1 downto 0) <= image_data_i;

            -- New time, fil the word with pxesl before sending            
            data_r((curr_pix_r+1)*image_data_width - 1 downto curr_pix_r*image_data_width) <= image_data_i;

            if curr_pix_r = curr_pix_max_c then
              we_r       <= '1';
              curr_pix_r <= 0;
            else
              we_r       <= '0';
              curr_pix_r <= curr_pix_r+1;
            end if;


            

--             -- no idea what this is, so i removed it (ES, 2010/03/19)  
--             if (h_count_r = 1 and v_count_r = 1) then  -- Rising one extra bit to bus for telling that
--               data_r(image_data_width)              <= '1';  -- Active picture starts from 1, 1 coordinates.
--             else
--               data_r(image_data_width)              <= '0';  -- Active picture area started.
--             end if;


            if (h_count_r = H_pixels_across-1 and v_count_r = V_pixels_down-1) then  -- Active picture area ends.
              state_r         <= picture_done;  -- picture done, lets move on..
              frame_counter_r <= frame_counter_r + 1;  -- entäs ylivuoto ?
            else
              state_r <= send_picture;            -- Otherwise, stay at this state
            end if;                               -- and keep sending the image..

            
          end if;
          --------------------------------------------------------
          

        when picture_done =>
          re_r       <= '0';
          we_r       <= '1';
          av_r       <= '1';            -- address valid
          data_r     <= std_logic_vector (conv_unsigned(picture_manipulator_addr_g, data_width_g));  -- kirjoitetaan osoite väylälle
          curr_pix_r <= 0;

          if (we_r = '1' and hibi_one_p_in = '1') or hibi_full_in = '1' then
            state_r     <= picture_done;
            we_r        <= '0';
            hibi_full_r <= '1';         -- keskeyttää kuvan laskurit.
          else
            state_r     <= inform_pic_manipulator;  -- State on next clock cycle
          end if;
          ---------------------------------------------------------


        when inform_pic_manipulator =>
          re_r <= '0';
          we_r <= '1';
          av_r <= '0';               

          -- data_r <= x"00000001";       

          if (we_r = '1' and hibi_one_p_in = '1') or hibi_full_in = '1' then
            state_r     <=  inform_pic_manipulator;
            we_r        <= '0';
            hibi_full_r <= '1';         -- keskeyttää kuvan laskurit.
          else
          --  state_r <= wait_info_from_linux;
            case frame_ready_param_r is
            when 0  =>
              data_r <= x"00000001";
              frame_ready_param_r <= 1;
            when 1  =>
              data_r <= x"c0100000" ;
              frame_ready_param_r <= 2;
            when 2  =>
              data_r <= std_logic_vector (conv_unsigned(n_words_per_pic_c, data_width_g));
              frame_ready_param_r <= 0;
              state_r <= wait_info_from_linux;       
            when others => null;
          end case; 


          end if;

          
          ---------------------------------------------------------             



        when wait_info_from_linux =>
          av_r   <= '0';
          data_r <= (others       => 'Z');
          we_r   <= '0';

          --              if HIBI väylältä tulee nanonano then
          --                state_r <= start;
          --              else
          --                state_r <= wait_info_from_linux;
          --        end if;             

          -- Check if there is some data for us.
          if (re_r = '1' and hibi_one_d_in = '1') or hibi_empty_in = '1' then
            re_r <= '0';
          else
            re_r <= '1';
          end if;

          if re_r = '1' and hibi_av_in = '0' then

            if hibi_data_in = x"00000011" then  -- If received FF from the HIBI
              state_r <= cfg_ddr_dma; --start;                 -- COM Express card & Linux...
            else
              state_r <= wait_info_from_linux;
            end if;

          end if;

          -- IF NEXT TIME, NEXT FRAME SHOULD START AUTOMATICLY without COM express.........          
          --        if (h_count_r = 0 and v_count_r = 0) then  --Picture gen is counting at Coordinates 0, 0
          --                state_r <= start;
          --              else
          --                state_r <= picture_done;        
          --        end if;               
          ---------------------------------------------------------             

      end case;

    end if;
  end process fsm;


  -- Registered outputs

  hibi_comm_out <= '0' & we_r & "000"; --'0' & we_r & '0';
  hibi_data_out <= data_r;
  hibi_av_out   <= av_r;
  hibi_we_out   <= we_r;
  hibi_re_out   <= re_r;

end arc;





