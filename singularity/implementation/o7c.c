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
#include <stddef.h>
#include <stdlib.h>
#include <assert.h>

#include "o7c.h"

int		o7c_cli_argc;
char**	o7c_cli_argv;

int o7c_exit_code;

extern void o7c_init(int argc, char *argv[O7C_VLA_LEN(argc)]) {
	double undefined;
/* Необходимо для "неопределённого значения" при двоичном дополнении.
 * Для платформ с симметричными целыми нужно что-то другое. */
	assert(INT_MIN < -INT_MAX);

	assert((sizeof(int ) * 2 == sizeof(double))
		|| (sizeof(long) * 2 == sizeof(double)));
	undefined = o7c_dbl_undef();
	assert(undefined != undefined);
	assert(sizeof(o7c_mmc_t) == sizeof(void *));

	/* для случая использования int в качестве INTEGER */
	assert(INT_MAX >= 2147483647);

	assert((int)(0 < 1) == 1);
	assert((int)(0 > 1) == 0);

	assert((argc > 0) == (argv != NULL));

	o7c_exit_code = 0;

	o7c_cli_argc = argc;
	o7c_cli_argv = argv;

	if (O7C_MEM_MAN == O7C_MEM_MAN_GC) {
		o7c_gc_init();
	}
}

extern void o7c_tag_init(o7c_tag_t ext, o7c_tag_t const base) {
	static int id = 1;
	int i;
	i = 1;
	if (NULL == base) {
		ext[0] = 0;
	} else {
		ext[0] = base[0] + 1;
		assert(ext[0] <= O7C_MAX_RECORD_EXT);
		while (i < ext[0]) {
			ext[i] = base[i];
			i += 1;
		}
		ext[i] = id;
		i += 1;
		id += 1;
	}
	/* нужно на случай, если тэг по каким-либо причинам не глобальный или
	 * глобальные переменные не зануляются (MISRA C Rule 9.1 Note) */
	while (i <= O7C_MAX_RECORD_EXT) {
		ext[i] = 0;
		i += 1;
	}
}

extern o7c_char* o7c_bools_undef(int len, o7c_char array[O7C_VLA_LEN(len)]) {
	int i;
	for (i = 0; i < len; i += 1) {
		array[i] = 0xff;
	}
	return array;
}

extern double* o7c_doubles_undef(int len, double array[O7C_VLA_LEN(len)]) {
	int i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7C_DBL_UNDEF;
	}
	return array;
}

extern int* o7c_ints_undef(int len, int array[O7C_VLA_LEN(len)]) {
	int i;
	for (i = 0; i < len; i += 1) {
		array[i] = O7C_INT_UNDEF;
	}
	return array;
}

extern int o7c_strcmp(int s1_len, o7c_char const s1[O7C_VLA_LEN(s1_len)],
                      int s2_len, o7c_char const s2[O7C_VLA_LEN(s2_len)]) {
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

