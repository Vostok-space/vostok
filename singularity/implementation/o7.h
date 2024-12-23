/* Copyright 2016-2024 ComdivByZero
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
#	elif __GNUC__ * 100 + __GNUC_MINOR__ >= 295
#		define O7_INLINE static __inline__
#	else
#		define O7_INLINE static
#	endif
#endif

#if defined(O7_USE_GNUC_BUILTIN_OVERFLOW)
#	define O7_GNUC_BUILTIN_OVERFLOW O7_USE_GNUC_BUILTIN_OVERFLOW
#elif __GNUC__ >= 5 || __clang_major__ > 5
#	define O7_GNUC_BUILTIN_OVERFLOW (0 < 1)
#else
#	define O7_GNUC_BUILTIN_OVERFLOW (0 > 1)
#endif

#if !defined(__STDC_NO_VLA__) \
 && (defined(__TINYC__) || !defined(__COMPCERT__) || !defined(__chibicc__))
#	define __STDC_NO_VLA__ 1
#endif

#if (__STDC_VERSION__ >= 199901L) && !defined(__STDC_NO_VLA__)
#	define O7_VLA(len) static len
#else
#	define O7_VLA(len)
#endif


#define O7_INIT_UNDEF 0
#define O7_INIT_ZERO  1
#define O7_INIT_NO    2

#if defined(O7_INIT_MODEL)
#	if (O7_INIT_UNDEF <= O7_INIT_MODEL) && (O7_INIT_MODEL <= O7_INIT_NO)
#		define O7_INIT O7_INIT_MODEL
#	else
#		error Wrong value of O7_INIT_MODEL
#	endif
#else
#	define O7_INIT O7_INIT_UNDEF
#endif

#if defined(__TenDRA__)
#	define O7_TWOS_COMPLEMENT     1
#	define O7_INT_ENOUGH_FOR_32   1
#	define O7_INT_ENOUGH_FOR_SIZE 1
#	define O7_LONG_SUPPORT        0
#	define O7_LONG_ENOUGH_FOR_64  0
#else
#	define O7_TWOS_COMPLEMENT (INT_MIN < -INT_MAX)
#	define O7_INT_ENOUGH_FOR_32 (INT_MAX >= 2147483647)
#	define O7_LONG_ENOUGH_FOR_64 (LONG_MAX > 2147483647l)
#	define O7_LONG_SUPPORT (0 < 1)
#	define O7_INT_ENOUGH_FOR_SIZE (((size_t)-1) == O7_UINT_MAX)
#endif

#define O7_ORDER_LE 1
#define O7_ORDER_BE 2

#if defined(__BYTE_ORDER__)
#	if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
#		define O7_BYTE_ORDER O7_ORDER_LE
#	elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#		define O7_BYTE_ORDER O7_ORDER_BE
#	elif __BYTE_ORDER__ == __ORDER_PDP_ENDIAN__
#		error PDP endianess is not supported
#	else
#		error Unknown byte order
#	endif
#elif __LITTLE_ENDIAN__
#	define O7_BYTE_ORDER O7_ORDER_LE
#elif __BIG_ENDIAN__
#	define O7_BYTE_ORDER O7_ORDER_BE
#else
	/* Вычисляемый в инициализации */
	extern int O7_BYTE_ORDER;
#endif

#if (O7_INIT == O7_INIT_UNDEF)
#	if O7_TWOS_COMPLEMENT
#		define O7_INT_UNDEF  (-1 - O7_INT_MAX)
#		define O7_LONG_UNDEF (-1 - O7_LONG_MAX)
#	else
#		define O7_INT_UNDEF  0
#		define O7_LONG_UNDEF 0
#	endif
#	if __GNUC__ * 100 + __GNUC_MINOR__ >= 330
#		define O7_DBL_UNDEF (__builtin_nans (""))
#		define O7_FLT_UNDEF (__builtin_nansf (""))
#	elif O7_USE_SIGNALING_NAN
#		define O7_USED_SIGNALING_NAN_BY_FUNC 1
#		define O7_DBL_UNDEF  o7_dbl_undef()
#		define O7_FLT_UNDEF  o7_flt_undef()
#	else
#		define O7_DBL_UNDEF  (0. / 0.)
#		define O7_FLT_UNDEF  (0.f / 0.f)
#	endif
#	define O7_BOOL_UNDEF 0xFF
#else
#	define O7_INT_UNDEF  0
#	define O7_LONG_UNDEF 0
#	define O7_DBL_UNDEF  0.0
#	define O7_FLT_UNDEF  0.0f
#	define O7_BOOL_UNDEF (0>1)
#endif
#if !defined(__TINYC__) && !O7_USED_SIGNALING_NAN_BY_FUNC
#	define O7_DBL_UNDEF_STATIC O7_DBL_UNDEF
#	define O7_FLT_UNDEF_STATIC O7_FLT_UNDEF
#else
#	define O7_DBL_UNDEF_STATIC 0.
#	define O7_FLT_UNDEF_STATIC 0.f
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
#elif O7_INIT == O7_INIT_UNDEF
	typedef o7_char o7_bool;
#else
	typedef o7_cbool o7_bool;
#endif

#if defined(O7_INT_T)
	typedef O7_INT_T  o7_int_t;
	typedef O7_UINT_T o7_uint_t;
#else
#	if O7_INT_ENOUGH_FOR_32
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

typedef size_t o7_ptr_t;

#define O7_INT_BITS  (sizeof(o7_int_t ) * CHAR_BIT)
#define O7_LONG_BITS (sizeof(o7_long_t) * CHAR_BIT)

#if defined(__GNUC__) || defined(__TINYC__) || defined(__COMPCERT__)
	enum { O7_ARITHMETIC_SHIFT = 1 };
#else
	enum { O7_ARITHMETIC_SHIFT = 0 };
#endif

enum { O7_DIV_BRANCHLESS = O7_ARITHMETIC_SHIFT };

#if !defined(O7_INT_MAX) || !defined(O7_UINT_MAX)
#	error
#endif

#if defined(O7_LONG_T)
	typedef O7_LONG_T             o7_long_t;
	typedef O7_ULONG_T            o7_ulong_t;
#	if !defined(O7_LONG_ABS) || !defined(O7_LONG_MAX) || !defined(O7_ULONG_MAX)
#		error
#	else
#		define O7_LABS(val) O7_LONG_ABS(val)
#	endif
#elif !O7_LONG_SUPPORT
#
#elif O7_LONG_ENOUGH_FOR_64
#	define O7_LONG_MAX  9223372036854775807l
#	define O7_ULONG_MAX 18446744073709551615ul
	typedef long               o7_long_t;
	typedef long unsigned      o7_ulong_t;
