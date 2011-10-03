//--------------------------------------------------------------------------//
// Title:       a2gx_pcie_top.v                                             //
// Rev:         Rev 3                                                      //
//--------------------------------------------------------------------------//
// Description: Golden Top file contains Stratix IV GX PCI Express Board    //
//              pins and I/O Standards.                                     //
//--------------------------------------------------------------------------//
// Revision History:                                                        //
// 1: Initial															    //
// 2: Swap user_pb[1:0] with ddr2_dimm_a[4:0]								//
// 3: Correct pin locations.												//
//------ 1 ------- 2 ------- 3 ------- 4 ------- 5 ------- 6 ------- 7 ------7
//------ 0 ------- 0 ------- 0 ------- 0 ------- 0 ------- 0 ------- 0 ------8
//Copyright © 2009 Altera Corporation. All rights reserved.  Altera products
//are protected under numerous U.S. and foreign patents, maskwork rights,
//copyrights and other intellectual property laws.
//                 
//This reference design file, and your use thereof, is subject to and
//governed by the terms and conditions of the applicable Altera Reference
//Design License Agreement.  By using this reference design file, you
//indicate your acceptance of such terms and conditions between you and
//Altera Corporation.  In the event that you do not agree with such terms and
//conditions, you may not use the reference design file. Please promptly                         
//destroy any copies you have made.
//
//This reference design file being provided on an "as-is" basis and as an
//accommodation and therefore all warranties, representations or guarantees
//of any kind (whether express, implied or statutory) including, without
//limitation, warranties of merchantability, non-infringement, or fitness for
//a particular purpose, are specifically disclaimed.  By making this
//reference design file available, Altera expressly does not recommend,
//suggest or require that this reference design file be used in combination 
//with any other product not provided by Altera
//----------------------------------------------------------------------------


