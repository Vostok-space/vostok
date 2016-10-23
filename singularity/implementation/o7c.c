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
	o7c_exit_code = 0;
	
	o7c_cli_argc = argc;
	o7c_cli_argv = argv;
}

extern void o7c_tag_init(o7c_tag_t ext, o7c_tag_t const base) {
	static int id = 1;
	int i;
	if (NULL == base) {
		ext[0] = 0;
	} else {
		ext[0] = base[0] + 1;
		assert(ext[0] <= O7C_MAX_RECORD_EXT);
		i = 1;
		while (i < ext[0]) {
			ext[i] = base[i];
			++i;
		}
		ext[i] = id;
		++id;
	}
}
