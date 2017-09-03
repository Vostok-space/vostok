/* Copyright 2016 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#if !defined(HEADER_GUARD_o7c)
#define HEADER_GUARD_o7c

#include <limits.h>

#if !defined(O7C_INLINE)
#	if __STDC_VERSION__ >= 199901L
#		define O7C_INLINE static inline
#	elif __GNUC__ > 2
#		define O7C_INLINE static __inline__
#	else
#		define O7C_INLINE static
#	endif
#endif

#define O7C_INT_UNDEF INT_MIN

#define O7C_DBL_UNDEF o7c_dbl_undef()

#if defined(O7C_USE_GNUC_BUILTIN_OVERFLOW)
#	define O7C_GNUC_BUILTIN_OVERFLOW O7C_USE_GNUC_BUILTIN_OVERFLOW
#elif __GNUC__ >= 5
#	define O7C_GNUC_BUILTIN_OVERFLOW (0 < 1)
#else
#	define O7C_GNUC_BUILTIN_OVERFLOW (0 > 1)
#	if !defined(__builtin_sadd_overflow)
#		define O7C_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF
#		define __builtin_sadd_overflow(a, b, res) (0 < sizeof(*(res) = (a)+(b)))
#		define __builtin_ssub_overflow(a, b, res) (0 < sizeof(*(res) = (a)-(b)))
#		define __builtin_smul_overflow(a, b, res) (0 < sizeof(*(res) = (a)*(b)))
#	endif
#endif

#if (__STDC_VERSION__ >= 199901L) && !defined(__TINYC__) && !defined(__STDC_NO_VLA__)
#	define O7C_VLA_LEN(len) static len
#else
#	define O7C_VLA_LEN(len)
#endif

typedef char unsigned o7c_char;

#if (__STDC_VERSION__ >= 199901L)
	typedef _Bool o7c_c_bool;
#elif defined(__cplusplus)
	typedef bool o7c_c_bool;
#else
	typedef int o7c_c_bool;
#endif

#if defined(O7C_BOOL)
	typedef O7C_BOOL o7c_bool;
#elif (__STDC_VERSION__ >= 199901L) && !defined(O7C_BOOL_UNDEFINED)
	typedef _Bool o7c_bool;
#elif defined(__cplusplus) && !defined(O7C_BOOL_UNDEFINED)
	typedef bool o7c_bool;
#else
#	define O7C_BOOL_UNDEF 0xFF
	typedef o7c_char o7c_bool;
#endif

#if defined(O7C_INT_T)
	typedef O7C_INT_T o7c_int_t;
#elif INT_MAX >= 2147483647
	typedef int o7c_int_t;
#elif LONG_MAX >= 2147483647
	typedef long o7c_int_t;
#else
#	error
#endif

#define O7C_MEM_MAN_NOFREE  0
#define O7C_MEM_MAN_COUNTER 1
#define O7C_MEM_MAN_GC      2

#if defined(O7C_MEM_MAN_MODEL)
#	define O7C_MEM_MAN O7C_MEM_MAN_MODEL
#else
#	define O7C_MEM_MAN O7C_MEM_MAN_NOFREE
#endif

#if __GNUC__ >= 2
#	define O7C_ATTR_CONST __attribute__((const))
#else
#	define O7C_ATTR_CONST
#endif

#if __GNUC__ > 2
#	define O7C_ATTR_PURE __attribute__((pure))
#	define O7C_ATTR_MALLOC __attribute__((malloc))
#else
#	define O7C_ATTR_PURE
#	define O7C_ATTR_MALLOC
#endif

#if __GNUC__ * 10 + __GNUC_MINOR__ >= 31
#	define O7C_ATTR_ALWAYS_INLINE __attribute__((always_inline))
#else
#	define O7C_ATTR_ALWAYS_INLINE
#endif

#define O7C_ALWAYS_INLINE O7C_ATTR_ALWAYS_INLINE O7C_INLINE

O7C_INLINE void o7c_gc_init(void) O7C_ATTR_ALWAYS_INLINE;

#if O7C_MEM_MAN == O7C_MEM_MAN_GC
#	include "gc.h"
	O7C_INLINE void o7c_gc_init(void) { GC_INIT(); }
#else
	O7C_INLINE void o7c_gc_init(void) { assert(0 > 1); }
#endif

#if defined(O7C_MEM_MAN_COUNTER_TYPE)
	typedef O7C_MEM_MAN_COUNTER_TYPE o7c_mmc_t;
#else
	typedef long o7c_mmc_t;
#endif

enum {
	O7C_VAR_INIT_UNDEF,
	O7C_VAR_INIT_ZERO,
	O7C_VAR_INIT_NO,

#if defined(O7C_VAR_INIT_MODEL)
	O7C_VAR_INIT = O7C_VAR_INIT_MODEL
#else
	O7C_VAR_INIT = O7C_VAR_INIT_ZERO
#endif
};

#if defined(O7C_CHECK_OVERFLOW)
	enum { O7C_OVERFLOW = O7C_CHECK_OVERFLOW };
#else
	enum { O7C_OVERFLOW = 1 };
#endif

#if defined(O7C_CHECK_DIV_BY_ZERO)
	enum { O7C_DIV_ZERO = O7C_CHECK_DIV_BY_ZERO };
#else
	enum { O7C_DIV_ZERO = 0 };
#endif

#if defined(O7C_CHECK_FLOAT_DIV_BY_ZERO)
	enum { O7C_FLOAT_DIV_ZERO = O7C_CHECK_FLOAT_DIV_BY_ZERO };
#else
	enum { O7C_FLOAT_DIV_ZERO = 1 };
#endif

#if defined(O7C_CHECK_UNDEFINED)
	enum { O7C_UNDEF = O7C_CHECK_UNDEFINED };
#else
	enum { O7C_UNDEF = 1 };
#endif

O7C_ATTR_MALLOC O7C_ALWAYS_INLINE
void* o7c_raw_alloc(size_t size) {
	void *mem;
	if ((O7C_VAR_INIT == O7C_VAR_INIT_ZERO)
	 || (O7C_MEM_MAN == O7C_MEM_MAN_COUNTER))
	{
		mem = calloc(1, size);
	} else {
		mem = malloc(size);
	}
	return mem;
}

O7C_INLINE void* o7c_malloc(size_t size) O7C_ATTR_ALWAYS_INLINE O7C_ATTR_MALLOC;
#if O7C_MEM_MAN == O7C_MEM_MAN_GC
	O7C_INLINE void* o7c_malloc(size_t size) {
		return GC_MALLOC(size);
	}
#elif defined(O7C_LSAN_LEAK_IGNORE)
#	include <sanitizer/lsan_interface.h>
	O7C_INLINE void* o7c_malloc(size_t size) {
		void *mem;
		mem = o7c_raw_alloc(size);
		__lsan_ignore_object(mem);
		return mem;
	}
#else
	O7C_INLINE void* o7c_malloc(size_t size) {
		return o7c_raw_alloc(size);
	}
#endif

#if !defined(O7C_MAX_RECORD_EXT)
#	define O7C_MAX_RECORD_EXT 15
#endif

#if defined(O7C_TAG_ID_TYPE)
	typedef O7C_TAG_ID_TYPE o7c_id_t;
#else
	typedef int o7c_id_t;
#endif

#define O7C_LEN(array) ((o7c_int_t)(sizeof(array) / sizeof((array)[0])))

typedef o7c_id_t o7c_tag_t[O7C_MAX_RECORD_EXT + 1];

O7C_ATTR_CONST O7C_ALWAYS_INLINE
o7c_c_bool o7c_bool_inited(o7c_bool b) {
	return *(o7c_char *)&b < 2;
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
o7c_bool o7c_bl(o7c_bool b) {
	if ((sizeof(b) == sizeof(o7c_char)) && O7C_UNDEF) {
		assert(o7c_bool_inited(b));
	}
	return b;
}

extern o7c_char* o7c_bools_undef(int len, o7c_char array[O7C_VLA_LEN(len)]);
#define O7C_BOOLS_UNDEF(array) \
	o7c_bools_undef(sizeof(array) / sizeof(o7c_char), (o7c_char *)(array))

O7C_ATTR_CONST O7C_ALWAYS_INLINE
double o7c_dbl_undef(void) {
	double undef = 0.0;
	if (sizeof(unsigned) == sizeof(double) / 2) {
		((unsigned *)&undef)[1] = 0x7FFFFFFF;
	} else {
		((unsigned long *)&undef)[1] = 0x7FFFFFFF;
	}
	return undef;
}

extern double* o7c_doubles_undef(int len, double array[O7C_VLA_LEN(len)]);
#define O7C_DOUBLES_UNDEF(array) \
	o7c_doubles_undef(sizeof(array) / sizeof(double), (double *)(array))

O7C_ATTR_CONST O7C_ALWAYS_INLINE
double o7c_dbl(double d) {
	if (!O7C_UNDEF) {
		;
	} else if (sizeof(unsigned) == sizeof(double) / 2) {
		assert(((unsigned *)&d)[1] != 0x7FFFFFFF);
	} else {
		assert(((unsigned long *)&d)[1] != 0x7FFFFFFF);
	}
	return d;
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
double o7c_fadd(double a1, double a2) {
	return o7c_dbl(a1) + o7c_dbl(a2);
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
double o7c_fsub(double m, double s) {
	return o7c_dbl(m) - o7c_dbl(s);
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
double o7c_fmul(double m1, double m2) {
	return o7c_dbl(m1) * o7c_dbl(m2);
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
double o7c_fdiv(double n, double d) {
	if (O7C_FLOAT_DIV_ZERO) {
		assert(d != 0.0);
	}
	return o7c_dbl(n) / o7c_dbl(d);
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
o7c_bool o7c_int_inited(int i) {
	return i >= -INT_MAX;
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
int o7c_int(int i) {
	if (O7C_UNDEF) {
		assert(o7c_int_inited(i));
	}
	return i;
}

extern int* o7c_ints_undef(int len, int array[O7C_VLA_LEN(len)]);
#define O7C_INTS_UNDEF(array) \
	o7c_ints_undef((int)(sizeof(array) / (sizeof(int))), (int *)(array))

O7C_ATTR_CONST O7C_ALWAYS_INLINE
int o7c_add(int a1, int a2) {
	int s;
	o7c_bool overflow;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_sadd_overflow(o7c_int(a1), o7c_int(a2), &s);
		assert(!overflow && s >= -INT_MAX);
	} else {
		if (!O7C_OVERFLOW) {
			if (O7C_UNDEF) {
				assert(o7c_int_inited(a1));
				assert(o7c_int_inited(a2));
			}
		} else if (a2 >= 0) {
			assert(o7c_int(a1) <=  INT_MAX - a2);
		} else {
			assert(a1 >= -INT_MAX - o7c_int(a2));
		}
		s = a1 + a2;
	}
	return s;
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
int o7c_sub(int m, int s) {
	int d;
	o7c_bool overflow;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_ssub_overflow(o7c_int(m), o7c_int(s), &d);
		assert(!overflow && d >= -INT_MAX);
	} else {
		if (!O7C_OVERFLOW) {
			if (O7C_UNDEF) {
				assert(o7c_int_inited(m));
				assert(o7c_int_inited(s));
			}
		} else if (s >= 0) {
			assert(m >= -INT_MAX + s);
		} else {
			assert(o7c_int(m) <= INT_MAX + o7c_int(s));
		}
		d = m - s;
	}
	return d;
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
int o7c_mul(int m1, int m2) {
	int p;
	o7c_bool overflow;
	if (O7C_OVERFLOW && O7C_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_smul_overflow(o7c_int(m1), o7c_int(m2), &p);
		assert(!overflow && p >= -INT_MAX);
	} else {
		if (O7C_OVERFLOW && (0 != m2)) {
			assert(abs(m1) <= INT_MAX / abs(m2));
		}
		p = o7c_int(m1) * o7c_int(m2);
	}
	return p;
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
int o7c_div(int n, int d) {
	if (O7C_OVERFLOW && O7C_DIV_ZERO) {
		assert(d != 0);
	}
	return o7c_int(n) / o7c_int(d);
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
int o7c_mod(int n, int d) {
	if (O7C_OVERFLOW && O7C_DIV_ZERO) {
		assert(d != 0);
	}
	return o7c_int(n) % o7c_int(d);
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
int o7c_ind(int len, int ind) {
	assert(len > 0); /* TODO remove */
	assert((unsigned)ind < (unsigned)len);
	return ind;
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
int o7c_cmp(int a, int b) {
	int cmp;
	if (a < b) {
		if (O7C_UNDEF) {
			assert(o7c_int_inited(a));
		}
		cmp = -1;
	} else {
		if (O7C_UNDEF) {
			assert(o7c_int_inited(b));
		}
		if (a == b) {
			cmp = 0;
		} else {
			cmp = 1;
		}
	}
	return cmp;
}

