#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "OsExec.h"

extern int OsExec_Do(o7c_char const cmd[/*len0*/], int cmd_len0) {
	return system((char const *)cmd);
}

