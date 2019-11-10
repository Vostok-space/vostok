#include <o7.h>

#include "TypesLimits.h"

extern o7_bool TypesLimits_InByteRange(o7_int_t v) {
	return (0 <= v) && (v <= TypesLimits_ByteMax_cnst);
}

extern o7_bool TypesLimits_InCharRange(o7_int_t v) {
	return (0 <= v) && (v <= (o7_int_t)0xFFu);
}

extern o7_bool TypesLimits_InSetRange(o7_int_t v) {
	return (0 <= v) && (v <= TypesLimits_SetMax_cnst);
}

