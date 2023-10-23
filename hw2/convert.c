#include <stdint.h>
#include "convert.h"

int32_t itos(int32_t input, char *str, int32_t strsize) {
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
        return 2;
    }
    char buf[12] = {0};
    int32_t bufidx = 0;
    int32_t stridx = 0;
    if(input < 0) {
        input = 0 - input;
        while(input > 0) {
            buf[bufidx] = (char) ((input % 10) + 48);
            input /= 10;
            bufidx += 1;
        }
        buf[bufidx] = '-';
    }
    else {
        while(input > 0) {
            buf[bufidx] = (char) ((input % 10) + 48);
            input /= 10;
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