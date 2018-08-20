/* Copyright 2016-2017 ComdivByZero
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
#if !defined(HEADER_GUARD_o7)
#define HEADER_GUARD_o7 1

#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <limits.h>
#include <math.h>
#include <float.h>

#if !defined(O7_INLINE)
#	if __STDC_VERSION__ >= 199901L
#		define O7_INLINE static inline
#	elif __GNUC__ > 2
#		define O7_INLINE static __inline__
#	else
#		define O7_INLINE static
#	endif
#endif

#if defined(O7_USE_GNUC_BUILTIN_OVERFLOW)
#	define O7_GNUC_BUILTIN_OVERFLOW O7_USE_GNUC_BUILTIN_OVERFLOW
#elif __GNUC__ >= 5
#	define O7_GNUC_BUILTIN_OVERFLOW (0 < 1)
#else
#	define O7_GNUC_BUILTIN_OVERFLOW (0 > 1)
#endif

#if (__STDC_VERSION__ >= 199901L) && !defined(__TINYC__) && !defined(__STDC_NO_VLA__)
#	define O7_VLA(len) static len
#else
#	define O7_VLA(len)
#endif


#define O7_INIT_UNDEF 0
#define O7_INIT_ZERO  1
#define O7_INIT_NO    2

#if defined(O7_INIT_MODEL)
#	define O7_INIT O7_INIT_MODEL
#else
#	define O7_INIT O7_INIT_UNDEF
#endif

#if O7_INIT == O7_INIT_UNDEF
#	if INT_MIN < -INT_MAX
#		define O7_INT_UNDEF  (-1 - O7_INT_MAX)
#		define O7_LONG_UNDEF (-1 - O7_LONG_MAX)
#	else
#		define O7_INT_UNDEF  0
#		define O7_LONG_UNDEF 0
#	endif
#	define O7_DBL_UNDEF  o7_dbl_undef()
#	define O7_FLT_UNDEF  o7_flt_undef()
#	define O7_BOOL_UNDEF 0xFF
#else
#	define O7_INT_UNDEF  0
#	define O7_LONG_UNDEF 0
#	define O7_DBL_UNDEF  0.0
#	define O7_FLT_UNDEF  0.0f
#	define O7_BOOL_UNDEF (0>1)
#endif

typedef char unsigned o7_char;

#if (__STDC_VERSION__ >= 199901L)
	typedef _Bool o7_cbool;
#elif defined(__cplusplus)
	typedef bool o7_cbool;
#else
	typedef o7_char o7_cbool;
#endif

#if defined(O7_BOOL)
	typedef O7_BOOL o7_bool;
#elif defined(O7_BOOL_UNDEFINED)
	typedef o7_char o7_bool;
#else
	typedef o7_cbool o7_bool;
#endif

#if defined(O7_INT_T)
	typedef O7_INT_T o7_int_t;
#	if !defined(O7_INT_MAX)
#		error
#	endif
#else
#	define O7_INT_MAX 2147483647
#	if INT_MAX    >= O7_INT_MAX
		typedef int   o7_int_t;
#	elif LONG_MAX >= O7_INT_MAX
		typedef long  o7_int_t;
#	else
#		error
#	endif
#endif

#if defined(O7_LONG_T)
	typedef O7_LONG_T             o7_long_t;
	typedef O7_ULONG_T            o7_ulong_t;
#	define O7_LABS(val)           O7_LONG_ABS(val)
#	if !defined(O7_LONG_MAX)
#		error
#	endif
#else
#	define O7_LONG_MAX 9223372036854775807
#	if LONG_MAX    >= O7_LONG_MAX
		typedef long               o7_long_t;
		typedef long unsigned      o7_ulong_t;
#		define O7_LABS(val)        labs(val)
#	elif LLONG_MAX >= O7_LONG_MAX
		typedef long long          o7_long_t;
		typedef long long unsigned o7_ulong_t;
#		define O7_LABS(val)        llabs(val)
#	else
#		error
#	endif
#endif

#if O7_GNUC_BUILTIN_OVERFLOW
#	define O7_GNUC_SADD(a, b, res)  __builtin_sadd_overflow(a, b, res)
#	define O7_GNUC_SSUB(a, b, res)  __builtin_ssub_overflow(a, b, res)
#	define O7_GNUC_SMUL(a, b, res)  __builtin_smul_overflow(a, b, res)
#	if LONG_MAX > O7_INT_MAX
#		define O7_GNUC_SADDL(a, b, res) __builtin_saddl_overflow(a, b, res)
#		define O7_GNUC_SSUBL(a, b, res) __builtin_ssubl_overflow(a, b, res)
#		define O7_GNUC_SMULL(a, b, res) __builtin_smull_overflow(a, b, res)
#	else
#		define O7_GNUC_SADDL(a, b, res) __builtin_saddll_overflow(a, b, res)
#		define O7_GNUC_SSUBL(a, b, res) __builtin_ssubll_overflow(a, b, res)
#		define O7_GNUC_SMULL(a, b, res) __builtin_smulll_overflow(a, b, res)
#	endif
#else
#	define O7_GNUC_SADD(a, b, res)  (0 < sizeof(*(res) = (a)+(b)))
#	define O7_GNUC_SSUB(a, b, res)  (0 < sizeof(*(res) = (a)-(b)))
#	define O7_GNUC_SMUL(a, b, res)  (0 < sizeof(*(res) = (a)*(b)))

#	define O7_GNUC_SADDL(a, b, res) (0 < sizeof(*(res) = (a)+(b)))
#	define O7_GNUC_SSUBL(a, b, res) (0 < sizeof(*(res) = (a)-(b)))
#	define O7_GNUC_SMULL(a, b, res) (0 < sizeof(*(res) = (a)*(b)))
#endif

typedef o7_ulong_t o7_set64_t;

#define O7_MEMNG_NOFREE  0
#define O7_MEMNG_COUNTER 1
#define O7_MEMNG_GC      2

#if !defined(O7_MEM_ALIGN)
#	define O7_MEM_ALIGN (8u > sizeof(void *) ? 8u : sizeof(void *))
#endif

#if defined(O7_MEMNG_MODEL)
#	define O7_MEMNG O7_MEMNG_MODEL
#else
#	define O7_MEMNG O7_MEMNG_NOFREE
#endif

#if defined(O7_MEMNG_NOFREE_BUFFER_SIZE)
#elif O7_MEMNG == O7_MEMNG_NOFREE
#	define O7_MEMNG_NOFREE_BUFFER_SIZE (256lu * 1024 * 1024)
#else
#	define O7_MEMNG_NOFREE_BUFFER_SIZE 1lu
#endif

#if __GNUC__ >= 2
#	define O7_ATTR_CONST __attribute__((const))
#else
#	define O7_ATTR_CONST
#endif

#if __GNUC__ > 2
#	define O7_ATTR_PURE __attribute__((pure))
#	define O7_ATTR_MALLOC __attribute__((malloc))
#else
#	define O7_ATTR_PURE
#	define O7_ATTR_MALLOC
#endif

#if __GNUC__ * 10 + __GNUC_MINOR__ >= 31
#	define O7_ATTR_ALWAYS_INLINE __attribute__((always_inline))
#else
#	define O7_ATTR_ALWAYS_INLINE
#endif

#define O7_ALWAYS_INLINE O7_ATTR_ALWAYS_INLINE O7_INLINE

O7_INLINE void o7_gc_init(void) O7_ATTR_ALWAYS_INLINE;

#if O7_MEMNG == O7_MEMNG_GC
#	include "gc.h"
	O7_INLINE void o7_gc_init(void) { GC_INIT(); }
#else
	O7_INLINE void o7_gc_init(void) { assert(0 > 1); }
#endif

#if defined(O7_MEMNG_COUNTER_TYPE)
	typedef O7_MEMNG_COUNTER_TYPE o7_mmc_t;
#else
	typedef o7_int_t o7_mmc_t;
#endif

#if defined(O7_CHECK_OVERFLOW)
	enum { O7_OVERFLOW = O7_CHECK_OVERFLOW };
#else
	enum { O7_OVERFLOW = 1 };
#endif

#if defined(O7_CHECK_DIV_BY_ZERO)
	enum { O7_DIV_ZERO = O7_CHECK_DIV_BY_ZERO };
#else
	enum { O7_DIV_ZERO = 0 };
#endif

#if defined(O7_CHECK_FLOAT_DIV_BY_ZERO)
	enum { O7_FLOAT_DIV_ZERO = O7_CHECK_FLOAT_DIV_BY_ZERO };
#else
	enum { O7_FLOAT_DIV_ZERO = 1 };
#endif

#if defined(O7_CHECK_UNDEFINED)
	enum { O7_UNDEF = O7_CHECK_UNDEFINED };
#else
	enum { O7_UNDEF = 1 };
#endif

#if defined(O7_CHECK_ARRAY_INDEX)
	enum { O7_ARRAY_INDEX = O7_CHECK_ARRAY_INDEX };
#elif !defined(__BOUNDS_CHECKING_ON)
	enum { O7_ARRAY_INDEX = 1 };
#else
	enum { O7_ARRAY_INDEX = 0 };
#endif

#if defined(O7_CHECK_NULL)
	enum { O7_CHECK_NIL = O7_CHECK_NULL };
#else
	enum { O7_CHECK_NIL = 1 };
#endif

O7_ATTR_CONST O7_ALWAYS_INLINE
void* o7_ref(void *ptr) {
	if (O7_CHECK_NIL) {
		assert(NULL != ptr);
	}
	return ptr;
}

#if (__GNUC__ >= 2) || defined(__TINYC__)
#	define O7_REF(ptr) ((__typeof__(ptr))o7_ref(ptr))
#else
#	define O7_REF(ptr) ptr
#endif

#if defined(NDEBUG)
	O7_ALWAYS_INLINE void o7_assert(o7_cbool cond) { assert(cond); }
#	define O7_ASSERT(condition) o7_assert(condition)
#else
#	define O7_ASSERT(condition) assert(condition)
#endif

#if __STDC_VERSION__ >= 201112L
#	define O7_STATIC_ASSERT(cond) static_assert(cond, "")
#	define O7_NORETURN _Noreturn
#else
#	define O7_STATIC_ASSERT(cond) \
		do { struct o7_static_assert { int a:(int)!!(cond); }; } while(0>1)
#	if __GNUC__ >= 2
#		define O7_NORETURN __attribute__((noreturn))
#	else
#		define O7_NORETURN
#	endif
#endif

O7_ATTR_MALLOC O7_ALWAYS_INLINE
void* o7_raw_alloc(size_t size) {
	extern char o7_memory[O7_MEMNG_NOFREE_BUFFER_SIZE];
	extern size_t o7_allocated;
	void *mem;
	if ((O7_MEMNG == O7_MEMNG_NOFREE)
	 && (1 < O7_MEMNG_NOFREE_BUFFER_SIZE))
	{
		if (o7_allocated < (size_t)O7_MEMNG_NOFREE_BUFFER_SIZE - size) {
			mem = (void *)(o7_memory + o7_allocated);
			o7_allocated +=
				(size - 1 + O7_MEM_ALIGN) / O7_MEM_ALIGN * O7_MEM_ALIGN;
		} else {
			mem = NULL;
		}
	} else if ((O7_INIT == O7_INIT_ZERO)
	        || (O7_MEMNG == O7_MEMNG_COUNTER))
	{
		mem = calloc(1, size);
	} else {
		mem = malloc(size);
	}
	return mem;
}

O7_ATTR_MALLOC O7_ALWAYS_INLINE void* o7_malloc(size_t size);
#if O7_MEMNG == O7_MEMNG_GC
	O7_INLINE void* o7_malloc(size_t size) {
		return GC_MALLOC(size);
	}
#elif defined(O7_LSAN_LEAK_IGNORE)
#	include <sanitizer/lsan_interface.h>
	O7_INLINE void* o7_malloc(size_t size) {
		void *mem;
		mem = o7_raw_alloc(size);
		__lsan_ignore_object(mem);
		return mem;
	}
#else
	O7_INLINE void* o7_malloc(size_t size) {
		return o7_raw_alloc(size);
	}
#endif

#if !defined(O7_MAX_RECORD_EXT)
#	define O7_MAX_RECORD_EXT 15
#endif

#if defined(O7_TAG_ID_TYPE)
	typedef O7_TAG_ID_TYPE o7_id_t;
#else
	typedef int o7_id_t;
#endif

#define O7_LEN(array) ((o7_int_t)(sizeof(array) / sizeof((array)[0])))

typedef o7_id_t o7_tag_t[O7_MAX_RECORD_EXT + 1];
extern o7_tag_t o7_base_tag;

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_cbool o7_bool_inited(o7_bool b) {
	return *(o7_char *)&b < 2;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_bool o7_bl(o7_bool b) {
	if ((sizeof(b) == sizeof(o7_char)) && O7_UNDEF) {
		assert(o7_bool_inited(b));
	}
	return b;
}

extern o7_char* o7_bools_undef(int len, o7_char array[O7_VLA(len)]);
#define O7_BOOLS_UNDEF(array) \
	o7_bools_undef(sizeof(array) / sizeof(o7_char), (o7_char *)(array))

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_dbl_undef(void) {
	return nan(NULL);
}

extern double* o7_doubles_undef(int len, double array[O7_VLA(len)]);
#define O7_DOUBLES_UNDEF(array) \
	o7_doubles_undef(sizeof(array) / sizeof(double), (double *)(array))

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_dbl(double d) {
	if (!O7_UNDEF) {
		;
	} else if (sizeof(unsigned) == sizeof(double) / 2) {
		unsigned u;
		memcpy(&u, (unsigned *)&d + 1, sizeof(u));
		assert(u != 0x7FFFFFFFul);
	} else {
		unsigned long u;
		memcpy(&u, (unsigned long *)&d + 1, sizeof(u));
		assert(u != 0x7FFFFFFFul);
	}
	return d;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
char unsigned o7_byte(int v) {
	assert((unsigned)v <= 255);
	return (char unsigned)v;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
char unsigned o7_chr(int v) {
	assert((unsigned)v <= 255);
	return (char unsigned)v;
}

#if (__STDC_VERSION__ >= 199901L) && !(defined(__TINYC__) && (defined(_WIN32) || defined(_WIN64)))
/* TODO в вычислительных функциях можно будет убрать o7_dbl после проверки*/
	O7_ATTR_CONST O7_ALWAYS_INLINE
	double o7_dbl_finite(double v) {
		assert(isfinite(v));
		return v;
	}
