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

int32_t HammingDistance_c(uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1) {
    uint64_t v0 = ((uint64_t) y0) << 32 | x0;
    uint64_t v1 = ((uint64_t) y1) << 32 | x1;
    int32_t Hdist = 0;
    int32_t max_digit = 64 - count_leading_zeros((v0 > v1)? v0 : v1);
    while(max_digit > 0){
        uint64_t c1 = v0 & 1;
        uint64_t c2 = v1 & 1;
        if(c1 != c2) Hdist += 1;

        v0 = v0 >> 1;
        v1 = v1 >> 1;
        max_digit -= 1;
    }
    return Hdist;
}
