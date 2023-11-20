#include <stdint.h>
/*
static uint32_t t1_x0 = 0x00100000; // low
static uint32_t t1_y0 = 0x00130000; // high
static uint32_t t1_x1 = 0x000FFFFF;
static uint32_t t1_y1 = 0x00000000;
static uint32_t t2_x0 = 0x00000001;
static uint32_t t2_y0 = 0x00000002;
static uint32_t t2_x1 = 0x7FFFFFFF;
static uint32_t t2_y1 = 0xFFFFFFFE;
static uint32_t t3_x0 = 0x00000002;
static uint32_t t3_y0 = 0x8370228F;
static uint32_t t3_x1 = 0x00000002;
static uint32_t t3_y1 = 0x8370228F;
*/
static int32_t count_leading_zeros(uint32_t x, uint32_t y) {
    if(y != 0) {
        x = y;
        y = 32;
    }
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    /* count ones (population count) */
    x -= ((x >> 1) & 0x55555555);
    x = ((x >> 2) & 0x33333333) + (x & 0x33333333);
    x = ((x >> 4) + x) & 0x0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);

    return (64 - y - (x & 0x7f));
}

static int32_t HammingDistance(uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1) {
    int32_t Hdist = 0;
    int32_t x = 0;
    int32_t y = 0;
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

//#include <stdio.h>

int main(){
    uint32_t t1_x0 = 0x00100000; // low
    uint32_t t1_y0 = 0x00130000; // high
    uint32_t t1_x1 = 0x000FFFFF;
    uint32_t t1_y1 = 0x00000000;
    uint32_t t2_x0 = 0x00000001;
    uint32_t t2_y0 = 0x00000002;
    uint32_t t2_x1 = 0x7FFFFFFF;
    uint32_t t2_y1 = 0xFFFFFFFE;
    uint32_t t3_x0 = 0x00000002;
    uint32_t t3_y0 = 0x8370228F;
    uint32_t t3_x1 = 0x00000002;
    uint32_t t3_y1 = 0x8370228F;
    *((volatile int32_t *) 4) = HammingDistance(t1_x0, t1_y0, t1_x1, t1_y1); //24
    *((volatile int32_t *) 8) = HammingDistance(t2_x0, t2_y0, t2_x1, t2_y1); //60
    *((volatile int32_t *) 12) = HammingDistance(t3_x0, t3_y0, t3_x1, t3_y1); //0
    while(1);
}
