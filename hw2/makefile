.PHONY: clean

include toolchain.mk

OLVL := -O0
ABIFLAGS := -march=rv32i_zicsr -mabi=ilp32
GCCFLAGS := -fdata-sections -ffunction-sections
CFLAGS := -Wall -Wextra $(OLVL)
LDFLAGS := -Wl,--gc-sections

OBJS = \
    main.o \
    cycles.o \
    print.o \
    convert.o \
    hammingc.o \
    hammings.o

BIN = hammingdistance.elf

%.o: %.s
	$(CROSS_COMPILE)gcc $(GCCFLAGS) $(ABIFLAGS) -c -o $@ $<

%.o: %.c
	$(CROSS_COMPILE)gcc $(GCCFLAGS) $(ABIFLAGS) $(CFLAGS) -c -o $@ $<

all: $(BIN)

$(BIN): $(OBJS)
	$(CROSS_COMPILE)gcc $(LDFLAGS) -o $@ $^

clean:
	$(RM) $(BIN) $(OBJS)
