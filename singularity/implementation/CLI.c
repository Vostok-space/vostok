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
#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>

#include "CLI.h"

int CLI_count;

static char **CLI_argv;

extern bool CLI_Get(
	int str_len, char unsigned str[O7C_VLA_LEN(str_len)], int *ofs, int arg)
{
	int i;
	assert((arg >= 0) && (arg < CLI_count));
	i = 0;
	while ((*ofs < str_len - 1) && ('\0' != CLI_argv[arg][i])) {
		str[*ofs] = CLI_argv[arg][i];
		++i;
		++*ofs;
	}
	str[*ofs] = '\0';
	++*ofs;
	return '\0' == CLI_argv[arg][i];
}

extern void CLI_SetExitCode(int code) {
	extern int o7c_exit_code;
	o7c_exit_code = code;
}

extern void CLI_init(void) {
	extern int o7c_cli_argc;
	extern char **o7c_cli_argv;

	CLI_count = o7c_cli_argc;
	CLI_argv = o7c_cli_argv;
}
