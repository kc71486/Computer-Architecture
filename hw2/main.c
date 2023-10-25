#include <stdint.h>
#include "convert.h"
#include "print.h"

extern uint64_t get_cycles();

extern int32_t HammingDistance_c(uint32_t, uint32_t, uint32_t, uint32_t);

static uint64_t t1_x0 = 0x00100000;//low
static uint64_t t1_y0 = 0x00130000;//high
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

char intbuf[12] = {0};

int main(){
    uint32_t startcycle = get_cycles();
    int32_t d1 = HammingDistance_c(t1_x0, t1_y0, t1_x1, t1_y1);
    int32_t d2 = HammingDistance_c(t2_x0, t2_y0, t2_x1, t2_y1);
    int32_t d3 = HammingDistance_c(t3_x0, t3_y0, t3_x1, t3_y1);
    uint32_t endcycle = get_cycles();
    // first print method
    printstr("Instruction count:", 18);
    printstr("Elapse cycle:", 13);
    int strsize = itos(end - start, intbuf, 12);
    printstr(intbuf, strsize - 1);
    printchar('\n');
    // second print method
    printstr("Hamming Distance:", 17);
    printint(d1);
    printchar('\n');
    printstr("Hamming Distance:", 17);
    printint(d2);
    printchar('\n');
    printstr("Hamming Distance:", 17);
    printint(d3);
    printchar('\n');
    return 0;
}
