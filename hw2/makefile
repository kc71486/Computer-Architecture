.PHONY: clean

include toolchain.mk

ASFLAGS = -march=rv32i_zicsr -mabi=ilp32
LDFLAGS = --oformat=elf32-littleriscv
CFLAGS = -O2 -Wall

OBJS = \
    getcycles.o \
    main.o \
    hammingc.o

LDS = link.ld

BIN = hammingdistance.elf

%.o: %.s
	$(CROSS_COMPILE)gcc $(ASFLAGS) -c -o $@ $<

%.o: %.c
	$(CROSS_COMPILE)gcc $(ASFLAGS) $(CFLAGS) -c -o $@ $<

all: $(BIN)

$(BIN): $(OBJS)
	 $(CROSS_COMPILE)gcc -o $@ -T $(LDS) $(LDFLAGS) -lc $^

clean:
	$(RM) $(BIN) $(OBJS)