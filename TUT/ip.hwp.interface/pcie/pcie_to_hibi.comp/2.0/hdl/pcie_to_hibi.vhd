-------------------------------------------------------------------------------
-- Funbase IP library Copyright (C) 2011 TUT Department of Computer Systems
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
-- Title      : PCIe to HIBI
-- Project    : Funbase
-------------------------------------------------------------------------------
-- File       : pcie_to_hibi.vhd
-- Author     : Juha Arvio
-- Company    : TUT
-- Last update: 05.10.2011
-- Version    : 0.91
-- Platform   : 
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 13.10.2010   0.1     arvio     Created
-- 05.10.2011   0.91    arvio
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- synthesis translate_off
use std.textio.all;
use work.txt_util.all;
-- synthesis translate_on

entity pcie_to_hibi is

  generic ( HIBI_DATA_WIDTH : integer := 32;
            HIBI_COM_WIDTH : integer := 3;
            HIBI_COM_WR     : std_logic_vector(15 downto 0) := x"0000";
            HIBI_COM_RD     : std_logic_vector(15 downto 0) := x"0000";
            HIBI_COM_MSG_WR : std_logic_vector(15 downto 0) := x"0000";
--            HIBI_COM_MSG_RD : std_logic_vector(15 downto 0) := x"0000";
            
            HIBI_ADDR_SPACE_WIDTH : integer := 11;
            HIBI_RW_LENGTH_WIDTH  : integer := 16;
            
            PCIE_DATA_WIDTH       : integer := 128;
            PCIE_ADDR_WIDTH       : integer := 64;
            PCIE_LOWER_ADDR_WIDTH : integer := 7;
            PCIE_RW_LENGTH_WIDTH  : integer := 13;
            PCIE_ID_WIDTH         : integer := 16;
            PCIE_FUNC_WIDTH       : integer := 3;
            PCIE_TAG_WIDTH        : integer := 6;
            PKT_TAG_WIDTH         : integer := 8;
            PCIE_CRED_WIDTH       : integer := 66;
            
            PCIE_CPL_LENGTH_MIN : integer := 128;
            
            PCIE_FORCE_MAX_RW_LENGTH : integer := 0;
            PCIE_MAX_RW_LENGTH : integer := 256;
            
            PCIE_IRQ_WIDTH : integer := 5;
            PCIE_TC_WIDTH : integer := 3;
            
            ADDR_TO_LIMIT_WIDTH : integer := 12;
            
            P2H_ADDR_SPACES      : integer := 4;
            P2H_HDMA_ADDR_SPACES : integer := 1;
            
            HIBI_IF_ADDR : std_logic_vector(31 downto 0) := x"00000000";
            
            P2H_ADDR_0_WIDTH : integer := 1;
            P2H_ADDR_0_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_0_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_1_WIDTH : integer := 1;
            P2H_ADDR_1_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_1_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_2_WIDTH : integer := 1;
            P2H_ADDR_2_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_2_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_3_WIDTH : integer := 1;
            P2H_ADDR_3_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_3_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_4_WIDTH : integer := 1;
            P2H_ADDR_4_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_4_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_5_WIDTH : integer := 1;
            P2H_ADDR_5_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_5_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_6_WIDTH : integer := 1;
            P2H_ADDR_6_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_6_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            P2H_ADDR_7_WIDTH : integer := 1;
            P2H_ADDR_7_PCIE_BASE : std_logic_vector(63 downto 0) := x"0000000000000000";
            P2H_ADDR_7_HIBI_BASE : std_logic_vector(31 downto 0) := x"00000000";
            
            HDMA_REQS_MIN : integer := 2;
            
            H2P_WR_CHANS : integer := 32;
            H2P_RD_CHANS : integer := 128;
            P2H_WR_CHANS : integer := 128;
            P2H_RD_CHANS : integer := 32;
            USE_PCIE_DMA : integer := 1;
            USE_PERF_REGS : integer := 1 );

  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    clk_pcie : in std_logic;
    
    init_done_out : out std_logic;
    
    rx_st_data_i   : in std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
    rx_st_valid_i  : in std_logic;
    rx_st_sop_i    : in std_logic;
    rx_st_eop_i    : in std_logic;
    rx_st_empty_i  : in std_logic;
    rx_st_bardec_i : in std_logic_vector(7 downto 0);
