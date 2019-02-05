#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "OsEnv.h"

extern o7_bool OsEnv_Exist(o7_int_t len, o7_char const name[O7_VLA(len)]) {
	return NULL != getenv((char *)name);
}

extern o7_bool OsEnv_Get(o7_int_t len, o7_char val[O7_VLA(len)], o7_int_t *ofs,
                         o7_int_t name_len, o7_char const name[O7_VLA(name_len)])
{
	char *env;
	o7_int_t i, j;
	assert((0 <= *ofs) && (*ofs < len - 1));

	env = getenv((char *)name);
	if (NULL != env) {
		i = *ofs;
		j = 0;
		while ((i < len - 1) && (env[j] != '\0')) {
			val[i] = (o7_char)env[j];
			i += 1;
			j += 1;
		}
		val[i] = '\0';
		*ofs = i;
	}
	return (NULL != env) && ('\0' == env[j]);
}
