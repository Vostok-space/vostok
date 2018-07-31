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

#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "CLI.h"

int CLI_count;

static char **CLI_argv;

static o7_cbool copyArg(
	o7_int_t len, char unsigned str[O7_VLA(len)], o7_int_t *ofs, o7_int_t arg)
{
	int i;
	i = 0;
	while ((*ofs < len) && ('\0' != CLI_argv[arg][i])) {
		str[*ofs] = CLI_argv[arg][i];
		i    += 1;
		*ofs += 1;
	}
	if (*ofs < len) {
		str[*ofs] = '\0';
	}
	return '\0' == CLI_argv[arg][i];
}

extern o7_cbool CLI_GetName(
	o7_int_t len, char unsigned str[O7_VLA(len)], o7_int_t *ofs)
{
	return copyArg(len, str, ofs, -1);
}

extern o7_cbool CLI_Get(
	o7_int_t len, char unsigned str[O7_VLA(len)], o7_int_t *ofs, o7_int_t arg)
{
	assert((0 <= arg) && (arg < CLI_count));
	return copyArg(len, str, ofs, arg);
}

extern void CLI_SetExitCode(int code) {
	extern int o7_exit_code;
	o7_exit_code = code;
}

extern void CLI_init(void) {
	extern int o7_cli_argc;
	extern char **o7_cli_argv;

	CLI_count = o7_cli_argc - 1;
	CLI_argv  = o7_cli_argv + 1;
}
