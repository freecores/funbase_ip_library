# Makefile for Funbase io

SHELL = /bin/sh

#### Start of system configuration section. ####
srcdir = .
CC = gcc -rdynamic -O
RM = rm -rf

# Directories.
prefix = /usr/local
bindir = $(prefix)/bin

LIBS =  
LIBDIRS = 
INCLUDES = -I../driver
CDEBUG = -g
CFLAGS = $(CDEBUG) $(INCLUDES) -Wall -O0
LDFLAGS = -g $(LIBDIRS) $(LIBS)

#### End of system configuration section. ####

OBJ = main.o io_ctrl.o
HDR = *.h

PROG = io_ctrl

.c.o:
	$(CC) -c $(CFLAGS) -o $@ $<

all: $(PROG) 

$(PROG): $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $(OBJ)

$(OBJ): $(HDR)

install: all
	cp $(PROG) $(bindir)/

clean: 
	$(RM) $(PROG) $(OBJ)

