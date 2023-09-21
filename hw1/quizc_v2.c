#include <stdio.h>

#include <stdint.h>

typedef struct {
    int32_t h;
    int32_t l;
} jint64_t;

typedef struct {
    uint32_t h;
    uint32_t l;
} ujint64_t;

uint32_t get_highest_digit(uint32_t x) {
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

    return x & 0x7f;
}

uint64_t mask_lowest_zero(uint64_t x) {
    // any bit higher than lowest zero will become zero
    // become the form of 00000001111
    uint64_t mask = x;
    mask &= (mask << 1) | 0x1;
    mask &= (mask << 2) | 0x3;
    mask &= (mask << 4) | 0xF;
    mask &= (mask << 8) | 0xFF;
    mask &= (mask << 16) | 0xFFFF;
    mask &= (mask << 32) | 0xFFFFFFFF;
    return mask;
}
int64_t inc(int64_t x) {
    if (~x == 0) {
        return 0;
    }
    /* TODO: Carry flag */
    int64_t mask = mask_lowest_zero(x);
    int64_t z1 = mask ^ ((mask << 1) | 1); // z1 = mask + 1 (?)
    return (x & ~mask) | z1;
}
static inline int64_t getbit(int64_t value, int n) {
    return (value >> n) & 1;
}
/* int32 multiply */
int64_t imul32(int32_t a, int32_t b) {
    int64_t r = 0;
    int64_t a64 = (int64_t) a;
    int64_t b64 = (int64_t) b;
    for (int i = 0; i < 32; i++) {
        if (getbit(b64, i)) {
            r += a64 << i;
        }
    }
    return r;
}
/* float32 multiply */
float fmul32(float a, float b) {
    int32_t ia = *(int32_t *) &a;
    int32_t ib = *(int32_t *) &b;
    /* define sign */
    int32_t sa = ia >> 31;
    int32_t sb = ib >> 31;
    int32_t sr;
    /* define mantissa */
    int32_t ma = (ia & 0x7FFFFF) | 0x800000;
    int32_t mb = (ib & 0x7FFFFF) | 0x800000;
    int32_t mr;
    /* define exponent */
    int32_t ea = ((ia >> 23) & 0xFF);
    int32_t eb = ((ib >> 23) & 0xFF);
    int32_t er;
    /* define result */
    int32_t result;
    /*special values*/
    if(ea == 0xFF && ma != 0x800000) {
        int32_t f_nan = 0x7FF80001;
        return *(float *) &f_nan;
    }
    if(eb == 0xFF && mb != 0x800000) {
        int32_t f_nan = 0x7FF80001;
        return *(float *) &f_nan;
    }
    if(ea == 0xFF && ma == 0x800000) {
        if(eb == 0) {
            int32_t f_nan = 0x7F800001;
            return *(float *) &f_nan;
        }
        else {
            int32_t f_inf = 0x7F800000 | (sa ^ sb) << 31;
            return *(float *) &f_inf;
        }
    }
    if(eb == 0xFF && mb == 0x800000) {
        if(ea == 0) {
            int32_t f_nan = 0x7F800001;
            return *(float *) &f_nan;
        }
        else {
            int32_t f_inf = 0x7F800000 | (sa ^ sb) << 31;
            return *(float *) &f_inf;
        }
    }
    if(ea == 0 || eb == 0) {
        int32_t f_zero = 0 | (sa ^ sb) << 31;
        return *(float *) &f_zero;
    }
    /* multiplication */
    sr = sa ^ sb;
    int64_t mrtmp = imul32(ma, mb) >> 23;
    int32_t ertmp = ea + eb - 127;
    /* realign mantissa */
    int32_t mshift = getbit(mrtmp, 24);
    mr = mrtmp >> mshift;
    er = mshift ? inc(ertmp) : ertmp;
    /* overflow and underflow */
    if(er < 0) {
        int32_t f_zero = 0 | (sa ^ sb) << 31;
        return *(float *) &f_zero;
    }
    if(er >= 0xFF) {
        int32_t f_inf = 0x7F800000 | (sa ^ sb) << 31;
        return *(float *) &f_inf;
    }
    /* result */
    result = (sr << 31) | ((er & 0xFF) << 23) | (mr & 0x7FFFFF);
    return *(float *) &result;
}

