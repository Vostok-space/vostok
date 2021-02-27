#if !defined(O7_INIT_MODEL)
#   define   O7_INIT_MODEL O7_INIT_ZERO
#endif

#include <o7.h>

#include "CheckIntArithmetic.h"

#define Min_cnst TypesLimits_IntegerMin_cnst
#define Max_cnst TypesLimits_IntegerMax_cnst

extern o7_bool CheckIntArithmetic_Add(o7_int_t *sum, o7_int_t a1, o7_int_t a2) {
	o7_bool norm;

	if (a2 > 0) {
		norm = a1 <= o7_sub(Max_cnst, a2);
	} else {
		norm = a1 >= o7_sub(Min_cnst, a2);
	}
	if (norm) {
		*sum = o7_add(a1, a2);
	}
	return norm;
}

extern o7_bool CheckIntArithmetic_Sub(o7_int_t *diff, o7_int_t m, o7_int_t s) {
	o7_bool norm;

	if (s > 0) {
		norm = m >= o7_add(Min_cnst, s);
	} else {
		norm = m <= o7_add(Max_cnst, s);
	}
	if (norm) {
		*diff = o7_sub(m, s);
	}
	return norm;
}

extern o7_bool CheckIntArithmetic_Mul(o7_int_t *prod, o7_int_t m1, o7_int_t m2) {
	o7_bool norm;

	norm = (m2 == 0) || (abs(m1) <= o7_div(Max_cnst, abs(m2)));
	if (norm) {
		*prod = o7_mul(m1, m2);
	}
	return norm;
}

extern o7_bool CheckIntArithmetic_Div(o7_int_t *frac, o7_int_t n, o7_int_t d) {
	if (0 < d) {
		*frac = o7_div(n, d);
	}
	return 0 < d;
}

extern o7_bool CheckIntArithmetic_Mod(o7_int_t *mod, o7_int_t n, o7_int_t d) {
	if (0 < d) {
		*mod = o7_mod(n, d);
	}
	return 0 < d;
}

extern o7_bool CheckIntArithmetic_DivMod(o7_int_t *frac, o7_int_t *mod, o7_int_t n, o7_int_t d) {
	if (0 < d) {
		*frac = o7_div(n, d);
		*mod = o7_mod(n, d);
	}
	return 0 < d;
}
