/** @file fbd.h
* Funbase device driver main header file.
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
* $Id: fbd.h 10668 2010-03-10 18:50:42Z timokosk $
*******************************************************************************/

#ifndef _FBD_H_
#define _FBD_H_

//#define DBG_PRINT(xyz...) printk(xyz) //enable debug printings
#define DBG_PRINT(xyz...)       //disable debug printings

#define DRV_NAME	"FBD"

#define PCI_SIZE 0x100000       //the size of the PCI io region

//PCI devices supported
struct supported_pci_device {
    unsigned long pci_vendor_id;
    unsigned long pci_device_id;
    char pci_device_name[50];
#define NO_MSI      0x0
#define MSI         0x1
#define MSI_ALTERA  0x2
    int msi_supported;
};


struct fbd_private {            //data specific to one certain fbd device
    int device_id;              //device id of this device
    int revision_id;            //revision id of this device
    unsigned int base_addr;

    struct pci_dev *pci_dev;    // FBD as a PCI device
};

// ioctl register functions
int fbd_register_char_device(struct fbd_private *fbd);
int fbd_unregister_char_device(struct fbd_private *fbd);

#endif                          // _FBD_H_
