#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "OsExec.h"

extern o7_int_t OsExec_Do(o7_int_t len, o7_char const cmd[O7_VLA(len)]) {
	return system((char const *)cmd);
}

