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
#if !defined HEADER_GUARD_Int32
#    define  HEADER_GUARD_Int32 1

typedef o7_int_t  Int32_t;
typedef o7_uint_t Int32_ut;
#define Int32_Max   O7_INT_MAX
#define Int32_Min (-O7_INT_MAX + (INT_MIN + INT_MAX))

#define Int32_Size_cnst ((int)sizeof(Int32_t))

typedef o7_char Int32_Type[Int32_Size_cnst];

static Int32_Type Int32_min, Int32_max;

O7_ALWAYS_INLINE void Int32_FromInt(Int32_Type v, o7_int_t i) {
	*(Int32_t *)v = o7_int(i);
}

O7_ALWAYS_INLINE void Int32_ToInt(o7_int_t *i, Int32_Type v) {
	if (O7_OVERFLOW) {
		assert(-O7_INT_MAX <= *(Int32_t *)v);
	}
	*i = *(Int32_t *)v;
}

O7_ALWAYS_INLINE void Int32_Add(Int32_Type sum, Int32_Type a1, Int32_Type a2) {
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SADD(*(Int32_t *)a1, *(Int32_t *)a2, (Int32_t *)sum);
		assert(!overflow);
	} else {
		if (!O7_OVERFLOW) {
			;
		} else if (0 <= *(Int32_t *)a2) {
			assert(*(Int32_t *)a1 <= Int32_Max - *(Int32_t *)a2);
		} else {
			assert(*(Int32_t *)a1 >= Int32_Min - *(Int32_t *)a2);
		}
		*(Int32_t *)sum = *(Int32_t *)a1 + *(Int32_t *)a2;
	}
}

O7_ALWAYS_INLINE void Int32_Sub(Int32_Type diff, Int32_Type m, Int32_Type s) {
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SSUB(*(Int32_t *)m, *(Int32_t *)s, (Int32_t *)diff);
		assert(!overflow);
	} else {
		if (!O7_OVERFLOW) {
			;
		} else if (0 <= *(Int32_t *)s) {
			assert(*(Int32_t *)m >= Int32_Min + *(Int32_t *)s);
		} else {
			assert(*(Int32_t *)m <= Int32_Max + *(Int32_t *)s);
		}
		*(Int32_t *)diff = *(Int32_t *)m - *(Int32_t *)s;
	}
}

O7_ALWAYS_INLINE void Int32_Mul(Int32_Type prod, Int32_Type m1, Int32_Type m2) {
	o7_cbool overflow;
	if (O7_OVERFLOW && O7_GNUC_BUILTIN_OVERFLOW) {
		overflow = O7_GNUC_SMUL(*(Int32_t *)m1, *(Int32_t *)m2, (Int32_t *)prod);
		assert(!overflow);
	} else {
		if (!O7_OVERFLOW) {
			;
		} else if (0 < *(Int32_t *)m2) {
			if (0 <= *(Int32_t *)m1) {
				assert(*(Int32_t *)m1 <= Int32_Max / *(Int32_t *)m2);
			} else {
				assert(*(Int32_t *)m1 >= Int32_Min / *(Int32_t *)m2);
			}
		} else if (*(Int32_t *)m2 != 0) {
			if (0 <= *(Int32_t *)m1) {
				assert(*(Int32_t *)m1 <=
				        ((Int32_ut)(-1 - Int32_Min) + 1u)
				      / ((Int32_ut)(-1 - *(Int32_t *)m2) + 1u)
				);
			} else {
				assert(*(Int32_t *)m1 >= Int32_Max / *(Int32_t *)m2);
			}
		}
		*(Int32_t *)prod = *(Int32_t *)m1 * *(Int32_t *)m2;
	}
}

O7_ALWAYS_INLINE void Int32_CheckDiv(Int32_Type n, Int32_Type d) {
	if (O7_OVERFLOW) {
		if (O7_DIV_ZERO) {
			assert(*(Int32_t *)d != 0);
		}
		if (Int32_Min < -Int32_Max) {
			assert((*(Int32_t *)d != -1) || (*(Int32_t *)n != Int32_Min));
		}
	}
}

O7_ALWAYS_INLINE void Int32_Div(Int32_Type div, Int32_Type n, Int32_Type d) {
	Int32_CheckDiv(n, d);
	*(Int32_t *)div = *(Int32_t *)n / *(Int32_t *)d;
}

O7_ALWAYS_INLINE void Int32_Mod(Int32_Type mod, Int32_Type n, Int32_Type d) {
	Int32_CheckDiv(n, d);
	*(Int32_t *)mod = *(Int32_t *)n % *(Int32_t *)d;
}

O7_ALWAYS_INLINE void
	Int32_DivMod(Int32_Type div, Int32_Type mod, Int32_Type n, Int32_Type d)
{
	Int32_CheckDiv(n, d);
	*(Int32_t *)div = *(Int32_t *)n / *(Int32_t *)d;
	*(Int32_t *)mod = *(Int32_t *)n % *(Int32_t *)d;
}

O7_ALWAYS_INLINE int Int32_Cmp(Int32_Type l, Int32_Type r) {
	int cmp;
	if (*(Int32_t *)l < *(Int32_t *)r) {
		cmp = -1;
	} else if (*(Int32_t *)l > *(Int32_t *)r) {
		cmp = +1;
	} else {
		cmp = 0;
	}
	return cmp;
}

O7_ALWAYS_INLINE void Int32_Neg(Int32_Type neg, Int32_Type pos) {
	if (O7_OVERFLOW) {
		assert(-Int32_Max <= *(Int32_t *)pos);
	}
	*(Int32_t *)neg = -*(Int32_t *)pos;
}

O7_ALWAYS_INLINE void Int32_init(void) {
	*(Int32_t *)Int32_min = Int32_Min;
	*(Int32_t *)Int32_max = Int32_Max;
}
O7_ALWAYS_INLINE void Int32_done(void) {}

#endif
