/** @file fbd_ioctl.c
* Funbase device driver ioctl file.
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
* $Id: fbd_ioctl.c 10668 2010-03-10 18:50:42Z timokosk $
*******************************************************************************/
#include <linux/mm.h>
#include <linux/random.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/string.h>
#include <linux/timer.h>
#include <linux/errno.h>
#include <linux/ioport.h>
#include <linux/slab.h>
#include <linux/interrupt.h>
#include <linux/pci.h>
#include <linux/init.h>
#include <linux/netdevice.h>
#include <linux/etherdevice.h>
#include <linux/skbuff.h>
#include <linux/ethtool.h>
#include <linux/proc_fs.h>
#include <asm/uaccess.h>
#include <asm/processor.h>
#include <asm/unaligned.h>
#include <asm/bitops.h>
#include <asm/io.h>
#include <asm/delay.h>
#include <linux/version.h>
#include <asm/div64.h>
#include <linux/wait.h>

#include "fbd_ioctl.h"
#include "fbd.h"

#define MAX_DEVICES 1
int char_dev_major = 0;
struct fbd_private *dev_fbd = 0;
static int fbd_char_open(struct inode *inode, struct file *filp);
static int fbd_char_release(struct inode *inode, struct file *filp);
static int fbd_char_ioctl(struct inode *inode, struct file *filp,
                          unsigned int cmd, unsigned long arg);

/**
 * Character device file operations.
 */
struct file_operations fbd_char_fops = {
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,0)
    owner:THIS_MODULE,
#endif
    ioctl:fbd_char_ioctl,
    open:fbd_char_open,
    release:fbd_char_release,
};

/**
 * Open character device. Called when file is opened in userspace.
 */
static int fbd_char_open(struct inode *inode, struct file *filp)
{
    unsigned int minor = MINOR(inode->i_rdev);

    if (!dev_fbd) {
        return -EFAULT;
    }

    if (minor >= MAX_DEVICES) {
        return -ENODEV;
    }
    filp->f_op = &fbd_char_fops;
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
    MOD_INC_USE_COUNT;
#endif
    return 0;
}

/**
 * Close character device. Called when file is closed in userspace.
 */
static int fbd_char_release(struct inode *inode, struct file *filp)
{
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,0)
    MOD_DEC_USE_COUNT;
#endif
    return 0;
}

/**
 * IOCTL command. Called by ioctl from userspace.
 */
static int fbd_char_ioctl(struct inode *inode, struct file *filp,
                          unsigned int cmd, unsigned long arg)
{
    unsigned int minor = MINOR(inode->i_rdev);
    unsigned long ioaddr = 0;
    int retval = 0;
    struct fbd_cmd_struct fbd_cmd;
    u32 address = 0;

    DBG_PRINT(KERN_INFO " %s: ioctl_call 0x%x called for device 0x%x.\n",
              DRV_NAME, cmd, minor);

    if (minor >= MAX_DEVICES) {
        return -ENODEV;
    }

    if (!dev_fbd) {
        return -EFAULT;
    }

    ioaddr = dev_fbd->base_addr;

    DBG_PRINT(KERN_INFO "  %s: base address is 0x%lx.\n", DRV_NAME,
              ioaddr);

    if (_IOC_DIR(cmd) & (_IOC_READ | _IOC_WRITE)) {
        if (!access_ok(VERIFY_READ, (void *) arg, _IOC_SIZE(cmd))) {
            return -EFAULT;
        }
        if (!access_ok(VERIFY_WRITE, (void *) arg, _IOC_SIZE(cmd))) {
            return -EFAULT;
        }
    }
    if (_IOC_DIR(cmd) & _IOC_WRITE) {
        if (!access_ok(VERIFY_READ, (void *) arg, _IOC_SIZE(cmd))) {
            return -EFAULT;
        }
    }

    switch (cmd) {
    case FBD_IOCTL_READ_DATA64:        //read data
    case FBD_IOCTL_READ_DATA32:        //read data
        if (copy_from_user(&fbd_cmd, (void *) arg, _IOC_SIZE(cmd))) {
            printk(KERN_INFO " %s: error in ioctl call 0x%x\n", DRV_NAME,
                   cmd);
            return -ENOTTY;
        }
        address = ioaddr + fbd_cmd.address;
        if (cmd == FBD_IOCTL_READ_DATA64) {
            fbd_cmd.data64 = *((u64 *) address);
            DBG_PRINT(KERN_INFO " %s: read64 from 0x%x: 0x%llx\n",
                      DRV_NAME, address, fbd_cmd.data64);
        } else {
            fbd_cmd.data32 = *((u32 *) address);
            DBG_PRINT(KERN_INFO " %s: read32 from 0x%x: 0x%x\n",
                      DRV_NAME, address, fbd_cmd.data32);
        }
        if (copy_to_user((void *) arg, &fbd_cmd, _IOC_SIZE(cmd))) {
            printk(KERN_INFO " %s: error in ioctl call 0x%x\n", DRV_NAME,
                   cmd);
            return -ENOTTY;
        }
        break;
    case FBD_IOCTL_WRITE_DATA64:       //write data
    case FBD_IOCTL_WRITE_DATA32:       //write data
        if (copy_from_user(&fbd_cmd, (void *) arg, _IOC_SIZE(cmd))) {
            printk(KERN_INFO " %s: error in ioctl call 0x%x\n", DRV_NAME,
                   cmd);
            return -ENOTTY;
        }
        address = ioaddr + fbd_cmd.address;
        if (cmd == FBD_IOCTL_WRITE_DATA64) {
            *((u64 *) address) = fbd_cmd.data64;
            DBG_PRINT(KERN_INFO " %s: write64 to 0x%x: 0x%llx\n", DRV_NAME,
                      address, fbd_cmd.data64);
        } else {
            *((u32 *) address) = fbd_cmd.data32;
            DBG_PRINT(KERN_INFO " %s: write32 to 0x%x: 0x%x\n", DRV_NAME,
                      address, fbd_cmd.data32);
        }
        break;
    default:
        printk(KERN_WARNING " %s: Unknown ioctl command 0x%x.\n", DRV_NAME,
               cmd);
        return -ENOTTY;
    }
    return retval;
}

/**
 * Register character device. Called from module init.
 * @param fbd Module private data.
 * @return 0 on success or negative error code.
 */
int fbd_register_char_device(struct fbd_private *fbd)
{
    int error;

    error = register_chrdev(0 /*dynamic */ , DRV_NAME, &fbd_char_fops);

    if (error < 0) {
        printk(KERN_WARNING "%s: unable to register char device.\n",
               DRV_NAME);
    } else {
        char_dev_major = error;
        dev_fbd = fbd;
        DBG_PRINT("%s: registered char device, major:0x%x.\n", DRV_NAME,
                  char_dev_major);
        error = 0;
    }

    return error;
}

/**
 * Unregister character device. Called from module close.
 * @param fbd Module private data.
 * @return 0 on success or negative error code.
 */
int fbd_unregister_char_device(struct fbd_private *fbd)
{

    dev_fbd = 0;

    unregister_chrdev(char_dev_major, DRV_NAME);

    return 0;
}