--    rx_st_be_i     : in std_logic_vector(15 downto 0);
    rx_st_ready_o  : out std_logic;
    rx_st_mask_o   : out std_logic;
                   
    tx_st_sop_o   : out std_logic;
    tx_st_eop_o   : out std_logic;
    tx_st_empty_o : out std_logic;
    tx_st_valid_o : out std_logic;
    tx_st_data_o  : out std_logic_vector(PCIE_DATA_WIDTH-1 downto 0);
    tx_st_ready_i : in std_logic;
    txcred_i      : in std_logic_vector(PCIE_CRED_WIDTH-1 downto 0);
    
    app_msi_req_out : out std_logic;
    app_msi_ack_in  : in  std_logic;
    app_msi_tc_out  : out std_logic_vector(2 downto 0);
    app_msi_num_out : out std_logic_vector(4 downto 0);
--    pex_msi_num_out : out std_logic_vector(4 downto 0);
--    app_int_sts_out : out std_logic;
--    app_int_ack_in  : in  std_logic;
    
    tl_cfg_add    : in std_logic_vector(3 downto 0);
    tl_cfg_ctl    : in std_logic_vector(31 downto 0);
    tl_cfg_ctl_wr : in  std_logic;
    
    lmi_data_in  : in std_logic_vector(31 downto 0);
    lmi_re_out   : out std_logic;
    lmi_we_out   : out std_logic;
    lmi_ack_in   : in  std_logic;
    lmi_addr_out : out std_logic_vector(11 downto 0);
    lmi_data_out : out std_logic_vector(31 downto 0);

    
    hibi_addr_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_data_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_comm_in  : in  std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_empty_in : in  std_logic;
    hibi_re_out   : out std_logic;

    hibi_addr_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_data_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_comm_out : out std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_full_in  : in  std_logic;
    hibi_we_out   : out std_logic;

    hibi_msg_addr_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_data_in  : in  std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_comm_in  : in  std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_msg_empty_in : in  std_logic;
    hibi_msg_re_out   : out std_logic;

    hibi_msg_data_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_addr_out : out std_logic_vector(HIBI_DATA_WIDTH - 1 downto 0);
    hibi_msg_comm_out : out std_logic_vector(HIBI_COM_WIDTH-1 downto 0);
    hibi_msg_full_in  : in  std_logic;
    hibi_msg_we_out   : out std_logic;
    
    dummy_debug_out   : out std_logic;
    debug_out         : out std_logic );

end pcie_to_hibi;

architecture rtl of pcie_to_hibi is

  function maximum (L : integer; R : integer) return integer is
  begin
    if L > R then
      return L;
    else
      return R;
    end if;
  end;
  
  function min (L : integer; R : integer) return integer is
  begin
    if L < R then
      return L;
    else
      return R;
    end if;
  end;
  
  function log2_ceil(N : natural) return positive is
  begin
    if N < 2 then
      return 1;
    else
      return 1 + log2_ceil(N/2);
    end if;
  end;
  
  constant ENABLE_SIM : integer := 0
  -- synthesis translate_off
  + 1
  -- synthesis translate_on
  ;
  
  constant HCOM_WR : std_logic_vector(HIBI_COM_WIDTH-1 downto 0) := HIBI_COM_WR(HIBI_COM_WIDTH-1 downto 0);
  constant HCOM_RD : std_logic_vector(HIBI_COM_WIDTH-1 downto 0) := HIBI_COM_RD(HIBI_COM_WIDTH-1 downto 0);
  constant HCOM_MSG_WR : std_logic_vector(HIBI_COM_WIDTH-1 downto 0) := HIBI_COM_MSG_WR(HIBI_COM_WIDTH-1 downto 0);
