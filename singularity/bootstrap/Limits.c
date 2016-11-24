#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "Limits.h"

extern o7c_bool Limits_IsNan(double r) {
	o7c_bool o7c_return;

	o7c_return = r != r;
	return o7c_return;
}

