#include <stdio.h>

#include <stdint.h>

typedef struct {
    int32_t row;
    int32_t col;
    int32_t *data;
} matf32_t;

/* data */
int32_t aarr[9] = {0x3f63d70a, 0x3e3851ec, 0x3d23d70a,
			  0x3d8f5c29, 0x3f800000, 0x3e4ccccd,
			  0x3e051eb8, 0x00000000, 0x3f333333};
int32_t barr[9] = {0x3ca3d70a, 0x3f8147ae, 0x3e0f5c29,
			  0x3dcccccd, 0x3e0f5c29, 0x3f7d70a4,
			  0x3f5eb852, 0x3e4ccccd, 0x3db851ec};
matf32_t amat = {.row = 3, .col = 3, .data = aarr};
matf32_t bmat = {.row = 3, .col = 3, .data = barr};
/* bss */
int32_t retdata[9] = {0};
matf32_t retmat = {0, 0, 0};
static uint32_t highestbit(register uint32_t x) {
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
static int32_t mmul(register int32_t a, register int32_t b) {
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
/* after modify fadd32 */
/* 6f0, (12074, 8903), (2526, 35, 5), (10441, 1634, 0) */
/* after modify fmul32 */
/* 644, (11204, 8114), (1690, 31, 5), (9775, 1430, 0) */
/* after special case bugfix*/
/* 680, (11150, 8060), (1663, 31, 5), (9809, 1342, 0) */
/* after improve matmul*/
/* 5d0, (10381, 7538), (1663, 37, 10), (9127, 1255, 0) */
/* after improve matmul again*/
/* 5b8, (10228, 7384), (1088, 29, 6), (8916, 1313, 0) */
static int32_t fmul32(int32_t ia, int32_t ib) {
    /*define const*/
    register int s0 = 0x7fffff;
    register int s1 = 0x800000;
    register int s2 = 0xff;
    /* define sign */
    register int32_t sr = (ia ^ ib) >> 31 << 31; /*s3*/
    /* define mantissa */
    register int32_t mar = (ia & s0) | s1; /*t4, ma and mr*/
    register int32_t mb = (ib & s0) | s1; /*t5*/
    /* define exponent */
    register int32_t ear = ((ia >> 23) & 0xff); /*s4, sa and sr*/
    register int32_t eb = ((ib >> 23) & 0xff); /*s5*/
    /* special values */
    if(ear == 0xff) {
        if(mar != 0x800000) {
            return 0x7f800001; /* a is nan*/
        }
        if(eb == 0xff) {
            if(mb != 0x800000) {
                return 0x7f800001; /* b is nan*/
            }
        }
        if(eb == 0) {
            return 0x7f800001; /* b is zero*/
        }
        return 0x7f800000 | sr;
    }
    if(eb == 0xff) {
        if(mb != 0x800000) {
            return 0x7f800001; /* b is nan*/
        }
        if(ear == 0) {
            return 0x7f800001; /* a is zero*/
        }
        return 0x7f800000 | sr;
    }
    if(ear == 0) {
        return sr;
    }
    if(eb == 0) {
        return sr;
    }
    /* multiplication and realign mantissa*/
    register int32_t mrtmp = mmul(mar, mb); /* a0 */
    register int32_t mshift = (mrtmp >> 24) & 1;
    mar = mrtmp >> mshift; /*ma -> mr*/
    ear = ear + eb - 127 + mshift; /*ea -> er*/
    /* overflow and underflow */
    if(ear <= 0) {
        return sr;
    }
    if(ear >= s2) {
        return 0x7f800000 | sr;
    }
    /* result */
    return sr | ((ear & s2) << 23) | (mar & s0);
}
static int32_t fadd32(int32_t ia, int32_t ib) {
    /*define const*/
    register int s0 = 0x7fffff;
    register int s1 = 0x800000;
    register int s2 = 0xff;
    /* define sign */
    register int32_t sa = ia >> 31 << 31; /*s3*/
    register int32_t sb = ib >> 31 << 31; /*s4*/
    register int32_t sr = sa; /*s5*/
    /* define mantissa */
    register int32_t mar = (ia & 0x7fffff) | 0x800000; /*s6, ma and mr*/
    register int32_t mb = (ib & 0x7fffff) | 0x800000; /*s7*/
    /* define exponent */
    register int32_t ear = ((ia >> 23) & 0xff); /*s8, ea and er*/
    register int32_t eb = ((ib >> 23) & 0xff); /*s9*/
    /* special values */
    if(ear == s2) {
        if(mar != 0x800000) {
            return 0x7f800001; /* a is nan*/
        }
        if(eb = s2) {
            if(mb != 0x800000) {
                return 0x7f800001; /* b is nan*/
            }
            if((ia ^ ib) != 0) {
                return 0x7f800001; /* a and b are opposite sign infinity*/
            }
        }
        return 0x7f800000 | sa;
    }
    if(eb == s2) {
        if(mb != 0x800000) {
            return 0x7f800001; /* b is nan*/
        }
        return 0x7f800000 | sb;
    }
    /* exponent align */
    if(ear >= eb) {
        register int32_t eab = ear - eb;
        if(eab > 24) {
            return ia;
        }
        mb = mb >> eab;
        ear = ear; /*ea -> er*/
    }
    else {
        register int32_t eab = eb - ear;
        if(eab > 24) {
            return ib;
        }
        mar = mar >> eab;
        ear = eb; /*ea -> er*/
    }
    /* addition or substraction */
    if((sa ^ sb) == 0) {
        mar = mar + mb; /*ma -> mr*/
    }
    else {
        mar = mar - mb; /*ma -> mr*/
        if(mar < 0) {
            sr ^= 1;
            mar = 0 - mar;
        }
    }
    /* realign mantissa */
    register int32_t digits = highestbit(mar);
    if(digits == 25) {
        mar = (mar + 1) >> 1;
    }
    else {
        mar = mar << (24 - digits);
    }
    ear = ear - 24 + digits;
    /* overflow and underflow */
    if(ear < 0) {
        return sr;
    }
    if(ear >= s2) {
        return 0x7f800000 | sr;
    }
    /* result */
    return sr | ((ear & 0xff) << 23) | (mar & s0);
}
static matf32_t *matmul(matf32_t *first, matf32_t *second) {
    /* (m * n) * (n * o) -> (m * o) */
    register int32_t m = first->row; /*s0*/
    register int32_t n = first->col; /*s1*/
    register int32_t o = second->col; /*s2*/
    if(n != second->row) {
        return NULL;
    }
    matf32_t *ret = &retmat; /*temporary t3, main (sp+56)*/
    if(m <= 0) {
        return ret;
    }
    if(n <= 0) {
        return ret;
    }
    if(o <= 0) {
        return ret;
    }
    ret->row = m;
    ret->col = o;
    ret->data = retdata;
    register int32_t *astart = first->data; /*s3*/
    int32_t * const cstart = ret->data; /*(sp+60)*/
    register int32_t *aptr = astart; /*s5*/
    register int32_t *bptr = second->data; /*s6*/
    register int32_t *cptr = cstart; /*s7*/
    register int32_t *brow = bptr; /*s8*/
    register int32_t i, j = 0, k; /*i=s9,  j=s10,  k=s11*/
    m <<= 2;
    n <<= 2;
    o <<= 2;
    do {
        aptr = astart + (j >> 2); /*aptr = astart + j*/
        cptr = cstart;
        i = 0;
        do {
            bptr = brow;
            register int32_t aval = *aptr; /*s4*/
            k = 0;
            do {
                *cptr = fadd32(fmul32(aval, *bptr), *cptr);
                bptr += 1; /*bptr += 4*/
                cptr += 1; /*cptr += 4*/
                k += 4;
            } while(k < o);
            aptr += (o >> 2); /*aptr += o*/
            i += 4;
        } while(i < m);
        brow += (o >> 2); /*brow += o*/
        j += 4;
    } while(j < n);
    
    return ret;
}
/*not using this*/
static matf32_t *matmul_alt(matf32_t *first, matf32_t *second) {
    /* (m * n) * (n * o) -> (m * o) */
    register int32_t m = first->row; /*s0*/
    register int32_t n = first->col; /*s1*/
    register int32_t o = second->col; /*s2*/
    if(n != second->row) {
        return NULL;
    }
    matf32_t *ret = &retmat; /*temporary t3, main (sp+56)*/
    if(m <= 0) {
        return ret;
    }
    if(n <= 0) {
        return ret;
    }
    if(o <= 0) {
        return ret;
    }
    ret->row = m;
    ret->col = o;
    ret->data = retdata; /* replace malloc array */
    register int32_t *bstart = second->data;  /*s3*/
    register int32_t *aptr = first->data; /*s5*/
    register int32_t *bptr = bstart; /*s6*/
    register int32_t *cptr = ret->data; /*s7*/
    register int32_t *arow = aptr; /*s8*/
    register int32_t i = 0, j, k; /*i=s9,  j=s10,  k=s11*/
    m <<= 2;
    n <<= 2;
    o <<= 2;
    do {
        j = 0;
        do {
            register int32_t subtotal = 0; /*s4*/
            aptr = arow;
            bptr = bstart + (j >> 2); /*bptr = bstart + j*/
            k = 0;
            do {
                subtotal = fadd32(fmul32(*aptr, *bptr), subtotal);
                aptr += 1; /*aptr += 4*/
                bptr += (o >> 2); /*bptr += o*/
                k += 4;
            } while(k < n);
            *(cptr) = subtotal;
            cptr += 1; /*cptr += 4*/
            j += 4;
        } while(j < o);
        arow += (n >> 2); /*arow += n*/
        i += 4;
    } while(i < m);
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