#if !defined HEADER_GUARD_o7
#    define  HEADER_GUARD_o7 1

#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <limits.h>
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

#if (__STDC_VERSION__ >= 199901L) && !defined(__STDC_NO_VLA__) \
 && !defined(__TINYC__) && !defined(__COMPCERT__)

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
#	else
#		define O7_INT_UNDEF  0
#	endif
#	define O7_DBL_UNDEF  o7_dbl_undef()
#	define O7_BOOL_UNDEF 0xFF
#else
#	define O7_INT_UNDEF  0
#	define O7_DBL_UNDEF  0.0
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
	typedef O7_INT_T  o7_int_t;
	typedef O7_UINT_T o7_uint_t;
#else
#	if INT_MAX >= 2147483647
#		define O7_INT_MAX 2147483647
#		define O7_UINT_MAX 4294967295u
		typedef int           o7_int_t;
		typedef unsigned      o7_uint_t;
#	elif LONG_MAX >= 2147483647l
#		define O7_INT_MAX 2147483647l
#		define O7_UINT_MAX 4294967295ul
		typedef long          o7_int_t;
		typedef unsigned long o7_uint_t;
#	else
#		error
#	endif
#endif

#if !defined(O7_INT_MAX) || !defined(O7_UINT_MAX)
#	error
#endif

#if O7_GNUC_BUILTIN_OVERFLOW
#	define O7_GNUC_SADD(a, b, res)  __builtin_sadd_overflow(a, b, res)
#	define O7_GNUC_SSUB(a, b, res)  __builtin_ssub_overflow(a, b, res)
#	define O7_GNUC_SMUL(a, b, res)  __builtin_smul_overflow(a, b, res)
#else
#	define O7_GNUC_SADD(a, b, res)  (0 < sizeof(*(res) = (a)+(b)))
#	define O7_GNUC_SSUB(a, b, res)  (0 < sizeof(*(res) = (a)-(b)))
#	define O7_GNUC_SMUL(a, b, res)  (0 < sizeof(*(res) = (a)*(b)))
#endif

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

#if __GNUC__ > 2
#	define O7_ATTR_CONST  __attribute__((const))
#	define O7_ATTR_PURE   __attribute__((pure))
#	define O7_ATTR_MALLOC __attribute__((malloc))
#else
#	define O7_ATTR_CONST
#	define O7_ATTR_PURE
#	define O7_ATTR_MALLOC
#endif

#if __GNUC__ * 10 + __GNUC_MINOR__ >= 31
#	define O7_ATTR_ALWAYS_INLINE __attribute__((always_inline))
#else
#	define O7_ATTR_ALWAYS_INLINE
#endif

#define O7_ALWAYS_INLINE O7_ATTR_ALWAYS_INLINE O7_INLINE

#if defined(O7_MEMNG_COUNTER_TYPE)
	typedef O7_MEMNG_COUNTER_TYPE
	                  o7_mmc_t;
#elif defined(__clang__) && (__SIZEOF_POINTER__ == __SIZEOF_INT__)
	typedef int       o7_mmc_t;
#elif defined(__clang__) && (__SIZEOF_POINTER__ == __SIZEOF_LONG__)
	typedef long      o7_mmc_t;
#elif ((size_t)-1) == O7_UINT_MAX
	typedef o7_int_t  o7_mmc_t;
#else
	typedef long      o7_mmc_t;
#endif

#if !defined(O7_MAX_RECORD_EXT)
#	define O7_MAX_RECORD_EXT 15
#endif

#if defined(O7_TAG_ID_TYPE)
	typedef O7_TAG_ID_TYPE o7_id_t;
#else
	typedef int o7_id_t;
#endif

typedef struct {
	o7_id_t ids[O7_MAX_RECORD_EXT + 1];
	void (*release)(void *);
} o7_tag_t;
extern o7_tag_t o7_base_tag;

enum {
	O7_MEMINFO_SIZE = sizeof(o7_mmc_t) * (int)(O7_MEMNG == O7_MEMNG_COUNTER)
	                + sizeof(o7_tag_t *)
};

#if O7_MEMNG == O7_MEMNG_GC
#	include "gc.h"
	O7_ALWAYS_INLINE void o7_gc_init(void) {
		GC_INIT();
		GC_REGISTER_DISPLACEMENT(O7_MEMINFO_SIZE);
	}
#else
	O7_ALWAYS_INLINE void o7_gc_init(void) {
		assert(0 > 1);
	}
#endif

#if defined(O7_CHECK_OVERFLOW)
	enum { O7_OVERFLOW = O7_CHECK_OVERFLOW };
#else
	enum { O7_OVERFLOW = 1 };
#endif

#if defined(O7_CHECK_NATURAL_DIVISOR)
	enum { O7_NATURAL_DIVISOR = O7_CHECK_NATURAL_DIVISOR };
