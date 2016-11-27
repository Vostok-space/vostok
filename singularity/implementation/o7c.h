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

enum {
	O7C_MEM_MAN_NOFREE,
	O7C_MEM_MAN_COUNTER,
	O7C_MEM_MAN_GC,

#if defined(O7C_MEM_MAN_MODEL)
	O7C_MEM_MAN = O7C_MEM_MAN_MODEL
#else
	O7C_MEM_MAN = O7C_MEM_MAN_NOFREE
#endif
};

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

typedef char unsigned o7c_char;

#if __GNUC__ > 2
#	define O7C_ATTR_ALWAYS_INLINE __attribute__((always_inline))
#else
#	define O7C_ATTR_ALWAYS_INLINE
#endif

static O7C_INLINE void* o7c_raw_alloc(size_t size) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void* o7c_raw_alloc(size_t size) {
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

static O7C_INLINE void* o7c_malloc(size_t size) O7C_ATTR_ALWAYS_INLINE;
#if defined(O7C_LSAN_LEAK_IGNORE)
#	include <sanitizer/lsan_interface.h>
	static O7C_INLINE void* o7c_malloc(size_t size) {
		void *mem;
		mem = o7c_raw_alloc(size);
		__lsan_ignore_object(mem);
		return mem;
	}
#else
	static O7C_INLINE void* o7c_malloc(size_t size) {
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

typedef o7c_id_t o7c_tag_t[O7C_MAX_RECORD_EXT + 1];

static O7C_INLINE o7c_bool o7c_bl(o7c_bool b) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE o7c_bool o7c_bl(o7c_bool b) {
	if (sizeof(b) == sizeof(o7c_char)) {
		assert(*(o7c_char *)&b < 2);
	}
	return b;
}

extern o7c_bool* o7c_bools_undef(o7c_bool array[], int size);

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

extern double* o7c_doubles_undef(double array[], int size);

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

extern int* o7c_ints_undef(int array[], int size);

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

static O7C_INLINE int o7c_cmp(int a, int b) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE int o7c_cmp(int a, int b) {
	int cmp;
	if (a < b) {
		assert(a != O7C_INT_UNDEF);
		cmp = -1;
	} else {
		assert(b != O7C_INT_UNDEF);
		if (a == b) {
			cmp = 0;
		} else {
			cmp = 1;
		}
	}
	return cmp;
}

static O7C_INLINE void o7c_release(void *mem) O7C_ATTR_ALWAYS_INLINE;

static O7C_INLINE void o7c_new(void **mem, int size, o7c_tag_t const tag)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void o7c_new(void **pmem, int size, o7c_tag_t const tag) {
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
	}
	o7c_release(*pmem);
	*pmem = mem;
}

#define O7C_NEW(mem, tag) o7c_new((void **)mem, sizeof(**(mem)), tag)

static O7C_INLINE void* o7c_retain(void *mem) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void* o7c_retain(void *mem) {
	if ((O7C_MEM_MAN == O7C_MEM_MAN_COUNTER) && (NULL != mem)) {
		++*((o7c_mmc_t *)((o7c_id_t **)mem - 1) - 1);
	}
	return mem;
}

static O7C_INLINE void o7c_release(void *mem) {
	o7c_mmc_t *counter;
	if ((O7C_MEM_MAN == O7C_MEM_MAN_COUNTER)
	 && (NULL != mem))
	{
		counter = (o7c_mmc_t *)((o7c_id_t **)mem - 1) - 1;
		if (1 == *counter) {
			free(counter);
		} else {
			assert(*counter > 1);
			--*counter;
		}
	}
}

/** уменьшает счётчик на 1, но не освобождает объект при достижении 0 */
static O7C_INLINE void* o7c_unhold(void *mem) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void* o7c_unhold(void *mem) {
	o7c_mmc_t *counter;
	if ((O7C_MEM_MAN == O7C_MEM_MAN_COUNTER)
	 && (NULL != mem))
	{
		counter = (o7c_mmc_t *)((o7c_id_t **)mem - 1) - 1;
		assert(*counter > 0);
		--*counter;
	}
	return mem;
}


#define O7C_RELEASE_PARAMS(array) o7c_release_array(array, sizeof(array) / sizeof(array[0]))

static O7C_INLINE void o7c_null(void **mem) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void o7c_null(void **mem) {
	o7c_release(*mem);
	*mem = NULL;
}

#define O7C_NULL(mem) o7c_null((void **)(mem))

static O7C_INLINE void o7c_release_array(void *mem[], int count)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void o7c_release_array(void *mem[], int count) {
	int i;
	if (O7C_MEM_MAN == O7C_MEM_MAN_COUNTER) {
		for (i = 0; i < count; ++i) {
			o7c_null(mem + i);
		}
	}
}

static O7C_INLINE void o7c_assign(void **m1, void *m2) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void o7c_assign(void **m1, void *m2) {
	assert(NULL != m1);
	o7c_retain(m2);
	if (NULL != *m1) {
		o7c_release(*m1);
	}
	*m1 = m2;
}

#define O7C_ASSIGN(m1, m2) o7c_assign((void **)(m1), m2) 

extern void o7c_tag_init(o7c_tag_t ext, o7c_tag_t const base);

static O7C_INLINE o7c_id_t const * o7c_dynamic_tag(void const *mem)
	O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE o7c_id_t const * o7c_dynamic_tag(void const *mem) {
	assert(NULL != mem);
	return *((o7c_id_t const **)mem - 1);
}

static O7C_INLINE o7c_bool o7c_is(o7c_tag_t const base, void const *strct,
	o7c_tag_t const ext) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE o7c_bool
	o7c_is(o7c_tag_t const base, void const *strct, o7c_tag_t const ext)
{
	if (NULL == base) {
		base = o7c_dynamic_tag(strct);
	}
	return base[ext[0]] == ext[ext[0]];
}

static O7C_INLINE void ** o7c_must(o7c_tag_t const base, void **strct,
	o7c_tag_t const ext) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void **
	o7c_must(o7c_tag_t const base, void **strct, o7c_tag_t const ext)
{
	assert(o7c_is(base, *strct, ext));
	return strct;
}

#define O7C_GUARD(ExtType, strct) \
	(*(struct ExtType **)o7c_must(NULL, (void **)strct, ExtType##_tag))


static O7C_INLINE void * o7c_must_r(o7c_tag_t const base, void *strct,
	o7c_tag_t const ext) O7C_ATTR_ALWAYS_INLINE;
static O7C_INLINE void *
	o7c_must_r(o7c_tag_t const base, void *strct, o7c_tag_t const ext)
{
	assert(o7c_is(base, strct, ext));
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
