#include "o7.h"

#include <math.h>
#if defined(_WIN32) || defined(_WIN64)
	extern double ldexp(double, int);
	extern double frexp(double, int*);
#endif

int     o7_cli_argc;
char**  o7_cli_argv;

int o7_exit_code;

size_t o7_allocated;

o7_tag_t o7_base_tag;

char o7_memory[O7_MEMNG_NOFREE_BUFFER_SIZE];

static void nothing(void *mem) {
	(void)mem;
}

extern void o7_init(int argc, char *argv[O7_VLA(argc)]) {
	double undefined;
	float undefinedf;
	O7_STATIC_ASSERT(INT_MIN < -INT_MAX);

	O7_STATIC_ASSERT((sizeof(int ) * 2 == sizeof(double))
	              || (sizeof(long) * 2 == sizeof(double)));

	O7_STATIC_ASSERT(INT_MAX >= 2147483647);

	O7_STATIC_ASSERT((int)(0 < 1) == 1);
	O7_STATIC_ASSERT((int)(0 > 1) == 0);

	undefined = o7_dbl_undef();
	assert(undefined != undefined);
	undefinedf = o7_flt_undef();
	assert(undefinedf != undefinedf);

	assert((0 < argc) == (argv != NULL));

	o7_exit_code = 0;

	o7_cli_argc = argc;
	o7_cli_argv = argv;

	o7_base_tag.release = nothing;

	if (O7_MEMNG == O7_MEMNG_GC) {
		o7_gc_init();
	}
}

extern void o7_tag_init(o7_tag_t *ext, o7_tag_t const *base, void release(void *)) {
	static o7_id_t id = 1;
	int i;
	assert((NULL != base) || (NULL != release));
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
	extern int puts(char const *s);
	char buf[26];
	o7_cbool neg;
	int ofs;
	neg = i < 0;
	if (neg) {
		i = -o7_int(i);
	}
	buf[15] = '\0';
	ofs = 15;
	while (i > 0) {
		ofs -= 1;
		buf[ofs] = '0' + i % 10;
		i /= 10;
	}
	if (neg) {
		ofs -= 1;
		buf[ofs] = '-';
	}
	ofs -= sizeof("case fail: ") - 1;
	memcpy(buf + ofs, "case fail: ", sizeof("case fail: ") - 1);
	puts(buf + ofs);
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

extern o7_int_t* o7_ints_undef(o7_int_t len, int array[O7_VLA(len)]) {
	o7_int_t i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7_INT_UNDEF;
	}
	return array;
}

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

extern double o7_raw_ldexp(double f, int n) {
	return ldexp(f, n);
}

extern double o7_raw_frexp(double x, int *exp) {
	return frexp(x, exp);
}
