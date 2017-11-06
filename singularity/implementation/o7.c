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

#include "o7.h"

int     o7_cli_argc;
char**  o7_cli_argv;

int o7_exit_code;

size_t o7_allocated;

o7_tag_t o7_base_tag;

char o7_memory[O7_MEMNG_NOFREE_BUFFER_SIZE];

extern void o7_init(int argc, char *argv[O7_VLA(argc)]) {
	double undefined;
	float undefinedf;
/* Необходимо для "неопределённого значения" при двоичном дополнении.
 * Для платформ с симметричными целыми нужно что-то другое. */
	assert(INT_MIN < -INT_MAX);

	assert((sizeof(int ) * 2 == sizeof(double))
		|| (sizeof(long) * 2 == sizeof(double)));
	undefined = o7_dbl_undef();
	assert(undefined != undefined);
	undefinedf = o7_flt_undef();
	assert(undefinedf != undefinedf);

	/* для случая использования int в качестве INTEGER */
	assert(INT_MAX >= 2147483647);

	assert((int)(0 < 1) == 1);
	assert((int)(0 > 1) == 0);

	assert((argc > 0) == (argv != NULL));

	o7_exit_code = 0;

	o7_cli_argc = argc;
	o7_cli_argv = argv;

	if (O7_MEMNG == O7_MEMNG_GC) {
		o7_gc_init();
	}
}

extern void o7_tag_init(o7_tag_t ext, o7_tag_t const base) {
	static int id = 1;
	int i;
	assert(NULL != base);
	i = 1;

	ext[0] = base[0] + 1;
	assert(ext[0] <= O7_MAX_RECORD_EXT);
	while (i < ext[0]) {
		ext[i] = base[i];
		i += 1;
	}
	ext[i] = id;
	i += 1;
	id += 1;

	/* нужно на случай, если тэг по каким-либо причинам не глобальный или
	 * глобальные переменные не зануляются (MISRA C Rule 9.1 Note) */
	while (i <= O7_MAX_RECORD_EXT) {
		ext[i] = 0;
		i += 1;
	}
}

extern o7_char* o7_bools_undef(int len, o7_char array[O7_VLA(len)]) {
	int i;
	for (i = 0; i < len; i += 1) {
		array[i] = 0xff;
	}
	return array;
}

extern double* o7_doubles_undef(int len, double array[O7_VLA(len)]) {
	int i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7_DBL_UNDEF;
	}
	return array;
}

extern float* o7_floats_undef(int len, float array[O7_VLA(len)]) {
	int i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7_FLT_UNDEF;
	}
	return array;
}

extern int* o7_ints_undef(int len, int array[O7_VLA(len)]) {
	int i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7_INT_UNDEF;
	}
	return array;
}

extern o7_long_t* o7_longs_undef(int len, o7_long_t array[O7_VLA(len)]) {
	int i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7_LONG_UNDEF;
	}
	return array;
}

extern int o7_strcmp(int s1_len, o7_char const s1[O7_VLA(s1_len)],
                      int s2_len, o7_char const s2[O7_VLA(s2_len)]) {
	int i, len, c1, c2;
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

