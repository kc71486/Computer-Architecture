.PHONY: clean

include toolchain.mk

ASFLAGS = -march=rv32i_zicsr -mabi=ilp32
CFLAGS = -O0 -Wall -Wextra

OBJS = \
    main.o \
    getcycles.o \
    print.o \
    convert.o \
    hammingc.o \
    hammings.o

BIN = hammingdistance.elf

%.o: %.s
	$(CROSS_COMPILE)gcc $(ASFLAGS) -c -o $@ $<

%.o: %.c
	$(CROSS_COMPILE)gcc $(ASFLAGS) $(CFLAGS) -c -o $@ $<

all: $(BIN)

$(BIN): $(OBJS)
	$(CROSS_COMPILE)ld -o $@ $^

clean:
	$(RM) $(BIN) $(OBJS)