#	define O7_LABS(val)        labs(val)
#elif LLONG_MAX >= 9223372036854775807ll
#	define O7_LONG_MAX  9223372036854775807ll
#	define O7_ULONG_MAX 18446744073709551615ull
	typedef long long          o7_long_t;
	typedef long long unsigned o7_ulong_t;
#	define O7_LABS(val)        llabs(val)
#else
#	error
#endif

#if O7_GNUC_BUILTIN_OVERFLOW
#	define O7_GNUC_SADD(a, b, res)  __builtin_sadd_overflow(a, b, res)
#	define O7_GNUC_SSUB(a, b, res)  __builtin_ssub_overflow(a, b, res)
#	define O7_GNUC_SMUL(a, b, res)  __builtin_smul_overflow(a, b, res)
#	define O7_GNUC_UADD(a, b, res)  __builtin_uadd_overflow(a, b, res)
#	define O7_GNUC_USUB(a, b, res)  __builtin_usub_overflow(a, b, res)
#	define O7_GNUC_UMUL(a, b, res)  __builtin_umul_overflow(a, b, res)
#	if LONG_MAX > O7_INT_MAX
#		define O7_GNUC_SADDL(a, b, res) __builtin_saddl_overflow(a, b, res)
#		define O7_GNUC_SSUBL(a, b, res) __builtin_ssubl_overflow(a, b, res)
#		define O7_GNUC_SMULL(a, b, res) __builtin_smull_overflow(a, b, res)
#		define O7_GNUC_UADDL(a, b, res) __builtin_uaddl_overflow(a, b, res)
#		define O7_GNUC_USUBL(a, b, res) __builtin_usubl_overflow(a, b, res)
#		define O7_GNUC_UMULL(a, b, res) __builtin_umull_overflow(a, b, res)
#	else
#		define O7_GNUC_SADDL(a, b, res) __builtin_saddll_overflow(a, b, res)
#		define O7_GNUC_SSUBL(a, b, res) __builtin_ssubll_overflow(a, b, res)
#		define O7_GNUC_SMULL(a, b, res) __builtin_smulll_overflow(a, b, res)
#		define O7_GNUC_UADDL(a, b, res) __builtin_uaddll_overflow(a, b, res)
#		define O7_GNUC_USUBL(a, b, res) __builtin_usubll_overflow(a, b, res)
#		define O7_GNUC_UMULL(a, b, res) __builtin_umulll_overflow(a, b, res)
#	endif
#else
#	define O7_GNUC_SADD(a, b, res)  (0 < sizeof(*(res) = (a)+(b)))
#	define O7_GNUC_SSUB(a, b, res)  (0 < sizeof(*(res) = (a)-(b)))
#	define O7_GNUC_SMUL(a, b, res)  (0 < sizeof(*(res) = (a)*(b)))
#	define O7_GNUC_UADD(a, b, res)  (0 < sizeof(*(res) = (a)+(b)))
#	define O7_GNUC_USUB(a, b, res)  (0 < sizeof(*(res) = (a)-(b)))
#	define O7_GNUC_UMUL(a, b, res)  (0 < sizeof(*(res) = (a)*(b)))

#	define O7_GNUC_SADDL(a, b, res) (0 < sizeof(*(res) = (a)+(b)))
#	define O7_GNUC_SSUBL(a, b, res) (0 < sizeof(*(res) = (a)-(b)))
#	define O7_GNUC_SMULL(a, b, res) (0 < sizeof(*(res) = (a)*(b)))
#	define O7_GNUC_UADDL(a, b, res) (0 < sizeof(*(res) = (a)+(b)))
#	define O7_GNUC_USUBL(a, b, res) (0 < sizeof(*(res) = (a)-(b)))
#	define O7_GNUC_UMULL(a, b, res) (0 < sizeof(*(res) = (a)*(b)))
#endif

#if defined(__arm__) || defined(__arm) || defined(_M_ARM)
#	define O7_ARM 1
#else
#	define O7_ARM 0
#endif

typedef o7_uint_t  o7_set_t;
#if O7_LONG_SUPPORT
	typedef o7_ulong_t o7_set64_t;
#endif

#define O7_MEMNG_NOFREE  0
#define O7_MEMNG_COUNTER 1
#define O7_MEMNG_GC      2

#if defined(O7_MEM_ALIGN)
#
#elif O7_ARM || _WIN32
#	define O7_MEM_ALIGN 8u
#else
#	define O7_MEM_ALIGN sizeof(void*)
#endif

#if defined(O7_MEMNG_MODEL)
#	define O7_MEMNG O7_MEMNG_MODEL
#else
#	define O7_MEMNG O7_MEMNG_NOFREE
#endif

#if defined(O7_MEMNG_NOFREE_BUFFER_SIZE)
#elif O7_MEMNG == O7_MEMNG_NOFREE
#	define O7_MEMNG_NOFREE_BUFFER_SIZE (128lu * 1024 * 1024)
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

#if __GNUC__ * 100 + __GNUC_MINOR__ >= 301
#	define O7_ATTR_ALWAYS_INLINE __attribute__((always_inline))
#else
#	define O7_ATTR_ALWAYS_INLINE
#endif

#define O7_ALWAYS_INLINE O7_ATTR_ALWAYS_INLINE O7_INLINE

#if O7_DISABLE_ATTR_CONST
    /* Помогает от выключения проверок в компиляторах, наподобие zig cc */
#	define O7_CONST_INLINE O7_ALWAYS_INLINE
#	define O7_PURE_INLINE  O7_ALWAYS_INLINE
#else
#	define O7_CONST_INLINE O7_ATTR_CONST O7_ALWAYS_INLINE
#	define O7_PURE_INLINE  O7_ATTR_PURE  O7_ALWAYS_INLINE
#endif

#if defined(O7_MEMNG_COUNTER_TYPE)
	typedef O7_MEMNG_COUNTER_TYPE
	                  o7_mmc_t;
#elif defined(__clang__) && (__SIZEOF_POINTER__ == __SIZEOF_INT__)
	typedef int       o7_mmc_t;
#elif defined(__clang__) && (__SIZEOF_POINTER__ == __SIZEOF_LONG__)
	typedef long      o7_mmc_t;
#elif O7_INT_ENOUGH_FOR_SIZE
	typedef o7_int_t  o7_mmc_t;
#elif ((size_t)-1) == O7_ULONG_MAX
	typedef o7_long_t o7_mmc_t;
#else
#	error
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
	O7_MEMINFO_SIZE = (sizeof(o7_mmc_t) * (int)(O7_MEMNG == O7_MEMNG_COUNTER)
	                 + sizeof(o7_tag_t *)
	                 + O7_MEM_ALIGN - 1
	                  ) / O7_MEM_ALIGN * O7_MEM_ALIGN
};

typedef struct {
	o7_uint_t addr[2];
	o7_uint_t  ofs, size;
} o7_e2k_ptr128_t;

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
#elif O7_INIT == O7_INIT_UNDEF
	enum { O7_UNDEF = 1 };