module a2gx_dev_kit_golden_top (
//CLK-Inputs---------------------------//15 pins
    //wired through XCVR blocks, all AC-coupled)
//    input           clkin_ref_q1_1_p,     //LVDS    //adj. defaut 100.000 MHz osc
//    input           clkin_ref_q1_2_p,     //LVDS    //adj. defaut 125.000 MHz osc
//    input           clkin_ref_q2_p,     //LVDS      //adj. default 125.000 MHz osc
//    input           clkin_ref_q3_p,     //LVDS      //adj. default 125.000 MHz osc
//    input   	    clkin_155_p,	   //LVPECL    //155.520 MHz osc 
    input           clkin_bot_p,       //LVDS      //ADJ default 100.000 MHz osc or sma in (Requires external termination.)
    input           clkin_top_p,       //LVDS      //ADJ default 125.000 MHz osc (Requires external termination.)
    output          clkout_sma,        //1.8V      //PLL CLK sma out

	
////DDR3-SDRAM-PORTS  -> 64Mx16 Interface ---------------------//49 pins
/*    output [14:0]  ddr3_a,          //SSTL15    //Address (1Gb max)
    output [2:0]   ddr3_ba,         //SSTL15    //Bank address
    inout  [15:0]  ddr3_dq,         //SSTL15    //Data
    inout  [1:0]   ddr3_dqs_p,      //SSTL15    //Strobe Pos
    inout  [1:0]   ddr3_dqs_n,      //SSTL15    //Strobe Neg
    output [1:0]   ddr3_dm,         //SSTL15    //Byte write mask
    output         ddr3_wen,        //SSTL15    //Write enable
    output         ddr3_rasn,       //SSTL15    //Row address select
    output         ddr3_casn,       //SSTL15    //Column address select
    inout          ddr3_ck_p,       //SSTL15    //System Clock Pos
    inout          ddr3_ck_n,       //SSTL15    //System Clock Neg
    output         ddr3_cke,        //SSTL15    //Clock Enable
    output         ddr3_csn,        //SSTL15    //Chip Select
    output         ddr3_resetn,     //SSTL15    //Reset
    output         ddr3_odt,        //SSTL15    //On-die termination enable*/
 
 //DDR2 SDRAM SoDIMM -------------------------------------//x64 -> 117 pins (Default)
	//x64 -> 125 pins
    output [15:0]  ddr2_dimm_a,	    //SSTL18    //Address		OK
    output [2:0]   ddr2_dimm_ba,    //SSTL18    //Bank address  OK
    inout  [31:0]  ddr2_dimm_dq,         //SSTL18    //Data x64 SODIMM		OK
    inout  [3:0]   ddr2_dimm_dqs_p,      //SSTL18    //Strobe Pos			OK
    inout  [3:0]   ddr2_dimm_dqs_n,      //SSTL18    //Strobe Neg			OK
    output [3:0]   ddr2_dimm_dm,         //SSTL18    //Byte write mask  OK
    output         ddr2_dimm_cke,    //SSTL18   //System Clock Enable  OK
    inout  [1:0]   ddr2_dimm_ck_p,   //SSTL18   //System Clock Pos     OK
    inout  [1:0]   ddr2_dimm_ck_n,   //SSTL18    //System Clock Neg		OK
    output         ddr2_dimm_wen,         //SSTL18    //Write enable		OK
    output         ddr2_dimm_rasn,       //SSTL18    //Row address select		OK
    output         ddr2_dimm_casn,       //SSTL18    //Column address select  OK
   output	  ddr2_dimm_csn,        //SSTL18    //Chip Select           OK
//    output         ddr2_dimm_resetn,     //SSTL18    //Reset
    output    ddr2_dimm_odt,        //SSTL18    //On-die termination enable	OK

////////////////////////////////////////////////////////////////// 
//ETHERNET-10/100/1000-RGMII-----------
    output  	   enet_gtx_clk,      //2.5V  //RGMII Transmit Clock
    output [3:0]   enet_tx_d,        //2.5V  //TX to PHY
    input  [3:0]   enet_rx_d,        //2.5V  //RX from PHY
    output         enet_tx_en,       //2.5V  //RGMII Transmit Control
    input	       enet_rx_clk,      //2.5V  //Derived Received Clock
    input          enet_rx_dv,       //2.5V  //RGMII Receive Control 
    output         enet_resetn,        //2.5V      //Reset to PHY (TR=0)
    output         enet_mdc,           //2.5V      //MDIO Control (TR=0)
    inout          enet_mdio,          //2.5V      //MDIO Data (TR=0)
    input          enet_intn,           //2.5V      //MDIO Interrupt (TR=0)
///////////////////////////////////////////////////////////////////

//FLASH-SRAM-MAX-------------FSM-Bus---//90 pins
    output [25:0]  fsm_a,              //2.5V      //FSM Address Bus (1Gb Flash)
    inout  [31:0]  fsm_d,              //2.5V      //FSM Data Bus
    output         flash_clk,          //2.5V  
    output         flash_cen,          //2.5V  
    output         flash_oen,          //2.5V
    output         flash_wen,          //2.5V
    output         flash_advn,         //2.5V
    input          flash_rdybsyn,      //2.5V
    output         flash_resetn,       //2.5V     // (TR=0)
    output         sram_clk,           //2.5V
    output         sram_cen,           //2.5V
    inout  [3:0]   sram_dqp,           //2.5V     //Parity bits only go to SRAM
    output [3:0]   sram_bwn,           //2.5V
    output         sram_gwn,           //2.5V
    output         sram_bwen,          //2.5V
    output         sram_oen,           //2.5V
    output         sram_advn,          //2.5V
    output         sram_adspn,         //2.5V
    output         sram_adscn,         //2.5V
    output         sram_zz,            //2.5V     // (TR=0)
/*    output         max2_clk,           //1.8V
    output         max2_csn,           //1.8V
    output [3:0]   max2_ben,           //1.8V
    output         max2_oen,           //1.8V
    output         max2_wen,           //1.8V*/

////LCD----------------------------------//11 pins
    inout  [7:0]   lcd_data,           //2.5V
    output         lcd_d_cn,           //2.5V
    output         lcd_wen,            //2.5V
    output         lcd_csn,            //2.5V
//
////User-IO------------------------------//22 pins
    input  [3:0]   user_dipsw,         //1.8V/2.5V     // (TR=0)
//    output [7:0]   user_led,           //2.5V
    output [3:0]   user_led,           //2.5V
    input  [1:0]   user_pb,            //1.8V/2.5V     // (TR=0)
//    input  [1:0]   user_pb,            //1.8V/2.5V     // (TR=0)
    input          cpu_resetn,         //2.5V (DEV_CLRn)    // (TR=0)
  
//// //PCI-EXPRESS-EDGE---------------------
    input          pcie_refclk_p,      //HCSL
    output [3:0]   pcie_tx_p,          //1.4V PCML
    input  [3:0]   pcie_rx_p,          //1.4V PCML
    input          pcie_smbclk,        //2.5V     // (TR=0)
    inout          pcie_smbdat,        //2.5V     // (TR=0)
    input          pcie_perstn,        //2.5V     // (TR=0)
    output         pcie_waken,         //2.5V     // (TR=0)
    output         pcie_led_x1,        //2.5V
    output         pcie_led_x4,        //2.5V
    output         pcie_led_x8,        //2.5V
//    output         pcie_led_g2,        //2.5V
    input		   cal_blk_clk,         //Virtual Pin
//HIGH-SPEED-MEZZANINE-CARD------------//198 pins (HSMB is only connected on EP2AGX260 devices)
    //Port A -->   single samtec conn  //107 pins  //------------------
//      output [3:0]   hsma_tx_p,    	 //1.4V PCML
//      input  [3:0]   hsma_rx_p,    	 //1.4V PCML
      //Enable below for CMOS HSMC     
      //inout  [79:0]  hsma_d,           //2.5V
      //Enable below for LVDS HSMC
    output [16:0]  hsma_tx_d_p,        //LVDS  //69 pins
    input  [16:0]  hsma_rx_d_p,        //LVDS
    inout  [3:0]   hsma_d,             //2.5V
    input          hsma_clk_in0,       //2.5V
    output         hsma_clk_out0,      //2.5V
    input          hsma_clk_in_p1,     //LVDS //Requires external termination  
    output         hsma_clk_out_p1,    //LVDS
    input          hsma_clk_in_p2,     //LVDS //Requires external termination
    output         hsma_clk_out_p2,    //LVDS
    inout          hsma_sda,           //2.5V     // (TR=0)
    output         hsma_scl,           //2.5V     // (TR=0)
    output         hsma_tx_led,        //2.5V
    output         hsma_rx_led,        //2.5V
    input          hsma_prsntn ,       //2.5V     // (TR=0)
//    //Port B -->   single samtec conn  //107 pins  //------------------
//      //output [3:0]   hsmb_tx_p,    	 //1.4V PCML   
//      //input  [3:0]   hsmb_rx_p,    	 //1.4V PCML   
//      //Enable below for CMOS HSMC     
//      //inout  [79:0]  hsmb_d,           //2.5V
//      //Enable below for LVDS HSMC  
//    output [16:0]  hsmb_tx_d_p,        //LVDS   
//    input  [16:0]  hsmb_rx_d_p,        //LVDS   
//    inout  [3:0]   hsmb_d,             //2.5V
    input          hsmb_clk_in0       //2.5V   
//    output         hsmb_clk_out0,      //2.5V   
//    output         hsmb_clk_out_p1,    //LVDS   
//    output         hsmb_clk_out_p2,    //LVDS   
//    inout          hsmb_sda,           //2.5V     // (TR=0)   
//    output         hsmb_scl,           //2.5V     // (TR=0)   
//    output         hsmb_tx_led,        //2.5V                 
//    output         hsmb_rx_led,        //2.5V                 
//    input          hsmb_prsntn         //2.5V     // (TR=0)  
);  

