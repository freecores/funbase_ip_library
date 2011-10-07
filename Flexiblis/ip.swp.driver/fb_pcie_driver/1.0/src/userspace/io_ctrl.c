/** @file funbase_io.c
* Funbase io.
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
* $Id: io_ctrl.c 10668 2010-03-10 18:50:42Z timokosk $
*******************************************************************************/
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>

#include <fbd_ioctl.h>

/**
 * Read 32 bit value from FPGA.
 * @param fd Character device fd.
 * @param address Address in FPGA internal bus.
 * @param data Read value is returned here.
 * @return 0 on success or negative error code.
 */
int read32(int fd, uint32_t address, uint32_t * data)
{
    struct fbd_cmd_struct fbd_cmd;

    fbd_cmd.address = address;
    if( ioctl(fd, FBD_IOCTL_READ_DATA32, &fbd_cmd) != 0 ){
        perror("ioctl");
        return -1;
    }

    *data = fbd_cmd.data32;

    return 0;
}

/**
 * Read 64 bit value from FPGA.
 * @param fd Character device fd.
 * @param address Address in FPGA internal bus.
 * @param data Read value is returned here.
 * @return 0 on success or negative error code.
 */
int read64(int fd, uint32_t address, uint64_t * data)
{
    struct fbd_cmd_struct fbd_cmd;

    fbd_cmd.address = address;
    if( ioctl(fd, FBD_IOCTL_READ_DATA64, &fbd_cmd) != 0 ){
        perror("ioctl");
        return -1;
    }

    *data = fbd_cmd.data64;

    return 0;
}

/**
 * Write 32 bit value to FPGA.
 * @param fd Character device fd.
 * @param address Address in FPGA internal bus.
 * @param data Data to write.
 * @return 0 on success or negative error code.
 */
int write32(int fd, uint32_t address, uint32_t data)
{
    struct fbd_cmd_struct fbd_cmd;

    fbd_cmd.address = address;
    fbd_cmd.data32 = data;

    if( ioctl(fd, FBD_IOCTL_WRITE_DATA32, &fbd_cmd) != 0 ){
        perror("ioctl");
        return -1;
    }

    return 0;
}

/**
 * Write 64 bit value to FPGA.
 * @param fd Character device fd.
 * @param address Address in FPGA internal bus.
 * @param data Data to write.
 * @return 0 on success or negative error code.
 */
int write64(int fd, uint32_t address, uint64_t data)
{
    struct fbd_cmd_struct fbd_cmd;

    fbd_cmd.address = address;
    fbd_cmd.data64 = data;

    if( ioctl(fd, FBD_IOCTL_WRITE_DATA64, &fbd_cmd) != 0 ){
        perror("ioctl");
        return -1;
    }


    return 0;
}