O7C_ALWAYS_INLINE void o7c_release(void *mem) {
	o7c_mmc_t *counter;
	if ((O7C_MEM_MAN == O7C_MEM_MAN_COUNTER)
	 && (NULL != mem))
	{
		counter = (o7c_mmc_t *)((o7c_id_t **)mem - 1) - 1;
		if (1 == *counter) {
			free(counter);
		} else {
			assert(*counter > 1);
			*counter -= 1;
		}
	}
}

O7C_ALWAYS_INLINE
void o7c_new(void **pmem, int size, o7c_tag_t const tag, void undef(void *)) {
	void *mem;
	mem = o7c_malloc(
	    sizeof(o7c_mmc_t) * (int)(O7C_MEM_MAN == O7C_MEM_MAN_COUNTER)
	  + sizeof(o7c_id_t *) + size);
	if (NULL != mem) {
		if (O7C_MEM_MAN == O7C_MEM_MAN_COUNTER) {
			*(o7c_mmc_t *)mem = 1;
			mem = (void *)((o7c_mmc_t *)mem + 1);
		}
		*(o7c_id_t const **)mem = tag;
		mem = (void *)((o7c_id_t **)mem + 1);
		if ((O7C_VAR_INIT == O7C_VAR_INIT_UNDEF) && (NULL != undef)) {
			undef(mem);
		}
	}
	o7c_release(*pmem);
	*pmem = mem;
}

