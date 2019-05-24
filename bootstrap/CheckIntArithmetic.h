#if !defined HEADER_GUARD_CheckIntArithmetic
#    define  HEADER_GUARD_CheckIntArithmetic 1

#include "TypesLimits.h"

extern o7_bool CheckIntArithmetic_Add(o7_int_t *sum, o7_int_t a1, o7_int_t a2);

extern o7_bool CheckIntArithmetic_Sub(o7_int_t *diff, o7_int_t m, o7_int_t s);

extern o7_bool CheckIntArithmetic_Mul(o7_int_t *prod, o7_int_t m1, o7_int_t m2);

extern o7_bool CheckIntArithmetic_Div(o7_int_t *frac, o7_int_t n, o7_int_t d);

extern o7_bool CheckIntArithmetic_Mod(o7_int_t *mod, o7_int_t n, o7_int_t d);

extern o7_bool CheckIntArithmetic_DivMod(o7_int_t *frac, o7_int_t *mod, o7_int_t n, o7_int_t d);

#endif
