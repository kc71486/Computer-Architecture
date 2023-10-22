int32_t HammingDistance_c(uint64_t x0, uint64_t x1) {
    int32_t Hdist = 0; //s3, not initialized
    uint32_t = x0low = x0 & 0xffffffffL; //s4
    uint32_t = x0high = x0 >> 32; //s5
    uint32_t = x1low = x1 & 0xffffffffL; //s6
    uint32_t = x1high = x1 >> 32; //s7
    int32_t max_digit = 64 - count_leading_zeros((x0 > x1)? x0 : x1); //s2
    while(max_digit != 0) {
        uint32_t c1, c2;
        if(max_digit > 32) {
            c1 = x0high & 1;
            c2 = x1high & 1;
        }
        else {
            c1 = x0low & 1;
            c2 = x1low & 1;
        }
        x0low = (x0low >> 1) | (x0high << 31);
        x0high = x0high >> 1;
        x1low = (x1low >> 1) | (x1high << 31);
        x1high = x1high >> 1;
        
        if(c1 != c2) Hdist += 1;
        
        max_digit -= 1;
    }
    return Hdist;
}
int32_t HammingDistance_c(uint64_t x0, uint64_t x1) {
    int32_t Hdist = 0; //s3, not initialized
    uint32_t = x0low = x0 & 0xffffffffL; //s4
    uint32_t = x0high = x0 >> 32; //s5
    uint32_t = x1low = x1 & 0xffffffffL; //s6
    uint32_t = x1high = x1 >> 32; //s7
    int32_t max_digit = 64 - count_leading_zeros((x0 > x1)? x0 : x1); //s2
    while(max_digit != 0) {
        uint32_t c1, c2;
        c1 = x0low & 1;
        c2 = x1low & 1;
        x0low = (x0low >> 1) | (x0high << 31);
        x0high = x0high >> 1;
        x1low = (x1low >> 1) | (x1high << 31);
        x1high = x1high >> 1;
        if(c1 != c2) Hdist += 1;
        max_digit -= 1;
    }
    return Hdist;
}