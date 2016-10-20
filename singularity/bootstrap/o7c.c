#include <stddef.h>
#include <stdlib.h>
#include <assert.h>

#include "o7c.h"

int		o7c_cli_argc;
char**	o7c_cli_argv;

int o7c_exit_code;

extern void o7c_cli_init(int argc, char *argv[]) {
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
		i = 1;
		while (i < ext[0]) {
			ext[i] = base[i];
			++i;
		}
		ext[i] = id;
		++id;
	}
}