#else
	enum { O7_UNDEF = 0 };
#endif

#if defined(O7_CHECK_ARRAY_INDEX)
	enum { O7_ARRAY_INDEX = O7_CHECK_ARRAY_INDEX };
#elif !defined(__BOUNDS_CHECKING_ON) && !(__e2k__ && __ptr128__)
	enum { O7_ARRAY_INDEX = 1 };
#else
	enum { O7_ARRAY_INDEX = 0 };
#endif

#if defined(O7_CHECK_NULL)
	enum { O7_CHECK_NIL = O7_CHECK_NULL };
#else
	enum { O7_CHECK_NIL = 1 };
#endif

#if (__GNUC__ < 4) || defined(O7_USE_BUILTIN_EXPECT) && !O7_USE_BUILTIN_EXPECT
#	define O7_EXPECT(cond) (cond)
#elif __GNUC__ < 4
#	error __builtin_expect is not available
#else
#	define O7_EXPECT(cond) __builtin_expect(cond, 1)
#endif

#if O7_ASSERT_NO_MESSAGE
	/* Уменьшает размер за счёт отсутствия текстового сообщения */
	O7_ALWAYS_INLINE void O7_ASSERT(o7_cbool condition) {
		if (!O7_EXPECT(condition)) {
			abort();
		}
	}
#	define o7_assert(condition) O7_ASSERT(condition)
#else
#	if defined(NDEBUG)
		/* Предотвращает удаление кода из ASSERT */
		O7_ALWAYS_INLINE void O7_ASSERT(o7_cbool cond) { assert(cond); }
#	else
#		define O7_ASSERT(condition) assert(condition)
#	endif
#	define o7_assert(condition) assert(condition)
#endif

#if (__STDC_VERSION__ >= 201112L) && !defined(__chibicc__)
#	if !defined(static_assert)
		/* fixed compilation with dietlibc and in OpenBSD */
#		define static_assert(cond, msg) _Static_assert(cond, msg)
#	endif
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


#if defined(O7_RAW_ADR)
	enum { O7_CHECKED_ADR = (int)!(O7_RAW_ADR) };
#else
	enum { O7_CHECKED_ADR = 1 };
#endif

typedef enum {
	O7_ADR_OUTDATE   = 0,
	O7_ADR_LOCAL_RO  = 2,
	O7_ADR_LOCAL     = 3,
	O7_ADR_GLOBAL_RO = 4,
	O7_ADR_GLOBAL    = 5
} o7_adr_kind_t;

/* checked address */
typedef struct {
	void *adr;
	o7_uint_t size;
	o7_adr_kind_t kind;
} o7_chadr_t;

O7_CONST_INLINE o7_cbool o7_adr_is_local(o7_adr_kind_t kind) {
	return (int)kind / 2 == 1;
}

O7_ALWAYS_INLINE
o7_int_t o7_ptr_to_int(void *ptr, size_t size, o7_adr_kind_t kind, o7_uint_t *count) {
	extern o7_uint_t o7_ptr_to_uint(void *, size_t, o7_adr_kind_t);
	extern o7_uint_t o7_lptr_to_uint(void *, size_t, o7_adr_kind_t, o7_uint_t *);
	o7_uint_t addr;

	if (O7_CHECKED_ADR || (sizeof(ptr) != sizeof(addr))) {
		if (O7_CHECKED_ADR && o7_adr_is_local(kind)) {
			addr = o7_lptr_to_uint(ptr, size, kind, count);
		} else {
			addr = o7_ptr_to_uint(ptr, size, kind);
		}
	} else if (sizeof(ptr) == sizeof(addr)) {
		addr = (o7_uint_t)(o7_ptr_t)ptr;
	} else {
		abort();
	}
	return (o7_int_t)addr;
}

O7_ALWAYS_INLINE
void const * o7_int_to_ptr(o7_int_t saddr, size_t size) {
	extern void const * o7_uint_to_ptr(o7_uint_t);
	extern void const * o7_uint_to_sptr(o7_uint_t, o7_uint_t);
	o7_uint_t addr;
	void const *ptr;

	addr = (o7_uint_t)saddr;
	if (O7_CHECKED_ADR || (sizeof(ptr) != sizeof(addr))) {
		if (size == 1) {
			ptr = o7_uint_to_ptr(addr);
		} else {
			ptr = o7_uint_to_sptr(addr, (o7_uint_t)size);
		}
	} else if (sizeof(ptr) == sizeof(addr)) {
		ptr = (void const *)(o7_ptr_t)addr;
	} else {
		abort();
	}
	return ptr;
}

O7_ALWAYS_INLINE /* writable pointer */
void* o7_int_to_wptr(o7_int_t saddr, size_t size) {
	extern void* o7_uint_to_wptr(o7_uint_t);
	extern void* o7_uint_to_swptr(o7_uint_t, o7_uint_t);
	o7_uint_t addr;
	char unsigned *ptr;

	addr = (o7_uint_t)saddr;
	if (O7_CHECKED_ADR || (sizeof(ptr) != sizeof(addr))) {
		if (size == 1) {
			ptr = o7_uint_to_wptr(addr);
		} else {
			ptr = o7_uint_to_swptr(addr, (o7_uint_t)size);
		}
	} else if (sizeof(ptr) == sizeof(addr)) {
		ptr = (void *)(o7_ptr_t)addr;
	} else {
		abort();
	}
	return ptr;
}

O7_ALWAYS_INLINE /* local address out of scoupe */
void O7_LADROUT(o7_uint_t count) {
	extern void o7_lptr_outdate(o7_uint_t);
	if (O7_CHECKED_ADR) {
		o7_lptr_outdate(count);
	}
}

#define O7_ADR(var)                   o7_ptr_to_int((void *)&(var)  , sizeof(var)  , O7_ADR_GLOBAL, NULL)
#define O7_ADRS(var, size)            o7_ptr_to_int((void *)(var)   , (size)       , O7_ADR_GLOBAL, NULL)
#define O7_LADR(local, count)         o7_ptr_to_int((void *)&(local), sizeof(local), O7_ADR_LOCAL , (count))
#define O7_LADRS(local, size, count)  o7_ptr_to_int((void *)(local) , (size)       , O7_ADR_LOCAL , (count))

#define O7_RADR(var)                  o7_ptr_to_int((void *)&(var)  , sizeof(var)  , O7_ADR_GLOBAL_RO, NULL)
#define O7_RLADR(local, count)        o7_ptr_to_int((void *)&(local), sizeof(local), O7_ADR_LOCAL_RO , (count))
#define O7_RLADRS(local, size, count) o7_ptr_to_int((void *)(local) , (size)       , O7_ADR_LOCAL_RO , (count))