#else
	enum { O7_NATURAL_DIVISOR = 1 };
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

#define O7_LEN(array) ((o7_int_t)(sizeof(array) / sizeof((array)[0])))

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

extern o7_char* o7_bools_undef(o7_int_t len, o7_char array[O7_VLA(len)]);
#define O7_BOOLS_UNDEF(array) \
	o7_bools_undef((o7_int_t)(sizeof(array) / sizeof(o7_char)), (o7_char *)(array))

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_dbl_undef(void) {
	o7_uint_t const u = 0x7FFFFFFFul;
	double signaling_nan;

	signaling_nan = 0.0;
	/* TODO check correctness for big endian */
	memcpy((o7_uint_t *)&signaling_nan + 1, &u, sizeof(u));
	return signaling_nan;
}

extern double* o7_doubles_undef(o7_int_t len, double array[O7_VLA(len)]);
#define O7_DOUBLES_UNDEF(array) \
	o7_doubles_undef((o7_int_t)(sizeof(array) / sizeof(double)), (double *)(array))

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
double o7_flt_undef(void) {
	o7_uint_t const u = 0x7FFFFFFFul;
	float signaling_nan;

	signaling_nan = 0.0;
	memcpy((o7_uint_t *)&signaling_nan, &u, sizeof(u));
	return signaling_nan;
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

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_dbl_finite(double v) {
	assert((v == v) && (-DBL_MAX <= v) && (v <= DBL_MAX));
	return v;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
float o7_flt_finite(float v) {
	assert((v == v) && (-FLT_MAX <= v) && (v <= FLT_MAX));
	return v;
}

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
o7_bool o7_int_inited(o7_int_t i) {
	return -O7_INT_MAX <= i;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_int(o7_int_t i) {
	if (O7_UNDEF) {
		assert(o7_int_inited(i));
	}
	return i;
}

extern o7_int_t* o7_ints_undef(o7_int_t len, o7_int_t array[O7_VLA(len)]);
#define O7_INTS_UNDEF(array) \
	o7_ints_undef((o7_int_t)(sizeof(array) / (sizeof(o7_int_t))), (o7_int_t *)(array))

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_add(o7_int_t a1, o7_int_t a2) {
	o7_int_t s;
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SADD(o7_int(a1), o7_int(a2), &s) || (-O7_INT_MAX > s);
		assert(!overflow);
	} else {
		if (!O7_OVERFLOW) {
			if (O7_UNDEF) {
				assert(o7_int_inited(a1));
				assert(o7_int_inited(a2));
			}
		} else if (0 <= a2) {
			assert(o7_int(a1) <= O7_INT_MAX - a2);
		} else {
			assert(-O7_INT_MAX - o7_int(a2) <= a1);
		}
		s = a1 + a2;
	}
	return s;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_sub(o7_int_t m, o7_int_t s) {
	o7_int_t d;
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SSUB(o7_int(m), o7_int(s), &d) || (-O7_INT_MAX > d);
		assert(!overflow);
	} else {
		if (!O7_OVERFLOW) {
			if (O7_UNDEF) {
				assert(o7_int_inited(m));
				assert(o7_int_inited(s));
			}
		} else if (0 <= s) {
			assert(-O7_INT_MAX + s <= m);
		} else {
			assert(o7_int(m) <= INT_MAX + o7_int(s));
		}
		d = m - s;
	}
	return d;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_mul(o7_int_t m1, o7_int_t m2) {
	o7_int_t p;
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SMUL(o7_int(m1), o7_int(m2), &p) || (-O7_INT_MAX > p);
		assert(!overflow);
	} else {
		if (O7_OVERFLOW && (0 != m2)) {
			assert(abs(m1) <= O7_INT_MAX / abs(m2));
		}
		p = o7_int(m1) * o7_int(m2);
	}
	return p;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_divisor(o7_int_t d) {
	if (O7_NATURAL_DIVISOR) {
		assert(0 < d);
	} else {
		if (O7_OVERFLOW && O7_DIV_ZERO) {
			assert(d != 0);
		}
		d = o7_int(d);
	}
	return d;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_div(o7_int_t n, o7_int_t d) {
	o7_int_t r;
	if (0 <= n) {
		r = n / o7_divisor(d);
	} else {
		r = -1 - (-1 - o7_int(n)) / o7_divisor(d);
	}
	return  r;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_mod(o7_int_t n, o7_int_t d) {
	o7_int_t r;
	if (0 <= n) {
		r = n % o7_divisor(d);
	} else {
		r = d + (-1 - (-1 - o7_int(n)) % o7_divisor(d));
	}
	return r;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_ind(o7_int_t len, o7_int_t ind) {
	if (O7_ARRAY_INDEX) {
		assert((o7_uint_t)ind < (o7_uint_t)len);
	}
	return ind;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
int o7_cmp(o7_int_t a, o7_int_t b) {
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

O7_ALWAYS_INLINE
void o7_release(void *mem) {
	o7_mmc_t *counter;
	o7_mmc_t count;
	o7_tag_t const **tag;
	if ((O7_MEMNG == O7_MEMNG_COUNTER)
	 && (NULL != mem))
	{
		tag = (o7_tag_t const **)mem - 1;
		counter = (o7_mmc_t *)tag - 1;
		count = *counter;
		if (1 < count) {
			*counter = count - 1;
		} else {
			assert(1 == count);
			(*tag)->release(mem);
			free(counter);
		}
	}
}

O7_ALWAYS_INLINE
void* o7_mem_info_init(void *mem, o7_tag_t const *tag) {
	o7_tag_t const **tg;
	if (O7_MEMNG == O7_MEMNG_COUNTER) {
		*(o7_mmc_t *)mem = 1;
		tg = (o7_tag_t const **)((o7_mmc_t *)mem + 1);
	} else {
		tg = (o7_tag_t const **)mem;
	}
	*tg = tag;
	return (void *)(tg + 1);
}

O7_ALWAYS_INLINE
o7_cbool o7_new(void **pmem, int size, o7_tag_t const *tag, void undef(void *)) {
	void *mem;
	mem = o7_malloc(O7_MEMINFO_SIZE + size);
	if (NULL != mem) {
		mem = o7_mem_info_init(mem, tag);
		if ((O7_INIT == O7_INIT_UNDEF) && (NULL != undef)) {
			undef(mem);
		}
	}
	o7_release(*pmem);
	*pmem = mem;
	return NULL != mem;
}

#if O7_INIT != O7_INIT_UNDEF
#	define O7_NEW(mem, name) \
		o7_new((void **)mem, sizeof(**(mem)), &name##_tag, (void (*)(void *))name##_undef)
#else
#	define O7_NEW(mem, name) \
		o7_new((void **)mem, sizeof(**(mem)), &name##_tag, NULL)
#endif

#define O7_NEW2(mem, tag, undef) \
	o7_new((void **)mem, sizeof(**(mem)), &tag, (void (*)(void *))undef)

O7_ALWAYS_INLINE
void* o7_retain(void *mem) {
	if ((O7_MEMNG == O7_MEMNG_COUNTER) && (NULL != mem)) {
		*((o7_mmc_t *)((o7_tag_t **)mem - 1) - 1) += 1;
	}
	return mem;
}

/** уменьшает счётчик на 1, но не освобождает объект при достижении 0 */
O7_ALWAYS_INLINE
void* o7_unhold(void *mem) {
	o7_mmc_t *counter;
	o7_mmc_t count;
	if ((O7_MEMNG == O7_MEMNG_COUNTER)
	 && (NULL != mem))
	{
		counter = (o7_mmc_t *)((o7_tag_t **)mem - 1) - 1;
		count = *counter;
		assert(0 < count);/* TODO remove */
		*counter = count - 1;
	}
	return mem;
}

O7_ALWAYS_INLINE
void o7_null(void **mem) {
	if (NULL != *mem) {
		o7_release(*mem);
		*mem = NULL;
	}
}

#define O7_NULL(mem) o7_null((void **)(mem))

O7_ALWAYS_INLINE
void o7_release_array(o7_int_t count, void *mem[O7_VLA(count)]) {
	o7_int_t i;
	if (O7_MEMNG == O7_MEMNG_COUNTER) {
		for (i = 0; i < count; i += 1) {
			o7_null(mem + i);
		}
	}
}

#define O7_RELEASE_ARRAY(array) \
	o7_release_array(sizeof(array) / sizeof(void *), (void **)array)

O7_ALWAYS_INLINE
void o7_retain_array(o7_int_t count, void *mem[O7_VLA(count)]) {
	o7_int_t i;
	if (O7_MEMNG == O7_MEMNG_COUNTER) {
		for (i = 0; i < count; i += 1) {
			o7_retain(mem + i);
		}
	}
}

#define O7_RETAIN_ARRAY(array) \
	o7_retain_array(sizeof(array) / sizeof(void *), (void **)array)

O7_ALWAYS_INLINE
void o7_release_records(o7_int_t count, o7_int_t item_size, void *array, void release(void *)) {
	o7_int_t i;
	assert(0 > 1);/* TODO */
	if (O7_MEMNG == O7_MEMNG_COUNTER) {
		for (i = 0; i < count; i += 1) {
			o7_null((void **)array + i);
		}
	}
}

O7_ALWAYS_INLINE
void o7_assign(void **m1, void *m2) {
	assert(NULL != m1);/* TODO remove */
	o7_retain(m2);
	o7_release(*m1);
	*m1 = m2;
}

#define O7_ASSIGN(m1, m2) o7_assign((void **)(m1), m2)

extern void o7_tag_init(o7_tag_t *ext, o7_tag_t const *base, void release(void *));

#if O7_MEMNG == O7_MEMNG_COUNTER
#	define O7_TAG_INIT(ExtType, BaseType) \
		o7_tag_init(&ExtType##_tag, &BaseType##_tag, (void (*)(void *))ExtType##_release)
#else
#	define O7_TAG_INIT(ExtType, BaseType) \
		o7_tag_init(&ExtType##_tag, &BaseType##_tag, NULL)
#endif

O7_ATTR_PURE O7_ALWAYS_INLINE
o7_tag_t const * o7_dynamic_tag(void const *mem) {
	assert(NULL != mem);
	return *((o7_tag_t const **)mem - 1);
}

O7_ATTR_PURE O7_ALWAYS_INLINE
o7_bool o7_is_r(o7_tag_t const *base, void const *strct, o7_tag_t const *ext) {
	if (NULL == base) {
		base = o7_dynamic_tag(strct);
	}
	return base->ids[ext->ids[0]] == ext->ids[ext->ids[0]];
}

O7_ATTR_PURE O7_ALWAYS_INLINE
o7_bool o7_is(void const *strct, o7_tag_t const *ext) {
	o7_tag_t const *base;
	base = o7_dynamic_tag(strct);
	return base->ids[ext->ids[0]] == ext->ids[ext->ids[0]];
}

O7_ATTR_PURE O7_ALWAYS_INLINE
void **o7_must(void **strct, o7_tag_t const *ext) {
	assert(o7_is(*strct, ext));
	return strct;
}

#define O7_GUARD(ExtType, strct) \
	(*(struct ExtType **)o7_must((void **)strct, &ExtType##_tag))


O7_ATTR_PURE O7_ALWAYS_INLINE
void * o7_must_r(o7_tag_t const *base, void *strct, o7_tag_t const *ext) {
	assert(o7_is_r(base, strct, ext));
	return strct;
}

#define O7_GUARD_R(ExtType, strct, base) \
	(*(struct ExtType *)o7_must_r(base, strct, &ExtType##_tag))

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_uint_t o7_set(o7_int_t low, o7_int_t high) {
	assert(high <= 31);
	assert(0 <= low && low <= high);
	return (~(o7_uint_t)0 << low) & (~(o7_uint_t)0 >> (31 - high));
}

#define O7_SET(low, high) (((o7_uint_t)-1 << low) & ((o7_uint_t)-1 >> (31 - high)))

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_bool o7_in(o7_int_t n, o7_uint_t set) {
	return (n >= 0) && (n <= 31) && (0 != (set & ((o7_uint_t)1 << n)));
}

#define O7_IN(n, set) (((n) >= 0) && ((n) <= 31) && (0 != ((set) & ((o7_uint_t)1u << (n)))))

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_sti(o7_uint_t v) {
	assert(v <= (o7_uint_t)O7_INT_MAX);
	return (o7_int_t)v;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
o7_int_t o7_floor(double v) {
	assert((double)(-O7_INT_MAX) <= v && v <= (double)O7_INT_MAX);
	return (o7_int_t)v;
}

O7_ATTR_CONST O7_ALWAYS_INLINE
double o7_flt(o7_int_t v) {
	return (double)o7_int(v);
}

O7_ALWAYS_INLINE
void o7_ldexp(double *f, o7_int_t n) {
	extern double o7_raw_ldexp(double f, int n);

	*f = o7_dbl_finite(o7_raw_ldexp(o7_dbl_finite(*f), o7_int(n)));
}

O7_ALWAYS_INLINE
void o7_frexp(double *f, o7_int_t *n) {
	extern double o7_raw_frexp(double x, int *exp);

	int p;

	*f = o7_raw_frexp(o7_dbl_finite(*f), &p) * 2.0;
	if (*f == 0.0) {
		*n = p;
	} else {
		*n = p - 1;
	}
}

extern O7_ATTR_PURE
int o7_strcmp(o7_int_t s1_len, o7_char const s1[O7_VLA(s1_len)],
              o7_int_t s2_len, o7_char const s2[O7_VLA(s2_len)]);

O7_ALWAYS_INLINE
void o7_memcpy(o7_int_t dest_len, o7_char dest[O7_VLA(dest_len)],
               o7_int_t src_len, o7_char const src[O7_VLA(src_len)])
{
	assert(src_len <= dest_len);
	memcpy(dest, dest, (size_t)src_len);
}

extern O7_NORETURN void o7_case_fail(o7_int_t i);

extern void o7_init(int argc, char *argv[O7_VLA(argc)]);

extern int o7_exit_code;

#endif
