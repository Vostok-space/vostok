/* Copyright 2016-2019,2021-2025 ComdivByZero
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

#include "o7.h"

#include <stdio.h>
#include <float.h>

#if defined(_WIN32) || defined(_WIN64)
	extern double ldexp(double, int);
	extern double frexp(double, int*);
#endif

int     o7_cli_argc;
char**  o7_cli_argv;

int o7_exit_code;

static o7_uint_t  addrs_i;
static o7_chadr_t addrs[1 + (int)(O7_CHECKED_ADR || (sizeof(void *) != sizeof(o7_int_t))) * 7];

size_t o7_allocated;

o7_tag_t o7_base_tag;

char o7_memory[O7_MEMNG_NOFREE_BUFFER_SIZE];

static void nothing(void *mem) {
	(void)mem;
}

static int calcByteOrder(void) {
	o7_int_t i, bo;
	char b[sizeof(i)];
	b[0] = 1;
	b[1] = 2;
	b[2] = 3;
	b[3] = 4;
	memcpy(&i, b, sizeof(b));
	if (i == 0x04030201) {
		bo = O7_ORDER_LE;
	} else { assert(i == 0x01020304);
		bo = O7_ORDER_BE;
	}
	return bo;
}

#if !defined(O7_BYTE_ORDER)
	o7_int_t O7_BYTE_ORDER;
	static void setByteOrder(void) {
		O7_BYTE_ORDER = calcByteOrder();
	}
#else
	static void setByteOrder(void) {(void)calcByteOrder;}
#endif

O7_ALWAYS_INLINE
o7_uint_t ptr_to_uint(void *ptr, size_t size, o7_adr_kind_t kind, o7_uint_t *count) {
	o7_uint_t s, i;

	addrs_i = (addrs_i + 1) % 16;
	i = addrs_i % 8;
	addrs[i].adr = ptr;
	if (O7_CHECKED_ADR) {
		s = (O7_UINT_MAX + (o7_long_t)1) / 32;
		if (size < s) {
			s = size;
		}
		addrs[i].size = s;
		addrs[i].kind = kind;
		if (o7_adr_is_local(kind)) {
			*count += 1;
		}
	}
	return (addrs_i << 28) | 1;
}

extern o7_uint_t o7_ptr_to_uint(void *ptr, size_t size, o7_adr_kind_t kind) {
	return ptr_to_uint(ptr, size, kind, NULL);
}

/* local pointer */
extern o7_uint_t o7_lptr_to_uint(void *ptr, size_t size, o7_adr_kind_t kind, o7_uint_t *count) {
	return ptr_to_uint(ptr, size, kind, count);
}

extern void o7_lptr_outdate(o7_uint_t count) {
	o7_uint_t i, j;
	if (count > 0) {
		i = addrs_i % 8;
		j = i;
		do {
			if (o7_adr_is_local(addrs[i].kind)) {
				addrs[i].kind = O7_ADR_OUTDATE;
				addrs[i].size = 0;
				count -= 1;
			}
			i = (i + 7) % 8;
		} while (count > 0 && i != j);
	}
}

O7_ALWAYS_INLINE int getAddrIndex(o7_uint_t addr, o7_uint_t *rofs) {
	o7_uint_t dist, ofs;
	o7_cbool outdatedAddress, outOfSize;
	int i;

	ofs  = addr % 0x10000000 - 1;
	addr = addr / 0x10000000;
	dist = (16 + addrs_i - addr) % 16;
	i = addr % 8;

	if (O7_CHECKED_ADR) {
		outdatedAddress = (addrs[i].kind == O7_ADR_OUTDATE) || (dist >= 8);
		assert(!outdatedAddress);

		outOfSize = ofs >= addrs[i].size;
		assert(!outOfSize);
	}

	*rofs = ofs;
	return i;
}