--  constant HCOM_MSG_RD : std_logic_vector(HIBI_COM_WIDTH-1 downto 0) := HIBI_COM_MSG_RD(HIBI_COM_WIDTH-1 downto 0);
  
  constant PCIE_TAGS : integer := 2**PCIE_TAG_WIDTH;
  constant PCIE_RD_LENGTH_WIDTH : integer := log2_ceil(256);
  
  constant CYCLES_IN_SEC : integer := 100000000;
  constant CYCLES_IN_SEC_WIDTH : integer := log2_ceil(CYCLES_IN_SEC);
  
  constant IN_SYS_PROBE_WIDTH  : integer := CYCLES_IN_SEC_WIDTH*2;
  constant IN_SYS_SOURCE_WIDTH : integer := 0;
  
  signal hibi_if_init_done : std_logic;
  
  
  signal ipkt_is_write : std_logic;
  signal ipkt_is_read_req : std_logic;
  signal ipkt_is_rdata : std_logic;
  signal ipkt_addr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal ipkt_dma_addr_to_limit : std_logic_vector(ADDR_TO_LIMIT_WIDTH-1 downto 0);
  signal ipkt_length : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal ipkt_tag : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  signal ipkt_bar : std_logic_vector(2 downto 0);
  signal ipkt_req_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal ipkt_valid : std_logic;
  signal ipkt_re : std_logic;
  signal ipkt_data : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  
  signal ipkt_dma_is_write : std_logic;
  signal ipkt_dma_is_read_req : std_logic;
  signal ipkt_dma_is_rdata : std_logic;
  signal ipkt_dma_addr : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  signal ipkt_dma_length : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal ipkt_dma_tag : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  signal ipkt_dma_req_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal ipkt_dma_valid : std_logic;
  signal ipkt_dma_re : std_logic;
  signal ipkt_dma_data : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  
  signal opkt_is_write : std_logic;
  signal opkt_is_read_req : std_logic;
  signal opkt_is_rdata : std_logic;
  signal opkt_addr : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal opkt_length : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal opkt_tag : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  signal opkt_req_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal opkt_ready : std_logic;
  signal opkt_wdata_req : std_logic;
  signal opkt_we : std_logic;
  signal opkt_burst_we : std_logic;
  signal opkt_data : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  
  signal opkt_dma_is_write : std_logic;
  signal opkt_dma_is_read_req : std_logic;
  signal opkt_dma_is_rdata : std_logic;
  signal opkt_dma_addr : std_logic_vector(PCIE_ADDR_WIDTH-1 downto 0);
  signal opkt_dma_length : std_logic_vector(PCIE_RW_LENGTH_WIDTH-1 downto 0);
  signal opkt_dma_tag : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  signal opkt_dma_req_id : std_logic_vector(PCIE_ID_WIDTH-1 downto 0);
  signal opkt_dma_ready : std_logic;
  signal opkt_dma_wdata_req : std_logic;
  signal opkt_dma_we : std_logic;
  signal opkt_dma_burst_we : std_logic;
  signal opkt_dma_data : std_logic_vector(HIBI_DATA_WIDTH-1 downto 0);
  
  signal pcie_irq : std_logic;
  signal pcie_dma_irq : std_logic;
  signal pcie_dma_irq_number : std_logic_vector(PCIE_IRQ_WIDTH-1 downto 0);
  signal pcie_dma_irq_tc : std_logic_vector(PCIE_TC_WIDTH-1 downto 0);
  signal pcie_irq_full : std_logic;
  signal pcie_dma_irq_ack : std_logic;
  
  signal tx_st_ready : std_logic;
  
  --synthesis translate_off
  constant DEBUG_CNT : integer := 256;
  constant DEBUG_CNT_WIDTH : integer := log2_ceil(DEBUG_CNT-1);
  
  signal debug_cnt_r : std_logic_vector(DEBUG_CNT_WIDTH-1 downto 0);
  signal debug_ena_r : std_logic;
  --synthesis translate_on
  
  signal tag_reserve : std_logic;
  signal tag_reserve_ready : std_logic;
  signal tag_reserve_res : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
  signal tag_reserve_amount : std_logic_vector(PCIE_RD_LENGTH_WIDTH-1 downto 0);
  signal tag_reserve_data : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  
  signal tag_release : std_logic;
  signal tag_release_ready : std_logic;
  signal tag_release_res : std_logic_vector(PCIE_TAG_WIDTH-1 downto 0);
  signal tag_release_amount : std_logic_vector(PCIE_RD_LENGTH_WIDTH-1 downto 0);
  signal tag_release_data : std_logic_vector(PKT_TAG_WIDTH-1 downto 0);
  
  signal in_sys_probe  : std_logic_vector(CYCLES_IN_SEC_WIDTH*3-1 downto 0);
--  signal in_sys_source : std_logic_vector(CYCLES_IN_SEC_WIDTH-1 downto 0);
  signal dma_writes_in_sec : std_logic_vector(CYCLES_IN_SEC_WIDTH-1 downto 0);
  signal dma_reads_in_sec : std_logic_vector(CYCLES_IN_SEC_WIDTH-1 downto 0);
  signal dma_write_to_read_cycles : std_logic_vector(CYCLES_IN_SEC_WIDTH-1 downto 0);
