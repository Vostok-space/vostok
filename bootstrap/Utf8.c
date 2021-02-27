#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "Utf8.h"

#define Utf8_R_tag o7_base_tag

extern o7_bool Utf8_EqualIgnoreCase(o7_char a, o7_char b) {
	o7_bool equal;

	if (a == b) {
		equal = (0 < 1);
	} else if (((o7_char)'a' <= a) && (a <= (o7_char)'z')) {
		equal = ((o7_int_t)(o7_char)'a') - ((o7_int_t)(o7_char)'A') == o7_sub((o7_int_t)a, (o7_int_t)b);
	} else if (((o7_char)'A' <= a) && (a <= (o7_char)'Z')) {
		equal = ((o7_int_t)(o7_char)'a') - ((o7_int_t)(o7_char)'A') == o7_sub((o7_int_t)b, (o7_int_t)a);
	} else {
		equal = (0 > 1);
	}
	return equal;
}
