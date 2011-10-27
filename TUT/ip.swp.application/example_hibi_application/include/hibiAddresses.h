// Automatically generated file for HIBI addresses
// 28.07.2009 17:21:38

#ifndef HIBI_ADDRESSES_H
#define HIBI_ADDRESSES_H

#define NUM_OF_SEGMENTS 1
#define TOTAL_PES_ON_HIBI 3

// This array contains PE name & PE HIBI address -pairs
extern unsigned int hibiAddresses[TOTAL_PES_ON_HIBI*2];
// This array contains PE name & segment number PE belongs to -pairs
extern unsigned int segments[TOTAL_PES_ON_HIBI*2];

// Index these arrays with segment number
extern unsigned int numOfCpusInSegment[NUM_OF_SEGMENTS];
extern unsigned int numOfPesInSegment[NUM_OF_SEGMENTS];

#endif
