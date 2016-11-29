#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#define O7C_BOOL_UNDEFINED
#include <o7c.h>

#include "Arithmetic.h"

#define Min_cnst Limits_IntegerMin_cnst
#define Max_cnst Limits_IntegerMax_cnst

extern o7c_bool Arithmetic_Add(int *sum, int a1, int a2) {
	o7c_bool o7c_return;

	o7c_bool norm = O7C_BOOL_UNDEF;

	if (o7c_cmp(a2, 0) >  0) {
		norm = o7c_cmp(a1, o7c_sub(Max_cnst, a2)) <=  0;
	} else {
		norm = o7c_cmp(a1, o7c_sub(Min_cnst, a2)) >=  0;
	}
	if (norm) {
		(*sum) = o7c_add(a1, a2);
	}
	o7c_return = o7c_bl(norm);
	return o7c_return;
}

extern o7c_bool Arithmetic_Sub(int *diff, int m, int s) {
	o7c_bool o7c_return;

	o7c_bool norm = O7C_BOOL_UNDEF;

	if (o7c_cmp(s, 0) >  0) {
		norm = o7c_cmp(m, o7c_add(Min_cnst, s)) >=  0;
	} else {
		norm = o7c_cmp(m, o7c_add(Max_cnst, s)) <=  0;
	}
	if (norm) {
		(*diff) = o7c_sub(m, s);
	}
	o7c_return = o7c_bl(norm);
	return o7c_return;
}

extern o7c_bool Arithmetic_Mul(int *prod, int m1, int m2) {
	o7c_bool o7c_return;

	o7c_bool norm = O7C_BOOL_UNDEF;

	norm = (o7c_cmp(m2, 0) ==  0) || (o7c_cmp(abs(m1), o7c_div(Max_cnst, abs(m2))) <=  0);
	if (norm) {
		(*prod) = o7c_mul(m1, m2);
	}
	o7c_return = o7c_bl(norm);
	return o7c_return;
}

extern o7c_bool Arithmetic_Div(int *frac, int n, int d) {
	o7c_bool o7c_return;

	if (o7c_cmp(d, 0) !=  0) {
		(*frac) = o7c_div(n, d);
	}
	o7c_return = o7c_cmp(d, 0) !=  0;
	return o7c_return;
}

extern o7c_bool Arithmetic_Mod(int *mod, int n, int d) {
	o7c_bool o7c_return;

	if (o7c_cmp(d, 0) !=  0) {
		(*mod) = o7c_mod(n, d);
	}
	o7c_return = o7c_cmp(d, 0) !=  0;
	return o7c_return;
}

extern void Arithmetic_init(void) {
	static int initialized = 0;
	if (0 == initialized) {
		Limits_init();

	}
	++initialized;
}