begin
  
  --synthesis translate_off
--   debug_gen_0 : if DEBUG = 1 generate
--   process
--   begin
--     report "---------------------------------------------------";
--     report "";
--     report "WRITE_CHANNELS_WIDTH: " & str(WRITE_CHANNELS_WIDTH);
--     report "READ_CHANNELS_WIDTH: " & str(READ_CHANNELS_WIDTH);
--     report "maximum(WRITE_CHANNELS, READ_CHANNELS)*2: " & str(maximum(WRITE_CHANNELS, READ_CHANNELS)*2);
--     report "---------------------------------------------------";
--     wait until DEBUG = 0;
--   end process;
--   end generate;
  --synthesis translate_on
  
  gen_in_sys_sp : if ((USE_PCIE_DMA = 1) and (ENABLE_SIM = 0)) generate
  in_sys_probe <= dma_write_to_read_cycles & dma_reads_in_sec & dma_writes_in_sec;
  
  alt_in_sys_sp_0 : entity work.alt_in_sys_sp 
  generic map (
	  INSTANCE_INDEX => 1,
    PROBE_WIDTH    => CYCLES_IN_SEC_WIDTH*3,
    SOURCE_WIDTH   => 0 )
  port map (
    probe => in_sys_probe );
--    source => in_sys_source );
  end generate;
  
  --synthesis translate_off
  process (clk_pcie, rst_n)
  begin
    if (rst_n = '0') then
      debug_cnt_r <= (others => '0');
      debug_ena_r <= '0';
      
    elsif (clk_pcie'event and clk_pcie = '1') then
      if (debug_cnt_r = (DEBUG_CNT-1)) then
        debug_cnt_r <= (others => '0');
        debug_ena_r <= '1';
      else
        debug_cnt_r <= debug_cnt_r + 1;
        debug_ena_r <= '0';
      end if;
    end if;
  end process;
  --synthesis translate_on
  
  tx_st_ready <= tx_st_ready_i
  --synthesis translate_off
--  and debug_ena_r
  --synthesis translate_on
  ;
  
  init_done_out <= hibi_if_init_done;

  pcie_rx_0 : entity work.pcie_rx
  generic map ( HIBI_DATA_WIDTH => HIBI_DATA_WIDTH,
                PCIE_DATA_WIDTH => PCIE_DATA_WIDTH,
                PCIE_ADDR_WIDTH => PCIE_ADDR_WIDTH,
                PKT_TAG_WIDTH => PKT_TAG_WIDTH,
                PCIE_RW_LENGTH_WIDTH => PCIE_RW_LENGTH_WIDTH,
                PCIE_RD_LENGTH_WIDTH => PCIE_RD_LENGTH_WIDTH )

  port map (
    clk_pcie => clk_pcie,
    clk => clk,
    rst_n => rst_n,
    
    pcie_rx_data_in => rx_st_data_i,    
	  pcie_rx_valid_in => rx_st_valid_i,  
	  pcie_rx_sop_in => rx_st_sop_i,      
	  pcie_rx_eop_in => rx_st_eop_i,      
	  pcie_rx_empty_in => rx_st_empty_i,  
    pcie_rx_bardec_in => rx_st_bardec_i,
--	  pcie_rx_be_in => ,                 
	  pcie_rx_ready_out => rx_st_ready_o,  
	  pcie_rx_mask_out => rx_st_mask_o,    
    
--    tag_fifo_re_out => tag_fifo_re,
--    tag_fifo_empty_in => tag_fifo_empty,
--    tag_fifo_data_in => tag_fifo_rdata,
    
    ipkt_is_write_out => ipkt_is_write,
    ipkt_is_read_req_out => ipkt_is_read_req,
    ipkt_is_rdata_out => ipkt_is_rdata,
    ipkt_addr_out => ipkt_addr,
    ipkt_length_out => ipkt_length,
    ipkt_req_id_out => ipkt_req_id,
    ipkt_tag_out => ipkt_tag,
    ipkt_bar_out => ipkt_bar,
    ipkt_valid_out => ipkt_valid,
    ipkt_re_in => ipkt_dma_re,
    ipkt_data_out => ipkt_data,
    
    tag_release_out => tag_release,
    tag_release_ready_in => tag_release_ready,
    tag_release_res_out => tag_release_res,
    tag_release_amount_out => tag_release_amount,
    tag_release_data_in => tag_release_data );
--    debug_out => debug_out );
  
  pcie_tx_0 : entity work.pcie_tx
  generic map ( HIBI_DATA_WIDTH => HIBI_DATA_WIDTH,
                PCIE_DATA_WIDTH => PCIE_DATA_WIDTH,
                PCIE_ADDR_WIDTH => PCIE_ADDR_WIDTH,
                PCIE_CRED_WIDTH => PCIE_CRED_WIDTH,
                PKT_TAG_WIDTH => PKT_TAG_WIDTH,
                PCIE_RW_LENGTH_WIDTH => PCIE_RW_LENGTH_WIDTH,
                PCIE_FORCE_MAX_RW_LENGTH => PCIE_FORCE_MAX_RW_LENGTH,
                PCIE_MAX_RW_LENGTH => PCIE_MAX_RW_LENGTH,
                PCIE_RD_LENGTH_WIDTH => PCIE_RD_LENGTH_WIDTH )
  
  port map (
    clk_pcie => clk_pcie,
    clk => clk,
    rst_n => rst_n,
    
    pcie_tx_data_out => tx_st_data_o,  
	  pcie_tx_valid_out  => tx_st_valid_o,
	  pcie_tx_sop_out => tx_st_sop_o,
	  pcie_tx_eop_out => tx_st_eop_o,
	  pcie_tx_empty_out => tx_st_empty_o,
    pcie_tx_cred_in => txcred_i,
	  pcie_tx_ready_in => tx_st_ready,
    
--    tag_fifo_we_out => tag_fifo_we,
--    tag_fifo_full_in => tag_fifo_full,
--    tag_fifo_data_out => tag_fifo_wdata,
    
    opkt_is_write_in => opkt_dma_is_write,
    opkt_is_read_req_in => opkt_dma_is_read_req,
    opkt_is_rdata_in => opkt_dma_is_rdata,
    opkt_addr_in => opkt_dma_addr,
    opkt_length_in => opkt_dma_length,
    opkt_tag_in => opkt_dma_tag,
    opkt_req_id_in => opkt_dma_req_id,
    
    opkt_ready_out => opkt_ready,
    
--    opkt_wdata_req_out => opkt_wdata_req,
    
    opkt_we_in => opkt_dma_we,
    opkt_burst_we_in => opkt_dma_burst_we,
    opkt_data_in => opkt_dma_data,
    
    pcie_irq_in => pcie_dma_irq,
    pcie_irq_number_in => pcie_dma_irq_number,
    pcie_irq_tc_in => pcie_dma_irq_tc,
    pcie_irq_full_out => pcie_irq_full,
    
    app_msi_req_out => app_msi_req_out,
    app_msi_ack_in => app_msi_ack_in,
    app_msi_tc_out => app_msi_tc_out,
    app_msi_num_out => app_msi_num_out,
--    pex_msi_num_out => pex_msi_num_out,
--    app_int_sts_out => app_int_sts_out,
--    app_int_ack_in => app_int_ack_in,
    
    tl_cfg_add => tl_cfg_add,
    tl_cfg_ctl => tl_cfg_ctl,
    tl_cfg_ctl_wr => tl_cfg_ctl_wr,
    
    lmi_data_in => lmi_data_in,
    lmi_re_out => lmi_re_out,
    lmi_we_out => lmi_we_out,
    lmi_ack_in => lmi_ack_in,
    lmi_addr_out => lmi_addr_out,
    lmi_data_out => lmi_data_out,
    
    tag_reserve_out => tag_reserve,
    tag_reserve_ready_in => tag_reserve_ready,
    tag_reserve_res_in => tag_reserve_res,
    tag_reserve_amount_out => tag_reserve_amount,
    tag_reserve_data_out => tag_reserve_data );
  
  gen_0 : if (USE_PCIE_DMA = 0) generate
  ipkt_dma_is_write <= ipkt_is_write;
  ipkt_dma_is_read_req <= ipkt_is_read_req;
  ipkt_dma_is_rdata <= ipkt_is_rdata;
  ipkt_dma_addr <= ipkt_addr;
  ipkt_dma_length <= ipkt_length;
  ipkt_dma_req_id <= ipkt_req_id;
  ipkt_dma_tag <= ipkt_tag;
  ipkt_dma_valid <= ipkt_valid;
  ipkt_dma_data <= ipkt_data;