/* writable address */
O7_ALWAYS_INLINE int getWaddrIndex(o7_uint_t addr, o7_uint_t *rofs) {
	o7_uint_t dist, ofs;
	o7_cbool outdatedAddress, writableAddress, outOfSize;
	int i;

	ofs  = addr % 0x10000000 - 1;
	addr = addr / 0x10000000;
	dist = (16 + addrs_i - addr) % 16;
	i = addr % 8;

	if (O7_CHECKED_ADR) {
		writableAddress = (addrs[i].kind % 2 == 1) && (dist < 8);
		if (!writableAddress) {
			outdatedAddress = (addrs[i].kind == O7_ADR_OUTDATE) || (dist >= 8);
			assert(!outdatedAddress);
			assert(writableAddress);
		}

		outOfSize = ofs >= addrs[i].size;
		assert(!outOfSize);
	}

	*rofs = ofs;
	return i;
}

extern void const * o7_uint_to_ptr(o7_uint_t addr) {
	o7_uint_t ofs;
	int i;

	i = getAddrIndex(addr, &ofs);
	return (void const *)((char const*)addrs[i].adr + ofs);
}

extern void* o7_uint_to_wptr(o7_uint_t addr) {
	o7_uint_t ofs;
	int i;

	i = getWaddrIndex(addr, &ofs);
	return (void *)((char *)addrs[i].adr + ofs);
}

extern void const * o7_uint_to_sptr(o7_uint_t addr, o7_uint_t size) {
	o7_uint_t ofs;
	int i;
	o7_cbool outOfSize;

	i = getAddrIndex(addr, &ofs);
	if (O7_CHECKED_ADR) {
		outOfSize = addrs[i].size - ofs < size;
		o7_assert(!outOfSize);
	}
	return (void const *)((char const*)addrs[i].adr + ofs);
}

extern void* o7_uint_to_swptr(o7_uint_t addr, o7_uint_t size) {
	o7_uint_t ofs;
	int i;
	o7_cbool outOfSize;

	i = getWaddrIndex(addr, &ofs);
	if (O7_CHECKED_ADR) {
		outOfSize = addrs[i].size - ofs < size;
		o7_assert(!outOfSize);
	}
	return (void *)((char *)addrs[i].adr + ofs);
}

extern void o7_chcopy(o7_int_t src, o7_int_t dst, o7_int_t n) {
	int si, di;
	o7_uint_t ss, ds;
	void const *sp;
	void *dp;
	o7_cbool outOfSize;

	si = getAddrIndex(src, &ss);
	if (O7_CHECKED_ADR) {
		outOfSize = (addrs[si].size - ss) / sizeof(o7_uint_t) < n;
		o7_assert(!outOfSize);
	}
	sp = (void const *)(ss + (char const *)addrs[si].adr);

	di = getWaddrIndex(dst, &ds);
	if (O7_CHECKED_ADR) {
		outOfSize = (addrs[di].size - ds) / sizeof(o7_uint_t) < n;
		o7_assert(!outOfSize);
	}
	dp = (void *)(ds + (char *)addrs[di].adr);

	memmove(dp, sp, n * sizeof(o7_int_t));
}

static void runtimeTest(void) {
	double undefined, nan;
	float undefinedf, nanf;
/* Необходимо для "неопределённого значения" при двоичном дополнении.
 * Для платформ с симметричными целыми нужно что-то другое. */
	O7_STATIC_ASSERT(INT_MIN < -INT_MAX);

	O7_STATIC_ASSERT((sizeof(int ) * 2 == sizeof(double))
	              || (sizeof(long) * 2 == sizeof(double)));

	/* для случая использования int в качестве INTEGER */
	O7_STATIC_ASSERT(INT_MAX >= 2147483647);

	O7_STATIC_ASSERT((int)(0 < 1) == 1);
	O7_STATIC_ASSERT((int)(0 > 1) == 0);

	undefined = O7_DBL_UNDEF;
	nan = O7_INF - O7_INF;
	o7_assert(undefined != undefined || (nan == nan));
	undefinedf = O7_FLT_UNDEF;
	nanf = nan;
	o7_assert(undefinedf != undefinedf || (nanf == nanf));
}

