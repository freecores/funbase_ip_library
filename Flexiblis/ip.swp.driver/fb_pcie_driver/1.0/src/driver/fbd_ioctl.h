/** @file fbd_ioctl.h
* Funbase device driver ioctl header file.
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
* $Id: fbd_ioctl.h 10668 2010-03-10 18:50:42Z timokosk $
*******************************************************************************/

#ifndef _FBD_IOCTL_H_
#define _FBD_IOCTL_H_

#define FBD_IOCTL_MAGIC 0x39
#define FBD_CTRL_DEV "/dev/fbd0"        // ioctl device, used form userspace


/**
* FBD commands.
*/
struct fbd_cmd_struct {
    uint32_t address;                ///< bus address
    union {
        uint32_t data32;             ///< data to write, place for read data
        uint64_t data64;
    };
};

// read from address
#define FBD_IOCTL_READ_DATA64     _IOWR(FBD_IOCTL_MAGIC,40, struct fbd_cmd_struct)
#define FBD_IOCTL_READ_DATA32     _IOWR(FBD_IOCTL_MAGIC,41, struct fbd_cmd_struct)
// write to address
#define FBD_IOCTL_WRITE_DATA64    _IOW(FBD_IOCTL_MAGIC,50, struct fbd_cmd_struct)
#define FBD_IOCTL_WRITE_DATA32    _IOW(FBD_IOCTL_MAGIC,51, struct fbd_cmd_struct)

#endif                          // _FBD_IOCTL_H_
