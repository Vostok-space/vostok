#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "OsExec.h"

extern o7_int_t OsExec_Do(O7_FPA(o7_char const, cmd)) {
	return system((char const *)cmd);
}