extern void o7_init(int argc, char *argv[O7_VLA(argc)]) {
	runtimeTest();

	o7_assert((0 < argc) == (argv != NULL));

	o7_exit_code = 0;

	o7_cli_argc = argc;
	o7_cli_argv = argv;

	o7_base_tag.release = nothing;

	if (O7_MEMNG == O7_MEMNG_GC) {
		o7_gc_init();
	}

	setByteOrder();

	addrs_i = 0;
}

extern void o7_tag_init(o7_tag_t *ext, o7_tag_t const *base, void release(void *)) {
	static o7_id_t id = 1;
	int i;
	o7_assert((NULL != base) || (NULL != release));
	i = 1;

	ext->ids[0] = base->ids[0] + 1;
	assert(ext->ids[0] <= O7_MAX_RECORD_EXT);
	while (i < ext->ids[0]) {
		ext->ids[i] = base->ids[i];
		i += 1;
	}
	ext->ids[i] = id;
	i  += 1;
	id += 1;

	/* нужно на случай, если тэг по каким-либо причинам не глобальный или
	 * глобальные переменные не зануляются (MISRA C Rule 9.1 Note) */
	while (i <= O7_MAX_RECORD_EXT) {
		ext->ids[i] = 0;
		i += 1;
	}

	if (NULL != release) {
		ext->release = release;
	} else if (NULL != base) {
		ext->release = base->release;
	} else {
		ext->release = nothing;
	}
}

extern O7_NORETURN void o7_case_fail(o7_int_t i) {
	char buf[25];
	o7_cbool neg;
	int ofs;

	neg = i < 0;
	if (neg) {
		i = -o7_int(i);
	}

	ofs = sizeof(buf) - 1;
	buf[ofs] = '\n';
	do {
		ofs -= 1;
		buf[ofs] = '0' + i % 10;
		i /= 10;
	} while (i > 0);

	if (neg) {
		ofs -= 1;
		buf[ofs] = '-';
	}
	ofs -= sizeof("case fail: ") - 1;
	memcpy(buf + ofs, "case fail: ", sizeof("case fail: ") - 1);
	fwrite(buf + ofs, 1, sizeof(buf) - ofs, stderr);
	abort();
}

extern o7_char* o7_bools_undef(o7_int_t len, o7_char array[O7_VLA(len)]) {
	o7_int_t i;
	if (sizeof(o7_char) == 1) {
		memset(array,  O7_BOOL_UNDEF, len);
	} else {
		for (i = 0; i < len; i += 1) {
			array[i] = O7_BOOL_UNDEF;
		}
	}
	return array;
}

extern double* o7_doubles_undef(o7_int_t len, double array[O7_VLA(len)]) {
	o7_int_t i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7_DBL_UNDEF;
	}
	return array;
}

extern float* o7_floats_undef(o7_int_t len, float array[O7_VLA(len)]) {
	o7_int_t i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7_FLT_UNDEF;
	}
	return array;
}

extern o7_int_t* o7_ints_undef(o7_int_t len, o7_int_t array[O7_VLA(len)]) {
	o7_int_t i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7_INT_UNDEF;
	}
	return array;
}

#if O7_LONG_SUPPORT
extern o7_long_t* o7_longs_undef(o7_int_t len, o7_long_t array[O7_VLA(len)]) {
	o7_int_t i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7_LONG_UNDEF;
	}
	return array;
}
#endif

extern int o7_strcmp(o7_int_t s1_len, o7_char const s1[O7_VLA(s1_len)],
                     o7_int_t s2_len, o7_char const s2[O7_VLA(s2_len)]) {
	int c1, c2;
	o7_int_t i, len;
	if (s1_len < s2_len) {
		len = s1_len;
	} else {
		len = s2_len;
	}
	i = 0;
	while ((i < len) && (s1[i] == s2[i]) && (s1[i] != '\0')) {
		i += 1;
	}
	if (i < s1_len) {
		c1 = (int)s1[i];
	} else {
		c1 = 0;
	}
	if (i < s2_len) {
		c2 = (int)s2[i];
	} else {
		c2 = 0;
	}
	return c1 - c2;
}