--  ipkt_dma_bar <= ipkt_bar;
  ipkt_dma_re <= ipkt_re;
  
  opkt_dma_is_write <= opkt_is_write;
  opkt_dma_is_read_req <= opkt_is_read_req;
  opkt_dma_is_rdata <= opkt_is_rdata;
  opkt_dma_addr <= opkt_addr;
  opkt_dma_length <= opkt_length;
  opkt_dma_tag <= opkt_tag;
  opkt_dma_req_id <= opkt_req_id;
  opkt_dma_we <= opkt_we;
  opkt_dma_data <= opkt_data;
  opkt_dma_we <= opkt_we;
  opkt_dma_burst_we <= opkt_burst_we;
  end generate;
  
  gen_1 : if (USE_PCIE_DMA = 1) generate
  pcie_dma_0 : entity work.pcie_dma
  generic map ( HIBI_DATA_WIDTH => HIBI_DATA_WIDTH,
                HIBI_RW_LENGTH_WIDTH => HIBI_RW_LENGTH_WIDTH,
                
                PCIE_RW_LENGTH_WIDTH => PCIE_RW_LENGTH_WIDTH,
                PCIE_ID_WIDTH => PCIE_ID_WIDTH,
                PCIE_TAG_WIDTH => PCIE_TAG_WIDTH,
                PKT_TAG_WIDTH => PKT_TAG_WIDTH,
                
                PCIE_DATA_WIDTH => PCIE_DATA_WIDTH,
                PCIE_ADDR_WIDTH => PCIE_ADDR_WIDTH,
                PCIE_LOWER_ADDR_WIDTH => PCIE_LOWER_ADDR_WIDTH,
                DMA_BAR => 2,
                
                CYCLES_IN_SEC => CYCLES_IN_SEC,
                CYCLES_IN_SEC_WIDTH => CYCLES_IN_SEC_WIDTH,
                PERF_REGS => USE_PERF_REGS )
  
  port map ( clk => clk,
    rst_n => rst_n,
    
    ipkt_is_write_in => ipkt_is_write,
    ipkt_is_read_req_in => ipkt_is_read_req,
    ipkt_is_rdata_in => ipkt_is_rdata,
    ipkt_addr_in => ipkt_addr,
    ipkt_length_in => ipkt_length,
    ipkt_req_id_in => ipkt_req_id,
    ipkt_tag_in => ipkt_tag,
    ipkt_valid_in => ipkt_valid,
    ipkt_data_in => ipkt_data,
    ipkt_bar_in => ipkt_bar,
    
    ipkt_is_write_out => ipkt_dma_is_write,
    ipkt_is_read_req_out => ipkt_dma_is_read_req,
    ipkt_is_rdata_out => ipkt_dma_is_rdata,
    ipkt_addr_out => ipkt_dma_addr,
    ipkt_addr_to_limit_out => ipkt_dma_addr_to_limit,
    ipkt_length_out => ipkt_dma_length,
    ipkt_req_id_out => ipkt_dma_req_id,
    ipkt_tag_out => ipkt_dma_tag,
    ipkt_valid_out => ipkt_dma_valid,
    ipkt_data_out => ipkt_dma_data,
    
    ipkt_re_out => ipkt_dma_re,
    
    ipkt_re_in => ipkt_re,
    
    opkt_is_write_in => opkt_is_write,
    opkt_is_read_req_in => opkt_is_read_req,
    opkt_is_rdata_in => opkt_is_rdata,
    opkt_addr_in => opkt_addr,
    opkt_length_in => opkt_length,
    opkt_tag_in => opkt_tag,
    opkt_req_id_in => opkt_req_id,
    opkt_we_in => opkt_we,
    opkt_burst_we_in => opkt_burst_we,
    opkt_data_in => opkt_data,
    
    opkt_is_write_out => opkt_dma_is_write,
    opkt_is_read_req_out => opkt_dma_is_read_req,
    opkt_is_rdata_out => opkt_dma_is_rdata,
    opkt_addr_out => opkt_dma_addr,
    opkt_length_out => opkt_dma_length,
    opkt_tag_out => opkt_dma_tag,
    opkt_req_id_out => opkt_dma_req_id,
    opkt_we_out => opkt_dma_we,
    opkt_burst_we_out => opkt_dma_burst_we,
    opkt_data_out => opkt_dma_data,
    
    opkt_ready_out => opkt_dma_ready,
    opkt_ready_in => opkt_ready,
    
--    opkt_wdata_req_in => opkt_wdata_req,
--    opkt_wdata_req_out => opkt_dma_wdata_req,
    
    irq_in => pcie_irq,
    dma_irq_out => pcie_dma_irq,
    dma_irq_number_out => pcie_dma_irq_number,
    dma_irq_info_out => pcie_dma_irq_tc,
    irq_full_in => pcie_irq_full,
    
    dummy_debug_out => dummy_debug_out,
    debug_out => debug_out,
    
    dma_writes_in_sec_out => dma_writes_in_sec,
    dma_reads_in_sec_out => dma_reads_in_sec,
    dma_write_to_read_cycles_out => dma_write_to_read_cycles );
