#include <stdio.h>

#include <stdint.h>

typedef struct {
    int32_t row;
    int32_t col;
    int32_t *data;
} matf32_t;

int32_t aarr[9] = {0x3f63d70a, 0x3e3851ec, 0x3d23d70a,
			  0x3d8f5c29, 0x3f800000, 0x3e4ccccd,
			  0x3e051eb8, 0x00000000, 0x3f333333};
int32_t barr[9] = {0x3ca3d70a, 0x3f8147ae, 0x3e0f5c29,
			  0x3dcccccd, 0x3e0f5c29, 0x3f7d70a4,
			  0x3f5eb852, 0x3e4ccccd, 0x3db851ec};
matf32_t amat = {.row = 3, .col = 3, .data = aarr};
matf32_t bmat = {.row = 3, .col = 3, .data = barr};
int32_t retdata[9] = {0}; /* preserve space for malloc replacement */
matf32_t retmat = {0, 0, 0}; /* preserve space, but not initialize */

uint32_t highestbit(register uint32_t x) {
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    /* count ones (population count) */
    x -= ((x >> 1) & 0x55555555);
    register int32_t num3333 = 0x33333333;
    x = ((x >> 2) & num3333) + (x & num3333);
    x = ((x >> 4) + x) & 0x0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);
    return x & 0x7f;
}
/* float32 mantissa multiply */
int32_t mmul(register int32_t a, register int32_t b) {
    register int32_t r = 0;
    a = a << 1; /* to counter last right shift */
    do {
        if((b & 1) != 0) {
            r = r + a;
        }
        b = b >> 1;
        r = r >> 1;
    } while(b != 0);
    return r;
}
/* float32 multiply */
int32_t fmul32(int32_t ia, int32_t ib) {
    /* define sign */
    int32_t sr = (ia ^ ib) >> 31;
    /* define mantissa */
    int32_t ma = (ia & 0x7fffff) | 0x800000;
    int32_t mb = (ib & 0x7fffff) | 0x800000;
    int32_t mr;
    /* define exponent */
    int32_t ea = ((ia >> 23) & 0xff);
    int32_t eb = ((ib >> 23) & 0xff);
    int32_t er;
    /* special values */
    if(ea == 0xff) {
        if(ma == 0x800000 && eb != 0) {
            return 0x7f800000 | sr << 31;
        }
        return 0x7f800001;
    }
    if(eb == 0xff) {
        if(mb == 0x800000 && ea != 0) {
            return 0x7f800000 | sr << 31;
        }
        return 0x7f800001;
    }
    if(ea == 0) {
        return sr << 31;
    }
    if(eb == 0) {
        return sr << 31;
    }
    /* multiplication */
    register int32_t mrtmp = mmul(ma, mb);
    register int32_t ertmp = ea + eb - 127;
    /* realign mantissa */
    register int32_t mshift = (mrtmp >> 24) & 1;
    mr = mrtmp >> mshift;
    er = ertmp + mshift;
    /* overflow and underflow */
    if(er <= 0) {
        return sr << 31;
    }
    if(er >= 0xff) {
        return 0x7f800000 | sr << 31;
    }
    /* result */
    return (sr << 31) | ((er & 0xff) << 23) | (mr & 0x7fffff);
}

int32_t fadd32(int32_t ia, int32_t ib) {
    /* define sign */
    int32_t sa = ia >> 31;
    int32_t sb = ib >> 31;
    int32_t sr;
    /* define mantissa */
    int32_t ma = (ia & 0x7fffff) | 0x800000;
    int32_t mb = (ib & 0x7fffff) | 0x800000;
    int32_t mr;
    /* define exponent */
    int32_t ea = ((ia >> 23) & 0xff);
    int32_t eb = ((ib >> 23) & 0xff);
    int32_t er;
    /* other variables*/
    int32_t madd;
    /* special values */
    if(ea == 0xff) {
        if(ma == 0x800000 && (ia ^ ib) != 0x80000000) {
            return 0x7f800000 | sa << 31;
        }
        return 0x7f800001;
    }
    if(eb == 0xff) {
        if(mb == 0x800000 && (ia ^ ib) != 0x80000000) {
            return 0x7f800000 | sb << 31;
        }
        return 0x7f800001;
    }
    /* exponent align */
    if(ea >= eb) {
        register int32_t eab = ea - eb;
        if(eab <= 24) {
            mb = mb >> eab;
        }
        else {
            mb = 0;
        }
        er = ea;
    }
    else {
        register int32_t eab = eb - ea;
        if(eab <= 24) {
            ma = ma >> eab;
        }
        else {
            ma = 0;
        }
        er = eb;
    }
    /* addition or substraction */
    sr = sa;
    if((sa ^ sb) == 0) {
        madd = ma + mb;
    }
    else {
        madd = ma - mb;
        if(madd < 0) {
            sr ^= 1;
            madd = 0 - madd;
        }
    }
    /* realign mantissa */
    register int32_t digits = highestbit(madd);
    if(digits == 25) {
        mr = (madd + 1) >> 1;
    }
    else {
        mr = madd << (24 - digits);
    }
    er = er - 24 + digits;
    /* overflow and underflow */
    if(er < 0) {
        return sr << 31;
    }
    if(er >= 0xff) {
        return 0x7f800000 | sr << 31;
    }
    /* result */
    return (sr << 31) | ((er & 0xff) << 23) | (mr & 0x7fffff);
}
matf32_t *matmul(matf32_t *first, matf32_t *second) {
    /* (m * n) * (n * o) -> (m * o) */
    int32_t m = first->row;
    int32_t n = first->col;
    int32_t o = second->col;
    if(n != second->row) {
        return NULL;
    }
    matf32_t *ret = &retmat; /* replace malloc struct */
    ret->row = m;
    ret->col = o;
    ret->data = retdata; /* replace malloc array */
    int32_t *a = first->data;
    int32_t *b = second->data;
    int32_t *c = ret->data;
    int32_t subtotal;
    int32_t arow = 0;
    int32_t aidx = 0;
    int32_t bidx = 0;
    int32_t *cptr = c;
    int32_t i = 0;
    int32_t j = 0;
    int32_t k = 0;
    while(i < m) {
        j = 0;
        while(j < o) {
            subtotal = 0;
            aidx = arow;
            bidx = j;
            k = 0;
            while(k < n) {
                subtotal = fadd32(fmul32(a[aidx], b[bidx]), subtotal);
                aidx += 1;
                bidx += o;
                k ++;
            }
            *(cptr) = subtotal;
            cptr += 1; // actually + 4
            j ++;
        }
        arow += n;
        i ++;
    }
    return ret;
}
static inline void printstr(const char *str) {
    asm("li  a7, 4");
    asm("ecall");
}
static inline void printline() {
    asm("li  a0, 10");
    asm("li  a7, 11");
    asm("ecall");
}
static inline void printfloat(int a) {
    asm("li  a7, 2");
    asm("ecall");
}
int main() {
    /*
    answer should be
    0.0706  0.9321  0.3064
    0.2753  0.2507  1.0178
    0.6116  0.2713  0.0812
    */
    matf32_t *cmat = matmul(&amat, &bmat);
    int32_t *c = cmat->data;
    printstr("result:\n");
    int32_t i = 0;
    do {
        printfloat(c[i]);
        printline();
        i ++;
    } while(i < 9);
	return 0;
}