#else
	/* TODO */
	O7_ATTR_CONST O7_ALWAYS_INLINE
	double o7_dbl_finite(double v) {
		assert((v == v) && (-DBL_MAX <= v) && (v <= DBL_MAX));
		return v;
	}
#endif

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_fadd(double a1, double a2) {
	return o7_dbl_finite(a1 + a2);
}

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_fsub(double m, double s) {
	return o7_dbl_finite(m - s);
}

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_fmul(double m1, double m2) {
	return o7_dbl_finite(m1 * m2);
}

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_fdiv(double n, double d) {
	if (O7_FLOAT_DIV_ZERO) {
		assert(d != 0.0);
	}
	return o7_dbl_finite(n / d);
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_bool o7_int_inited(int i) {
	return i >= -INT_MAX;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_int(int i) {
	if (O7_UNDEF) {
		assert(o7_int_inited(i));
	}
	return i;
}

extern int* o7_ints_undef(int len, int array[O7_VLA(len)]);
#define O7_INTS_UNDEF(array) \
	o7_ints_undef((int)(sizeof(array) / (sizeof(int))), (int *)(array))

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_add(int a1, int a2) {
	int s;
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SADD(o7_int(a1), o7_int(a2), &s);
		assert(!overflow && s >= -INT_MAX);
	} else {
		if (!O7_OVERFLOW) {
			if (O7_UNDEF) {
				assert(o7_int_inited(a1));
				assert(o7_int_inited(a2));
			}
		} else if (a2 >= 0) {
			assert(o7_int(a1) <=  INT_MAX - a2);
		} else {
			assert(a1 >= -INT_MAX - o7_int(a2));
		}
		s = a1 + a2;
	}
	return s;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_sub(int m, int s) {
	int d;
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SSUB(o7_int(m), o7_int(s), &d);
		assert(!overflow && d >= -INT_MAX);
	} else {
		if (!O7_OVERFLOW) {
			if (O7_UNDEF) {
				assert(o7_int_inited(m));
				assert(o7_int_inited(s));
			}
		} else if (s >= 0) {
			assert(m >= -INT_MAX + s);
		} else {
			assert(o7_int(m) <= INT_MAX + o7_int(s));
		}
		d = m - s;
	}
	return d;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_mul(int m1, int m2) {
	int p;
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SMUL(o7_int(m1), o7_int(m2), &p);
		assert(!overflow && p >= -INT_MAX);
	} else {
		if (O7_OVERFLOW && (0 != m2)) {
			assert(abs(m1) <= INT_MAX / abs(m2));
		}
		p = o7_int(m1) * o7_int(m2);
	}
	return p;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_div(int n, int d) {
	if (O7_OVERFLOW && O7_DIV_ZERO) {
		assert(d != 0);
	}
	return o7_int(n) / o7_int(d);
}

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_mod(int n, int d) {
	if (O7_OVERFLOW && O7_DIV_ZERO) {
		assert(d != 0);
	}
	return o7_int(n) % o7_int(d);
}

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_ind(int len, int ind) {
	if (O7_ARRAY_INDEX) {
		assert((unsigned)ind < (unsigned)len);
	}
	return ind;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_cmp(int a, int b) {
	int cmp;
	if (a < b) {
		if (O7_UNDEF) {
			assert(o7_int_inited(a));
		}
		cmp = -1;
	} else {
		if (O7_UNDEF) {
			assert(o7_int_inited(b));
		}
		if (a == b) {
			cmp = 0;
		} else {
			cmp = 1;
		}
	}
	return cmp;
}

O7_ALWAYS_INLINE void o7_release(void *mem) {
	o7_mmc_t *counter;
	if ((O7_MEMNG == O7_MEMNG_COUNTER)
	 && (NULL != mem))
	{
		counter = (o7_mmc_t *)((o7_id_t **)mem - 1) - 1;
		if (1 == *counter) {
			free(counter);
		} else {
			assert(*counter > 1);
			*counter -= 1;
		}
	}
}

O7_ALWAYS_INLINE o7_cbool
o7_new(void **pmem, int size, o7_tag_t const tag, void undef(void *)) {
	void *mem;
	mem = o7_malloc(
	    sizeof(o7_mmc_t) * (int)(O7_MEMNG == O7_MEMNG_COUNTER)
	  + sizeof(o7_id_t *) + size);
	if (NULL != mem) {
		if (O7_MEMNG == O7_MEMNG_COUNTER) {
			*(o7_mmc_t *)mem = 1;
			mem = (void *)((o7_mmc_t *)mem + 1);
		}
		*(o7_id_t const **)mem = tag;
		mem = (void *)((o7_id_t **)mem + 1);
		if ((O7_INIT == O7_INIT_UNDEF) && (NULL != undef)) {
			undef(mem);
		}
	}
	o7_release(*pmem);
	*pmem = mem;
	return NULL != mem;
}

#define O7_NEW(mem, name) \
	o7_new((void **)mem, sizeof(**(mem)), name##_tag, (void (*)(void *))name##_undef)

#define O7_NEW2(mem, tag, undef) \
	o7_new((void **)mem, sizeof(**(mem)), tag, (void (*)(void *))undef)

O7_ALWAYS_INLINE void* o7_retain(void *mem) {
	if ((O7_MEMNG == O7_MEMNG_COUNTER) && (NULL != mem)) {
		*((o7_mmc_t *)((o7_id_t **)mem - 1) - 1) += 1;
	}
	return mem;
}

/** уменьшает счётчик на 1, но не освобождает объект при достижении 0 */
O7_ALWAYS_INLINE void* o7_unhold(void *mem) {
	o7_mmc_t *counter;
	if ((O7_MEMNG == O7_MEMNG_COUNTER)
	 && (NULL != mem))
	{
		counter = (o7_mmc_t *)((o7_id_t **)mem - 1) - 1;
		assert(*counter > 0);
		*counter -= 1;
	}
	return mem;
}


#define O7_RELEASE_PARAMS(array) o7_release_array(sizeof(array) / sizeof(array[0]), array)

O7_ALWAYS_INLINE void o7_null(void **mem) {
	o7_release(*mem);
	*mem = NULL;
}

#define O7_NULL(mem) o7_null((void **)(mem))

O7_ALWAYS_INLINE void o7_release_array(int count, void *mem[O7_VLA(count)]) {
	int i;
	if (O7_MEMNG == O7_MEMNG_COUNTER) {
		for (i = 0; i < count; i += 1) {
			o7_null(mem + i);
		}
	}
}

O7_ALWAYS_INLINE void o7_assign(void **m1, void *m2) {
	assert(NULL != m1);/* TODO remove */
	o7_retain(m2);
	if (NULL != *m1) {
		o7_release(*m1);
	}
	*m1 = m2;
}

#define O7_ASSIGN(m1, m2) o7_assign((void **)(m1), m2)

extern void o7_tag_init(o7_tag_t ext, o7_tag_t const base);

O7_ATTR_PURE O7_ALWAYS_INLINE
o7_id_t const * o7_dynamic_tag(void const *mem) {
	assert(NULL != mem);
	return *((o7_id_t const **)mem - 1);
}

O7_ATTR_PURE O7_ALWAYS_INLINE
o7_bool o7_is_r(o7_id_t const *base, void const *strct, o7_tag_t const ext) {
	if (NULL == base) {
		base = o7_dynamic_tag(strct);
	}
	return base[ext[0]] == ext[ext[0]];
}

O7_ATTR_PURE O7_ALWAYS_INLINE
o7_bool o7_is(void const *strct, o7_tag_t const ext) {
	o7_id_t const *base;
	base = o7_dynamic_tag(strct);
	return base[ext[0]] == ext[ext[0]];
}

O7_ATTR_PURE O7_ALWAYS_INLINE
void **o7_must(void **strct, o7_tag_t const ext) {
	assert(o7_is(*strct, ext));
	return strct;
}

#define O7_GUARD(ExtType, strct) \
	(*(struct ExtType **)o7_must((void **)strct, ExtType##_tag))


O7_ATTR_PURE O7_ALWAYS_INLINE
void * o7_must_r(o7_tag_t const base, void *strct, o7_tag_t const ext) {
	assert(o7_is_r(base, strct, ext));
	return strct;
}

#define O7_GUARD_R(ExtType, strct, base) \
	(*(struct ExtType *)o7_must_r(base, strct, ExtType##_tag))

O7_ATTR_CONST O7_ALWAYS_INLINE
unsigned o7_set(int low, int high) {
	assert(high <= 31);
	assert(0 <= low && low <= high);
	return (~0u << low) & (~0u >> (31 - high));
}

#define O7_SET(low, high) (((o7_ulong_t)-1 << low) & ((o7_ulong_t)-1 >> (63 - high)))

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_bool o7_in(int n, unsigned set) {
	return (n >= 0) && (n <= 63) && (0 != (set & ((o7_ulong_t)1 << n)));
}

#define O7_IN(n, set) (((n) >= 0) && ((n) <= 63) && (0 != (set) & ((o7_ulong_t)1u << (n))))

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_sti(unsigned v) {
	assert(v <= (unsigned)INT_MAX);
	return (int)v;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_floor(double v) {
	assert((double)(-INT_MAX) <= v && v <= (double)INT_MAX);
	return (int)v;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_flt(int v) {
	return (double)o7_int(v);
}

O7_ALWAYS_INLINE o7_cbool o7_ldexp(double *f, int n) {
	*f = ldexp(o7_dbl(*f), o7_int(n));
	return 0 < 1;/* TODO */
}

O7_ALWAYS_INLINE o7_cbool o7_frexp(double *f, int *n) {
	int p;
	*f = frexp(o7_dbl(*f), &p) * 2.0;
	*n = p - 1;
	return 0 < 1;/* TODO */
}

extern int o7_strcmp(int s1_len, o7_char const s1[O7_VLA(s1_len)],
                     int s2_len, o7_char const s2[O7_VLA(s2_len)])
	O7_ATTR_PURE;

O7_ALWAYS_INLINE
void o7_memcpy(int dest_len, o7_char dest[O7_VLA(dest_len)],
               int src_len, o7_char const src[O7_VLA(src_len)])
{
	assert(src_len <= dest_len);
	memcpy(dest, dest, src_len);
}

extern O7_NORETURN void o7_case_fail(int i);

extern void o7_init(int argc, char *argv[O7_VLA(argc)]);

extern int o7_exit_code;

#undef O7_GNUC_SADD
#undef O7_GNUC_SSUB
#undef O7_GNUC_SMUL
#undef O7_GNUC_SADDL
#undef O7_GNUC_SSUBL
#undef O7_GNUC_SMULL

#endif
