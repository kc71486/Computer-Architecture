#include <stdint.h>

static uint16_t count_leading_zeros(uint64_t x) {
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    x |= (x >> 32);

    /* count ones (population count) */
    x -= ((x >> 1) & 0x5555555555555555);
    x = ((x >> 2) & 0x3333333333333333) + (x & 0x3333333333333333);
    x = ((x >> 4) + x) & 0x0f0f0f0f0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);
    x += (x >> 32);

    return (64 - (x & 0x7f));
}

int32_t HammingDistance_c(uint64_t x0, uint64_t x1) {
    int32_t Hdist = 0;
    int32_t max_digit = 64 - count_leading_zeros((x0 > x1)? x0 : x1);
    while(max_digit > 0){
        uint64_t c1 = x0 & 1;
        uint64_t c2 = x1 & 1;
        if(c1 != c2) Hdist += 1;

        x0 = x0 >> 1;
        x1 = x1 >> 1;
        max_digit -= 1;
    }
    return Hdist;
}

int32_t HammingDistancev2_c(uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1) {
    int32_t Hdist = 0;
    int x = 0, y = 0;
    if(y0 > y1) {
        x = x0;
        y = y0;
    }
    else if(y0 < y1) {
        x = x1;
        y = y1;
    }
    else if(x0 > x1) {
        x = x0;
        y = y0;
    }
    else {
        x = x1;
        y = y1;
    }
    int32_t max_digit = 64 - count_leading_zeros(x, y);
    while(max_digit > 32) {
        Hdist += (y0 ^ y1) & 1;
        y0 = y0 >> 1;
        y1 = y1 >> 1;
        max_digit -= 1;
    }
    while(max_digit > 0) {
        Hdist += (x0 ^ x1) & 1;
        x0 = x0 >> 1;
        x1 = x1 >> 1;
        max_digit -= 1;
    }
    return Hdist;
}