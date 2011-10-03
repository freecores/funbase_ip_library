-------------------------------------------------------------------------------
-- Title         : PCI Express BFM Root Port Driver 
-- Project       : PCI Express MegaCore function
-------------------------------------------------------------------------------
-- File          : altpcietb_bfm_driver.vhd
-- Author        : Altera Corporation
-------------------------------------------------------------------------------
-- Description :
-- This entity is driver for the Root Port BFM. It processes the list of
-- functions to perform and passes them off to the VC specific interfaces
-------------------------------------------------------------------------------
-- Copyright (c) 2008 Altera Corporation. All rights reserved.  Altera products are
-- protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
-- other intellectual property laws.  
--
-- This reference design file, and your use thereof, is subject to and governed by
-- the terms and conditions of the applicable Altera Reference Design License Agreement.
-- By using this reference design file, you indicate your acceptance of such terms and
-- conditions between you and Altera Corporation.  In the event that you do not agree with
-- such terms and conditions, you may not use the reference design file. Please promptly
-- destroy any copies you have made.
--
-- This reference design file being provided on an "as-is" basis and as an accommodation 
-- and therefore all warranties, representations or guarantees of any kind 
-- (whether express, implied or statutory) including, without limitation, warranties of 
-- merchantability, non-infringement, or fitness for a particular purpose, are 
-- specifically disclaimed.  By making this reference design file available, Altera
-- expressly does not recommend, suggest or require that this reference design file be
-- used in combination with any other product not provided by Altera.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.altpcietb_bfm_constants.all;
use work.altpcietb_bfm_log.all;
use work.altpcietb_bfm_shmem.all;
use work.altpcietb_bfm_rdwr.all;
use work.altpcietb_bfm_configure.all;

