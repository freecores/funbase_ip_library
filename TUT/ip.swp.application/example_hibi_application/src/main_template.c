// 2009-10-02 Tapio Koskinen
//
// This file illustrates simple usage of HIBI with nios communication

// This is the only header that requires OS libraries.
// Used by printf().
#include <stdio.h>

// If printf is not available, maybe leds can be used.
//#include "led_api.h"

// N2H register locations
#include "N2H_registers_and_macros.h"

// N2H commands
#include "tut_n2h_regs.h"

// Contains HW names which are mapped to integers with "#define" statements.
//#include "hw_ids.h"

// hibiAddresses.c must be compiled too. These too files are generated within
// Kactus. See Generators-tab in Kactus.
//#include "hibiAddresses.h"

#define RX_DATA_CH 0
#define RCV_AMOUNT 10

volatile unsigned int data[RCV_AMOUNT];

// Initialize a given channel for incoming data. Wait data to address
// rx_hibi_addr and save it to dst_mem_addr (which must be in
// dual-port memory, which both Nios and N2H2 can access.
// See N2H_registers_and_macros.h and N2H_REGISTERS_BUFFER_START-macro).
void initCh(unsigned int rx_hibi_addr, int channel, int dst_mem_addr, int amount) {
    N2H_CLEAR_IRQ(channel, N2H_REGISTERS_BASE_ADDRESS);
    N2H_CHAN_CONF(channel,
              dst_mem_addr, 
              rx_hibi_addr,
              amount,
              N2H_REGISTERS_BASE_ADDRESS);
}

// Print received data.
void getAnswer() {

    int chan = -1;
    // Polling N2H2 IRQ register
    while (chan != RX_DATA_CH) {

        // Get channel number which has received data
        chan = N2H_GET_IRQ_CHAN(N2H_REGISTERS_BASE_ADDRESS);

        if (chan == RX_DATA_CH) {
            printf("Received data: %s\n", data);
        }
    }  
}

int main() {
    LedInitialize();
    
    // When codes are compiled with SW compilation -tool, macro "CPU_ID"
    // is defined with another macro, which in turn is defined in hw_ids.h
    // header file.
    unsigned int my_base_hibi_addr = getHibiAddress(CPU_ID);
    
    // CPU2 is also defined in hw_ids.h -file
    // (which is created based on IP-XACT design during execution of Koski GUI)
    unsigned int dest_hibi_addr = getHibiAddress(CPU1);

    // Enable N2H2.
    N2H_RX_IRQ_ENA(N2H_REGISTERS_BASE_ADDRESS);
    
    // Initialize channel for receiving data.
    initCh(my_base_hibi_addr, RX_DATA_CH, &data, RCV_AMOUNT);
    
    // Send data to other CPU. Just send one word of anything
    // (whatever is at "data").
    N2H_SEND(&data, 1, dest_hibi_addr, N2H_REGISTERS_BASE_ADDRESS);
    
    // Wait for an answer.
    printf("Data has been sent\n");
    getAnswer();
    
    // Turn one led on.
    LedTurnOn(0);
    
    return 0;
}