float fadd32(float a, float b) {
    int32_t ia = *(int32_t *) &a;
    int32_t ib = *(int32_t *) &b;
    /* define sign */
    int32_t sa = ia >> 31;
    int32_t sb = ib >> 31;
    int32_t sr;
    /* define mantissa */
    int32_t ma = (ia & 0x7FFFFF) | 0x800000;
    int32_t mb = (ib & 0x7FFFFF) | 0x800000;
    int32_t mr;
    /* define exponent */
    int32_t ea = ((ia >> 23) & 0xFF);
    int32_t eb = ((ib >> 23) & 0xFF);
    int32_t er;
    /* define result */
    int32_t result;
    /*special values*/
    if(ea == 0xFF && ma != 0x800000) {
        int32_t f_nan = 0x7FF80001;
        return *(float *) &f_nan;
    }
    if(eb == 0xFF && mb != 0x800000) {
        int32_t f_nan = 0x7FF80001;
        return *(float *) &f_nan;
    }
    if(ea == 0xFF && ma == 0x800000) {
        if(eb == 0xFF && mb == 0x800000 && sb != sa) {
            int32_t f_nan = 0x7F800001;
            return *(float *) &f_nan;
        }
        else {
            int32_t f_inf = 0x7F800000 | sa << 31;
            return *(float *) &f_inf;
        }
    }
    if(eb == 0xFF && mb == 0x800000) {
        if(ea == 0xFF && ma == 0x800000 && sa != sb) {
            int32_t f_nan = 0x7F800001;
            return *(float *) &f_nan;
        }
        else {
            int32_t f_inf = 0x7F800000 | sb << 31;
            return *(float *) &f_inf;
        }
    }
    /* exponent align */
    if(ea >= eb) {
        if(ea - eb <= 24) {
            mb = mb >> (ea - eb);
        }
        else {
            mb = 0;
        }
        er = ea;
    }
    else {
        if(eb - ea <= 24) {
            ma = ma >> (eb - ea);
        }
        else {
            ma = 0;
        }
        er = eb;
    }
    /* addition or substraction */
    sr = sa;
    int32_t madd;
    if((sa ^ sb) == 0) {
        madd = ma + mb;
    }
    else {
        madd = ma - mb;
        if((madd >> 31) != 0) {
            sr ^= 1;
            madd = ~madd + 1;
        }
    }
    /* realign mantissa */
    int32_t digits = get_highest_digit(madd);
    if(digits == 25) {
        mr = (madd + 1) >> 1;
    }
    else {
        mr = madd << (24 - digits);
    }
    er = er - (24 - digits);
    /* overflow and underflow */
    if(er < 0) {
        int f_zero = 0 | sr << 31;
        return *(float *) &f_zero;
    }
    if(er >= 0xFF) {
        int f_inf = 0x7F800000 | sr << 31;
        return *(float *) &f_inf;
    }
    /* result */
    result = (sr << 31) | ((er & 0xFF) << 23) | (mr & 0x7FFFFF);
    return *(float *) &result;
}
float **matmul(float **a, float **b, int m, int n, int o) {
    /* (m * n) * (n * o) -> (m * o) */
    float subtotal;
    float **ret = malloc(m * sizeof(float *));
    for(int i = 0; i < m; i ++) {
        ret[i] = malloc(o * sizeof(float));
    }
    for(int i = 0; i < m; i ++) {
        for(int j = 0; j < o; j ++) {
            subtotal = 0;
            for(int k = 0; k < n; k ++) {
                subtotal = fadd32(subtotal, fmul32(a[i][k], b[k][j]));
            }
            ret[i][j] = subtotal;
        }
    }
    return ret;
}
int main() {
    float *a1 = {0.89, 0.18, 0.04};
    float *a2 = {0.07, 1, 0.2};
    float *a3 = {0.13, 0, 0.7};
    float **a = {a1, a2, a3};
    float *b1 = {0.02, 1.01, 0.14};
    float *b2 = {0.1, 0.14, 0.99};
    float *b3 = {0.87, 0.2, 0.09};
    float **b = {b1, b2, b3};
    /*
    answer should be
    0.0706  0.9321  0.3064
    0.2753  0.2507  1.0178
    0.6116  0.2713  0.0812
    */
    float **c = matmul(a, b, 3, 3, 3);
    for(int i = 0; i < 3; i ++) {
        for(int j = 0; j < 3; j ++) {
            printf("%f\n", c[i][j]);
        }
    }
}