entity altpcietb_bfm_driver is

  generic (
    -- TEST_LEVEL is a parameter passed in from the top level test bench that
    -- could control the amount of testing done. It is not currently used. 
    TEST_LEVEL : natural := 1;
    RUN_TGT_MEM_TST : std_logic := '0';
    RUN_DMA_MEM_TST : std_logic := '0';
    MEM_OFFSET : std_logic_vector(31 downto 0) := x"80000000"

    );
  port (
    -- The clk_in and rstn signals are provided for possible use in controlling
    -- the transactions issued, they are not currently used.
    clk_in            : in  std_logic;
    rstn              : in  std_logic;
    INTA              : in  std_logic;
    INTB              : in  std_logic;
    INTC              : in  std_logic;
    INTD              : in  std_logic;
    dummy_out         : out  std_logic    
    );

  -- purpose: Use Reads and Writes to test the target memory
  --          The starting offset in the target memory and the
  --          length can be specified
  procedure target_mem_test (
    constant bar_table : in natural;          -- Pointer to the BAR sizing and
                                              -- address information set up by
                                              -- the configuration routine
    constant tgt_bar : in natural := 0;       -- BAR to use to access the target
                                              -- memory
    constant start_offset : in natural := 0;  -- Starting offset in the target
                                              -- memory to use
    constant tgt_data_len : in natural := 512 -- Length of data to test
    ) is
    constant TGT_WR_DATA_ADDR : natural := 1*(2**16) ;

    variable tgt_rd_data_addr : natural ;
    variable err_addr : integer;

  begin  -- target_mem_test

    ebfm_display(EBFM_MSG_INFO,
                 "Starting Target Write/Read Test.") ;
    ebfm_display(EBFM_MSG_INFO,
                 "  Target BAR = " &
                 integer'image(tgt_bar) ) ;
    ebfm_display(EBFM_MSG_INFO,
                 "  Length = " & integer'image(tgt_data_len) &
                 ", Start Offset = " & integer'image(start_offset) ) ;

    -- Setup some data to write to the Target
    shmem_fill(TGT_WR_DATA_ADDR,SHMEM_FILL_DWORD_INC,tgt_data_len) ;

    -- Setup an address for the data to read back from the Target
    tgt_rd_data_addr := TGT_WR_DATA_ADDR + (2*tgt_data_len) ;
    -- Clear the target data area
    shmem_fill(tgt_rd_data_addr,SHMEM_FILL_ZERO,tgt_data_len) ;

    --
    -- Now write the data to the target with this BFM call
    --
    ebfm_barwr(bar_table,tgt_bar,start_offset,TGT_WR_DATA_ADDR,tgt_data_len) ;
    
    --
    -- Read the data back from the target in one burst, wait for the read to
    -- be complete
    -- 
    ebfm_barrd_wait(bar_table,tgt_bar,start_offset,tgt_rd_data_addr,tgt_data_len) ;

    -- Check the data
    if (shmem_chk_ok(tgt_rd_data_addr,SHMEM_FILL_DWORD_INC,tgt_data_len)) then
      ebfm_display(EBFM_MSG_INFO,"  Target Write and Read compared okay!") ;
    else
      ebfm_display(EBFM_MSG_ERROR_FATAL,"  Stopping simulation due to miscompare") ;
    end if;
    
  end target_mem_test;

  -- purpose: This procedure polls the DMA engine until it is done
  procedure dma_wait_done (
    constant bar_table : in natural;
    constant setup_bar : in natural := 4;
    constant msi_mem : in natural)
  is
  begin  -- dma_wait_done
    shmem_fill(msi_mem,SHMEM_FILL_ZERO,4) ;
    while (shmem_read(msi_mem,4) /= x"0000abcd") loop
       wait for 200 ns;
    end loop;
    ebfm_barwr_imm(bar_table,setup_bar, 16#1000#,x"00000000");
  end dma_wait_done;

  -- purpose: Use the reference design's DMA engine to move data from the BFM's
  -- shared memory to the reference design's master memory and then back
  procedure dma_mem_test (
    constant bar_table : in natural;  -- Pointer to the BAR sizing and
                                            -- address information set up by
                                            -- the configuration routine
    constant setup_bar : in natural := 4;   -- BAR to be used for setting up
                                            -- the DMA operation and checking
                                            -- the status 
    constant start_offset : in natural := 0;  -- Starting offset in the master
                                              -- memory 
    constant dma_data_len : in natural := 512  -- Length of DMA operations 
    ) is

    constant SCR_MEM : natural := (2**17)-4;
    variable dma_rd_data_addr : natural := SCR_MEM + 4 ;
    variable dma_wr_data_addr : natural ;
    variable passthru_msk : std_logic_vector(31 downto 0) ;
    variable passthru_msk_inv : std_logic_vector(31 downto 0) ;    
    variable err_addr : integer ;
    variable comp_status : std_logic_vector(2 downto 0);
    variable multi_message_enable : std_logic_vector(2 downto 0);
    variable msi_enable : std_logic;
    variable msi_capabilities : natural;
    variable msi_data : std_logic_vector(15 downto 0);
    variable msi_address : std_logic_vector(31 downto 0);
    


  begin

    ebfm_display(EBFM_MSG_INFO,
                 "Starting DMA Read/Write Test.");
    ebfm_display(EBFM_MSG_INFO,
                 "  Setup BAR = " &
                 integer'image(setup_bar) ) ;
    ebfm_display(EBFM_MSG_INFO,
                 "  Length = " & integer'image(dma_data_len) &
                 ", Start Offset = " & integer'image(start_offset) ) ;
    
    dma_rd_data_addr := dma_rd_data_addr + start_offset ; 
    -- Setup some data for the DMA to read
    shmem_fill(dma_rd_data_addr,SHMEM_FILL_DWORD_INC,dma_data_len) ;

    -- MSI capabilities
   
    msi_capabilities := 16#50#;
    msi_address := std_logic_vector(to_unsigned(scr_mem,32)) ;
    msi_data := x"abcd";
    msi_enable := '0';
    multi_message_enable := "000";
   
  -- Set PCIe Interrupt enable (bit 7) in PCIe-AvalonMM bridge logic
ebfm_barwr_imm(bar_table,setup_bar, 16#4050#, x"00000080");

   

    -- check the # of passthru bits
    ebfm_barwr_imm(bar_table,setup_bar, 16#5000# ,x"ffffffff") ;
    ebfm_barrd_wait(bar_table,setup_bar, 16#5000# ,scr_mem,4) ;
    passthru_msk := shmem_read(scr_mem,4) and x"ffff_fffc";
    passthru_msk_inv := not passthru_msk;

    -- To program DMA and translation, take the portion of the DMA address that
-- is below passthru bits and program them to DMA. The remaining portion goes
-- to address translation table

    -- Program translation table
    ebfm_barwr_imm(bar_table,setup_bar, 16#5000# ,std_logic_vector(to_unsigned(dma_rd_data_addr,32)) and passthru_msk) ;
    ebfm_barwr_imm(bar_table,setup_bar, 16#5004#,x"00000000");
    
    -- Program the DMA to Read Data from Shared Memory
    ebfm_barwr_imm(bar_table,setup_bar, 16#1008#,std_logic_vector(to_unsigned(dma_rd_data_addr,32)) and passthru_msk_inv) ;
    ebfm_barwr_imm(bar_table,setup_bar, 16#1010#, MEM_OFFSET);
    ebfm_barwr_imm(bar_table,setup_bar, 16#1018#, std_logic_vector(to_unsigned(dma_data_len,32)));
    ebfm_barwr_imm(bar_table,setup_bar, 16#1030#, x"00000498");

    
    -- Wait for INTA asserted
wait until ( INTA='1');
ebfm_display(EBFM_MSG_INFO,"INTA asserted");
ebfm_display(EBFM_MSG_INFO,"Clearing INTA");
ebfm_barwr_imm(bar_table,setup_bar, 16#1000#,x"00000000"); -- clear done bit in the DMA

 
wait until ( INTA='0');

-- Enable MSI
msi_enable := '1';
ebfm_cfgwr_imm_wait(1,0,0,msi_capabilities ,4, (x"00" & '0' & multi_message_enable & "000" & msi_enable & x"0000") , comp_status);
ebfm_cfgwr_imm_wait(1,0,0,(msi_capabilities + 4),4, msi_address, comp_status);
ebfm_cfgwr_imm_wait(1,0,0,(msi_capabilities + 12),4, ( x"0000" & msi_data), comp_status);



    -- Setup an area for DMA to write back to
    -- Currently DMA Engine Uses smae lower address bits for it's MRAM and PCIE
    -- Addresses. So use the same address we started with
    dma_wr_data_addr := dma_rd_data_addr ; 
    shmem_fill(dma_wr_data_addr,SHMEM_FILL_ZERO,dma_data_len) ;

    -- Program the DMA to Write Data Back to Shared Memory
    ebfm_barwr_imm(bar_table,setup_bar, 16#1008#, MEM_OFFSET);
    ebfm_barwr_imm(bar_table,setup_bar, 16#1010#, std_logic_vector(to_unsigned(dma_wr_data_addr,32)) and passthru_msk_inv) ;
    ebfm_barwr_imm(bar_table,setup_bar, 16#1018#, std_logic_vector(to_unsigned(dma_data_len,32)));
    ebfm_barwr_imm(bar_table,setup_bar, 16#1030#, x"00000498");

    -- Wait Until the DMA is done via MSI
    dma_wait_done(bar_table,setup_bar,SCR_MEM) ;
    ebfm_display(EBFM_MSG_INFO,"MSI Received");


    -- Check the data
    if (shmem_chk_ok(dma_rd_data_addr,SHMEM_FILL_DWORD_INC,dma_data_len)) then
      ebfm_display(EBFM_MSG_INFO,"  DMA Read and Write compared okay!") ;
    else
      ebfm_display(EBFM_MSG_ERROR_FATAL,"  Stopping simulation due to miscompare") ;
    end if;

  end procedure dma_mem_test ;

  -- purpose: Examine the DUT's BAR setup and pick a reasonable BAR to use
  impure function find_mem_bar (
    constant bar_table : natural ;
    constant allowed_bars    : std_logic_vector(5 downto 0);
    constant min_log2_size   : natural 
    ) return natural is
    variable cur_bar : natural := 0;
    variable bar32 : std_logic_vector(31 downto 0) ;
    variable log2_size : natural;
    variable is_mem : std_logic ;
    variable is_pref : std_logic ;
    variable is_64b : std_logic ;
  begin  -- find_mem_bar
    chk_loop : while (cur_bar < 6) loop
      ebfm_cfg_decode_bar(bar_table,cur_bar,log2_size,is_mem,is_pref,is_64b) ;
      if ( (is_mem = '1') and
           (log2_size >= min_log2_size) and
           (allowed_bars(cur_bar) = '1') ) then
        return cur_bar;
      end if;
      if (is_64b = '1') then
        cur_bar := cur_bar + 2 ;
      else
        cur_bar := cur_bar + 1 ;        
      end if;
    end loop chk_loop;
    return natural'high; -- Invalid BAR if we get this far...
  end find_mem_bar;



end altpcietb_bfm_driver;

architecture behavioral of altpcietb_bfm_driver is

  signal activity_toggle : std_logic := '0';
  
begin  -- behavioral

  main: process

    -- This constant defines where we save the sizes and programmed addresses
    -- of the Endpoint Device Under Test BARs 
    constant bar_table : natural := BAR_TABLE_POINTER;  -- 64 bytes

    -- tgt_bar indicates which bar to use for testing the target memory of the
    -- reference design.
    variable tgt_bar : natural := 0;
    variable dma_bar : natural := 4;
    variable addr_map_4GB_limit : natural := 0;
    
  begin  -- process main

     ebfm_display(EBFM_MSG_INFO,"Starting ebfm_cfg_rp_ep");
     -- Setup the Root Port and Endpoint Configuration Spaces
     ebfm_cfg_rp_ep(
       bar_table => bar_table,                  -- BAR Size/Address info for Endpoint
       ep_bus_num => 1,                         -- Bus Number for Endpoint Under Test
       ep_dev_num => 1,                         -- Device Number for Endpoint Under Test
       rp_max_rd_req_size => 512,               -- Maximum Read Request Size for Root Port
       display_ep_config => 1,                  -- Display EP Config Space after setup
       addr_map_4GB_limit => addr_map_4GB_limit -- Limit the BAR assignments to 4GB address map
       ) ;

     ebfm_display(EBFM_MSG_INFO,"Finished ebfm_cfg_rp_ep");
     activity_toggle <= not activity_toggle ;

     -- Find a memory BAR to use to test the target memory
     -- The reference design implements the target memory on BARs 0,1, 4 or 5
     -- We need one at least 4 KB big
     tgt_bar := find_mem_bar(bar_table,"110011",12) ;
     
     -- Test the reference design's target memory
     if (RUN_TGT_MEM_TST = '0')  then
       ebfm_display(EBFM_MSG_WARNING,"Skipping target test.");
     elsif (tgt_bar < 6)  then
      target_mem_test(
        bar_table => bar_table,        -- BAR Size/Address info for Endpoint
        tgt_bar => tgt_bar,            -- BAR to access target memory with
        start_offset => 0,             -- Starting offset from BAR
        tgt_data_len => 4096) ;        -- Length of memory to test
     else
       ebfm_display(EBFM_MSG_WARNING,"Unable to find a 4 KB BAR to test Target Memory, skipping target test.");
     end if;

     activity_toggle <= not activity_toggle ;
     
     -- Find a memory BAR to use to setup the DMA channel
     -- The reference design implements the DMA channel registers on BAR 2 or 3
     -- We need one at least 128 B big
     dma_bar := find_mem_bar(bar_table,"001100",15) ;
     
     -- Test the reference design's DMA channel and master memory
     if (RUN_DMA_MEM_TST = '0') then
       ebfm_display(EBFM_MSG_WARNING,"Skipping DMA test.");
     elsif (dma_bar < 6) then
      dma_mem_test(
        bar_table => bar_table,        -- BAR Size/Address info for Endpoint
        setup_bar => dma_bar,          -- BAR to access DMA control registers
        start_offset => 0,             -- Starting offset of DMA memory
        dma_data_len => 4096) ;        -- Length of memory to test
     else
       ebfm_display(EBFM_MSG_WARNING,"Unable to find a 128B BAR to test setup DMA channel, skipping DMA test.");
     end if;

     -- Stop the simulator and indicate successful completion
     ebfm_log_stop_sim(1) ;

     wait;
  end process main;

  -- purpose: this is a watchdog timer, if it sees no activity on the activity
  -- toggle signal for 200 us it ends the simulation
  watchdog: process 
  begin  -- process watchdog
    wait on activity_toggle for 200 us ;
    if (not activity_toggle'event) then
      ebfm_display(EBFM_MSG_ERROR_FATAL,"Simulation stopped due to inactivity!") ;
    end if;
  end process watchdog;

end behavioral;
