// a2h.v

// This file was auto-generated as part of a SOPC Builder generate operation.
// If you edit it your changes will probably be lost.

module a2h (
		input  wire [31:0] av_wr_data_in,   // avalon_slave.writedata
		output wire [31:0] av_rd_data_out,  //             .readdata
		input  wire [22:0] av_addr_in,      //             .address
		input  wire        av_we_in,        //             .write
		input  wire        av_re_in,        //             .read
		input  wire [3:0]  av_byte_en_in,   //             .byteenable
		output wire        av_wait_req_out, //             .waitrequest
		input  wire        clk,             //  clock_reset.clk
		input  wire        rst_n,           //             .reset_n
		input  wire        hibi_av_in,      //       export.export
		input  wire        hibi_full_in,    //             .export
		input  wire [31:0] hibi_data_in,    //             .export
		input  wire        hibi_one_p_in,   //             .export
		input  wire        hibi_empty_in,   //             .export
		input  wire        hibi_one_d_in,   //             .export
		output wire [2:0]  hibi_comm_out,   //             .export
		output wire [31:0] hibi_data_out,   //             .export
		output wire        hibi_av_out,     //             .export
		output wire        hibi_we_out,     //             .export
		output wire        hibi_re_out,     //             .export
		input  wire [2:0]  hibi_comm_in     //             .export
	);

	avalon_to_hibi #(
		.AV_ADDR_SIZE        (23)
//		.AV_M2H2_ADDR        (2'b00)
//		.AV_OTHER_HIBI_ADDR  (2'b01),
//		.HIBI_BASE_ADDR      (5'b01100),
//		.HIBI_M2H2_BASE_ADDR (5'b01110)
//		.HIBI_M2H2_CONF_ADDR (30'b000000000000000000000000010000)
	) a2h (
		.av_wr_data_in   (av_wr_data_in),   // avalon_slave.writedata
		.av_rd_data_out  (av_rd_data_out),  //             .readdata
		.av_addr_in      (av_addr_in),      //             .address
		.av_we_in        (av_we_in),        //             .write
		.av_re_in        (av_re_in),        //             .read
		.av_byte_en_in   (av_byte_en_in),   //             .byteenable
		.av_wait_req_out (av_wait_req_out), //             .waitrequest
		.clk             (clk),             //  clock_reset.clk
		.rst_n           (rst_n),           //             .reset_n
		.hibi_av_in      (hibi_av_in),      //       export.export
		.hibi_full_in    (hibi_full_in),    //             .export
		.hibi_data_in    (hibi_data_in),    //             .export
		.hibi_one_p_in   (hibi_one_p_in),   //             .export
		.hibi_empty_in   (hibi_empty_in),   //             .export
		.hibi_one_d_in   (hibi_one_d_in),   //             .export
		.hibi_comm_out   (hibi_comm_out),   //             .export
		.hibi_data_out   (hibi_data_out),   //             .export
		.hibi_av_out     (hibi_av_out),     //             .export
		.hibi_we_out     (hibi_we_out),     //             .export
		.hibi_re_out     (hibi_re_out),     //             .export
		.hibi_comm_in    (hibi_comm_in)     //             .export
	);

endmodule
