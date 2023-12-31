#include <stdio.h>

#include <stdint.h>

typedef struct {
    int32_t row;
    int32_t col;
    int32_t *data;
} matf32_t;

/* data */
int32_t aarr1[9] = {0x3f63d70a, 0x3e3851ec, 0x3d23d70a,
			  0x3d8f5c29, 0x3f800000, 0x3e4ccccd,
			  0x3e051eb8, 0x00000000, 0x3f333333};
int32_t barr1[9] = {0x3ca3d70a, 0x3f8147ae, 0x3e0f5c29,
			  0x3dcccccd, 0x3e0f5c29, 0x3f7d70a4,
			  0x3f5eb852, 0x3e4ccccd, 0x3db851ec};
matf32_t amat1 = {.row = 3, .col = 3, .data = aarr1};
matf32_t bmat1 = {.row = 3, .col = 3, .data = barr1};
int32_t aarr2[6] = {0x404ccccd, 0x3f8ccccd, 0x3fa66666,
			  0x3fcccccd, 0x3fb33333, 0x40133333};
int32_t barr2[12] = {0x3f8ccccd, 0x3e9eb852, 0x3de147ae, 0x3e570a3d,
			  0x3f000000, 0x40066666, 0x3db851ec, 0x3ed70a3d,
			  0x3e99999a, 0x3e2e147b, 0x3fc8f5c3, 0x3e800000};
matf32_t amat2 = {.row = 2, .col = 3, .data = aarr2};
matf32_t bmat2 = {.row = 3, .col = 4, .data = barr2};
int32_t aarr3[9] = {0x3f63d70a, 0x3e3851ec, 0x3d23d70a,
			  0x3d8f5c29, 0x3f800000, 0x3e4ccccd,
			  0x3e051eb8, 0x00000000, 0x3f333333};
int32_t barr3[9] = {0x3e0f5c29, 
              0x3e0f5c29, 
              0x3f5eb852};
matf32_t amat3 = {.row = 3, .col = 3, .data = aarr3};
matf32_t bmat3 = {.row = 3, .col = 1, .data = barr3};
char * heap_top = (char *)0x123597af; /* non zero random number so it will not appear in bss and mess with the compiler */
/* bss */
int bss_end = 0; /*bss end, heap top should be this + 4*/
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
        r = r >> 1;
        if((b & 2) != 0) {
            r = r + a;
        }
        r = r >> 1;
        if((b & 4) != 0) {
            r = r + a;
        }
        r = r >> 1;
        if((b & 8) != 0) {
            r = r + a;
        }
        b = b >> 4;
        r = r >> 1;
    } while(b != 0);
    return r;
}
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
/* after mmul loop unroll*/
/* 610, (8500, 6520), (1088, 29, 6), (7215, 1286, 0) */
/* float32 multiply */
static int32_t fmul32(int32_t ia, int32_t ib) {
    /*define const*/
    register int32_t s0 = 0x7fffff;
    register int32_t s1 = 0x800000;
    register int32_t s2 = 0xff;
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
    register int32_t s0 = 0x7fffff;
    register int32_t s1 = 0x800000;
    register int32_t s2 = 0xff;
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
static inline matf32_t *new_mat() {
    register char *ptr = (char *) heap_top; /* for exact pointer calculation */
    heap_top = ptr + 12;
    return (matf32_t *) ptr;
}
static inline int32_t *new_arr(int32_t size) {
    register char *ptr = (char *) heap_top; /* for exact pointer calculation */
    size = size << 2;
    heap_top = ptr + size;
    register int32_t *whptr = (int32_t *)ptr;
    do {
        *whptr = 0;
        whptr ++; /* whptr += 4*/
    } while(whptr < (int32_t *) heap_top);
    return (int32_t *) ptr;
}
/* integer multiply without 0 */
static inline int32_t imul32(register int32_t a, register int32_t b) {
    register int32_t r = 0;
    do {
        if((b & 1) != 0) {
            r = r + a;
        }
        a = a << 1;
        b = b >> 1;
    } while(b != 0);
    return r;
}
static matf32_t *matmul(matf32_t *first, matf32_t *second) {
    /* (m * n) * (n * o) -> (m * o) */
    register int32_t m = first->row; /*s0*/
    register int32_t n = first->col; /*s1*/
    register int32_t o = second->col; /*s2*/
    if(n != second->row) {
        return NULL;
    }
    register int32_t *astart = first->data; /*s3*/
    register int32_t *aptr = astart; /*s5*/
    register int32_t *bptr = second->data; /*s6*/
    register int32_t *brow = bptr; /*s8*/
    matf32_t *ret = new_mat();/*temp #t3 = (sp+56)*/
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
    ret->data = new_arr(imul32(m, o)); /*temp #t2*/
    int32_t * const cstart = ret->data; /*(sp+60)*/
    register int32_t *cptr = cstart; /*s7*/
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
static inline void printstr(const char *str) {
    asm("li  a7, 4");
    asm("ecall");
}
static inline void printspace() {
    asm("li  a0, 32");
    asm("li  a7, 11");
    asm("ecall");
}
static inline void printline() {
    asm("li  a0, 10");
    asm("li  a7, 11");
    asm("ecall");
}
static inline void printfloat(int32_t a) {
    asm("li  a7, 2");
    asm("ecall");
}
void printmatrix(matf32_t *mat) {
    register int32_t row = mat->row; /* t0 */
    register int32_t col = mat->col; /* t1 */
    if(row == 0) {
        return;
    }
    if(col == 0) {
        return;
    }
    register int32_t *marr = mat->data; /* t2 */
    register int32_t i = 0; /* t3 */
    register int32_t idx = 0; /* t4 */
    do {
        register int32_t j = 0; /* t5 */
        do {
            printfloat(*(marr + idx));
            printspace();
            j ++;
            idx ++; /* idx += 4 */
        } while(j < col);
        printline();
        i ++;
    } while(i < row);
}
int main() {
    heap_top = (char *) (&bss_end + 1);/* or any arbitrary number, use 0x10000000 for gcc*/
    /*
    answer should be
    0.0706  0.9321  0.3064
    0.2753  0.2507  1.0178
    0.6116  0.2713  0.0812
    */
    printstr("first result:\n");
    matf32_t *cmat1 = matmul(&amat1, &bmat1);
    printmatrix(cmat1);
    /*
    answer should be
    4.46  3.523  2.492  1.459
    3.15  3.827  3.913  1.499
    */
    printstr("second result:\n");
    matf32_t *cmat2 = matmul(&amat2, &bmat2);
    printmatrix(cmat2);
    /*
    answer should be
    0.1846
    0.0917
    0.8854
    */
    printstr("third result:\n");
    matf32_t *cmat3 = matmul(&amat3, &bmat3);
    printmatrix(cmat3);
	return 0;
}