#include <stdio.h>
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

int32_t HammingDistancev0_c(uint64_t x0, uint64_t x1) {
    int32_t Hdist = 0;
    int16_t max_digit = 64 - (int16_t)count_leading_zeros((x0 > x1)? x0 : x1);
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