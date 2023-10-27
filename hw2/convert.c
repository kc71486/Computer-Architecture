#include <stdint.h>
#include "convert.h"

extern uint32_t udiv32(uint32_t, uint32_t);
extern uint32_t umod32(uint32_t, uint32_t);

uint32_t itos(int32_t input, char *str, uint32_t strsize) {
    //otherwise it will not put anything
    if(input == 0) {
        if(strsize < 2) {
            return 0;
        }
        str[0] = '0';
        str[1] = 0;
        return 2;
    }
    //cannot simply negate this
    if(input == -2147483648) {
        if(strsize < 12) {
            return 0;
        }
        str[0] = '-';
        str[1] = '2';
        str[2] = '1';
        str[3] = '4';
        str[4] = '7';
        str[5] = '4';
        str[6] = '8';
        str[7] = '3';
        str[8] = '6';
        str[9] = '4';
        str[10] = '8';
        str[11] = 0;
        return 12;
    }
    char buf[12] = {0};
    uint32_t bufidx = 0;
    uint32_t stridx = 0;
    uint32_t uinput;
    if(input < 0) {
        uinput = 0 - input;
        while(uinput > 0) {
            buf[bufidx] = (char) (umod32(uinput, 10) + 48);
            uinput = udiv32(uinput, 10);
            bufidx += 1;
        }
        buf[bufidx] = '-';
        bufidx += 1;
    }
    else {
        uinput = input;
        while(uinput > 0) {
            buf[bufidx] = (char) (umod32(uinput, 10) + 48);
            uinput = udiv32(uinput, 10);
            bufidx += 1;
        }
    }
    // will buffer overflow
    if(bufidx > strsize) {
        return 0;
    }
    while(bufidx > 0) {
        bufidx --;
        str[stridx] = buf[bufidx];
        stridx ++;
    }
    str[stridx] = 0;
    return stridx + 1;
}