wire clk_ref_100;
wire clk;

wire rst_n;

wire flash_0_ce_n;
wire flash_0_oe_n;
wire flash_0_we_n;
wire flash_1_ce_n;
wire flash_1_oe_n;
wire flash_1_we_n;

wire a2h_hibi_av_in;
wire a2h_hibi_av_out;
wire [2:0]a2h_hibi_comm_in;
wire [2:0]a2h_hibi_comm_out;
wire [31:0]a2h_hibi_data_in;
wire [31:0]a2h_hibi_data_out;
wire a2h_hibi_empty_in;
wire a2h_hibi_full_in;
wire a2h_hibi_re_out;
wire a2h_hibi_we_out;
wire a2h_one_d_in;
wire a2h_one_p_in;

wire m2h2_hibi_av_in;
wire m2h2_hibi_av_out;
wire [2:0]m2h2_hibi_comm_in;
wire [2:0]m2h2_hibi_comm_out;
wire [31:0]m2h2_hibi_data_in;
wire [31:0]m2h2_hibi_data_out;
wire m2h2_hibi_empty_in;
wire m2h2_hibi_full_in;
wire m2h2_hibi_re_out;
wire m2h2_hibi_we_out;
wire m2h2_one_d_in;
wire m2h2_one_p_in;

assign clk_ref_100 = clkin_bot_p;

