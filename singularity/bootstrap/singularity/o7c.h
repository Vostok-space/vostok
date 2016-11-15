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
#		define O7C_INLINE inline
#	elif __GNUC__ > 2
#		define O7C_INLINE __inline__
#	else
#		define O7C_INLINE 
#	endif
#endif

#define O7C_INT_UNDEF INT_MIN

#define O7C_DBL_UNDEF o7c_dbl_undef()

#if defined(O7C_BOOL)
	typedef O7C_BOOL o7c_bool;
#elif (__STDC_VERSION__ >= 199901L) && !defined(O7C_BOOL_UNDEFINED)
	typedef _Bool o7c_bool;
#else
#	define O7C_BOOL_UNDEF 0xFF
	typedef char unsigned o7c_bool;
#endif

#if defined(O7C_INT_T)
	typedef O7C_INT_T o7c_int_t;
#elif INT_MAX >= 2147483647
	typedef int o7c_int_t;
#elif LONG_MAX >= 2147483647
	typedef int o7c_int_t;
#else
#	error
#endif

typedef char unsigned o7c_char;

#if __GNUC__ > 2
#	define O7C_ATTR_ALWAYS_INLINE __attribute__((always_inline))
#else
#	define O7C_ATTR_ALWAYS_INLINE
#endif

#if defined(O7C_LSAN_LEAK_IGNORE)
#	include <sanitizer/lsan_interface.h>
	static O7C_INLINE void* o7c_malloc(size_t size) O7C_ATTR_ALWAYS_INLINE;
	static O7C_INLINE void* o7c_malloc(size_t size) {
		void *mem;
		mem = malloc(size);
		__lsan_ignore_object(mem);
		return mem;
	}
#else
	static O7C_INLINE void* o7c_malloc(size_t size) O7C_ATTR_ALWAYS_INLINE;
	static O7C_INLINE void* o7c_malloc(size_t size) {
		return malloc(size);
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

typedef o7c_id_t o7c_tag_t[O7C_MAX_RECORD_EXT + 1];

static O7C_INLINE o7c_bool o7c_bl(o7c_bool b) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE o7c_bool o7c_bl(o7c_bool b) {
	if (sizeof(b) == sizeof(o7c_char)) {
		assert(*(o7c_char *)&b < 2);
	}
	return b;
}

static O7C_INLINE double o7c_dbl_undef(void) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE double o7c_dbl_undef(void) {
	double undef;
	if (sizeof(unsigned) == sizeof(double) / 2) {
		((unsigned *)&undef)[1] = 0x7FFFFFFF;
	} else {
		((unsigned long *)&undef)[1] = 0x7FFFFFFF;
	}
	return undef;
}

static O7C_INLINE double o7c_dbl(double d) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE double o7c_dbl(double d) {
	if (sizeof(unsigned) == sizeof(double) / 2) {
		assert(((unsigned *)&d)[1] != 0x7FFFFFFF);
	} else {
		assert(((unsigned long *)&d)[1] != 0x7FFFFFFF);
	}
	return d;
}

static O7C_INLINE double o7c_fadd(double a1, double a2) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE double o7c_fadd(double a1, double a2) {
	return o7c_dbl(a1) + o7c_dbl(a2);
}

static O7C_INLINE double o7c_fsub(double m, double s) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE double o7c_fsub(double m, double s) {
	return o7c_dbl(m) - o7c_dbl(s);
}

static O7C_INLINE double o7c_fmul(double m1, double m2) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE double o7c_fmul(double m1, double m2) {
	return o7c_dbl(m1) * o7c_dbl(m2);
}

static O7C_INLINE double o7c_fdiv(double n, double d) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE double o7c_fdiv(double n, double d) {
	return o7c_dbl(n) / o7c_dbl(d);
}

static O7C_INLINE int o7c_int(int i) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE int o7c_int(int i) {
	assert(i != O7C_INT_UNDEF);
	return i;
}

static O7C_INLINE int o7c_add(int a1, int a2) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE int o7c_add(int a1, int a2) {
	return o7c_int(a1) + o7c_int(a2);
}

static O7C_INLINE int o7c_sub(int m, int s) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE int o7c_sub(int m, int s) {
	return o7c_int(m) - o7c_int(s);
}

static O7C_INLINE int o7c_mul(int m1, int m2) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE int o7c_mul(int m1, int m2) {
	return o7c_int(m1) * o7c_int(m2);
}

static O7C_INLINE int o7c_div(int n, int d) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE int o7c_div(int n, int d) {
	return o7c_int(n) / o7c_int(d);
}

static O7C_INLINE int o7c_mod(int n, int d) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE int o7c_mod(int n, int d) {
	return o7c_int(n) % o7c_int(d);
}

static O7C_INLINE int o7c_ind(int len, int ind) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE int o7c_ind(int len, int ind) {
	assert(len > 0);
	assert((unsigned)ind < (unsigned)len);
	return ind;
}

extern void o7c_tag_init(o7c_tag_t ext, o7c_tag_t const base);

static O7C_INLINE void* o7c_new(int size, o7c_tag_t const tag)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void* o7c_new(int size, o7c_tag_t const tag) {
	void *mem;
	mem = o7c_malloc(sizeof(o7c_id_t *) + size);
	if (NULL != mem) {
		*(o7c_id_t const **)mem = tag;
		mem = (void *)((o7c_id_t **)mem + 1);
	}
	return mem;
}

static O7C_INLINE o7c_id_t const * o7c_dynamic_tag(void const *mem)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE o7c_id_t const * o7c_dynamic_tag(void const *mem) {
	return *((o7c_id_t const **)mem - 1);
}

static O7C_INLINE o7c_bool o7c_is(o7c_tag_t const base, void const *strct,
	o7c_tag_t const ext) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE o7c_bool
	o7c_is(o7c_tag_t const base, void const *strct, o7c_tag_t const ext)
{
	if ((NULL == base) && (NULL != strct)) {
		base = o7c_dynamic_tag(strct);
	}
	return (NULL != strct) && (base[ext[0]] == ext[ext[0]]);
}

static O7C_INLINE void ** o7c_must(o7c_tag_t const base, void **strct,
	o7c_tag_t const ext) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void **
	o7c_must(o7c_tag_t const base, void **strct, o7c_tag_t const ext)
{
	assert((NULL == *strct) || o7c_is(base, *strct, ext));
	return strct;
}

#define O7C_GUARD(ExtType, strct) \
	(*(struct ExtType **)o7c_must(NULL, (void **)strct, ExtType##_tag))


static O7C_INLINE void * o7c_must_r(o7c_tag_t const base, void *strct,
	o7c_tag_t const ext) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void *
	o7c_must_r(o7c_tag_t const base, void *strct, o7c_tag_t const ext)
{
	assert((NULL == strct) || o7c_is(base, strct, ext));
	return strct;
}

#define O7C_GUARD_R(ExtType, strct, base) \
	(*(struct ExtType *)o7c_must_r(base, strct, ExtType##_tag))

static O7C_INLINE unsigned o7c_set(int low, int high) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE unsigned o7c_set(int low, int high) {
	assert(low >= 0);
	assert(high <= 31);
	assert(low <= high);
	return (~0u << low) & (~0u >> (31 - high));
}

#define O7C_SET(low, high) ((~0u << low) & (~0u >> (31 - high)))

extern void o7c_init(int argc, char *argv[]);

extern int o7c_exit_code;

#endif
