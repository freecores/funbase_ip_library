// *****************************************************************************
// File             : HPD_registers_and_macros.h
// Author           : Tero Arpinen
// Date             : 22.12.2004
// Decription       : This file contains customizable register address 
//                    definitions
//                    for HPD interface and some needed macros
// 
// Version history  : 22.12.2004    tar    Original version 
//                  : 06.07.2005    tar    Modified to work with HPD2
//                  : 02.10.2009    tko    Removed unneeded macros
//                  : 17.09.2010    lm     N2H -> HPD(HIBI PE DMA)
// *****************************************************************************
 
#ifndef HPD_REGISTERS_AND_MACROS_H
#define HPD_REGISTERS_AND_MACROS_H

// DEFINE FOLLOWING REGISTERS ACCORDING TO NIOS OR NIOS II HARDWARE 
// CONFIGURATION

#ifdef __TCE__
#define HPD_REGISTERS_BASE_ADDRESS           ((void*) 0x80000000)

#else

// Hibi PE DMA Avalon slave base address
#define HPD_REGISTERS_BASE_ADDRESS            ((void*) 0x00140000)              


// Buffer start address in cpu's memory
#define HPD_REGISTERS_BUFFER_START            (0x00300000)

// Writeable registers
// set bit 31 to 1 so that writes and reads bypass cache
#define HPD_REGISTERS_TX_BUFFER_START         (0x80300000)
//#define HPD_REGISTERS_TX_BUFFER_START         (0x00300000)
#define HPD_REGISTERS_TX_BUFFER_BYTE_LENGTH (0x00000200)
#define HPD_REGISTERS_TX_BUFFER_END (HPD_REGISTERS_TX_BUFFER_START + \
                                     HPD_REGISTERS_TX_BUFFER_BYTE_LENGTH - 1)

// Readable registers
#define HPD_REGISTERS_RX_BUFFER_START	    (0x80300200)
#define HPD_REGISTERS_RX_BUFFER_BYTE_LENGTH (0x00000800)
#define HPD_REGISTERS_RX_BUFFER_END       (HPD_REGISTERS_RX_BUFFER_START + \
					   HPD_REGISTERS_RX_BUFFER_BYTE_LENGTH \
					   - 1)
                       
// Readable registers
/* #define HPD_REGISTERS_RX_BUFFER_START       (HPD_REGISTERS_TX_BUFFER_START + HPD_REGISTERS_TX_BUFFER_BYTE_LENGTH) */
/* #define HPD_REGISTERS_RX_BUFFER_BYTE_LENGTH (0x00002200) */
/* #define HPD_REGISTERS_RX_BUFFER_END         (HPD_REGISTERS_RX_BUFFER_START + \ */
/* 					   HPD_REGISTERS_RX_BUFFER_BYTE_LENGTH \ */
/* 					   - 1) */
// HPD Interrupt registers, numbers and priorities
#define HPD_RX_IRQ                      (2)
#define HPD_RX_IRQ_PRI                  (3)

#endif
// HPD Channels
//#define HPD_NUMBER_OF_CHANNELS              (8)

#endif // HPD_REGISTERS_AND_MACROS_H
