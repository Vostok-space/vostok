#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "OsEnv.h"

extern o7_bool OsEnv_Exist(O7_FPA(o7_char const, name)) {
	return NULL != getenv((char *)name);
}

extern o7_bool OsEnv_Get(O7_FPA(o7_char, val), o7_int_t *ofs, O7_FPA(o7_char const, name)) {
	char *env;
	o7_int_t i, j;
	assert((0 <= *ofs) && (*ofs < O7_FPA_LEN(val) - 1));

	env = getenv((char *)name);
	if (NULL != env) {
		i = *ofs;
		j = 0;
		while ((i < O7_FPA_LEN(val) - 1) && (env[j] != '\0')) {
			val[i] = (o7_char)env[j];
			i += 1;
			j += 1;
		}
		val[i] = '\0';
		*ofs = i;
	}
	return (NULL != env) && ('\0' == env[j]);
}