--    dma_irq_ack_out => pcie_dma_irq_ack );
  end generate;
  
  hibi_if_0 : entity work.hibi_if
  generic map ( HIBI_DATA_WIDTH => HIBI_DATA_WIDTH,
                HIBI_COM_WIDTH  => HIBI_COM_WIDTH,
                HIBI_COM_WR     => HIBI_COM_WR,
                HIBI_COM_RD     => HIBI_COM_RD,
                HIBI_COM_MSG_WR => HIBI_COM_MSG_WR,
--                HIBI_COM_MSG_RD => HIBI_COM_MSG_RD,
                
                HIBI_ADDR_SPACE_WIDTH => HIBI_ADDR_SPACE_WIDTH,
                HIBI_RW_LENGTH_WIDTH => HIBI_RW_LENGTH_WIDTH,
                
                PCIE_DATA_WIDTH       => PCIE_DATA_WIDTH,
                PCIE_ADDR_WIDTH       => PCIE_ADDR_WIDTH,
                PCIE_LOWER_ADDR_WIDTH => PCIE_LOWER_ADDR_WIDTH,
                PCIE_RW_LENGTH_WIDTH  => PCIE_RW_LENGTH_WIDTH,
                PCIE_ID_WIDTH         => PCIE_ID_WIDTH,
                PCIE_FUNC_WIDTH       => PCIE_FUNC_WIDTH,
                PCIE_TAG_WIDTH        => PCIE_TAG_WIDTH,
                PKT_TAG_WIDTH => PKT_TAG_WIDTH,
                
                ADDR_TO_LIMIT_WIDTH => ADDR_TO_LIMIT_WIDTH,
                
                PCIE_CPL_LENGTH_MIN => PCIE_CPL_LENGTH_MIN,
                
                P2H_ADDR_SPACES => P2H_ADDR_SPACES,
                P2H_HDMA_ADDR_SPACES => P2H_HDMA_ADDR_SPACES,
                
                HIBI_IF_ADDR => HIBI_IF_ADDR,
                
                P2H_ADDR_0_WIDTH => P2H_ADDR_0_WIDTH,
                P2H_ADDR_0_PCIE_BASE => P2H_ADDR_0_PCIE_BASE,
                P2H_ADDR_0_HIBI_BASE => P2H_ADDR_0_HIBI_BASE,
                P2H_ADDR_1_WIDTH => P2H_ADDR_1_WIDTH,
                P2H_ADDR_1_PCIE_BASE => P2H_ADDR_1_PCIE_BASE,
                P2H_ADDR_1_HIBI_BASE => P2H_ADDR_1_HIBI_BASE,
                P2H_ADDR_2_WIDTH => P2H_ADDR_2_WIDTH,
                P2H_ADDR_2_PCIE_BASE => P2H_ADDR_2_PCIE_BASE,
                P2H_ADDR_2_HIBI_BASE => P2H_ADDR_2_HIBI_BASE,
                P2H_ADDR_3_WIDTH => P2H_ADDR_3_WIDTH,
                P2H_ADDR_3_PCIE_BASE => P2H_ADDR_3_PCIE_BASE,
                P2H_ADDR_3_HIBI_BASE => P2H_ADDR_3_HIBI_BASE,
                P2H_ADDR_4_WIDTH => P2H_ADDR_4_WIDTH,
                P2H_ADDR_4_PCIE_BASE => P2H_ADDR_4_PCIE_BASE,
                P2H_ADDR_4_HIBI_BASE => P2H_ADDR_4_HIBI_BASE,
                P2H_ADDR_5_WIDTH => P2H_ADDR_5_WIDTH,
                P2H_ADDR_5_PCIE_BASE => P2H_ADDR_5_PCIE_BASE,
                P2H_ADDR_5_HIBI_BASE => P2H_ADDR_5_HIBI_BASE,
                P2H_ADDR_6_WIDTH => P2H_ADDR_6_WIDTH,
                P2H_ADDR_6_PCIE_BASE => P2H_ADDR_6_PCIE_BASE,
                P2H_ADDR_6_HIBI_BASE => P2H_ADDR_6_HIBI_BASE,
                P2H_ADDR_7_WIDTH => P2H_ADDR_7_WIDTH,
                P2H_ADDR_7_PCIE_BASE => P2H_ADDR_7_PCIE_BASE,
                P2H_ADDR_7_HIBI_BASE => P2H_ADDR_7_HIBI_BASE,
                
                HDMA_REQS_MIN => HDMA_REQS_MIN,
            
                H2P_WR_CHANS => H2P_WR_CHANS,
                H2P_RD_CHANS => H2P_RD_CHANS,
                P2H_WR_CHANS => P2H_WR_CHANS,
                P2H_RD_CHANS => P2H_RD_CHANS )

  port map (
    clk   => clk,
    rst_n => rst_n,
    
    init_done_out => hibi_if_init_done,
    
    
    ipkt_is_write_in => ipkt_dma_is_write,
    ipkt_is_read_req_in => ipkt_dma_is_read_req,
    ipkt_is_rdata_in => ipkt_dma_is_rdata,
    ipkt_addr_in => ipkt_dma_addr,
    ipkt_addr_to_limit_in => ipkt_dma_addr_to_limit,
    ipkt_length_in => ipkt_dma_length,
    ipkt_tag_in => ipkt_dma_tag,
    ipkt_req_id_in => ipkt_dma_req_id,
    
    ipkt_valid_in => ipkt_dma_valid,
    ipkt_re_out => ipkt_re,
    ipkt_data_in => ipkt_dma_data,
    
    opkt_is_write_out => opkt_is_write,
    opkt_is_read_req_out => opkt_is_read_req,
    opkt_is_rdata_out => opkt_is_rdata,
    opkt_addr_out => opkt_addr,
    opkt_length_out => opkt_length,
    opkt_req_id_out => opkt_req_id,
    opkt_tag_out => opkt_tag,
    
    opkt_ready_in => opkt_dma_ready,
--    opkt_wdata_req_in => opkt_dma_wdata_req,
    opkt_we_out => opkt_we,
    opkt_burst_we_out => opkt_burst_we,
    opkt_data_out => opkt_data,
    
    irq_out => pcie_irq,
    irq_ack_in => '0', --pcie_dma_irq_ack,
    
    hibi_addr_in => hibi_addr_in,
    hibi_data_in => hibi_data_in,
    hibi_comm_in => hibi_comm_in,
    hibi_empty_in => hibi_empty_in,
    hibi_re_out => hibi_re_out,

    hibi_addr_out => hibi_addr_out,
    hibi_data_out => hibi_data_out,
    hibi_comm_out => hibi_comm_out,
    hibi_full_in => hibi_full_in,
    hibi_we_out => hibi_we_out,

    hibi_msg_addr_in => hibi_msg_addr_in,
    hibi_msg_data_in => hibi_msg_data_in,
    hibi_msg_comm_in => hibi_msg_comm_in,
    hibi_msg_empty_in => hibi_msg_empty_in,
    hibi_msg_re_out => hibi_msg_re_out,

    hibi_msg_data_out => hibi_msg_data_out,
    hibi_msg_addr_out => hibi_msg_addr_out,
    hibi_msg_comm_out => hibi_msg_comm_out,
    hibi_msg_full_in => hibi_msg_full_in,
    hibi_msg_we_out => hibi_msg_we_out );
  
  tag_mutex : entity work.multi_mutex
 	generic map ( RESOURCES => PCIE_TAGS,
                RESOURCES_WIDTH => PCIE_TAG_WIDTH,
                RES_DATA_WIDTH => PKT_TAG_WIDTH,
                RES_AMOUNT_WIDTH => PCIE_RD_LENGTH_WIDTH )
  
  port map ( clk_rsv => clk_pcie,
 	           clk_rls => clk,
             rst_n => rst_n,
             
             reserve_in => tag_reserve,
             reserve_ready_out => tag_reserve_ready,
             reserve_res_out => tag_reserve_res,
             reserve_amount_in => tag_reserve_amount,
             reserve_data_in => tag_reserve_data,
             
             release_in => tag_release,
             release_ready_out => tag_release_ready,
             release_res_in => tag_release_res,
             release_amount_in => tag_release_amount,
             release_data_out => tag_release_data );

end rtl;
