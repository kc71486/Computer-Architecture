#include <stdint.h>
#include <stdio.h>

extern uint64_t get_cycles();
extern void printstr(const char *, uint32_t);

//extern int HammingDistance_c(uint64_t, uint64_t);
extern int HammingDistance_s(uint64_t *, uint64_t *);

uint64_t test1_x0 = 0x0013000000100000;
uint64_t test1_x1 = 0x00000000000FFFFF;
uint64_t test2_x0 = 0x0000000200000001;
uint64_t test2_x1 = 0x7FFFFFFFFFFFFFFE;
uint64_t test3_x0 = 0x000000028370228F;
uint64_t test3_x1 = 0x000000028370228F;

int main(){
    uint32_t start = get_cycles();
    //int32_t d1 = HammingDistance_c(test1_x0, test1_x1);
    //int32_t d2 = HammingDistance_c(test2_x0, test2_x1);
    //int32_t d3 = HammingDistance_c(test3_x0, test3_x1);
    int32_t d1 = HammingDistance_s(&test1_x0, &test1_x1);
    int32_t d2 = HammingDistance_s(&test2_x0, &test2_x1);
    int32_t d3 = HammingDistance_s(&test3_x0, &test3_x1);
    uint32_t end = get_cycles();
    printstr("Elapse cycle:", 14);
    printf("ld\n", end - start);
    printf("Hamming Distance:%ld\n", d1); // 24
    printf("Hamming Distance:%ld\n", d2); // 62
    printf("Hamming Distance:%ld\n", d3); // 0
    return 0;
}