O7_CONST_INLINE
o7_int_t o7_size_to_int(size_t size) {
	/* TODO static assert */
	o7_assert(size <= O7_INT_MAX);
	return (o7_int_t)size;
}

#define O7_SIZE(type) o7_size_to_int(sizeof(type))

O7_ALWAYS_INLINE
o7_cbool o7_bit(o7_int_t addr, o7_int_t bit) {
	char unsigned *ptr;
	o7_cbool v;
	O7_STATIC_ASSERT(CHAR_BIT == 8);
	o7_assert((0 <= bit) && (bit < 8));

	ptr = (char unsigned *)o7_int_to_ptr(addr, 1);
	if (O7_BYTE_ORDER == O7_ORDER_LE) {
		v = (*ptr & (1u << bit)) != 0;
	} else if (O7_BYTE_ORDER == O7_ORDER_BE) {
		v = (*ptr & (0x80u >> bit)) != 0;
	} else { abort(); }
	return v;
}

#define O7_GET(src, dst) memcpy((void *)dst, o7_int_to_ptr(src, sizeof(*(dst))), sizeof(*(dst)))

O7_ALWAYS_INLINE
void o7_put_bool(o7_int_t addr, o7_bool val) {
	*(o7_bool *)o7_int_to_wptr(addr, sizeof(val)) = val;
}

O7_ALWAYS_INLINE
void o7_put_char(o7_int_t addr, o7_char val) {
	*(o7_char *)o7_int_to_wptr(addr, sizeof(val)) = val;
}

O7_ALWAYS_INLINE
void o7_put_uint(o7_int_t addr, o7_uint_t val) {
	memcpy(o7_int_to_wptr(addr, sizeof(val)), &val, sizeof(val));
}

O7_ALWAYS_INLINE
void o7_put_ulong(o7_int_t addr, o7_ulong_t val) {
	memcpy(o7_int_to_wptr(addr, sizeof(val)), &val, sizeof(val));
}

O7_ALWAYS_INLINE
void o7_put_double(o7_int_t addr, double val) {
	memcpy(o7_int_to_wptr(addr, sizeof(val)), &val, sizeof(val));
}

O7_ALWAYS_INLINE
void o7_put_float(o7_int_t addr, float val) {
	memcpy(o7_int_to_wptr(addr, sizeof(val)), &val, sizeof(val));
}

O7_ALWAYS_INLINE
void o7_copy(o7_int_t src, o7_int_t dst, o7_int_t n) {
	extern void o7_chcopy(o7_int_t, o7_int_t, o7_int_t);

	o7_assert(0 <= n && n <= (size_t)-1 / sizeof(o7_int_t));
	if (O7_CHECKED_ADR) {
		o7_chcopy(src, dst, n);
	} else {
		memmove(o7_int_to_wptr(dst, 1), o7_int_to_ptr(src, 1), n * sizeof(o7_int_t));
	}
}


O7_CONST_INLINE
void* o7_ref(void *ptr) {
	if (O7_CHECK_NIL) {
		o7_assert(NULL != ptr);
	}
	return ptr;
}

