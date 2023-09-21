#include <stdio.h>

#include <stdint.h>

typedef struct {
    int32_t h;
    int32_t l;
} jint64_t;

typedef struct {
    int32_t row;
    int32_t col;
    float *data;
} matf32_t;

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
/* int32 multiply */
jint64_t imul32(int32_t a, int32_t b) {
    uint32_t ua = a;
    int32_t ah; /* added higher word */
    int32_t al; /* added lower word */
    int32_t carry;
    int32_t tmp;
    int32_t rh = 0; /* result higher word */
    int32_t rl = 0; /* result lower word */
    for(int32_t i = 0; i < 32; i++) {
        if((b >> i & 1) == 1) {
            al = ua << i;
            ah = ua >> (31 - i) >> 1;/* prevent no shift */
            tmp = rl;
            rl = rl + al;
            carry = ((tmp ^ al) & ~rl | (tmp & al)) >> 31 & 1;
            rh = rh + ah + carry;
        }
    }
    jint64_t r64 = {.h = rh, .l = rl};
    return r64;
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
    /* special values */
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
    jint64_t jmr = imul32(ma, mb);
    int32_t mrtmp = ((jmr.l >> 23) & 0x1FF) | (jmr.h << 9); // >>23 in long
    int32_t ertmp = ea + eb - 127;
    /* realign mantissa */
    int32_t mshift = (mrtmp >> 24) & 1;
    mr = mrtmp >> mshift;
    er = ertmp + mshift;
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
    /* special values */
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
        int f_zero = sr << 31;
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
float retdata[9] = {0}; /* preserve space for malloc replacement */
matf32_t *retmat = {.row = 0, .col = 0, .data = NULL}; /* preserve space, not initialize */
matf32_t *matmul(matf32_t *first, matf32_t *second) {
    /* (m * n) * (n * o) -> (m * o) */
    int m = first->row;
    int n = first->col;
    int o = second->col;
    if(n != second->row) {
        return NULL;
    }
    matf32_t *ret = retmat; /* replace malloc struct */
    ret->row = m;
    ret->col = o;
    ret->data = retdata; /* replace malloc array */
    float *a = first->data;
    float *b = second->data;
    float *c = ret->data;
    float subtotal;
    for(int i = 0; i < m; i ++) {
        for(int j = 0; j < o; j ++) {
            subtotal = 0;
            for(int k = 0; k < n; k ++) {
                subtotal = fadd32(subtotal, fmul32(a[i * n + k], b[k * o + j]));
            }
            c[i * o + j] = subtotal;
        }
    }
    return ret;
}
int main() {
    float a[9] = {0.89, 0.18, 0.04,
                  0.07, 1, 0.2,
                  0.13, 0, 0.7};
    float b[9] = {0.02, 1.01, 0.14,
                  0.1, 0.14, 0.99,
                  0.87, 0.2, 0.09};
    matf32_t amat = {.row = 3, .col = 3, .data = a};
    matf32_t bmat = {.row = 3, .col = 3, .data = b};
    /*
    answer should be
    0.0706  0.9321  0.3064
    0.2753  0.2507  1.0178
    0.6116  0.2713  0.0812
    */
    matf32_t *cmat = matmul(amat, bmat);
    float *c = cmat->data;
    printf("result:\n");
    for(int i = 0; i < 3; i ++) {
        for(int j = 0; j < 3; j ++) {
            printf("%f", c[i * 3 + j]);
            printf(" ");
        }
        printf("\n");
    }
}