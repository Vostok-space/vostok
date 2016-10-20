#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>

#include "CLI.h"

int CLI_count;

static char **CLI_argv;

extern bool CLI_Get(char str[/*len0*/], int str_len0, int *ofs, int arg) {
	int i;
	assert((arg >= 0) && (arg < CLI_count));
	i = 0;
	while ((*ofs < str_len0 - 1) && ('\0' != CLI_argv[arg][i])) {
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

extern void CLI_init_(void) {
	extern int o7c_cli_argc;
	extern char **o7c_cli_argv;
	
	CLI_count = o7c_cli_argc;
	CLI_argv = o7c_cli_argv;
}
