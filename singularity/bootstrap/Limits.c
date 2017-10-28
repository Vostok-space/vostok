#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include "o7c.h"

#include "Limits_.h"

extern o7c_bool Limits_IsNan(double r) {
	return r != r;
}

extern o7c_bool Limits_InByteRange(int v) {
	return (o7c_cmp(v, 0) >=  0) && (o7c_cmp(v, Limits_ByteMax_cnst) <=  0);
}

extern o7c_bool Limits_InCharRange(int v) {
	return (o7c_cmp(v, 0) >=  0) && (o7c_cmp(v, (int)0xFFu) <=  0);
}

