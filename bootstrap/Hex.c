#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "Hex.h"

extern o7_char Hex_To(o7_int_t d) {
	O7_ASSERT(o7_in(d, Hex_Range_cnst));
	if (d < 10) {
		d = o7_add(d, ((o7_int_t)(o7_char)'0'));
	} else {
		d = o7_add(d, ((o7_int_t)(o7_char)'A') - 10);
	}
	return o7_chr(d);
}

extern o7_bool Hex_InRange(o7_char ch) {
	return ((o7_char)'0' <= ch) && (ch <= (o7_char)'9') || ((o7_char)'A' <= ch) && (ch <= (o7_char)'F');
}

extern o7_int_t Hex_From(o7_char d) {
	o7_int_t i;

	O7_ASSERT(Hex_InRange(d));

	if ((d >= (o7_char)'0') && (d <= (o7_char)'9')) {
		i = o7_sub((o7_int_t)d, ((o7_int_t)(o7_char)'0'));
	} else {
		O7_ASSERT((d >= (o7_char)'A') && (d <= (o7_char)'F'));
		i = o7_sub(o7_add(10, (o7_int_t)d), ((o7_int_t)(o7_char)'A'));
	}
	return i;
}
