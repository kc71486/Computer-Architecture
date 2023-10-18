#include <stdint.h>
#include <stdio.h>

extern uint64_t get_cycles();

extern int HammingDistance(uint64_t, uint64_t);

uint64_t test1_x0 = 0x0000000000100000;
uint64_t test1_x1 = 0x00000000000FFFFF;
uint64_t test2_x0 = 0x0000000000000001;
uint64_t test2_x1 = 0x7FFFFFFFFFFFFFFE;
uint64_t test3_x0 = 0x000000028370228F;
uint64_t test3_x1 = 0x000000028370228F;

int main(){
    int32_t start = get_cycles();
    int32_t d1 = HammingDistance(test1_x0, test1_x1);
    int32_t d2 = HammingDistance(test2_x0, test2_x1);
    int32_t d3 = HammingDistance(test3_x0, test3_x1);
    int32_t end = get_cycles();
    
    printf("Hamming Distance=%d\n", d1);
    printf("Hamming Distance=%d\n", d2);
    printf("Hamming Distance=%d\n", d3);
    return 0;
}