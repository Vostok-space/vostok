#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include <o7c.h>

#include "Limits.h"

extern bool Limits_IsNan(double r) {
	return r != r;
}

