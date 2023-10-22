#include <stdint.h>
#include "convert.h"
#include "print.h"

extern uint64_t get_cycles();

//extern int32_t HammingDistance_c(uint64_t, uint64_t);
extern int32_t HammingDistance_s(uint64_t *, uint64_t *);

static uint64_t test1_x0 = 0x0013000000100000;
static uint64_t test1_x1 = 0x00000000000FFFFF;
static uint64_t test2_x0 = 0x0000000200000001;
static uint64_t test2_x1 = 0x7FFFFFFFFFFFFFFE;
static uint64_t test3_x0 = 0x000000028370228F;
static uint64_t test3_x1 = 0x000000028370228F;

char intbuf[12] = {0};

int main(){
    uint32_t start = get_cycles();
    //int32_t d1 = HammingDistance_c(test1_x0, test1_x1);
    //int32_t d2 = HammingDistance_c(test2_x0, test2_x1);
    //int32_t d3 = HammingDistance_c(test3_x0, test3_x1);
    int32_t d1 = HammingDistance_s(&test1_x0, &test1_x1);
    int32_t d2 = HammingDistance_s(&test2_x0, &test2_x1);
    int32_t d3 = HammingDistance_s(&test3_x0, &test3_x1);
    uint32_t end = get_cycles();
    // first print method
    printstr("Elapse cycle:", 14);
    int strsize = itos(end - start, intbuf, 12);
    printstr(intbuf, strsize);
    printchar('\n');
    // second print method
    printstr("Hamming Distance:", 18);
    printint(d1);
    printchar('\n');
    printstr("Hamming Distance:", 18);
    printint(d2);
    printchar('\n');
    printstr("Hamming Distance:", 18);
    printint(d3);
    printchar('\n');
    return 0;
}