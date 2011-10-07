#include "hibi_pe_dma.h"
#include "HPD_registers_and_macros.h"


#if defined(API)
struct Channel_reservation {
 
    int mem_addr;
    int amount;
    
};

static struct Channel_reservation 
    channel_reservations[HPD_NUMBER_OF_CHANNELS] = {};


// Common interrupt service routine. Clear IRQ and call HPD_RX_DONE.
void isr() {
  
    int chan = HPD_GET_IRQ_CHAN(HPD_REGISTERS_BASE_ADDRESS);
    HPD_RX_DONE( chan, channel_reservations[chan].mem_addr, channel_reservations[chan].amount );
    channel_reservations[chan].mem_addr = 0;
    channel_reservations[chan].amount = 0;
    HPD_RX_CLEAR_IRQ(chan,HPD_REGISTERS_BASE_ADDRESS);
}


// NIOSII specific interrupt handling

void hpd_isr( void* context, int id ) {
    isr();
}

// NIOSII specific interrupt init
void HPD_INIT_ISR() {
  
  alt_irq_register( HPD_RX_IRQ, 0, hpd_isr );
  HPD_RX_IRQ_ENA( HPD_REGISTERS_BASE_ADDRESS );

}

void HPD_GET_RX_BUFFER( int* dst, int src, int amount ) {
 
    // TODO: check that src is inside RX buffer
    // TODO: if src and dst are same, do nothing    
    int i;
    for( i = 0; i < amount; ++i ) {
    
	*(dst + i) = *((int*)src + i);
    }
}

void HPD_PUT_TX_BUFFER( int dst, int* src, int amount ) {
    
    // TODO: check that dst is inside TX buffer
    // TODO: if src and dst are same, do nothing   
    
    int i;
    for( i = 0; i < amount; ++i ) {
	
	*((int*)dst + i) = *(src + i);
    }
    
}
#endif // API

/*
* DMA engine configuration functions (Updated on 27/04/2005)
*/

// Prepare channel for receiving data.
void HPD_CHAN_CONF(int channel, int dst_mem_addr, int rx_haddr, int amount, 
		   int* base)
{
#ifdef API
  channel_reservations[channel].mem_addr = dst_mem_addr;
  channel_reservations[channel].amount = amount; 
#endif
  HPD_CHAN_MEM_ADDR(channel, dst_mem_addr, base);
  HPD_CHAN_HIBI_ADDR(channel, rx_haddr, base);
  HPD_CHAN_AMOUNT(channel, amount, base);
  HPD_CHAN_INIT(channel, base);
}

void HPD_SEND(int src_mem_addr, int amount, int dst_haddr, int* base) {
  while( !HPD_TX_DONE(base) );
  HPD_TX_MEM_ADDR(src_mem_addr, base);
  HPD_TX_AMOUNT(amount, base);
  HPD_TX_HIBI_ADDR(dst_haddr, base);
  HPD_TX_COMM_WRITE(base);
  HPD_TX_START(base);
}

// Parameter types were uint32. Int works in other places, so why not here?
void HPD_SEND_READ(int mem_addr, int amount, int haddr, int* base) {
  while( !HPD_TX_DONE(base) );
  HPD_TX_MEM_ADDR(mem_addr, base);
  HPD_TX_AMOUNT(amount, base);
  HPD_TX_HIBI_ADDR(haddr, base);
  HPD_TX_COMM_READ(base);
  HPD_TX_START(base);
}

void HPD_SEND_MSG(int src_mem_addr, int amount, int dst_haddr, int* base) {
  while( !HPD_TX_DONE(base) );
  HPD_TX_MEM_ADDR(src_mem_addr, base);
  HPD_TX_AMOUNT(amount, base);
  HPD_TX_HIBI_ADDR(dst_haddr, base);
  HPD_TX_COMM_WRITE_MSG(base);
  HPD_TX_START(base);
}

// Return 0 if transmission is not done yet, 1 otherwise.
int HPD_TX_DONE(int* base) {
  int y = 0;
  HPD_GET_TX_DONE(y, base);
  return y;  
}

void HPD_CLEAR_IRQ(int chan, int* base) {
  HPD_RX_CLEAR_IRQ(chan, base);
}

// Returns first channel number which has IRQ flag up.
// If no interrupts have been received -1 is returned.
int HPD_GET_IRQ_CHAN(int* base)
{
  volatile int * apu = base + 7;
  int irq_reg = *apu;
  int mask = 1;
  int shift = 0;
  for (shift = 0; shift < 32; shift++) {
    if ((irq_reg & (mask << shift)) != 0) {
      return shift;
    }
  }
  return -1;
}

