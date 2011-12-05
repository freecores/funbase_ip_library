-- ***************************************************
-- File: de2_sdram_example.structural.vhd
-- Creation date: 01.12.2011
-- Creation time: 09:16:25
-- Description: 
-- Created by: ege
-- This file was generated with Kactus2 vhdl generator.
-- ***************************************************
library IEEE;
library std;

library work;
use work.all;
use IEEE.std_logic_1164.all;

entity de2_sdram_example is

	port (

                -- Interface: Chip
                Chip_sdram_address_out : out   std_logic_vector(11 downto 0);
                Chip_sdram_ba_out      : out   std_logic_vector(1 downto 0);
                Chip_sdram_cas_n_out   : out   std_logic;
                Chip_sdram_cke_out     : out   std_logic;
                Chip_sdram_cs_n_out    : out   std_logic;
                Chip_sdram_dqm_out     : out   std_logic_vector(1 downto 0);
                Chip_sdram_ras_n_out   : out   std_logic;
                Chip_sdram_we_n_out    : out   std_logic;
                Chip_sdram_data_inout  : inout std_logic_vector(15 downto 0);

		-- Interface: clk
		clk_CLK : in std_logic;

		-- Interface: LEDG
		LEDG_gpio_out : out std_logic_vector(8 downto 0);

		-- Interface: LEDR
		LEDR_gpio_out : out std_logic_vector(17 downto 0);

		-- Interface: rst_n
		rst_n_RESETn : in std_logic;

		-- Interface: sdram_clk
		sdram_clk_CLK : out std_logic;

		-- Interface: SW
		SW_gpio_in : in std_logic_vector(15 downto 0));

end de2_sdram_example;


architecture structural of de2_sdram_example is

	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationaddress_in : std_logic_vector(21 downto 0);
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationbusy_out : std_logic;
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationbyte_select_in : std_logic_vector(1 downto 0);
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationcommand_in : std_logic_vector(1 downto 0);
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationdata_amount_in : std_logic_vector(21 downto 0);
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationdata_in : std_logic_vector(15 downto 0);
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationdata_out : std_logic_vector(15 downto 0);
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationinput_empty_in : std_logic;
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationinput_one_d_in : std_logic;
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationinput_re_out : std_logic;
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationoutput_full_in : std_logic;
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationoutput_we_out : std_logic;
	signal de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationwrite_on_out : std_logic;

	-- SDRAM controller for A2V64S40CTP and compatible (e.g. Altera DE2 board) with interface optimized for simple HW applications.
	component de2_sdram
		generic (
			clk_freq_mhz_g : integer := 143 -- clk frequency in MHz

		);
		port (

			-- Interface: Application
			address_in : in std_logic_vector(21 downto 0);
			byte_select_in : in std_logic_vector(1 downto 0);
			command_in : in std_logic_vector(1 downto 0);
			data_amount_in : in std_logic_vector(21 downto 0);
			data_in : in std_logic_vector(15 downto 0);
			input_empty_in : in std_logic;
			input_one_d_in : in std_logic;
			output_full_in : in std_logic;
			busy_out : out std_logic;
			data_out : out std_logic_vector(15 downto 0);
			input_re_out : out std_logic;
			output_we_out : out std_logic;
			write_on_out : out std_logic;

			-- Interface: Chip
			-- IO to chip.
			sdram_address_out : out std_logic_vector(11 downto 0);
			sdram_ba_out : out std_logic_vector(1 downto 0);
			sdram_cas_n_out : out std_logic;
			sdram_cke_out : out std_logic;
			sdram_cs_n_out : out std_logic;
			sdram_dqm_out : out std_logic_vector(1 downto 0);
			sdram_ras_n_out : out std_logic;
			sdram_we_n_out : out std_logic;
			sdram_data_inout : inout std_logic_vector(15 downto 0);

			-- Interface: clk
			-- clk
			clk : in std_logic;

			-- Interface: rst_n
			-- rst_n
			rst_n : in std_logic

		);
	end component;

	-- Creates test data to SDRAM controller, reads it back and verifies it. LEDs show the status.
	component de2_sdram_tester
		port (

			-- Interface: clk
			-- clk
			clk : in std_logic;

			-- Interface: LEDG
			-- Green LED output (error status).
			LEDG : out std_logic_vector(8 downto 0);

			-- Interface: LEDR
			-- Red status leds (progress)
			LEDR : out std_logic_vector(17 downto 0);

			-- Interface: rst_n
			-- rst_n
			rst_n : in std_logic;

			-- Interface: sdram
			-- Connection to sdram controller application interface
			busy_in : in std_logic;
			data_in : in std_logic_vector(15 downto 0);
			input_re_in : in std_logic;
			output_we_in : in std_logic;
			write_on_in : in std_logic;
			address_out : out std_logic_vector(21 downto 0);
			byte_select_out : out std_logic_vector(1 downto 0);
			command_out : out std_logic_vector(1 downto 0);
			data_amount_out : out std_logic_vector(21 downto 0);
			data_out : out std_logic_vector(15 downto 0);
			input_empty_out : out std_logic;
			input_one_d_out : out std_logic;
			output_full_out : out std_logic;

			-- Interface: sdram_clk
			-- SDRAM clock. Have to route it this way because of limitations in IP-XACT.
			sdram_clk_out : out std_logic;

			-- Interface: SW
			-- 16 toggle switches
			SW : in std_logic_vector(15 downto 0)

		);
	end component;

	-- You can write vhdl code after this tag and it is saved through the generator.
	-- ##KACTUS2_BLACK_BOX_DECLARATIONS_BEGIN##
	-- ##KACTUS2_BLACK_BOX_DECLARATIONS_END##
	-- Stop writing your code after this tag.


