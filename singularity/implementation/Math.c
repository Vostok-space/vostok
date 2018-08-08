/* Copyright 2017, 2018 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define O7_BOOL_UNDEFINED
#include "o7.h"

#include "Math.h"

#include <math.h>

#if (__STDC_VERSION__ >= 199901L) && !(defined(__TINYC__) && (defined(_WIN32) || defined(_WIN64)))
	/* TODO */
	enum { O7_C99 = 1 };
	O7_INLINE double o7_log2 (double x) {
		double log2(double);
		return log2(x);
	}
	O7_INLINE double o7_asinh(double x) {
		double asinh(double);
		return asinh(x);
	}
	O7_INLINE double o7_acosh(double x) {
		double acosh(double);
		return acosh(x);
	}
	O7_INLINE double o7_atanh(double x) {
		double atanh(double);
		return atanh(x);
	}
	O7_INLINE double o7_round(double x) {
		double round(double);
		return round(x);
	}
#else
	enum { O7_C99 = 0 };
	O7_INLINE double o7_log2 (double x) { return O7_DBL_UNDEF; }
	O7_INLINE double o7_asinh(double x) { return O7_DBL_UNDEF; }
	O7_INLINE double o7_acosh(double x) { return O7_DBL_UNDEF; }
	O7_INLINE double o7_atanh(double x) { return O7_DBL_UNDEF; }
	O7_INLINE double o7_round(double x) { return O7_DBL_UNDEF; }
#endif

extern double Math_sqrt(double x) {
	extern double sqrt(double);
	assert(0.0 <= x);
	return sqrt(x);
}

extern double Math_power(double x, double base) {
	extern double pow(double, double);
	return pow(o7_dbl(x), o7_dbl(base));
}

extern double Math_exp(double x) {
	extern double exp(double);
	return exp(o7_dbl(x));
}

extern double Math_ln(double x) {
	extern double log(double);
	return log(o7_dbl(x));
}

extern double Math_log(double x, double base) {
	extern double log(double);
	extern double log10(double);
	double res;
	if (O7_C99 && (base == 2.0)) {
		res = o7_log2(o7_dbl(x));
	} else if (base == 10.0) {
		res = log10(o7_dbl(x));
	} else if (base == Math_e_cnst) {
		res = log(o7_dbl(x));
	} else {
		res = log(o7_dbl(x)) / log(o7_dbl(base));
	}
	return res;
}

extern double Math_round(double x) {
	/* TODO check */
	double res;

	if (O7_C99) {
		res = o7_round(x);
	} else {
		/* TODO */
		assert(0 > 1);
	}
	return res;
}

extern double Math_sin(double x) {
	extern double sin(double);
	return sin(o7_dbl(x));
}

extern double Math_cos(double x) {
	extern double cos(double);
	return cos(o7_dbl(x));
}

extern double Math_tan(double x) {
	extern double tan(double);
	return tan(o7_dbl(x));
}

extern double Math_arcsin(double x) {
	extern double asin(double);
	return asin(o7_dbl(x));
}

extern double Math_arccos(double x) {
	extern double acos(double);
	return acos(o7_dbl(x));
}

extern double Math_arctan(double x) {
	extern double atan(double);
	return atan(o7_dbl(x));
}

extern double Math_arctan2(double x, double y) {
	extern double atan2(double, double);
	return atan2(o7_dbl(x), o7_dbl(y));
}

extern double Math_sinh(double x) {
	extern double sinh(double);
	return sinh(o7_dbl(x));
}

extern double Math_cosh(double x) {
	extern double cosh(double);
	return cosh(o7_dbl(x));
}

extern double Math_tanh(double x) {
	extern double tanh(double);
	return tanh(o7_dbl(x));
}

extern double Math_arcsinh(double x) {
	return o7_asinh(o7_dbl(x));
}

extern double Math_arccosh(double x) {
	return o7_acosh(o7_dbl(x));
}

extern double Math_arctanh(double x) {
	return o7_atanh(o7_dbl(x));
}
