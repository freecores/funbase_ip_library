  --Example instantiation for system 'pcie_to_hibi_4x_sopc'
  pcie_to_hibi_4x_sopc_inst : pcie_to_hibi_4x_sopc
    port map(
      clk125_out_pcie => clk125_out_pcie,
      clk250_out_pcie => clk250_out_pcie,
      clk500_out_pcie => clk500_out_pcie,
      hibi_av_out_from_the_a2h => hibi_av_out_from_the_a2h,
      hibi_comm_out_from_the_a2h => hibi_comm_out_from_the_a2h,
      hibi_data_out_from_the_a2h => hibi_data_out_from_the_a2h,
      hibi_re_out_from_the_a2h => hibi_re_out_from_the_a2h,
      hibi_we_out_from_the_a2h => hibi_we_out_from_the_a2h,
      powerdown_ext_pcie => powerdown_ext_pcie,
      rate_ext_pcie => rate_ext_pcie,
      reconfig_fromgxb_pcie => reconfig_fromgxb_pcie,
      rxpolarity0_ext_pcie => rxpolarity0_ext_pcie,
      rxpolarity1_ext_pcie => rxpolarity1_ext_pcie,
      rxpolarity2_ext_pcie => rxpolarity2_ext_pcie,
      rxpolarity3_ext_pcie => rxpolarity3_ext_pcie,
      test_out_pcie => test_out_pcie,
      tx_out0_pcie => tx_out0_pcie,
      tx_out1_pcie => tx_out1_pcie,
      tx_out2_pcie => tx_out2_pcie,
      tx_out3_pcie => tx_out3_pcie,
      txcompl0_ext_pcie => txcompl0_ext_pcie,
      txcompl1_ext_pcie => txcompl1_ext_pcie,
      txcompl2_ext_pcie => txcompl2_ext_pcie,
      txcompl3_ext_pcie => txcompl3_ext_pcie,
      txdata0_ext_pcie => txdata0_ext_pcie,
      txdata1_ext_pcie => txdata1_ext_pcie,
      txdata2_ext_pcie => txdata2_ext_pcie,
      txdata3_ext_pcie => txdata3_ext_pcie,
      txdatak0_ext_pcie => txdatak0_ext_pcie,
      txdatak1_ext_pcie => txdatak1_ext_pcie,
      txdatak2_ext_pcie => txdatak2_ext_pcie,
      txdatak3_ext_pcie => txdatak3_ext_pcie,
      txdetectrx_ext_pcie => txdetectrx_ext_pcie,
      txelecidle0_ext_pcie => txelecidle0_ext_pcie,
      txelecidle1_ext_pcie => txelecidle1_ext_pcie,
      txelecidle2_ext_pcie => txelecidle2_ext_pcie,
      txelecidle3_ext_pcie => txelecidle3_ext_pcie,
      clk => clk,
      gxb_powerdown_pcie => gxb_powerdown_pcie,
      hibi_av_in_to_the_a2h => hibi_av_in_to_the_a2h,
      hibi_comm_in_to_the_a2h => hibi_comm_in_to_the_a2h,
      hibi_data_in_to_the_a2h => hibi_data_in_to_the_a2h,
      hibi_empty_in_to_the_a2h => hibi_empty_in_to_the_a2h,
      hibi_full_in_to_the_a2h => hibi_full_in_to_the_a2h,
      hibi_one_d_in_to_the_a2h => hibi_one_d_in_to_the_a2h,
      hibi_one_p_in_to_the_a2h => hibi_one_p_in_to_the_a2h,
      pcie_rstn_pcie => pcie_rstn_pcie,
      phystatus_ext_pcie => phystatus_ext_pcie,
      pipe_mode_pcie => pipe_mode_pcie,
      pll_powerdown_pcie => pll_powerdown_pcie,
      reconfig_clk_pcie => reconfig_clk_pcie,
      reconfig_togxb_pcie => reconfig_togxb_pcie,
      refclk_pcie => refclk_pcie,
      reset_n => reset_n,
      rx_in0_pcie => rx_in0_pcie,
      rx_in1_pcie => rx_in1_pcie,
      rx_in2_pcie => rx_in2_pcie,
      rx_in3_pcie => rx_in3_pcie,
      rxdata0_ext_pcie => rxdata0_ext_pcie,
      rxdata1_ext_pcie => rxdata1_ext_pcie,
      rxdata2_ext_pcie => rxdata2_ext_pcie,
      rxdata3_ext_pcie => rxdata3_ext_pcie,
      rxdatak0_ext_pcie => rxdatak0_ext_pcie,
      rxdatak1_ext_pcie => rxdatak1_ext_pcie,
      rxdatak2_ext_pcie => rxdatak2_ext_pcie,
      rxdatak3_ext_pcie => rxdatak3_ext_pcie,
      rxelecidle0_ext_pcie => rxelecidle0_ext_pcie,
      rxelecidle1_ext_pcie => rxelecidle1_ext_pcie,
      rxelecidle2_ext_pcie => rxelecidle2_ext_pcie,
      rxelecidle3_ext_pcie => rxelecidle3_ext_pcie,
      rxstatus0_ext_pcie => rxstatus0_ext_pcie,
      rxstatus1_ext_pcie => rxstatus1_ext_pcie,
      rxstatus2_ext_pcie => rxstatus2_ext_pcie,
      rxstatus3_ext_pcie => rxstatus3_ext_pcie,
      rxvalid0_ext_pcie => rxvalid0_ext_pcie,
      rxvalid1_ext_pcie => rxvalid1_ext_pcie,
      rxvalid2_ext_pcie => rxvalid2_ext_pcie,
      rxvalid3_ext_pcie => rxvalid3_ext_pcie,
      test_in_pcie => test_in_pcie
    );


