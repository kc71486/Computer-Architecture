#include <stdint.h>

int32_t itos(int32_t input, char *str, int32_t strsize) {
    if(input == 0) {
        str[0] = '0';
        str[1] = 0;
        return;
    }
    char[12] buf = {0};
    int32_t bufidx = 0;
    int32_t stridx = 0;
    while(input > 0) {
        buf[bufidx] = (char) ((input % 10) + 48);
        input /= 10;
        bufidx += 1;
    }
    // will buffer overflow
    if(bufidx > strsize) {
        return;
    }
    while(bufidx > 0) {
        bufidx --;
        str[stridx] = buf[bufidx];
        stridx ++;
    }
    str[stridx] = 0;
    return stridx + 1;
}