extern double o7_raw_regular_frexp(double x, o7_int_t *exp) {
	o7_ulong_t u; int e;

	memcpy(&u, &x, sizeof(u));
	e = u / 0x0010000000000000ULL % 0x800 - 0x3FF;
	u = (u & 0x800FFFFFFFFFFFFFULL) | 0x3FF0000000000000ULL;
	memcpy(&x, &u, sizeof(u));
	*exp = e;
	return x;
}

extern double o7_raw_regular_ldexp(double x, int n) {
	o7_uint_t u[2];
	int e;

	memcpy(u, &x, sizeof(u));
	e = (int)(u[2 - O7_BYTE_ORDER] / 0x00100000UL % 0x800) + n;
	u[2 - O7_BYTE_ORDER] = (u[2 - O7_BYTE_ORDER] & 0x800FFFFFUL) | ((unsigned)e * 0x00100000UL);
	memcpy(&x, u, sizeof(u));
	return x;
}

#if !O7_USED_GNUC_BUILTIN_LDEXP

extern double o7_raw_frexp(double x, o7_int_t *exp) {
	o7_ulong_t u, m;
	int se, e, lz;

	memcpy(&u, &x, sizeof(u));
	se = u / 0x0010000000000000ULL;
	e = se % 0x800;
	if (e == 0x7FF) {
		e = 0x400;
		m = u % 0x0010000000000000ULL;
		if (m != 0) {
			x = 0.0;
		} else if (se < 0x800) {
			x = 1.0;
		} else {
			x = -1.0;
		}
	} else if (e != 0) {
		e -= 0x3FF;
		u = (u & 0x800FFFFFFFFFFFFFULL) | 0x3FF0000000000000ULL;
		memcpy(&x, &u, sizeof(u));
	} else {
		m = u % 0x0010000000000000ULL;
		if (m != 0) {
			lz = o7_lclz(m) - 11;
			e = -lz - 0x3FD;
			u = (u & 0x8000000000000000ULL) | 0x3FF0000000000000ULL | (m << lz);
			memcpy(&x, &u, sizeof(u));
		}
	}
	*exp = e;
	return x;
}

O7_ATTR_CONST
extern double o7_raw_ldexp(double x, int n) {
	o7_ulong_t u, m; int se, e0, e, lz;

	memcpy(&u, &x, sizeof(u));
	se = u / 0x0010000000000000ULL;
	e0 = se % 0x800;
	if (e0 != 0x7FF && u * 2 != 0) {
		if (n > 0x10000) { n = 0x10000; }
		e = e0 + n;

		if (e0 == 0) {/*денормализовано*/
			lz = o7_lclz(u << 12);
			e -= lz;
			u = (0x8000000000000000ULL & u)
			  | (0x000FFFFFFFFFFFFFULL & (u << (lz + 1)));
		}

		if (e >= 0x7FF) {
			u =  0xFFF0000000000000ULL & u;
		} else if (e > 0) {
			u = (0x800FFFFFFFFFFFFFULL & u) | ((o7_ulong_t)e << 0x34);
		} else if (e < -0x34) {
			u =  0x8000000000000000ULL & u;
		} else {
			/* денормализация, восстанавление подразумеваемой 1 */
			m = (0x000FFFFFFFFFFFFFULL & u) | 0x0010000000000000ULL;
			/* округление (при переполнении денормализация самоустраняется) */
			m += m & (0x1ULL << -e);
			u = (0x8000000000000000ULL & u) | (m >> (1 - e));
		}
		memcpy(&x, &u, sizeof(u));
	}
	return x;
}

#endif
