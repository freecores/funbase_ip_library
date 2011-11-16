// **************************************************************************
// File             : video_gen.c
// Author           : Lauri Matilainen
// Date             : 17.09.2010
// Decription       : 1st funcapi demo code
// Version history  : 21.10.2005    LM   1st version  
//
//
//
//
// **************************************************************************



#include "mcapi.h"
#include <mcapi_datatypes.h>
#include <mapping.h>

#define VIDEO_GEN_ID 0
#define PIC_MAN_ID 1
#define MEM_ID 2
#define IMG_DISPLAY 3

#define MY_NODE_ID VIDEO_GEN_ID


#define PORT_NUM_0 0
#define PORT_NUM_1 1
#define PORT_NUM_2 2


#define START_RAW_FRAME_MANIP_PORT 0

#define RECV_NODE_ID 1
#define NUM_OF_NODES 2

#define RX_DATA_CH 0


#define MSG_SIZE 1
#define PKT_SIZE 1

#define PKT_HEADER 0x1



#define PRIORITY 1


#define BUFF_SIZE 640


#define H_pixels_across 4
#define V_pixels_down 8


//#define WRONG printf("ERRORR!\n")

#define WRONG 

#define WRONG wrong(__LINE__);

void wrong(unsigned line)
{
printf(stderr,"WRONG: line=%u\n", line);
 fflush(stdout);
 exit(1);
}

uint8_t buffer[BUFF_SIZE];

uint8_t* buf_ptr;

int main (){

  
  unsigned int image_data, x_move, y_move, h_count, v_count, picture_start;

  mcapi_pktchan_send_hndl_t send_hndl;
  mcapi_pktchan_recv_hndl_t recv_hndl;

  mcapi_status_t status;
  mcapi_version_t version;
  mcapi_request_t request;
  size_t received_size;

  // internal endpoints
  mcapi_endpoint_t start_new_frame_gen;
  mcapi_endpoint_t start_frame_manip_out;
  mcapi_endpoint_t raw_frame_out;
  mcapi_endpoint_t cfg_mem_out;
  
  // external endpoints
  mcapi_endpoint_t start_frame_manip;
  mcapi_endpoint_t mem_cfg;
  mcapi_endpoint_t mem_data;
  

  /************************************/
  /*       FUNCAPI INIT BEGINS        */
  /************************************/

  /*Create node*/
  mcapi_initialize(MY_NODE_ID,&version,&status);
  if (status != MCAPI_SUCCESS) { WRONG }
  
  /* create endpoints */
  start_new_frame_gen = mcapi_create_endpoint (PORT_NUM_0,&status);
  if (status != MCAPI_SUCCESS) { WRONG }

  start_frame_manip_out = mcapi_create_endpoint (PORT_NUM_1,&status);
  if (status != MCAPI_SUCCESS) { WRONG }

  raw_frame_out = mcapi_create_endpoint (PORT_NUM_2,&status);
  if (status != MCAPI_SUCCESS) { WRONG }

  /* get start_raw_frame_manip  receive endpoint from database */
  start_frame_manip = mcapi_get_endpoint(PIC_MAN_ID, START_RAW_FRAME_MANIP_PORT, &status);
  if (status != MCAPI_SUCCESS) { WRONG}
  
  /* get mem data_input  endpoint from database */
  mem_data = mcapi_get_endpoint(MEM_ID, MEM_DATA_PORT, &status);
  if (status != MCAPI_SUCCESS) { WRONG}

  /* connect packet channel */
  mcapi_connect_pktchan_i(raw_frame_out,ext_data_out,&request,&status);
  while (!mcapi_test(&request,&size,&status)) {}
  if (status != MCAPI_SUCCESS) { WRONG }

  /* now open the send side of the connected channel */
  mcapi_open_pktchan_send_i(&send_handle,int_data_out, &request, &status);
  while (!mcapi_test(&request,&size,&status)) {}
  if (status != MCAPI_SUCCESS) { WRONG }
  
  
  /************************************/
  /*       FUNCAPI INIT DONE          */
  /************************************/



  /************************************/
  /*       FRAME GEN BEGINS           */
  /************************************/ 
  buf_ptr = &buffer;

  while(TRUE) {
    
    x_move = 0;
    y_move = 0;
    h_count = 0;
    v_count = 0;
    
    while( (h_count == H_pixels_across) && (v_count != V_pixels_down) ) { // Active picture area ends. 
      if ( h_count == H_pixels_across) { 
	h_count = 0;
      }
    
      if (h_count > 60 + x_move && 
	  h_count < 120 + x_move &&
	  v_count > 50 + y_move &&
	  v_count < 65 + y_move) {
      
	*buf_ptr = 0xFF; // White T-letter, _-section
	buf_ptr = buf_ptr+1;
      }
      else if (h_count > (80 + x_move) &&
	       h_count < (100 + x_move) &&
	       v_count > (50 + y_move) &&
	       v_count < (100 + y_move) ) {
	
	*buf_ptr = 0xFF; // White T-letter, I-section
	buf_ptr = buf_ptr+1;
      }    
      else
	*buf_ptr = 0x00; // Black background
        buf_ptr = buf_ptr+1;
      if (h_count == H_pixels_across-1) {
	// new horiz row starts
	v_count = v_count +1;
	buf_ptr = buffer;
	mcapi_pkt_send(send_handle,buf_ptr,PKT_SIZE,&status);
	
      }
      else
 	h_count <= h_count + 1;
     

    }


    if (x_move < 320) {
      x_move = x_move + 1;
    }
    else
      {
	x_move = 0; 
	x_move = x_move; 
	
	if (x_move = 319) {
	  if (y_move >= 240) {
	    y_move = 0;
	  }
	  else
	    y_move <= y_move + 1;
	  
	}
	
      }
  
      
    /************************************/
    /*       FRAME GEN DONE             */
    /************************************/
    
    *buf_ptr = START_MANIPULATION;
    buf_ptr = buf_ptr +1;
    *buf_ptr = RAW_FRAME_ADDRESS;
    /* Infrom picture manipulator to start frame manipulation from raw frame location  */
    mcapi_msg_send(start_frame_manip_out, start_frame_manip  , &buffer, 8 , PRIORITY, &status);
    if (status != status) { WRONG}
    
    *buf_ptr = 0;
    
    // waiting for start new frame generation command (= 0x03)
    while ( *buf_ptr != 0x3) { 
      mcapi_msg_recv(start_new_frame_gen, buf_ptr, BUFF_SIZE, &received_size, &status);
      if (status != exp_status) { WRONG}
    }
    
    
  }
  
  
  
  
  return 0;
}
