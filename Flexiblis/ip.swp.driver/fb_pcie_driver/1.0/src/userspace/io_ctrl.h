/** @file io_ctrl.h
* Funbase io main header file.
*/

/*
    This confidential and proprietary software may be used only as
    authorized by a licensing agreement from Flexibilis Oy.

    (C) COPYRIGHT 2008-2010 FLEXIBILIS OY, ALL RIGHTS RESERVED

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

/*******************************************************************************
* $Id: fbd.h 10667 2010-03-10 17:43:28Z timokosk $
*******************************************************************************/

#ifndef _IO_CTRL_H_
#define _IO_CTRL_H_

#include <stdio.h>
#include <stdint.h>

/**
 * Read 32 bit value from FPGA.
 * @param fd Character device fd.
 * @param address Address in FPGA internal bus.
 * @param data Read value is returned here.
 * @return 0 on success or negative error code.
 */
int read32(int fd, uint32_t address, uint32_t * data);

/**
 * Read 64 bit value from FPGA.
 * @param fd Character device fd.
 * @param address Address in FPGA internal bus.
 * @param data Read value is returned here.
 * @return 0 on success or negative error code.
 */
int read64(int fd, uint32_t address, uint64_t * data);

/**
 * Write 32 bit value to FPGA.
 * @param fd Character device fd.
 * @param address Address in FPGA internal bus.
 * @param data Data to write.
 * @return 0 on success or negative error code.
 */
int write32(int fd, uint32_t address, uint32_t data);

/**
 * Write 64 bit value to FPGA.
 * @param fd Character device fd.
 * @param address Address in FPGA internal bus.
 * @param data Data to write.
 * @return 0 on success or negative error code.
 */
int write64(int fd, uint32_t address, uint64_t data);

#endif                          // _IO_CTRL_H_
