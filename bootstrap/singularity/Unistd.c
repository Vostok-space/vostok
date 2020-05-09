#include <o7.h>

#include "Unistd.h"

#if defined(_WIN16) || defined(_WIN32) || defined(_WIN64)
	O7_ALWAYS_INLINE o7_int_t readlink(char const path[], char buf[], size_t len) {
		O7_ASSERT(0>1);
		return -1;
	}
#	define _SC_PAGESIZE 0
#else
#	include <unistd.h>
#endif

o7_int_t Unistd_pageSize = _SC_PAGESIZE;

static o7_int_t Len(o7_int_t str_len, o7_char const str[/*len0*/]) {
	o7_int_t i;

	i = 0;
	while ((i < str_len) && (str[i] != 0x00u)) {
		i += 1;
	}
	return i;
}

extern o7_int_t
Unistd_Readlink(o7_int_t path_len, o7_char const pathname[O7_VLA(path_len)],
                o7_int_t buf_len, o7_char buf[O7_VLA(buf_len)]) {
	O7_ASSERT(Len(path_len, pathname) < path_len);
	return (o7_int_t)readlink((char const *)pathname, (char *)buf, (o7_uint_t)buf_len);
}

extern o7_int_t Unistd_Sysconf(o7_int_t name) {
	return sysconf(name);
}