assign rst_n = user_pb[0];

assign flash_cen = flash_0_ce_n & flash_1_ce_n;
assign flash_oen = flash_0_oe_n & flash_1_oe_n;
assign flash_wen = flash_0_we_n & flash_1_we_n;

assign fsm_a[25] = ~flash_1_ce_n;
assign flash_advn = 1'b0;
assign flash_resetn = 1'b1;
assign flash_clk = 1'b0;


/*pll_0 pll_0 (
  .inclk0(clkin_bot_p),
  .c0(clk_100) );*/

pcie_to_hibi_4x pcie_to_hibi_4x(
  .clk(clk),
  .rst_n(rst_n),
  
  .pcie_rst_n(rst_n),
  .pcie_ref_clk(pcie_refclk_p),
  .pcie_rx(pcie_rx_p),
  .pcie_tx(pcie_tx_p),

  
  .hibi_av_in(a2h_hibi_av_in),
  .hibi_av_out(a2h_hibi_av_out),
  .hibi_comm_in(a2h_hibi_comm_in),
  .hibi_comm_out(a2h_hibi_comm_out),
  .hibi_data_in(a2h_hibi_data_in),
  .hibi_data_out(a2h_hibi_data_out),
  .hibi_empty_in(a2h_hibi_empty_in),
  .hibi_full_in(a2h_hibi_full_in),
  .hibi_one_d_in(a2h_hibi_one_d_in),
  .hibi_one_p_in(a2h_hibi_one_p_in),
  .hibi_re_out(a2h_hibi_re_out),
  .hibi_we_out(a2h_hibi_we_out) );

