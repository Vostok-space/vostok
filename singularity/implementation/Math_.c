/* Copyright 2017 ComdivByZero
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

#include "Math_.h"

#if (__STDC_VERSION__ >= 199901L) && !(defined(__TINYC__) && (defined(_WIN32) || defined(_WIN64)))
	/* TODO */
	enum { O7_C99 = 1 };
	O7_INLINE double o7_log2 (double x) { return log2(x);  }
	O7_INLINE double o7_asinh(double x) { return asinh(x); }
	O7_INLINE double o7_acosh(double x) { return acosh(x); }
	O7_INLINE double o7_atanh(double x) { return atanh(x); }
#else
	enum { O7_C99 = 0 };
	O7_INLINE double o7_log2 (double x) { return O7_DBL_UNDEF; }
	O7_INLINE double o7_asinh(double x) { return O7_DBL_UNDEF; }
	O7_INLINE double o7_acosh(double x) { return O7_DBL_UNDEF; }
	O7_INLINE double o7_atanh(double x) { return O7_DBL_UNDEF; }
#endif

extern double Math__sqrt(double x) {
	assert(0.0 <= x);
	return sqrt(x);
}

extern double Math__power(double x, double base) {
	return pow(o7_dbl(x), o7_dbl(base));
}

extern double Math__exp(double x) {
	return exp(o7_dbl(x));
}

extern double Math__ln(double x) {
	return log(o7_dbl(x));
}

extern double Math__log(double x, double base) {
	double res;
	if (O7_C99 && (base == 2.0)) {
		res = o7_log2(o7_dbl(x));
	} else if (base == 10.0) {
		res = log10(o7_dbl(x));
	} else if (base == Math__e_cnst) {
		res = log(o7_dbl(x));
	} else {
		res = log(o7_dbl(x)) / log(o7_dbl(base));
	}
	return res;
}

extern double Math__round(double x) {
	/* TODO */
	assert(0 > 1);
	return 0.0;
}

extern double Math__sin(double x) {
	return sin(o7_dbl(x));
}

extern double Math__cos(double x) {
	return cos(o7_dbl(x));
}

extern double Math__tan(double x) {
	return tan(o7_dbl(x));
}

extern double Math__arcsin(double x) {
	return asin(o7_dbl(x));
}

extern double Math__arccos(double x) {
	return acos(o7_dbl(x));
}

extern double Math__arctan(double x) {
	return atan(o7_dbl(x));
}

extern double Math__arctan2(double x, double y) {
	return atan2(o7_dbl(x), o7_dbl(y));
}

extern double Math__sinh(double x) {
	return sinh(o7_dbl(x));
}

extern double Math__cosh(double x) {
	return cosh(o7_dbl(x));
}

extern double Math__tanh(double x) {
	return tanh(o7_dbl(x));
}

extern double Math__arcsinh(double x) {
	return o7_asinh(o7_dbl(x));
}

extern double Math__arccosh(double x) {
	return o7_acosh(o7_dbl(x));
}

extern double Math__arctanh(double x) {
	return o7_atanh(o7_dbl(x));
}