#if (__GNUC__ >= 2) || defined(__TINYC__)
#	define O7_REF(ptr) ((__typeof__(ptr))o7_ref(ptr))
#else
#	define O7_REF(ptr) ptr
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
	O7_INLINE void* o7_malloc(size_t size) {
		extern void __lsan_ignore_object(void*);
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

#if !defined(O7_USE_E2K_LEN)
#	define O7_USE_E2K_LEN 0
#elif O7_USE_E2K_LEN && !(__e2k__ && __ptr128__)
#	error Array length from Elbrus fat pointer is not available
#endif

/* FPA - Formal Parameter Array, APA - Actual Parameter Array
 * Нужен для возможности компиляции привязок к C в защищённом режиме Эльбруса */
#if O7_USE_E2K_LEN
#	define O7_FPA(typeName, arrayName)  typeName arrayName[]
#	define O7_APA(arrayName)            arrayName
#	define O7_FPA_LEN(arrayName)        O7_E2K_LEN(arrayName)
#else
#	define O7_FPA(typeName, arrayName)  o7_int_t arrayName##_len, typeName arrayName[O7_VLA(arrayName##_len)]
#	define O7_APA(arrayName)            arrayName##_len, arrayName
#	define O7_FPA_LEN(arrayName)        arrayName##_len
#endif

#define O7_LEN(array) ((o7_int_t)(sizeof(array) / sizeof((array)[0])))

#define O7_E2K_LEN(array) o7_e2k_len((void *)array, (o7_int_t)sizeof((array)[0]))
#define O7_E2K_SIZE(array) o7_e2k_size((void *)array)

O7_CONST_INLINE
o7_int_t o7_e2k_size(void *array) {
	o7_e2k_ptr128_t ptr;

	memcpy(&ptr, &array, sizeof(array));
	return ptr.size;
}

O7_CONST_INLINE
o7_int_t o7_e2k_len(void *array, o7_int_t itemSize) {
	return o7_e2k_size(array) / itemSize;
}

O7_CONST_INLINE
o7_cbool o7_bool_inited(o7_bool b) {
	return O7_EXPECT(*(o7_char *)&b < 2);
}

O7_CONST_INLINE
o7_bool o7_bl(o7_bool b) {
	if ((sizeof(b) == sizeof(o7_char)) && O7_UNDEF) {
		o7_assert(o7_bool_inited(b));
	}
	return b;
}

extern o7_char* o7_bools_undef(o7_int_t len, o7_char array[O7_VLA(len)]);
#define O7_BOOLS_UNDEF(array) \
	o7_bools_undef((o7_int_t)(sizeof(array) / sizeof(o7_char)), (o7_char *)(array))

O7_CONST_INLINE
double o7_dbl_undef(void) {
	o7_uint_t const u = 0x7FFFFFFFul;
	double signaling_nan;

	signaling_nan = 0.0;
	memcpy((o7_uint_t *)&signaling_nan + (1 - O7_BYTE_ORDER), &u, sizeof(u));
	return signaling_nan;
}

extern double* o7_doubles_undef(o7_int_t len, double array[O7_VLA(len)]);
#define O7_DOUBLES_UNDEF(array) \
	o7_doubles_undef((o7_int_t)(sizeof(array) / sizeof(double)), (double *)(array))

O7_CONST_INLINE
double o7_dbl(double d) {
	if (!O7_UNDEF) {
		;
	} else if (sizeof(unsigned) == sizeof(double) / 2) {
		unsigned u;
		memcpy(&u, (unsigned *)&d + 1, sizeof(u));
		o7_assert(u != 0x7FFFFFFFul);
	} else {
		unsigned long u;
		memcpy(&u, (unsigned long *)&d + 1, sizeof(u));
		o7_assert(u != 0x7FFFFFFFul);
	}
	return d;
}

O7_CONST_INLINE
double o7_flt_undef(void) {
	o7_uint_t const u = 0x7FFFFFFFul;
	float signaling_nan;

	signaling_nan = 0.0;
	memcpy((o7_uint_t *)&signaling_nan, &u, sizeof(u));
	return signaling_nan;
}

extern float* o7_floats_undef(o7_int_t len, float array[O7_VLA(len)]);
#define O7_FLOATS_UNDEF(array) \
	o7_floats_undef((o7_int_t)(sizeof(array) / sizeof(float)), (float *)(array))

O7_CONST_INLINE
float o7_fl(float d) {
	if (!O7_UNDEF) {
		;
	} else if (sizeof(unsigned) == sizeof(double) / 2) {
		unsigned u;
		memcpy(&u, &d, sizeof(u));
		o7_assert(u != 0x7FFFFFFFul);
	} else {
		unsigned long u;
		memcpy(&u, &d, sizeof(u));
		o7_assert(u != 0x7FFFFFFFul);
	}
	return d;
}

O7_CONST_INLINE
char unsigned o7_byte(int v) {
	o7_assert((unsigned)v <= 0x100);
	return (char unsigned)v;
}

O7_CONST_INLINE
char unsigned o7_chr(int v) {
	o7_assert((unsigned)v <= 0x100);
	return (char unsigned)v;
}

#if (__GNUC__ * 100 + __GNUC_MINOR__ >= 440) || (__clang_major__ > 5)
	O7_CONST_INLINE
	o7_cbool o7_isfinite(double v) {
		return __builtin_isfinite(v);
	}

	O7_CONST_INLINE
	o7_cbool o7_isfinitef(float v) {
		return __builtin_isfinite(v);
	}
#else
	O7_CONST_INLINE
	o7_cbool o7_isfinite(double v) {
		return O7_EXPECT((-1.0/0.0 < v) && (v < 1.0/0.0));
	}

	O7_CONST_INLINE
	o7_cbool o7_isfinitef(float v) {
		return O7_EXPECT((-1.0f/0.0f < v) && (v < 1.0f/0.0f));
	}
#endif

O7_CONST_INLINE
double o7_dbl_finite(double v) {
	if (O7_OVERFLOW > 0 || O7_UNDEF) {
		o7_assert(o7_isfinite(v));
	}
	return v;
}

O7_CONST_INLINE
float o7_flt_finite(float v) {
	if (O7_OVERFLOW > 0 || O7_UNDEF) {
		o7_assert(o7_isfinitef(v));
	}
	return v;
}

O7_CONST_INLINE
double o7_fadd(double a1, double a2) {
	return o7_dbl_finite(a1 + a2);
}

O7_CONST_INLINE
double o7_fsub(double m, double s) {
	return o7_dbl_finite(m - s);
}

O7_CONST_INLINE
double o7_fmul(double m1, double m2) {
	return o7_dbl_finite(m1 * m2);
}

O7_CONST_INLINE
double o7_fdiv(double n, double d) {
	if (O7_FLOAT_DIV_ZERO) {
		o7_assert(d != 0.0);
	}
	return o7_dbl_finite(n / d);
}

O7_CONST_INLINE
float o7_faddf(float a1, float a2) {
	return o7_flt_finite(a1 + a2);
}

O7_ATTR_CONST O7_ALWAYS_INLINE
float o7_fsubf(float m, float s) {
	return o7_flt_finite(m - s);
}

O7_CONST_INLINE
float o7_fmulf(float m1, float m2) {
	return o7_flt_finite(m1 * m2);
}

O7_CONST_INLINE
float o7_fdivf(float n, float d) {
	if (O7_FLOAT_DIV_ZERO) {
		o7_assert(d != 0.0f);
	}
	return o7_flt_finite(n / d);
}

O7_CONST_INLINE
o7_bool o7_int_inited(o7_int_t i) {
	return O7_EXPECT(-O7_INT_MAX <= i);
}

O7_CONST_INLINE
o7_int_t o7_int(o7_int_t i) {
	if (O7_UNDEF) {
		o7_assert(o7_int_inited(i));
	}
	return i;
}

O7_CONST_INLINE
o7_int_t o7_not_neg(o7_int_t i) {
	if (O7_OVERFLOW > 0) {
		o7_assert(0 <= i);
	}
	return i;
}

extern o7_int_t* o7_ints_undef(o7_int_t len, o7_int_t array[O7_VLA(len)]);
#define O7_INTS_UNDEF(array) \
	o7_ints_undef((o7_int_t)(sizeof(array) / (sizeof(o7_int_t))), (o7_int_t *)(array))

#define O7_MUL(a, b) ((a) * (b))
#define O7_DIV(n, d) ((0 <= n) ? ((n) / (d)) : (-1 - (-1 - (n)) / (d)))
#define O7_MOD(n, d) ((0 <= n) ? ((n) % (d)) : ((d) - 1 - (-1 - (n)) % (d)))

O7_CONST_INLINE
o7_int_t o7_add(o7_int_t a1, o7_int_t a2) {
	o7_int_t s;
	o7_cbool overflow;
	if (O7_OVERFLOW > 0 && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SADD(o7_int(a1), o7_int(a2), &s) || (-O7_INT_MAX > s);
		o7_assert(!overflow);
	} else {
		if (O7_OVERFLOW < 1) {
			if (O7_UNDEF) {
				o7_assert(o7_int_inited(a1));
				o7_assert(o7_int_inited(a2));
			}
		} else if (0 <= a2) {
			o7_assert(o7_int(a1) <= O7_INT_MAX - a2);
		} else {
			o7_assert(-O7_INT_MAX - o7_int(a2) <= a1);
		}
		s = a1 + a2;
	}
	return s;
}

O7_CONST_INLINE
o7_int_t o7_sub(o7_int_t m, o7_int_t s) {
	o7_int_t d;
	o7_cbool overflow;
	if (O7_OVERFLOW > 0 && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SSUB(o7_int(m), o7_int(s), &d) || (-O7_INT_MAX > d);
		o7_assert(!overflow);
	} else {
		if (O7_OVERFLOW < 1) {
			if (O7_UNDEF) {
				o7_assert(o7_int_inited(m));
				o7_assert(o7_int_inited(s));
			}
		} else if (0 <= s) {
			o7_assert(-O7_INT_MAX + s <= m);
		} else {
			o7_assert(o7_int(m) <= INT_MAX + o7_int(s));
		}
		d = m - s;
	}
	return d;
}

O7_CONST_INLINE
o7_int_t o7_mul(o7_int_t m1, o7_int_t m2) {
	o7_int_t p;
	o7_cbool overflow;
	if (O7_OVERFLOW > 0 && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SMUL(o7_int(m1), o7_int(m2), &p) || (-O7_INT_MAX > p);
		o7_assert(!overflow);
	} else {
		if (O7_OVERFLOW > 0 && (0 != m2)) {
			o7_assert(abs(m1) <= O7_INT_MAX / abs(m2));
		}
		p = o7_int(m1) * o7_int(m2);
	}
	return p;
}

O7_CONST_INLINE
o7_int_t o7_divisor(o7_int_t d) {
	if (O7_NATURAL_DIVISOR) {
		o7_assert(0 < d);
	} else {
		if (O7_OVERFLOW > 0 && O7_DIV_ZERO > 0) {
			o7_assert(d != 0);
		}
		d = o7_int(d);
	}
	return d;
}

O7_CONST_INLINE
o7_int_t o7_div_general(o7_int_t n, o7_int_t d) {
	o7_int_t r;
	if (0 <= n) {
		r = n / d;
	} else {
		r = -1 - (-1 - o7_int(n)) / d;
	}
	return  r;
}

O7_CONST_INLINE
o7_int_t o7_div_specific(o7_int_t n, o7_int_t d) {
	o7_int_t mask;
	mask = n >> (O7_INT_BITS - 1);
	return mask ^ ((mask ^ o7_int(n)) / d);
}

O7_CONST_INLINE
o7_int_t o7_div_nat(o7_int_t n, o7_int_t d) {
	o7_int_t r;
	if (O7_DIV_BRANCHLESS) {
		r = o7_div_specific(n, d);
	} else {
		r = o7_div_general(n, d);
	}
	return r;
}

O7_CONST_INLINE
o7_int_t o7_div(o7_int_t n, o7_int_t d) {
	return o7_div_nat(n, o7_divisor(d));
}

O7_CONST_INLINE
o7_int_t o7_mod_general(o7_int_t n, o7_int_t d) {
	o7_int_t r;
	if (0 <= n) {
		r = n % d;
	} else {
		r = d + (-1 - (-1 - o7_int(n)) % d);
	}
	return r;
}

O7_CONST_INLINE
o7_int_t o7_mod_specific(o7_int_t n, o7_int_t d) {
	o7_int_t mask;
	mask = n >> (O7_INT_BITS - 1);
	return (d & mask) + (mask ^ ((mask ^ o7_int(n)) % d));
}

O7_CONST_INLINE
o7_int_t o7_mod_nat(o7_int_t n, o7_int_t d) {
	o7_int_t r;
	if (O7_DIV_BRANCHLESS) {
		r = o7_mod_specific(n, d);
	} else {
		r = o7_mod_general(n, d);
	}
	return r;
}

O7_CONST_INLINE
o7_int_t o7_mod(o7_int_t n, o7_int_t d) {
	return o7_mod_nat(n, o7_divisor(d));
}

#if O7_LONG_SUPPORT

O7_CONST_INLINE
o7_bool o7_long_inited(o7_long_t i) {
	return O7_EXPECT(i >= -O7_LONG_MAX);
}

O7_CONST_INLINE
o7_long_t o7_long(o7_long_t i) {
	if (O7_UNDEF) {
		o7_assert(o7_long_inited(i));
	}
	return i;
}

extern o7_long_t* o7_longs_undef(o7_int_t len, o7_long_t array[O7_VLA(len)]);
#define O7_LONGS_UNDEF(array) \
	o7_longs_undef((o7_int_t)(sizeof(array) / (sizeof(int))), (o7_long_t *)(array))

O7_CONST_INLINE
o7_long_t o7_ladd(o7_long_t a1, o7_long_t a2) {
	o7_long_t s;
	o7_cbool overflow;
	if (O7_OVERFLOW > 0 && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SADDL(o7_long(a1), o7_long(a2), &s) || s < -O7_LONG_MAX;
		o7_assert(!overflow);
	} else {
		if (O7_OVERFLOW < 1) {
			if (O7_UNDEF) {
				o7_assert(o7_long_inited(a1));
				o7_assert(o7_long_inited(a2));
			}
		} else if (a2 >= 0) {
			o7_assert(o7_long(a1) <=  O7_LONG_MAX - a2);
		} else {
			o7_assert(a1 >= -O7_LONG_MAX - o7_long(a2));
		}
		s = a1 + a2;
	}
	return s;
}

O7_CONST_INLINE
o7_long_t o7_lsub(o7_long_t m, o7_long_t s) {
	o7_long_t d;
	o7_cbool overflow;
	if (O7_OVERFLOW < 1) {
		d = o7_long(m) - o7_long(s);
	} else if (O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SSUBL(o7_long(m), o7_long(s), &d);
		o7_assert(!overflow && d >= -O7_LONG_MAX);
	} else {
		if (s >= 0) {
			o7_assert(m >= s - O7_LONG_MAX);
		} else {
			o7_assert(o7_long(m) <= O7_LONG_MAX + o7_long(s));
		}
		d = m - s;
	}
	return d;
}

O7_CONST_INLINE
o7_long_t o7_lmul(o7_long_t m1, o7_long_t m2) {
	o7_long_t p;
	o7_cbool overflow;
	if (O7_OVERFLOW > 0 && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SMULL(o7_long(m1), o7_long(m2), &p);
		o7_assert(!overflow && p >= -O7_LONG_MAX);
	} else {
		if (O7_OVERFLOW > 0 && (0 != m2)) {
			o7_assert(O7_LABS(m1) <= O7_LONG_MAX / O7_LABS(m2));
		}
		p = o7_long(m1) * o7_long(m2);
	}
	return p;
}

O7_CONST_INLINE
o7_long_t o7_ldivisor(o7_long_t d) {
	if (O7_NATURAL_DIVISOR > 0) {
		o7_assert(0 < d);
	} else {
		if (O7_OVERFLOW > 0 && O7_DIV_ZERO > 0) {
			o7_assert(d != 0);
		}
		d = o7_long(d);
	}
	return d;
}

O7_CONST_INLINE
o7_long_t o7_ldiv_general(o7_long_t n, o7_long_t d) {
	o7_long_t r;
	if (0 <= n) {
		r = n / d;
	} else {
		r = -1 - (-1 - o7_long(n)) / d;
	}
	return  r;
}

O7_CONST_INLINE
o7_long_t o7_ldiv_specific(o7_long_t n, o7_long_t d) {
	o7_long_t mask;
	mask = n >> (O7_LONG_BITS - 1);
	return mask ^ ((mask ^ o7_long(n)) / d);
}

O7_CONST_INLINE
o7_long_t o7_ldiv_nat(o7_long_t n, o7_long_t d) {
	o7_long_t r;
	if (O7_DIV_BRANCHLESS) {
		r = o7_ldiv_specific(n, d);
	} else {
		r = o7_ldiv_general(n, d);
	}
	return r;
}

O7_CONST_INLINE
o7_long_t o7_ldiv(o7_long_t n, o7_long_t d) {
	return o7_ldiv_nat(n, o7_ldivisor(d));
}

O7_CONST_INLINE
o7_long_t o7_lmod_general(o7_long_t n, o7_long_t d) {
	o7_long_t r;
	if (0 <= n) {
		r = n % d;
	} else {
		r = d + (-1 - (-1 - o7_long(n)) % d);
	}
	return r;
}

O7_CONST_INLINE
o7_long_t o7_lmod_specific(o7_long_t n, o7_long_t d) {
	o7_long_t mask;
	mask = n >> (O7_LONG_BITS - 1);
	return (d & mask) + (mask ^ ((mask ^ o7_long(n)) % d));
}

O7_CONST_INLINE
o7_long_t o7_lmod_nat(o7_long_t n, o7_long_t d) {
	o7_long_t r;
	if (O7_DIV_BRANCHLESS) {
		r = o7_lmod_specific(n, d);
	} else {
		r = o7_lmod_general(n, d);
	}
	return r;
}

O7_CONST_INLINE
o7_long_t o7_lmod(o7_long_t n, o7_long_t d) {
	return o7_lmod_nat(n, o7_ldivisor(d));
}

O7_CONST_INLINE
char unsigned o7_lbyte(o7_long_t v) {
	o7_assert((o7_ulong_t)v <= 0x100);
	return (char unsigned)v;
}

O7_CONST_INLINE
int o7_lcmp(o7_long_t a, o7_long_t b) {
	int cmp;
	if (a < b) {
		if (O7_UNDEF) {
			o7_assert(o7_long_inited(a));
		}
		cmp = -1;
	} else {
		if (O7_UNDEF) {
			o7_assert(o7_long_inited(b));
		}
		if (a == b) {
			cmp = 0;
		} else {
			cmp = 1;
		}
	}
	return cmp;
}

O7_CONST_INLINE
o7_set64_t o7_lset(o7_int_t low, o7_int_t high) {
	o7_assert(0 <= low  && low  <= 63);
	o7_assert(0 <= high && high <= 63);
	return ((o7_set64_t)-1 << low) & ((o7_set64_t)-1 >> (63 - high));
}

#define O7_SET(low, high) (((o7_set64_t)-1 << (low)) & ((o7_set64_t)-1 >> (63 - (high))))

#define O7_IN(n, set) (0 != ((set) & ((o7_set64_t)1 << (n))))

O7_CONST_INLINE
o7_cbool o7_lin(o7_int_t n, o7_set64_t set) {
	o7_assert((0 <= n) && (n <= 63));
	return 0 != (set & ((o7_set64_t)1 << n));
}

#else /* O7_LONG_SUPPORT */

#define O7_SET(low, high) ((~(o7_set_t)0 << (low)) & (~(o7_set_t)0 >> (31 - (high))))

#define O7_IN(n, set) (0 != ((set) & ((o7_set_t)1 << (n))))

#endif /* O7_LONG_SUPPORT */

O7_CONST_INLINE
o7_set_t o7_set(o7_int_t low, o7_int_t high) {
	o7_assert(0 <= low  && low  <= 31);
	o7_assert(0 <= high && high <= 31);
	return (~(o7_set_t)0 << low) & (~(o7_set_t)0 >> (31 - high));
}

O7_CONST_INLINE
o7_cbool o7_in(o7_int_t n, o7_set_t set) {
	o7_assert((0 <= n) && (n <= 31));
	return 0 != (set & ((o7_set_t)1 << n));
}

#define O7_ASR(n, shift) \
	(((shift) >= 32) ? ((n) >= 0 ? 0 : -1) : (((n) >= 0) ? (n) >> (shift) : -1 - ((-1 - (n)) >> (shift))))

O7_CONST_INLINE
o7_int_t o7_asr(o7_int_t n, o7_int_t shift) {
	o7_int_t r;
	if (0 <= shift && shift < 32) {
		if (O7_ARITHMETIC_SHIFT) {
			r = o7_int(n) >> shift;
		} else if (n >= 0) {
			r = n >> shift;
		} else {
			r = -1 - ((-1 - o7_int(n)) >> shift);
		}
	} else {
		if (O7_OVERFLOW > 0) { o7_assert(0 <= shift); }
		r = -(int)(n < 0);
	}
	return r;
}

#define O7_ROR(n, shift) \
	(((shift) % 32 == 0) \
	? (n)                \
	: (o7_int_t)(((((o7_uint_t)n) >> ((shift) % 32)) | (((o7_uint_t)n) << (32 - (shift) % 32))) & 0xFFFFFFFFul))

O7_CONST_INLINE
o7_int_t o7_ror(o7_int_t n, o7_int_t shift) {
	o7_uint_t u;

	u     = o7_not_neg(n    ) & 0xFFFFFFFFul;
	shift = o7_not_neg(shift) & 0x1F;
	if (O7_EXPECT(0 != shift)) {
		u = ((u >> shift) | (u << (32 - shift))) & 0xFFFFFFFFul;
		if (O7_OVERFLOW > 0) {
			o7_assert(u < 0x80000000ul);
		}
	}
	return u;
}

O7_CONST_INLINE
o7_int_t o7_lsl(o7_int_t n, o7_int_t shift) {
	o7_cbool overflow;
	if (O7_OVERFLOW > 0) {
		(void)o7_not_neg(shift);
		if (O7_EXPECT(n != 0)) {
			if (n > 0) {
				overflow = shift >= 31 || ((O7_INT_MAX >> shift) < n);
			} else {
				overflow = shift >= 31 || (-(O7_INT_MAX >> shift) > n);
			}
			o7_assert(!overflow);
			n = n << shift;
		}
	} else {
		if (o7_int(n) != 0) {
			n = n << shift;
		}
	}
	return n;
}

O7_CONST_INLINE
o7_int_t o7_ind(o7_int_t len, o7_int_t ind) {
	if (O7_ARRAY_INDEX) {
		o7_assert((o7_uint_t)ind < (o7_uint_t)len);
	}
	return ind;
}

O7_CONST_INLINE
int o7_cmp(o7_int_t a, o7_int_t b) {
	int cmp;
	if (a < b) {
		if (O7_UNDEF) {
			o7_assert(o7_int_inited(a));
		}
		cmp = -1;
	} else {
		if (O7_UNDEF) {
			o7_assert(o7_int_inited(b));
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
			o7_assert(1 == count);/* TODO remove */
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
	if (O7_EXPECT(NULL != mem)) {
		mem = o7_mem_info_init(mem, tag);
		if ((O7_INIT == O7_INIT_UNDEF) && (NULL != undef)) {
			undef(mem);
		}
	}
	o7_release(*pmem);
	*pmem = mem;
	return NULL != mem;
}

#if O7_INIT == O7_INIT_UNDEF
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
		o7_assert(0 < count);/* TODO remove */
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
	char *a;
	if (O7_MEMNG == O7_MEMNG_COUNTER) {
		a = (char *)array;
		for (i = 0; i < count; i += 1) {
			release((void *)a);
			a += item_size;
		}
	}
}

O7_ALWAYS_INLINE
void o7_assign(void **m1, void *m2) {
	o7_assert(NULL != m1);/* TODO remove */
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

O7_CONST_INLINE
o7_tag_t const * o7_dynamic_tag(void const *mem) {
	o7_assert(NULL != mem);
	return *((o7_tag_t const **)mem - 1);
}

O7_CONST_INLINE
o7_cbool o7_is_r(o7_tag_t const *base, void const *strct, o7_tag_t const *ext) {
	if (NULL == base) {
		base = o7_dynamic_tag(strct);
	}
	return base->ids[ext->ids[0]] == ext->ids[ext->ids[0]];
}

O7_CONST_INLINE
o7_cbool o7_is(void const *strct, o7_tag_t const *ext) {
	o7_tag_t const *base;
	base = o7_dynamic_tag(strct);
	return base->ids[ext->ids[0]] == ext->ids[ext->ids[0]];
}

O7_CONST_INLINE
void *o7_must(void *strct, o7_tag_t const *ext) {
	o7_assert(o7_is(strct, ext));
	return strct;
}

#define O7_GUARD(ExtType, strct) \
	((struct ExtType *)o7_must((void *)strct, &ExtType##_tag))


O7_PURE_INLINE
void * o7_must_r(o7_tag_t const *base, void *strct, o7_tag_t const *ext) {
	o7_assert(o7_is_r(base, strct, ext));
	return strct;
}

#define O7_GUARD_R(ExtType, strct, base) \
	(*(struct ExtType *)o7_must_r(base, strct, &ExtType##_tag))


O7_CONST_INLINE
o7_int_t o7_sti(o7_uint_t v) {
	o7_assert(v <= (o7_uint_t)O7_INT_MAX);
	return (o7_int_t)v;
}

O7_CONST_INLINE
o7_int_t o7_floor(double v) {
	o7_assert((double)(-O7_INT_MAX) <= v && v <= (double)O7_INT_MAX);
	return (o7_int_t)v;
}

O7_CONST_INLINE
double o7_flt(o7_int_t v) {
	return (double)o7_int(v);
}

O7_ALWAYS_INLINE
void o7_ldexp(double *f, o7_int_t n) {
	extern double o7_raw_ldexp(double f, int n);
	/* TODO убрать o7_dbl_finite для результата */
	*f = o7_dbl_finite(o7_raw_ldexp(o7_dbl_finite(*f), o7_int(n)));
}

O7_ALWAYS_INLINE
void o7_frexp(double *f, o7_int_t *n) {
	extern double o7_raw_unpk(double x, o7_int_t *exp);
	*f = o7_raw_unpk(o7_dbl_finite(*f), n);
}

extern O7_ATTR_PURE
int o7_strcmp(o7_int_t s1_len, o7_char const s1[O7_VLA(s1_len)],
              o7_int_t s2_len, o7_char const s2[O7_VLA(s2_len)]);

O7_PURE_INLINE
int o7_strchcmp(o7_int_t len, o7_char const s[O7_VLA(len)], o7_char c) {
	int ret;
	if (len == 0) {
		/* TODO не должно быть таких строк */
		ret = -(int)c;
	} else {
		ret = (int)s[0] - c;
		if (ret == 0 && len > 1 && c != '\0' && s[1] != '\0') {
			ret = -1;
		}
	}
	return ret;
}

O7_PURE_INLINE
int o7_chstrcmp(o7_char c, o7_int_t len, o7_char const s[O7_VLA(len)]) {
	return -o7_strchcmp(len, s, c);
}

O7_ALWAYS_INLINE
void o7_memcpy(o7_int_t dest_len, o7_char dest[O7_VLA(dest_len)],
               o7_int_t src_len, o7_char const src[O7_VLA(src_len)])
{
	o7_assert(src_len <= dest_len);
	memcpy(dest, src, (size_t)src_len);
}

#if ((__GNUC__ * 100 + __GNUC_MINOR__ >= 480) || (__clang_major__ > 5)) \
 && (!defined(O7_USE_GNUC_BUILTIN_BSWAP) || O7_USE_GNUC_BUILTIN_BSWAP)

	enum { O7_USED_GNUC_BUILTIN_BSWAP = 0 < 1 };
	O7_CONST_INLINE
	o7_uint_t  o7_gnuc_bswap32(o7_uint_t i ) { return __builtin_bswap32(i); }
	O7_CONST_INLINE
	o7_ulong_t o7_gnuc_bswap64(o7_ulong_t i) { return __builtin_bswap64(i); }
#else
	enum { O7_USED_GNUC_BUILTIN_BSWAP = 0 > 1 };
	O7_CONST_INLINE
	o7_uint_t  o7_gnuc_bswap32(o7_uint_t i ) { abort(); return O7_INT_UNDEF;  }
	O7_CONST_INLINE
	o7_ulong_t o7_gnuc_bswap64(o7_ulong_t i) { abort(); return O7_LONG_UNDEF; }
#endif

O7_CONST_INLINE
o7_uint_t o7_bswap_uint(o7_uint_t i) {
	if (O7_USED_GNUC_BUILTIN_BSWAP) {
		i = o7_gnuc_bswap32(i);
	} else {
		i = (i >> 24) | ((i >> 8) & 0xFF00)
		  | (i << 24) | ((i & 0xFF00) << 8);
	}
	return i;
}

O7_CONST_INLINE
o7_int_t o7_bswap_int(o7_int_t i) {
	/* TODO */
	return (o7_int_t)o7_bswap_uint((o7_uint_t)i);
}

O7_CONST_INLINE
o7_ulong_t o7_bswap_ulong(o7_ulong_t i) {
	if (O7_USED_GNUC_BUILTIN_BSWAP) {
		i = o7_gnuc_bswap64(i);
	} else {
		i = (i >> 56) | ((i >> 40) & 0xFF00) | ((i >> 24) & 0xFF0000) | ((i >> 8) & 0xFF000000)
		  | (i << 56) | ((i & 0xFF00) << 40) | ((i & 0xFF0000) << 24) | ((i & 0xFF000000) << 8);
	}
	return i;
}

O7_CONST_INLINE
o7_long_t o7_bswap_long(o7_long_t i) {
	/* TODO */
	return (o7_long_t)o7_bswap_ulong((o7_ulong_t)i);
}

extern O7_NORETURN void o7_case_fail(o7_int_t i);

extern void o7_init(int argc, char *argv[O7_VLA(argc)]);

extern int o7_exit_code;

#endif
