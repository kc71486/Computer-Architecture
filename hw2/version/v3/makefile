.PHONY: clean

include toolchain.mk

OLVL := -O0
ASFLAGS := -march=rv32i_zicsr -mabi=ilp32
CFLAGS := -Wall -Wextra $(OLVL)


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
	$(CROSS_COMPILE)gcc -o $@ $^

clean:
	$(RM) $(BIN) $(OBJS)
