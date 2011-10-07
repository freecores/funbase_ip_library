/** @file fbd_main.c
* Funbase device driver main file.
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
* $Id: fbd_main.c 10668 2010-03-10 18:50:42Z timokosk $
*******************************************************************************/

#if !defined(__OPTIMIZE__)
#warning  You must compile this file with the correct options!
#warning  See the last lines of the source file.
#error You must compile this driver with "-O".
#endif

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
#include <linux/mii.h>
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
#include <linux/version.h>

#include "fbd.h"
#include "fbd_ioctl.h"

#define PCI_IOTYPE (PCI_USES_MASTER | PCI_USES_MEM | PCI_ADDR0)

static struct pci_device_id fbd_pci_tbl[] __devinitdata = {
    {0x1172, 0x0008, PCI_ANY_ID, PCI_ANY_ID, 0, 0, 0},  //Altera
    {0,}
};

//supported FBD devices:
#define NUMBER_OF_SUPPORTED_PCI_DEVICES 1
struct supported_pci_device
    supported_pci_devices[NUMBER_OF_SUPPORTED_PCI_DEVICES] = {
    {0x1172, 0x0008, "Altera Stratix GX PCIe DevKit", MSI_ALTERA},
};

//global variables:
#ifdef MODULE                   //if compiled as a kernel module
MODULE_DESCRIPTION("Flexibilis Funbase device driver");
MODULE_AUTHOR("Timo Koskiahde");
MODULE_DEVICE_TABLE(pci, fbd_pci_tbl);
MODULE_LICENSE("Proprietary");
#endif                          //MODULE

// Static data
static struct fbd_private fbd_priv;


//functions:
static int __devinit fbd_init_one_pci(struct pci_dev *pdev,
                                      const struct pci_device_id *ent);
static void __devexit fbd_remove_one_pci(struct pci_dev *pdev);
static int __init fbd_init(void);
static void __exit fbd_cleanup(void);

/**
 * Init one Funbase device that is in PCI bus.
 */
static int __devinit fbd_init_one_pci(struct pci_dev *pdev,
                                      const struct pci_device_id *ent)
{
    unsigned long pci_ioaddr;
    int pci_device_type;        //in supported_pci_devices -list
    int pci_device_identified = 0;
    int error;
    
    error = pci_enable_device(pdev);
    if (error) {
        printk("FBD: warning: pci_enable_device returned %x.\n", error);
        return error;
    }
    
    error = pci_request_regions(pdev, DRV_NAME);
    if (error) {
        printk("FBD: cannot allocate io region\n");
        return error;
    }
    
    pci_set_master(pdev);
    
    pci_ioaddr = pci_resource_start(pdev, 0);
    printk(" FBD: PCI io address for FBD: 0x%lx.\n", pci_ioaddr);
    pci_ioaddr = (long) ioremap_nocache(pci_ioaddr, PCI_SIZE);
    printk(" FBD: Remapped to: 0x%lx.\n", pci_ioaddr);
    
    if (!pci_ioaddr) {
        printk("FBD: unable to remap io region\n");
        goto err_out_3;
    }

    //check which kind of a PCI device we have here:
    for (pci_device_type = 0;
         pci_device_type < NUMBER_OF_SUPPORTED_PCI_DEVICES;
         pci_device_type++) {
        if (pdev->vendor !=
            supported_pci_devices[pci_device_type].pci_vendor_id)
            continue;
        if (pdev->device !=
            supported_pci_devices[pci_device_type].pci_device_id)
            continue;
        pci_device_identified = 1;
        goto identified;
    }
    if (!pci_device_identified) {
        printk
            ("FBD: PCI device with vendor id 0x%x and device id 0x%x not supported by this driver.\n",
             pdev->vendor, pdev->device);
        goto err_out_2;
    }

  identified:
    //tell the user what kind of a PCI device we are:
    printk("FBD: Identified PCI device: %s\n",
           supported_pci_devices[pci_device_type].pci_device_name);
    printk(" FBD: PCI device vendor id 0x%x and device id 0x%x.\n",
           pdev->vendor, pdev->device);
    
    //enable msi interrupts if msi supported
    if (supported_pci_devices[pci_device_type].msi_supported) {
#ifndef CONFIG_PCI_MSI
        printk
            ("FBD: Must enable MSI support in kernel to be able to use PCI Express version of FBD.\n");
        goto err_out_2;
#else                           //CONFIG_PCI_MSI
        if (supported_pci_devices[pci_device_type].msi_supported ==
            MSI_ALTERA) {
            outl(1 << 7, pci_ioaddr + 0x20000 + 0x50);  //Enabling MSI in Altera PCI Express core
        }
        error = pci_enable_msi(pdev);
        if (error) {
            printk("FBD: unable to enable MSI, error 0x%x", error);
        } else {
            printk("FBD: FBD enabled MSI succesfully.\n");
        }
#endif                          //CONFIG_PCI_MSI
    }
    // fill fbd_private
    fbd_priv.device_id = 0;     //TODO
    fbd_priv.revision_id = 0;   //TODO
    fbd_priv.base_addr = pci_ioaddr;
    fbd_priv.pci_dev = pdev;

    // Open char device
    fbd_register_char_device(&fbd_priv);
    
    return 0;
err_out_2:
    iounmap((void *) pci_ioaddr);
err_out_3:
    pci_release_regions(pdev);
    return -ENODEV;
}


/**
 * Remove PCI device from the system.
 */
static void __devexit fbd_remove_one_pci(struct pci_dev *pdev)
{

    fbd_unregister_char_device(&fbd_priv);
#ifdef CONFIG_PCI_MSI
    pci_disable_msi(pdev);
#endif
    pci_release_regions(pdev);  //release io areas
//    iounmap ((void *) pci_resource_start (pdev, 0));
    iounmap((void *) fbd_priv.base_addr);
    pci_set_drvdata(pdev, NULL);
}

/**
 * PCI driver data.
 */
static struct pci_driver fbd_driver = {
  name:DRV_NAME,
  id_table:fbd_pci_tbl,
  probe:fbd_init_one_pci,
  remove:fbd_remove_one_pci,
};

/**
 * Init the FBD driver.
 */
static int __init fbd_init(void)
{
    int res;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,20)
    res = pci_register_driver(&fbd_driver);     //init PCI devices
#else
    res = pci_module_init(&fbd_driver); //init PCI devices
#endif

    if (res)
        goto errout;

    return 0;

  errout:
    return res;
}

/**
 * Remove the FBD driver from the system.
 */
static void __exit fbd_cleanup(void)
{
    pci_unregister_driver(&fbd_driver);
}

module_init(fbd_init);
module_exit(fbd_cleanup);