m2h2 m2h2 (
  .rst_n(rst_n),
  .ref_clk(clk_ref_100),
  .mem_ctrl_clk(clk),
  
  .hibi_0_comm_in(m2h2_hibi_comm_in),
  .hibi_0_data_in(m2h2_hibi_data_in),
  .hibi_0_av_in(m2h2_hibi_av_in),
  .hibi_0_full_in(m2h2_hibi_full_in),
  .hibi_0_one_p_in(m2h2_hibi_one_p_in),
  .hibi_0_empty_in(m2h2_hibi_empty_in),
  .hibi_0_one_d_in(m2h2_hibi_one_d_in),
  
  .hibi_0_comm_out(m2h2_hibi_comm_out),
  .hibi_0_data_out(m2h2_hibi_data_out),
  .hibi_0_av_out(m2h2_hibi_av_out),
  .hibi_0_we_out(m2h2_hibi_we_out),
  .hibi_0_re_out(m2h2_hibi_re_out),
  
  .ddr2_odt(ddr2_dimm_odt),
  .ddr2_cs_n(ddr2_dimm_cs_n),
  .ddr2_cke(ddr2_dimm_cke),
  .ddr2_addr(ddr2_dimm_addr),
  .ddr2_ba(ddr2_dimm_ba),
  .ddr2_ras_n(ddr2_dimm_ras_n),
  .ddr2_cas_n(ddr2_dimm_cas_n),
  .ddr2_we_n(ddr2_dimm_we_n),
  .ddr2_dm(ddr2_dimm_dm),
  .ddr2_clk(ddr2_dimm_ck_p),
  .ddr2_clk_n(ddr2_dimm_ck_n),
  .ddr2_dq(ddr2_dimm_dq),
  .ddr2_dqs(ddr2_dimm_dqs_p),
  .ddr2_dqs_n(ddr2_dimm_dqs_n) );

Hibi_segment #( 32, 16, 32, 3, 5, 2, 0 )
  hibi_seg (
/*  .bus_clk(clk),
  .agent_clk(clk),
  .bus_sync_clk(clk),
  .agent_sync_clk(clk),*/
  
  .clk(clk),
  .rst_n(rst_n),
  
  .agent_av_in_1(a2h_hibi_av_out),
  .agent_av_out_1(a2h_hibi_av_in),
  .agent_comm_in_1(a2h_hibi_comm_out),
  .agent_comm_out_1(a2h_hibi_comm_in),
  .agent_data_in_1(a2h_hibi_data_out),
  .agent_data_out_1(a2h_hibi_data_in),
  .agent_empty_out_1(a2h_hibi_empty_in),
  .agent_full_out_1(a2h_hibi_full_in),
  .agent_re_in_1(a2h_hibi_re_out),
  .agent_we_in_1(a2h_hibi_we_out),
  
  .agent_av_in_2(m2h2_hibi_av_out),
  .agent_av_out_2(m2h2_hibi_av_in),
  .agent_comm_in_2(m2h2_hibi_comm_out),
  .agent_comm_out_2(m2h2_hibi_comm_in),
  .agent_data_in_2(m2h2_hibi_data_out),
  .agent_data_out_2(m2h2_hibi_data_in),
  .agent_empty_out_2(m2h2_hibi_empty_in),
  .agent_full_out_2(m2h2_hibi_full_in),
  .agent_one_p_out_2(m2h2_hibi_one_p_in),
  .agent_one_d_out_2(m2h2_hibi_one_d_in),
  .agent_re_in_2(m2h2_hibi_re_out),
  .agent_we_in_2(m2h2_hibi_we_out),
  
  .agent_comm_in_5(3'b0),
  .agent_comm_in_3(3'b0),
  .agent_re_in_5(1'b0),
  .agent_re_in_4(1'b0),
  .agent_av_in_5(1'b0),
  .agent_av_in_4(1'b0),
  .agent_we_in_3(1'b0),
  .agent_we_in_4(1'b0),
  .agent_we_in_5(1'b0),
  .agent_we_in_6(1'b0),
  .agent_we_in_7(1'b0),
  .agent_re_in_3(1'b0),
  .agent_comm_in_8(3'b0),
  .agent_comm_in_4(3'b0),
  .agent_av_in_7(1'b0),
  .agent_av_in_6(1'b0),
  .agent_re_in_7(1'b0),
  .agent_re_in_6(1'b0),
  .agent_av_in_3(1'b0),
  .agent_re_in_8(1'b0),
  .agent_av_in_8(1'b0),
  .agent_we_in_8(1'b0),
  .agent_data_in_8(0),
  .agent_data_in_6(0),
  .agent_data_in_7(0),
  .agent_data_in_4(0),
  .agent_data_in_5(0),
  .agent_data_in_3(0),
  .agent_comm_in_6(3'b0),
  .agent_comm_in_7(3'b0) );

endmodule