#define O7C_NEW(mem, name) \
	o7c_new((void **)mem, sizeof(**(mem)), name##_tag, (void (*)(void *))name##_undef)

#define O7C_NEW2(mem, tag, undef) \
	o7c_new((void **)mem, sizeof(**(mem)), tag, (void (*)(void *))undef)

O7C_ALWAYS_INLINE void* o7c_retain(void *mem) {
	if ((O7C_MEM_MAN == O7C_MEM_MAN_COUNTER) && (NULL != mem)) {
		*((o7c_mmc_t *)((o7c_id_t **)mem - 1) - 1) += 1;
	}
	return mem;
}

/** уменьшает счётчик на 1, но не освобождает объект при достижении 0 */
O7C_ALWAYS_INLINE void* o7c_unhold(void *mem) {
	o7c_mmc_t *counter;
	if ((O7C_MEM_MAN == O7C_MEM_MAN_COUNTER)
	 && (NULL != mem))
	{
		counter = (o7c_mmc_t *)((o7c_id_t **)mem - 1) - 1;
		assert(*counter > 0);
		*counter -= 1;
	}
	return mem;
}


#define O7C_RELEASE_PARAMS(array) o7c_release_array(sizeof(array) / sizeof(array[0]), array)

O7C_ALWAYS_INLINE void o7c_null(void **mem) {
	o7c_release(*mem);
	*mem = NULL;
}

#define O7C_NULL(mem) o7c_null((void **)(mem))

O7C_ALWAYS_INLINE void o7c_release_array(int count, void *mem[O7C_VLA_LEN(count)]) {
	int i;
	if (O7C_MEM_MAN == O7C_MEM_MAN_COUNTER) {
		for (i = 0; i < count; i += 1) {
			o7c_null(mem + i);
		}
	}
}

O7C_ALWAYS_INLINE void o7c_assign(void **m1, void *m2) {
	assert(NULL != m1);/* TODO remove */
	o7c_retain(m2);
	if (NULL != *m1) {
		o7c_release(*m1);
	}
	*m1 = m2;
}

#define O7C_ASSIGN(m1, m2) o7c_assign((void **)(m1), m2)

extern void o7c_tag_init(o7c_tag_t ext, o7c_tag_t const base);

O7C_ATTR_PURE O7C_ALWAYS_INLINE
o7c_id_t const * o7c_dynamic_tag(void const *mem) {
	assert(NULL != mem);
	return *((o7c_id_t const **)mem - 1);
}

O7C_ATTR_PURE O7C_ALWAYS_INLINE
o7c_bool o7c_is_r(o7c_id_t const *base, void const *strct, o7c_tag_t const ext) {
	if (NULL == base) {
		base = o7c_dynamic_tag(strct);
	}
	return base[ext[0]] == ext[ext[0]];
}

O7C_ATTR_PURE O7C_ALWAYS_INLINE
o7c_bool o7c_is(void const *strct, o7c_tag_t const ext) {
	o7c_id_t const *base;
	base = o7c_dynamic_tag(strct);
	return base[ext[0]] == ext[ext[0]];
}

O7C_ATTR_PURE O7C_ALWAYS_INLINE
void **o7c_must(void **strct, o7c_tag_t const ext) {
	assert(o7c_is(*strct, ext));
	return strct;
}

#define O7C_GUARD(ExtType, strct) \
	(*(struct ExtType **)o7c_must((void **)strct, ExtType##_tag))


O7C_ATTR_PURE O7C_ALWAYS_INLINE
void * o7c_must_r(o7c_tag_t const base, void *strct, o7c_tag_t const ext) {
	assert(o7c_is_r(base, strct, ext));
	return strct;
}

#define O7C_GUARD_R(ExtType, strct, base) \
	(*(struct ExtType *)o7c_must_r(base, strct, ExtType##_tag))

O7C_ATTR_CONST O7C_ALWAYS_INLINE
unsigned o7c_set(int low, int high) {
	assert(low >= 0);
	assert(high <= 31);
	assert(low <= high);
	return (~0u << low) & (~0u >> (31 - high));
}

#define O7C_SET(low, high) ((~0u << low) & (~0u >> (31 - high)))

O7C_ATTR_CONST O7C_ALWAYS_INLINE
o7c_bool o7c_in(int n, unsigned set) {
	return (n >= 0) && (n <= 31) && (0 != (set & (1u << n)));
}

#define O7C_IN(n, set) (((n) >= 0) && ((n) <= 31) && (0 != (set) & (1u << (n))))

O7C_ATTR_CONST O7C_ALWAYS_INLINE
char unsigned o7c_byte(int v) {
	assert((unsigned)v <= 255);
	return (char unsigned)v;
}

O7C_ATTR_CONST O7C_ALWAYS_INLINE
char unsigned o7c_chr(int v) {
	assert((unsigned)v <= 255);
	return (char unsigned)v;
}

extern int o7c_strcmp(int s1_len, o7c_char const s1[O7C_VLA_LEN(s1_len)],
                      int s2_len, o7c_char const s2[O7C_VLA_LEN(s2_len)])
	O7C_ATTR_PURE;

extern void o7c_init(int argc, char *argv[O7C_VLA_LEN(argc)]);

extern int o7c_exit_code;

#if defined(O7C_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF)
#	undef O7C_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF
#	undef __builtin_sadd_overflow
#	undef __builtin_ssub_overflow
#	undef __builtin_smul_overflow
#endif

#endif
