/* Copyright 2016, 2018 ComdivByZero
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
#if !defined HEADER_GUARD_Int64
#    define  HEADER_GUARD_Int64 1

#if !O7_GNUC_BUILTIN_OVERFLOW
#	define O7_GNUC_BUILTIN_OVERFLOW (0 > 1)
#	if !defined(__builtin_add_overflow)
#		define O7_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF
#		define __builtin_add_overflow(a, b, res) (0 < sizeof(*(res) = (a)+(b)))
#		define __builtin_sub_overflow(a, b, res) (0 < sizeof(*(res) = (a)-(b)))
#		define __builtin_mul_overflow(a, b, res) (0 < sizeof(*(res) = (a)*(b)))
#	endif
#endif

#if INT_MAX > 2147483647l
	typedef int      Int64_t;
	typedef unsigned Int64_ut;
#	define Int64_Max   9223372036854775807
#	define Int64_Min (-9223372036854775807 + (INT_MIN + INT_MAX))
#elif LONG_MAX > 2147483647l
	typedef          long Int64_t;
	typedef unsigned long Int64_ut;
#	define Int64_Max   9223372036854775807l
#	define Int64_Min (-9223372036854775807l + (INT_MIN + INT_MAX))
#else
	typedef          long long Int64_t;
	typedef unsigned long long Int64_ut;
#	define Int64_Max   9223372036854775807ll
#	define Int64_Min (-9223372036854775807ll + (INT_MIN + INT_MAX))
#endif

#define Int64_Size_cnst sizeof(Int64_t)

typedef o7_char Int64_Type[Int64_Size_cnst];

static Int64_Type Int64_min;
static Int64_Type Int64_max;

O7_ALWAYS_INLINE void Int64_FromInt(Int64_Type v, int high, int low) {
	*(Int64_t *)v = o7_int(high) * (Int64_t)INT_MAX + o7_int(low);
}

O7_ALWAYS_INLINE void Int64_ToInt(int *i, Int64_Type v) {
	o7_cbool ov;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		ov = __builtin_add_overflow(*(Int64_t *)v, 0, i);
		assert(!ov);
	} else {
		if (O7_OVERFLOW) {
			assert((-INT_MAX <= *(Int64_t *)v) && (*(Int64_t *)v <= INT_MAX));
		}
		*i = *(Int64_t *)v;
	}
}

O7_ALWAYS_INLINE void Int64_Add(Int64_Type sum, Int64_Type a1, Int64_Type a2) {
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_add_overflow(*(Int64_t *)a1, *(Int64_t *)a2,
		                                  (Int64_t *)sum);
		assert(!overflow);
	} else {
		if (!O7_OVERFLOW) {
			;
		} else if (*(Int64_t *)a2 >= 0) {
			assert(*(Int64_t *)a1 <= Int64_Max - *(Int64_t *)a2);
		} else {
			assert(*(Int64_t *)a1 >= Int64_Min - *(Int64_t *)a2);
		}
		*(Int64_t *)sum = *(Int64_t *)a1 + *(Int64_t *)a2;
	}
}

O7_ALWAYS_INLINE void Int64_Sub(Int64_Type diff, Int64_Type m, Int64_Type s) {
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_sub_overflow(*(Int64_t *)m, *(Int64_t *)s,
		                                  (Int64_t *)diff);
		assert(!overflow);
	} else {
		if (!O7_OVERFLOW) {
			;
		} else if (*(Int64_t *)s >= 0) {
			assert(*(Int64_t *)m >= Int64_Min + *(Int64_t *)s);
		} else {
			assert(*(Int64_t *)m <= Int64_Max + *(Int64_t *)s);
		}
		*(Int64_t *)diff = *(Int64_t *)m - *(Int64_t *)s;
	}
}

O7_ALWAYS_INLINE void Int64_Mul(Int64_Type prod, Int64_Type m1, Int64_Type m2) {
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = __builtin_mul_overflow(*(Int64_t *)m1, *(Int64_t *)m2,
		                                  (Int64_t *)prod);
		assert(!overflow);
	} else {
		if (!O7_OVERFLOW) {
			;
		} else if (*(Int64_t *)m2 > 0) {
			if (*(Int64_t *)m1 >= 0) {
				assert(*(Int64_t *)m1 <= Int64_Max / *(Int64_t *)m2);
			} else {
				assert(*(Int64_t *)m1 >= Int64_Min / *(Int64_t *)m2);
			}
		} else if (*(Int64_t *)m2 != 0) {
			if (*(Int64_t *)m1 >= 0) {
				assert(*(Int64_t *)m1 <=
				        ((Int64_ut)(-1 - Int64_Min) + 1u)
				      / ((Int64_ut)(-1 - *(Int64_t *)m2) + 1u)
				);
			} else {
				assert(*(Int64_t *)m1 >= Int64_Max / *(Int64_t *)m2);
			}
		}
		*(Int64_t *)prod = *(Int64_t *)m1 * *(Int64_t *)m2;
	}
}

O7_ALWAYS_INLINE void Int64_CheckDiv(Int64_Type n, Int64_Type d) {
	if (O7_OVERFLOW) {
		if (O7_DIV_ZERO) {
			assert(*(Int64_t *)d != 0);
		}
		if (Int64_Min < -Int64_Max) {
			assert((*(Int64_t *)d != -1) || (*(Int64_t *)n != Int64_Min));
		}
	}
}

O7_ALWAYS_INLINE void Int64_Div(Int64_Type div, Int64_Type n, Int64_Type d) {
	Int64_CheckDiv(n, d);
	*(Int64_t *)div = *(Int64_t *)n / *(Int64_t *)d;
}

O7_ALWAYS_INLINE void Int64_Mod(Int64_Type mod, Int64_Type n, Int64_Type d) {
	Int64_CheckDiv(n, d);
	*(Int64_t *)mod = *(Int64_t *)n % *(Int64_t *)d;
}

O7_ALWAYS_INLINE void
	Int64_DivMod(Int64_Type div, Int64_Type mod, Int64_Type n, Int64_Type d)
{
	Int64_CheckDiv(n, d);
	*(Int64_t *)div = *(Int64_t *)n / *(Int64_t *)d;
	*(Int64_t *)mod = *(Int64_t *)n % *(Int64_t *)d;
}

O7_ALWAYS_INLINE int Int64_Cmp(Int64_Type l, Int64_Type r) {
	int cmp;
	if (*(Int64_t *)l < *(Int64_t *)r) {
		cmp = -1;
	} else if (*(Int64_t *)l > *(Int64_t *)r) {
		cmp = +1;
	} else {
		cmp = 0;
	}
	return cmp;
}

O7_ALWAYS_INLINE void Int64_Neg(Int64_Type neg, Int64_Type pos) {
	if (O7_OVERFLOW) {
		assert(*(Int64_t *)pos >= -Int64_Max);
	}
	*(Int64_t *)neg = -*(Int64_t *)pos;
}

O7_ALWAYS_INLINE void Int64_init(void) {
	*(Int64_t *)Int64_min = Int64_Min;
	*(Int64_t *)Int64_max = Int64_Max;
}

#if defined(O7_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF)
#	undef O7_GNUC_BUILTIN_OVERFLOW_NEED_UNDEF
#	undef __builtin_add_overflow
#	undef __builtin_sub_overflow
#	undef __builtin_mul_overflow
#endif

#endif
