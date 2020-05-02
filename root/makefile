LDFLAGS=-lpthread -ldl
CFLAGS=-Wall -Os
CC=$(CROSS_COMPILE)gcc

all : dcow dcow-mem ratc

dcow-mem		:	dcow-mem.o
					$(CC) -o dcow-mem dcow-mem.o $(LDFLAGS)

dcow 			:	dcow.o dirtycow.o
					$(CC) -o dcow dcow.o dirtycow.o $(LDFLAGS)

ratc			:	ratc.o
					$(CC) -o ratc ratc.o $(LDFLAGS)

dicow-mem.o		:	dcow-mem.c
					$(CC) $(CFLAGS) -c dcow-mem.c

dcow.o			:	dcow.c
					$(CC) $(CFLAGS) -c dcow.c

dirtycow.o		:	dirtycow.c
					$(CC) $(CFLAGS) -c dirtycow.c

ratc.o			:	ratc.c
					$(CC) $(CFLAGS) -c ratc.c

clean:
	rm *.o
	rm dcow
	rm dcow-mem
	rm ratc
