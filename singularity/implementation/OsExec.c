#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "OsExec.h"

extern int OsExec_Do(int len, o7c_char const cmd[O7C_VLA_LEN(len)]) {
	return system((char const *)cmd);
}