begin

	-- You can write vhdl code after this tag and it is saved through the generator.
	-- ##KACTUS2_BLACK_BOX_ASSIGNMENTS_BEGIN##
	-- ##KACTUS2_BLACK_BOX_ASSIGNMENTS_END##
	-- Stop writing your code after this tag.

	de2_sdram_1 : de2_sdram
		port map (
			address_in(21 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationaddress_in(21 downto 0),
			busy_out => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationbusy_out,
			byte_select_in(1 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationbyte_select_in(1 downto 0),
			clk => clk_CLK,
			command_in(1 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationcommand_in(1 downto 0),
			data_amount_in(21 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationdata_amount_in(21 downto 0),
			data_in(15 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationdata_in(15 downto 0),
			data_out(15 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationdata_out(15 downto 0),
			input_empty_in => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationinput_empty_in,
			input_one_d_in => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationinput_one_d_in,
			input_re_out => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationinput_re_out,
			output_full_in => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationoutput_full_in,
			output_we_out => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationoutput_we_out,
			rst_n => rst_n_RESETn,
			sdram_address_out(11 downto 0) => Chip_sdram_address_out(11 downto 0),
			sdram_ba_out(1 downto 0) => Chip_sdram_ba_out(1 downto 0),
			sdram_cas_n_out => Chip_sdram_cas_n_out,
			sdram_cke_out => Chip_sdram_cke_out,
			sdram_cs_n_out => Chip_sdram_cs_n_out,
			sdram_data_inout(15 downto 0) => Chip_sdram_data_inout(15 downto 0),
			sdram_dqm_out(1 downto 0) => Chip_sdram_dqm_out(1 downto 0),
			sdram_ras_n_out => Chip_sdram_ras_n_out,
			sdram_we_n_out => Chip_sdram_we_n_out,
			write_on_out => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationwrite_on_out
		);

	de2_sdram_tester_1 : de2_sdram_tester
		port map (
			address_out(21 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationaddress_in(21 downto 0),
			busy_in => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationbusy_out,
			byte_select_out(1 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationbyte_select_in(1 downto 0),
			clk => clk_CLK,
			command_out(1 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationcommand_in(1 downto 0),
			data_amount_out(21 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationdata_amount_in(21 downto 0),
			data_in(15 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationdata_out(15 downto 0),
			data_out(15 downto 0) => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationdata_in(15 downto 0),
			input_empty_out => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationinput_empty_in,
			input_one_d_out => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationinput_one_d_in,
			input_re_in => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationinput_re_out,
			LEDG(8 downto 0) => LEDG_gpio_out(8 downto 0),
			LEDR(17 downto 0) => LEDR_gpio_out(17 downto 0),
			output_full_out => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationoutput_full_in,
			output_we_in => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationoutput_we_out,
			rst_n => rst_n_RESETn,
			sdram_clk_out => sdram_clk_CLK,
			SW(15 downto 0) => SW_gpio_in(15 downto 0),
			write_on_in => de2_sdram_tester_1_sdram_to_de2_sdram_1_Applicationwrite_on_out
		);

end structural;

