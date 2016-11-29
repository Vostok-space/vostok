#if !defined(HEADER_GUARD_Arithmetic)
#define HEADER_GUARD_Arithmetic

#include "Limits.h"

extern o7c_bool Arithmetic_Add(int *sum, int a1, int a2);

extern o7c_bool Arithmetic_Sub(int *diff, int m, int s);

extern o7c_bool Arithmetic_Mul(int *prod, int m1, int m2);

extern o7c_bool Arithmetic_Div(int *frac, int n, int d);

extern o7c_bool Arithmetic_Mod(int *mod, int n, int d);

extern void Arithmetic_init(void);
#endif
