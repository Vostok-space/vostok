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

extern void o7c_init(int argc, char *argv[]) {
	double undefined;
/* Необходимо для "неопределённого значения" при двоичном дополнении.
 * Для платформ с симметричными целыми нужно что-то другое. */
	assert(INT_MIN < -INT_MAX);

	assert((sizeof(int ) * 2 == sizeof(double))
		|| (sizeof(long) * 2 == sizeof(double)));
	undefined = o7c_dbl_undef();
	assert(undefined != undefined);

	assert((argc > 0) == (argv != NULL));

	o7c_exit_code = 0;

	o7c_cli_argc = argc;
	o7c_cli_argv = argv;
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
			++i;
		}
		ext[i] = id;
		++i;
		++id;
	}
	/* нужно на случай, если тэг по каким-либо причинам не глобальный или
	 * глобальные переменные не зануляются (MISRA C Rule 9.1 Note) */
	while (i <= O7C_MAX_RECORD_EXT) {
		ext[i] = 0;
		++i;
	}
}
