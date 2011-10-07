/** @file main.c
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
* $Id: main.c 10668 2010-03-10 18:50:42Z timokosk $
*******************************************************************************/
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include <fbd_ioctl.h>

#include "io_ctrl.h"

int main(void){
    int ret = 0;
    int fd = 0;
    uint32_t address = 0;
    uint32_t data = 0;

    fd = open(FBD_CTRL_DEV, O_RDWR | O_NONBLOCK);
    if( fd < 0) {
        perror("open");
        return -1;
    }

    ret = read32(fd, address, &data);
 
    printf("Read from address 0x%08x data 0x%08x\n", address, data);

    close(fd);

    return 0;
}
